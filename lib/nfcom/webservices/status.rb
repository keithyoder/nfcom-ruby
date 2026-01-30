# frozen_string_literal: true

module Nfcom
  module Webservices
    # Consulta o status do serviço NFCom na SEFAZ
    #
    # Implementa a operação "Status do Serviço", utilizada para verificar
    # se o ambiente da SEFAZ está disponível.
    class Status < Base
      # Executa a consulta de status do serviço NFCom
      #
      # @return [String] Resposta SOAP bruta da SEFAZ
      # @raise [Errors::ConfigurationError] se a URL não estiver configurada
      # @raise [Errors::SefazError] se houver erro na comunicação
      def verificar
        url = url_status!

        body_xml = build_status_body
        envelope = montar_envelope(body_xml)

        post_soap(
          url: url,
          action: soap_action,
          xml: envelope
        )
      rescue StandardError => e
        configuration.logger&.error("Erro ao consultar Status NFCom: #{e.message}")
        raise
      end

      private

      def url_status!
        configuration.webservice_url(:status) ||
          raise(
            Errors::ConfigurationError,
            "URL de status não configurada para #{configuration.estado}"
          )
      end

      def soap_action
        'http://www.portalfiscal.inf.br/nfcom/wsdl/NFComStatusServico/nfcomStatusServico'
      end

      # Monta o XML da consulta de status do serviço
      #
      # Importante:
      # - A mensagem NÃO deve ser compactada
      # - Deve seguir exatamente o schema NFCom v1.00
      #
      # @return [String]
      def build_status_body
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
    end
  end
end
