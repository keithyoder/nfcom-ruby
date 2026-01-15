# frozen_string_literal: true

require 'net/http'
require 'openssl'
require 'nokogiri'

module Nfcom
  module Webservices
    # Classe base para webservices da SEFAZ
    #
    # Fornece infraestrutura comum para comunicação SOAP 1.2
    # com a SEFAZ, incluindo configuração de certificados digitais,
    # timeouts e tratamento de erros.
    class Base
      attr_reader :configuration, :certificate

      def initialize(configuration)
        @configuration = configuration
        @certificate = Utils::Certificate.new(
          configuration.certificado_path,
          configuration.certificado_senha
        )
      end

      protected

      # Envia requisição SOAP 1.2 para SEFAZ
      #
      # @param url [String] URL do webservice
      # @param action [String] SOAP Action
      # @param xml [String] Envelope SOAP completo
      # @return [Nokogiri::XML::Document] Resposta SOAP parseada
      # @raise [Errors::SefazError] Se houver erro na comunicação
      # @raise [Errors::TimeoutError] Se houver timeout
      def post_soap(url:, action:, xml:)
        uri = URI.parse(url)
        http = configure_http_client(uri)

        request = build_http_request(uri, action, xml)

        log_request(xml) if configuration.log_level == :debug

        response = execute_request(http, request)

        log_response(response) if configuration.log_level == :debug

        validate_http_response(response)

        Nokogiri::XML(response.body)
      rescue Net::OpenTimeout, Net::ReadTimeout, Timeout::Error # rubocop:disable Lint/ShadowedException
        raise Errors::TimeoutError, 'Timeout na comunicação com SEFAZ'
      rescue OpenSSL::SSL::SSLError => e
        raise Errors::SefazError, "Erro SSL: #{e.message}"
      rescue StandardError => e
        raise Errors::SefazError, "Erro SOAP: #{e.message}"
      end

      # Constrói envelope SOAP 1.2 padrão (sem Header)
      #
      # @param body_xml [String] Conteúdo do Body
      # @return [String] Envelope SOAP completo
      def montar_envelope(body_xml)
        <<~SOAP
          <soap12:Envelope xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
            <soap12:Body>
              #{body_xml}
            </soap12:Body>
          </soap12:Envelope>
        SOAP
      end

      private

      # Configura cliente HTTP com certificado e timeouts
      def configure_http_client(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        cert_pem = certificate.to_pem
        http.cert = OpenSSL::X509::Certificate.new(cert_pem[:cert])
        http.key = OpenSSL::PKey::RSA.new(cert_pem[:key])

        http.open_timeout = configuration.timeout
        http.read_timeout = configuration.timeout

        http
      end

      # Constrói requisição HTTP POST para SOAP
      def build_http_request(uri, action, xml)
        request = Net::HTTP::Post.new(uri.request_uri)

        # SOAP 1.2 → action vai NO Content-Type
        request['Content-Type'] =
          %(application/soap+xml;charset=UTF-8;action="#{action}")

        request.body = xml
        request
      end

      # Executa requisição HTTP
      def execute_request(http, request)
        http.request(request)
      end

      # Valida resposta HTTP
      def validate_http_response(response)
        return if response.is_a?(Net::HTTPSuccess)

        raise Errors::SefazError,
              "Erro HTTP #{response.code}: #{response.message}"
      end

      # Logging de requisição
      def log_request(xml)
        configuration.logger&.debug("SOAP Request:\n#{xml}")
      end

      # Logging de resposta
      def log_response(response)
        configuration.logger&.debug("SOAP Response:\n#{response.body}")
      end
    end
  end
end
