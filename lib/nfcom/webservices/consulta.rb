# frozen_string_literal: true

module Nfcom
  module Webservices
    # Consulta situação de uma NFCom na SEFAZ
    #
    # Implementa a operação "Consulta Protocolo", utilizada para verificar
    # a situação de uma NFCom já transmitida.
    #
    # Fluxo:
    # 1. Resolve a URL do webservice de consulta conforme UF e ambiente
    # 2. Monta o XML de consulta com a chave de acesso
    # 3. Encapsula a mensagem em envelope SOAP 1.2
    # 4. Envia a requisição via POST
    # 5. Extrai e normaliza a resposta
    class Consulta < Base
      # Consulta a situação de uma NFCom pela chave de acesso
      #
      # @param chave_acesso [String] Chave de acesso da NFCom (44 dígitos)
      # @return [Net::HTTPResponse] Resposta HTTP da SEFAZ
      # @raise [Errors::ConfigurationError] se a URL não estiver configurada
      # @raise [Errors::SefazError] se a resposta for inválida
      def consultar(chave_acesso)
        url = url_consulta!
        xml = xml_consulta_nfcom(chave_acesso)
        soap_xml = montar_envelope(xml)

        enviar_requisicao(url, soap_xml)
      rescue StandardError => e
        configuration.logger&.error("Erro ao consultar NFCom: #{e.message}")
        raise
      end

      private

      # Obtém a URL do webservice de consulta ou levanta erro se não configurada
      #
      # @return [String] URL do serviço de consulta
      def url_consulta!
        configuration.webservice_url(:consulta) ||
          raise(
            Errors::ConfigurationError,
            "URL de consulta não configurada para #{configuration.estado}"
          )
      end

      # Monta o XML da consulta de NFCom
      #
      # @param chave_acesso [String] Chave de acesso da NFCom
      # @return [String] XML da requisição
      def xml_consulta_nfcom(chave_acesso)
        <<~XML
          <nfcomConsultaNF xmlns="http://www.portalfiscal.inf.br/nfcom/wsdl/NFComConsulta">
            <NFComDadosMsg>
              <consSitNFCom xmlns="http://www.portalfiscal.inf.br/nfcom" versao="1.00">
                <tpAmb>#{configuration.ambiente_codigo}</tpAmb>
                <chNFCom>#{chave_acesso}</chNFCom>
              </consSitNFCom>
            </NFComDadosMsg>
          </nfcomConsultaNF>
        XML
      end

      # Retorna a SOAP Action do serviço de consulta
      #
      # @return [String]
      def soap_action
        'http://www.portalfiscal.inf.br/nfcom/wsdl/NFComConsulta/nfcomConsultaNF'
      end

      # Envia a requisição SOAP para a SEFAZ
      #
      # @param url [String] Endpoint do webservice
      # @param soap_xml [String] Envelope SOAP
      # @return [Net::HTTPResponse] Resposta HTTP bruta
      def enviar_requisicao(url, soap_xml)
        uri = URI.parse(url)
        http = configure_http_client(uri)
        request = build_http_request(uri, soap_action, soap_xml)

        log_request(soap_xml) if configuration.log_level == :debug

        response = execute_request(http, request)

        log_response(response) if configuration.log_level == :debug

        validate_http_response(response)
        response
      rescue Net::OpenTimeout, Net::ReadTimeout, Timeout::Error # rubocop:disable Lint/ShadowedException
        raise Errors::TimeoutError, 'Timeout na comunicação com SEFAZ'
      rescue OpenSSL::SSL::SSLError => e
        raise Errors::SefazError, "Erro SSL: #{e.message}"
      rescue StandardError => e
        raise Errors::SefazError, "Erro SOAP: #{e.message}"
      end
    end
  end
end
