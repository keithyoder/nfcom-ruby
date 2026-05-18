# frozen_string_literal: true

module Nfcom
  module Webservices
    # Consulta situação de uma NFCom na SEFAZ
    #
    # Implementa a operação "Consulta Protocolo", utilizada para verificar
    # a situação de uma NFCom já transmitida.
    class Consulta < Base
      # Consulta a situação de uma NFCom pela chave de acesso
      #
      # @param chave_acesso [String] Chave de acesso da NFCom (44 dígitos)
      # @return [String] Resposta SOAP bruta da SEFAZ
      # @raise [Errors::ConfigurationError] se a URL não estiver configurada
      # @raise [Errors::SefazError] se houver erro na comunicação
      def consultar(chave_acesso)
        url = url_consulta!

        body_xml  = build_consulta_body(chave_acesso)
        envelope  = montar_envelope(body_xml)

        post_soap(
          url: url,
          action: soap_action,
          xml: envelope
        )
      rescue StandardError => e
        configuration.logger&.error("Erro ao consultar NFCom: #{e.message}")
        raise
      end

      private

      def url_consulta!
        configuration.webservice_url(:consulta) ||
          raise(
            Errors::ConfigurationError,
            "URL de consulta não configurada para #{configuration.estado}"
          )
      end

      def soap_action
        'http://www.portalfiscal.inf.br/nfcom/wsdl/NFComConsulta/nfcomConsultaNF'
      end

      def build_consulta_body(chave_acesso)
        <<~XML.strip
          <nfcomDadosMsg xmlns="http://www.portalfiscal.inf.br/nfcom/wsdl/NFComConsulta">
            <consSitNFCom xmlns="http://www.portalfiscal.inf.br/nfcom" versao="1.00">
              <tpAmb>#{configuration.ambiente_codigo}</tpAmb>
              <xServ>CONSULTAR</xServ>
              <chNFCom>#{chave_acesso}</chNFCom>
            </consSitNFCom>
          </nfcomDadosMsg>
        XML
      end
    end
  end
end
