# frozen_string_literal: true

module Nfcom
  module Webservices
    class Inutilizacao < Base
      def inutilizar(serie:, numero_inicial:, numero_final:, justificativa:)
        url = configuration.webservice_url(:inutilizacao)
        raise Errors::ConfigurationError, "URL de inutilização não configurada para #{configuration.estado}" unless url

        client = criar_cliente_soap(url)

        message = {
          'versao' => '1.00',
          'infInut' => {
            'tpAmb' => configuration.ambiente_codigo,
            'cUF' => configuration.codigo_uf,
            'ano' => Time.now.strftime('%y'),
            'CNPJ' => configuration.cnpj.gsub(/\D/, ''),
            'mod' => '62',
            'serie' => serie,
            'nNFIni' => numero_inicial,
            'nNFFin' => numero_final,
            'xJust' => justificativa
          }
        }

        begin
          response = client.call(
            :nfcom_inutilizacao,
            message: { 'nfcomDadosMsg' => message }
          )

          extrair_resposta(response, :nfcom_inutilizacao_response)
        rescue => e
          tratar_erro_soap(e)
        end
      end
    end
  end
end
