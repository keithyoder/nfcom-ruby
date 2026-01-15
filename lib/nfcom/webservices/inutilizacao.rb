# frozen_string_literal: true

module Nfcom
  module Webservices
    class Inutilizacao < Base
      def inutilizar(serie:, numero_inicial:, numero_final:, justificativa:) # rubocop:disable Metrics/MethodLength
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
            soap_action: 'http://www.portalfiscal.inf.br/nfcom/wsdl/nfcomInutilizacao',
            message: { 'nfcomDadosMsg' => message }
          )

          extrair_resposta(response, :nfcom_inutilizacao_response)
        rescue StandardError => e
          tratar_erro_soap(e)
        end
      end
    end
  end
end
