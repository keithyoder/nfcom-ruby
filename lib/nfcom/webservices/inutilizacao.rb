# frozen_string_literal: true

module Nfcom
  module Webservices
    class Inutilizacao < Base
      # Solicita inutilização de faixa de numeração de NFCom
      #
      # @return [String] XML SOAP bruto retornado pela SEFAZ
      def inutilizar(serie:, numero_inicial:, numero_final:, justificativa:)
        url = url_inutilizacao!

        body_xml = build_inutilizacao_body(
          serie: serie,
          numero_inicial: numero_inicial,
          numero_final: numero_final,
          justificativa: justificativa
        )

        envelope = montar_envelope(body_xml)

        post_soap(
          url: url,
          action: soap_action,
          xml: envelope
        )
      rescue StandardError => e
        configuration.logger&.error("Erro ao inutilizar NFCom: #{e.message}")
        raise
      end

      private

      def url_inutilizacao!
        configuration.webservice_url(:inutilizacao) ||
          raise(
            Errors::ConfigurationError,
            "URL de inutilização não configurada para #{configuration.estado}"
          )
      end

      def soap_action
        'http://www.portalfiscal.inf.br/nfcom/wsdl/nfcomInutilizacao'
      end

      # Monta o XML da inutilização conforme schema NFCom
      #
      # @return [String]
      def build_inutilizacao_body(serie:, numero_inicial:, numero_final:, justificativa:)
        <<~XML
          <nfcomInutilizacaoNF xmlns="http://www.portalfiscal.inf.br/nfcom/wsdl/nfcomInutilizacao">
            <NFComDadosMsg>
              <inutNFCom xmlns="http://www.portalfiscal.inf.br/nfcom" versao="1.00">
                <infInut>
                  <tpAmb>#{configuration.ambiente_codigo}</tpAmb>
                  <cUF>#{configuration.codigo_uf}</cUF>
                  <ano>#{Time.now.strftime('%y')}</ano>
                  <CNPJ>#{configuration.cnpj.gsub(/\D/, '')}</CNPJ>
                  <mod>62</mod>
                  <serie>#{serie}</serie>
                  <nNFIni>#{numero_inicial}</nNFIni>
                  <nNFFin>#{numero_final}</nNFFin>
                  <xJust>#{justificativa}</xJust>
                </infInut>
              </inutNFCom>
            </NFComDadosMsg>
          </nfcomInutilizacaoNF>
        XML
      end
    end
  end
end
