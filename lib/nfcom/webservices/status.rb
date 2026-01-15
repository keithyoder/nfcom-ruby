# frozen_string_literal: true

module Nfcom
  module Webservices
    class Status < Base
      def verificar
        url = configuration.webservice_url(:status)
        unless url
          raise Errors::ConfigurationError,
                "URL de status não configurada para #{configuration.estado}"
        end

        # ------------------------------------------------------------
        # Corpo da mensagem (SEM compactação, conforme manual)
        # ------------------------------------------------------------
        body_xml = <<~XML
          <nfcomStatusServicoNF xmlns="http://www.portalfiscal.inf.br/nfcom/wsdl/NFComStatusServico">
            <NFComDadosMsg>
              <consStatServNFCom xmlns="http://www.portalfiscal.inf.br/nfcom" versao="1.00">
                <tpAmb>#{configuration.ambiente_codigo}</tpAmb>
                <xServ>STATUS</xServ>
              </consStatServNFCom>
            </NFComDadosMsg>
          </nfcomStatusServicoNF>
        XML

        # ------------------------------------------------------------
        # Envelope SOAP 1.2
        # ------------------------------------------------------------
        soap_xml = montar_envelope(body_xml)

        # ------------------------------------------------------------
        # Envio
        # ------------------------------------------------------------
        action =
          'http://www.portalfiscal.inf.br/nfcom/wsdl/NFComStatusServico/nfcomStatusServico'

        doc = post_soap(
          url: url,
          action: action,
          xml: soap_xml
        )

        # ------------------------------------------------------------
        # Extração da resposta
        # ------------------------------------------------------------
        extrair_resultado(doc)
      rescue StandardError => e
        configuration.logger&.error("Erro ao consultar Status NFCom: #{e.message}")
        raise
      end

      private

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
