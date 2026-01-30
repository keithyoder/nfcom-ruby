# frozen_string_literal: true

module Nfcom
  module Webservices
    class Autorizacao < Base
      def enviar(xml_assinado)
        url = configuration.webservice_url(:recepcao)
        unless url
          raise Errors::ConfigurationError,
                "URL de recepção não configurada para #{configuration.estado}"
        end

        xml_limpo = Utils::XmlCleaner.clean(xml_assinado)
        configuration.logger&.debug("XML da nota:\n#{xml_limpo}") if configuration.log_level == :debug

        xml_comprimido = Utils::Compressor.gzip_base64(xml_limpo)

        body_xml = build_nfcom_body(xml_comprimido)
        envelope = montar_envelope(body_xml)

        action = 'http://www.portalfiscal.inf.br/nfcom/wsdl/NFComRecepcao/nfcomRecepcao'
        post_soap(url: url, action: action, xml: envelope)
      end

      private

      def build_nfcom_body(xml_comprimido)
        <<~XML
          <nfcomDadosMsg xmlns="http://www.portalfiscal.inf.br/nfcom/wsdl/NFComRecepcao">
            #{xml_comprimido}
          </nfcomDadosMsg>
        XML
      end
    end
  end
end
