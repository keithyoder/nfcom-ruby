# frozen_string_literal: true

module Nfcom
  module Webservices
    class Consulta < Base
      def consultar(chave_acesso)
        url = configuration.webservice_url(:consulta)
        raise Errors::ConfigurationError, "URL de consulta não configurada para #{configuration.estado}" unless url

        client = criar_cliente_soap(url)

        message = {
          'versao' => '1.00',
          'tpAmb' => configuration.ambiente_codigo,
          'chNFCom' => chave_acesso
        }

        begin
          response = client.call(
            :nfcom_consulta_protocolo,
            message: { 'nfcomDadosMsg' => message }
          )

          extrair_resposta(response, :nfcom_consulta_protocolo_response)
        rescue StandardError => e
          tratar_erro_soap(e)
        end
      end
    end
  end
end
