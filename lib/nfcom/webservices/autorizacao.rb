# frozen_string_literal: true

module Nfcom
  module Webservices
    class Autorizacao < Base
      def enviar(xml_assinado)
        url = configuration.webservice_url(:autorizacao)
        raise Errors::ConfigurationError, "URL de autorização não configurada para #{configuration.estado}" unless url

        client = criar_cliente_soap(url)

        message = {
          'nfcomDadosMsg' => xml_assinado
        }

        begin
          response = client.call(
            :nfcom_autorizacao,
            message: message
          )

          extrair_resposta(response, :nfcom_autorizacao_response)
        rescue StandardError => e
          tratar_erro_soap(e)
        end
      end
    end
  end
end
