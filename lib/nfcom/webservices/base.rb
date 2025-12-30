# frozen_string_literal: true

require 'savon'

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

      def criar_cliente_soap(wsdl_url)
        cert_pem = @certificate.to_pem

        Savon.client(
          wsdl: wsdl_url,
          ssl_cert: OpenSSL::X509::Certificate.new(cert_pem[:cert]),
          ssl_cert_key: OpenSSL::PKey::RSA.new(cert_pem[:key]),
          ssl_verify_mode: :peer,
          open_timeout: configuration.timeout,
          read_timeout: configuration.timeout,
          log: configuration.log_level == :debug,
          pretty_print_xml: configuration.log_level == :debug,
          logger: configuration.logger,
          log_level: configuration.log_level || :info,
          convert_request_keys_to: :none, # Não converter nomes de tags
          env_namespace: :soap,
          namespace_identifier: :nfcom
        )
      rescue Savon::Error => e
        raise Errors::SefazError, "Erro ao criar cliente SOAP: #{e.message}"
      end

      def tratar_erro_soap(error)
        case error
        when Savon::SOAPFault
          raise Errors::SefazError, "Erro SOAP: #{error.message}"
        when Savon::HTTPError
          raise Errors::SefazIndisponivel, 'SEFAZ temporariamente indisponível' if error.http.code == 503

          raise Errors::SefazError, "Erro HTTP #{error.http.code}: #{error.message}"

        when Errno::ETIMEDOUT, Timeout::Error
          raise Errors::TimeoutError, 'Timeout na comunicação com SEFAZ'
        else
          raise Errors::SefazError, "Erro desconhecido: #{error.message}"
        end
      end

      def extrair_resposta(response, tag_resposta)
        body = response.body
        body[tag_resposta] || {}
      rescue StandardError => e
        raise Errors::SefazError, "Erro ao processar resposta: #{e.message}"
      end
    end
  end
end
