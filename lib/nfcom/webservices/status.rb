# frozen_string_literal: true

module Nfcom
  module Webservices
    # Consulta o status do serviço NFCom na SEFAZ
    #
    # Implementa a operação "Status do Serviço", utilizada para verificar
    # se o ambiente da SEFAZ está disponível para recepção de NFCom.
    #
    # Fluxo:
    # 1. Resolve a URL do webservice de status conforme UF e ambiente
    # 2. Monta o XML de consulta conforme o schema NFCom
    # 3. Encapsula a mensagem em envelope SOAP 1.2
    # 4. Envia a requisição via POST
    # 5. Extrai e normaliza a resposta
    class Status < Base
      # Executa a consulta de status do serviço NFCom
      #
      # @return [Hash] Dados normalizados da resposta da SEFAZ
      # @raise [Errors::ConfigurationError] se a URL não estiver configurada
      # @raise [Errors::SefazError] se a resposta for inválida
      def verificar
        url = url_status!
        xml = xml_status_servico
        soap_xml = montar_envelope(xml)

        doc = enviar_requisicao(url, soap_xml)
        extrair_resultado(doc)
      rescue StandardError => e
        configuration.logger&.error("Erro ao consultar Status NFCom: #{e.message}")
        raise
      end

      private

      # Obtém a URL do webservice de status ou levanta erro se não configurada
      #
      # @return [String] URL do serviço de status
      def url_status!
        configuration.webservice_url(:status) ||
          raise(
            Errors::ConfigurationError,
            "URL de status não configurada para #{configuration.estado}"
          )
      end

      # Monta o XML da consulta de status do serviço
      #
      # Importante:
      # - A mensagem NÃO deve ser compactada
      # - Deve seguir exatamente o schema NFCom v1.00
      #
      # @return [String] XML da requisição
      def xml_status_servico
        <<~XML
          <nfcomStatusServicoNF xmlns="http://www.portalfiscal.inf.br/nfcom/wsdl/NFComStatusServico">
            <NFComDadosMsg>
              <consStatServNFCom xmlns="http://www.portalfiscal.inf.br/nfcom" versao="1.00">
                <tpAmb>#{configuration.ambiente_codigo}</tpAmb>
                <xServ>STATUS</xServ>
              </consStatServNFCom>
            </NFComDadosMsg>
          </nfcomStatusServicoNF>
        XML
      end

      # Retorna a SOAP Action do serviço de status
      #
      # @return [String]
      def soap_action
        'http://www.portalfiscal.inf.br/nfcom/wsdl/NFComStatusServico/nfcomStatusServico'
      end

      # Envia a requisição SOAP para a SEFAZ
      #
      # @param url [String] Endpoint do webservice
      # @param soap_xml [String] Envelope SOAP
      # @return [Nokogiri::XML::Document]
      def enviar_requisicao(url, soap_xml)
        post_soap(
          url: url,
          action: soap_action,
          xml: soap_xml
        )
      end

      # Extrai e normaliza os dados da resposta da SEFAZ
      #
      # @param doc [Nokogiri::XML::Document]
      # @return [Hash]
      # @raise [Errors::SefazError] se o XML retornado for inválido
      def extrair_resultado(doc)
        ret = doc.at_xpath('//retConsStatServNFCom')

        raise Errors::SefazError, 'Resposta inválida do serviço Status' unless ret

        {
          cstat: ret.at_xpath('cStat')&.text,
          xmotivo: ret.at_xpath('xMotivo')&.text,
          tpamb: ret.at_xpath('tpAmb')&.text,
          cuf: ret.at_xpath('cUF')&.text,
          dh_retorno: ret.at_xpath('dhRecbto')&.text,
          versao: ret['versao']
        }
      end
    end
  end
end
