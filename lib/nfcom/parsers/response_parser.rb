# frozen_string_literal: true

module Nfcom
  module Parsers
    # Interpreta as respostas XML da SEFAZ para diferentes operações
    #
    # Esta classe é responsável por processar as respostas SOAP retornadas
    # pela SEFAZ e convertê-las em hashes Ruby com informações estruturadas.
    #
    # @example Processar resposta de autorização
    #   response = webservice.autorizar(xml)
    #   parser = Nfcom::Parsers::ResponseParser.new(response)
    #   resultado = parser.parse_autorizacao
    #
    #   if resultado[:autorizada]
    #     puts "Nota autorizada!"
    #     puts "Protocolo: #{resultado[:protocolo]}"
    #     puts "Chave: #{resultado[:chave]}"
    #   end
    #
    # @example Consultar status do serviço
    #   response = webservice.status
    #   parser = Nfcom::Parsers::ResponseParser.new(response)
    #   status = parser.parse_status
    #
    #   if status[:online]
    #     puts "SEFAZ online (#{status[:tempo_medio]}ms)"
    #   else
    #     puts "SEFAZ offline: #{status[:motivo]}"
    #   end
    #
    # @example Consultar situação de uma nota
    #   response = webservice.consultar(chave)
    #   parser = Nfcom::Parsers::ResponseParser.new(response)
    #   consulta = parser.parse_consulta
    #
    #   puts "Situação: #{consulta[:situacao]}"
    #   puts "Protocolo: #{consulta[:protocolo]}"
    #
    # @example Tratar erro de autorização
    #   begin
    #     resultado = parser.parse_autorizacao
    #   rescue Nfcom::Errors::NotaRejeitada => e
    #     puts "Nota rejeitada [#{e.codigo}]: #{e.motivo}"
    #   rescue Nfcom::Errors::NotaDenegada => e
    #     puts "Nota denegada: #{e.message}"
    #   end
    #
    # Métodos de parsing:
    #
    # - parse_autorizacao - Processa resposta de autorização de nota
    #   Retorna: { autorizada, protocolo, chave, data_autorizacao, xml, mensagem }
    #   Códigos: '100' = Autorizada, '110' = Denegada, outros = Rejeitada
    #
    # - parse_consulta - Processa resposta de consulta de nota
    #   Retorna: { codigo, motivo, situacao, protocolo, data_autorizacao }
    #   Situações: 'Autorizada', 'Cancelada', 'Denegada', 'Desconhecida'
    #
    # - parse_status - Processa resposta de status do serviço
    #   Retorna: { online, codigo, motivo, tempo_medio, data_hora }
    #   Código: '107' = Serviço em operação
    #
    # - parse_inutilizacao - Processa resposta de inutilização de numeração
    #   Retorna: { inutilizada, codigo, motivo, protocolo }
    #   Código: '102' = Inutilização homologada
    #
    # Códigos de status comuns da SEFAZ:
    # - 100 - Autorizado o uso da NF-COM
    # - 102 - Inutilização de número homologado
    # - 107 - Serviço em Operação
    # - 110 - Uso Denegado (irregularidade fiscal do emitente)
    # - 101 - Cancelamento de NF-COM homologado
    # - 135 - Evento registrado e vinculado a NF-COM
    #
    # Exceções lançadas:
    # - Errors::NotaRejeitada - Quando a nota é rejeitada pela SEFAZ
    # - Errors::NotaDenegada - Quando o uso da nota é denegado
    #
    # @note Este parser é usado internamente pelo Client, você normalmente
    #   não precisa instanciá-lo diretamente.
    class ResponseParser
      class NotaRejeitada < StandardError
        attr_reader :codigo, :motivo

        def initialize(codigo, motivo)
          @codigo = codigo
          @motivo = motivo
          super("#{codigo}: #{motivo}")
        end
      end
      attr_reader :http_response, :document

      def initialize(http_response)
        @http_response = http_response

        # Convert HTTP response body to Nokogiri document
        @document = Nokogiri::XML(http_response.body)
      end

      # Processa resposta de autorização
      def parse_autorizacao
        ret = extract_ret_nfcom
        validate_response!(ret)

        c_stat, x_motivo = extract_status(ret)
        prot_hash = extract_protocol(ret)

        validate_authorization!(c_stat, x_motivo)

        build_success_response(prot_hash, x_motivo)
      end

      def parse_consulta
        codigo = response.dig(:ret_cons_sit_nfcom, :c_stat)
        motivo = response.dig(:ret_cons_sit_nfcom, :x_motivo)

        {
          codigo: codigo,
          motivo: motivo,
          situacao: interpretar_situacao(codigo),
          protocolo: response.dig(:ret_cons_sit_nfcom, :prot_nfcom, :n_prot),
          data_autorizacao: response.dig(:ret_cons_sit_nfcom, :prot_nfcom, :dh_rec_bto)
        }
      end

      def parse_status
        codigo = response.dig(:ret_cons_stat_serv, :c_stat)
        motivo = response.dig(:ret_cons_stat_serv, :x_motivo)
        tempo_medio = response.dig(:ret_cons_stat_serv, :t_med)

        {
          online: codigo.to_s == '107',
          codigo: codigo,
          motivo: motivo,
          tempo_medio: tempo_medio,
          data_hora: response.dig(:ret_cons_stat_serv, :dh_recbto)
        }
      end

      def parse_inutilizacao
        codigo = response.dig(:ret_inut_nfcom, :inf_inut, :c_stat)
        motivo = response.dig(:ret_inut_nfcom, :inf_inut, :x_motivo)

        {
          inutilizada: codigo.to_s == '102',
          codigo: codigo,
          motivo: motivo,
          protocolo: response.dig(:ret_inut_nfcom, :inf_inut, :n_prot)
        }
      end

      private

      def interpretar_situacao(codigo)
        case codigo.to_s
        when '100', '150'
          'Autorizada'
        when '110', '301', '302'
          'Denegada'
        when '101', '151', '155'
          'Cancelada'
        else
          'Desconhecida'
        end
      end

      # Namespaces XML padrão para NFCom
      def nfcom_namespaces
        {
          'soap' => 'http://www.w3.org/2003/05/soap-envelope',
          'nfcom' => 'http://www.portalfiscal.inf.br/nfcom'
        }
      end

      # Extrai o elemento retNFCom do documento
      def extract_ret_nfcom
        document.at_xpath('//nfcom:retNFCom', nfcom_namespaces)
      end

      # Valida se a resposta contém o elemento esperado
      def validate_response!(ret)
        raise NotaRejeitada.new('000', 'Resposta inválida') unless ret
      end

      # Extrai código de status e motivo
      def extract_status(ret)
        c_stat = ret.at_xpath('.//nfcom:cStat', nfcom_namespaces)&.text
        x_motivo = ret.at_xpath('.//nfcom:xMotivo', nfcom_namespaces)&.text
        [c_stat, x_motivo]
      end

      # Extrai dados do protocolo de autorização
      def extract_protocol(ret)
        prot = ret.at_xpath('.//nfcom:protNFCom', nfcom_namespaces)
        return nil unless prot

        {
          n_prot: prot.at_xpath('.//nfcom:nProt', nfcom_namespaces)&.text,
          ch_nfcom: prot.at_xpath('.//nfcom:chNFCom', nfcom_namespaces)&.text,
          dh_rec_bto: prot.at_xpath('.//nfcom:dhRecbto', nfcom_namespaces)&.text,
          xml: prot.to_xml
        }
      end

      # Valida se a nota foi autorizada
      def validate_authorization!(c_stat, x_motivo)
        raise NotaRejeitada.new(c_stat, x_motivo) unless c_stat == '100'
      end

      # Constrói hash de resposta de sucesso
      def build_success_response(prot_hash, x_motivo)
        {
          autorizada: true,
          protocolo: prot_hash&.dig(:n_prot),
          chave: prot_hash&.dig(:ch_nfcom),
          data_autorizacao: prot_hash&.dig(:dh_rec_bto),
          xml: prot_hash&.dig(:xml),
          mensagem: x_motivo
        }
      end
    end
  end
end
