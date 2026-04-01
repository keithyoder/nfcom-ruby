# frozen_string_literal: true

module Nfcom
  module Webservices
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

      def post_soap(url:, action:, xml:)
        uri  = URI.parse(url)
        http = configure_http_client(uri)
        req  = build_http_request(uri, action, xml)

        log_request(xml)
        response = http.request(req)
        log_response(response)

        validate_http_response(response)

        response.body
      rescue ::Timeout::Error
        raise Errors::TimeoutError, 'Timeout na comunicação com SEFAZ'
      rescue OpenSSL::SSL::SSLError => e
        raise Errors::SefazError, "Erro SSL: #{e.message}"
      rescue StandardError => e
        raise Errors::SefazError, "Erro SOAP: #{e.message}"
      end

      def montar_envelope(body_xml)
        xml = '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">' \
              '<soap:Body>' \
              "#{body_xml}" \
              '</soap:Body>' \
              '</soap:Envelope>'
        Utils::XmlCleaner.clean(xml)
      end

      private

      def configure_http_client(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl     = uri.scheme == 'https'
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http.open_timeout = configuration.timeout
        http.read_timeout = configuration.timeout

        cert = certificate.to_pem
        http.cert = OpenSSL::X509::Certificate.new(cert[:cert])
        http.key  = OpenSSL::PKey::RSA.new(cert[:key])

        http
      end

      def build_http_request(uri, action, xml)
        path = uri.request_uri
        path = '/' if path.nil? || path.empty?

        request = Net::HTTP::Post.new(path)
        request['Content-Type'] =
          %(application/soap+xml;charset=UTF-8;action="#{action}")
        request.body = xml
        request
      end

      def validate_http_response(response)
        return if response.is_a?(Net::HTTPSuccess)

        raise Errors::SefazError,
              "Erro HTTP #{response.code}: #{response.message}"
      end

      def log_request(xml)
        return unless configuration.log_level == :debug

        configuration.logger&.debug("SOAP Request:\n#{xml}")
      end

      def log_response(response)
        return unless configuration.log_level == :debug

        configuration.logger&.debug(
          "SOAP Response (raw):\n#{response.body}"
        )
      end
    end
  end
end
