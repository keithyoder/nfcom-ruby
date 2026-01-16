# frozen_string_literal: true

module Nfcom
  class Client
    attr_reader :configuration

    def initialize(config = nil)
      @configuration = config || Nfcom.configuration
      raise Errors::ConfigurationError, 'Nfcom não está configurado' if @configuration.nil?
    end

    # Autoriza uma nota fiscal
    def autorizar(nota) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      validar_configuracao!

      raise Errors::ValidationError, nota.erros.join(', ') unless nota.valida?

      # Gera chave de acesso
      nota.gerar_chave_acesso

      # Constrói XML
      xml_builder = Builder::XmlBuilder.new(nota, configuration)
      xml = xml_builder.gerar

      # Assina XML
      signature = Builder::Signature.new(configuration)
      xml_assinado = signature.assinar(xml)

      tentativa = 0
      begin
        ws = Webservices::Autorizacao.new(configuration)
        doc = ws.enviar(xml_assinado)
        doc.remove_namespaces!
        ret = doc.at_xpath('//retNFCom')
        raise Errors::SefazError, "Resposta SEFAZ não contém retNFCom. XML: #{doc.to_xml}" unless ret

        nota_status = ret.at_xpath('.//cStat')&.text
        motivo = ret.at_xpath('.//xMotivo')&.text
        nota_autorizada = nota_status == '100'

        if (prot = ret.at_xpath('.//protNFCom'))
          inf_prot = prot.at_xpath('.//infProt')
          nota.protocolo = inf_prot.at_xpath('.//nProt')&.text
          nota.data_autorizacao = inf_prot.at_xpath('.//dhRecbto')&.text
          nota.xml_autorizado = Utils::XmlAuthorized.build_nfcom_proc(
            xml_assinado: xml_assinado,
            xml_protocolo: prot.to_xml
          )
        end

        {
          c_stat: nota_status,
          x_motivo: motivo,
          autorizada: nota_autorizada,
          prot_nfcom: prot&.to_xml
        }
      rescue Errors::SefazIndisponivel => e
        tentativa += 1
        raise e unless tentativa < configuration.max_tentativas

        sleep(configuration.tempo_espera_retry**tentativa)
        retry
      end
    end

    # Consulta uma nota pela chave de acesso
    def consultar_nota(chave:)
      validar_configuracao!

      ws = Webservices::Consulta.new(configuration)
      resposta = ws.consultar(chave)

      parser = Parsers::ResponseParser.new(resposta)
      parser.parse_consulta
    end

    # Verifica status do serviço da SEFAZ
    def status_servico
      validar_configuracao!

      ws = Webservices::Status.new(configuration)
      resposta = ws.verificar

      parser = Parsers::ResponseParser.new(resposta)
      parser.parse_status
    end

    # Inutiliza uma numeração de nota
    def inutilizar(serie:, numero_inicial:, numero_final:, justificativa:)
      validar_configuracao!

      raise Errors::ValidationError, 'Justificativa deve ter no mínimo 15 caracteres' if justificativa.length < 15

      ws = Webservices::Inutilizacao.new(configuration)
      resposta = ws.inutilizar(
        serie: serie,
        numero_inicial: numero_inicial,
        numero_final: numero_final,
        justificativa: justificativa
      )

      parser = Parsers::ResponseParser.new(resposta)
      parser.parse_inutilizacao
    end

    private

    def validar_configuracao!
      erros = []
      erros << 'Certificado não configurado' if configuration.certificado_path.nil?
      erros << 'CNPJ não configurado' if configuration.cnpj.nil?
      erros << 'Inscrição Estadual não configurada' if configuration.inscricao_estadual.nil?
      erros << 'Estado não configurado' if configuration.estado.nil?

      raise Errors::ConfigurationError, erros.join(', ') unless erros.empty?
    end
  end
end
