# frozen_string_literal: true

module Nfcom
  module Webservices
    class Status < Base
      def verificar
        url = configuration.webservice_url(:status)
        raise Errors::ConfigurationError, "URL de status não configurada para #{configuration.estado}" unless url

        client = criar_cliente_soap(url)

        message = {
          'versao' => '1.00',
          'tpAmb' => configuration.ambiente_codigo,
          'cUF' => configuration.codigo_uf,
          'xServ' => 'STATUS'
        }

        begin
          response = client.call(
            :nfcom_status_servico,
            message: { 'nfcomDadosMsg' => message }
          )

          extrair_resposta(response, :nfcom_status_servico_response)
        rescue => e
          tratar_erro_soap(e)
        end
      end
    end
  end
end
