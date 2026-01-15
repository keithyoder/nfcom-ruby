# frozen_string_literal: true

require 'openssl'

module Nfcom
  module Utils
    class Certificate
      attr_reader :cert, :key

      def initialize(path, password = nil)
        @path = path
        @password = password
        carregar_certificado
      end

      def valido?
        return false if @cert.nil? || @key.nil?
        return false if expirado?

        true
      end

      def expirado?
        @cert.not_after < Time.now
      end

      def dias_para_vencer
        return 0 if expirado?

        ((@cert.not_after - Time.now) / 86_400).to_i
      end

      def cnpj
        # Extrai CNPJ do subject do certificado
        # Formato pode ser: CN=12345678000100 ou CN=EMPRESA:12345678000100
        subject = @cert.subject.to_s

        # Tenta formato direto: CN=12345678000100
        match = subject.match(/CN=(\d{14})/)
        return match[1] if match

        # Tenta formato com nome: CN=EMPRESA:12345678000100
        match = subject.match(/CN=[^:]+:(\d{14})/)
        return match[1] if match

        # Tenta buscar CNPJ em qualquer lugar do subject
        match = subject.match(/(\d{14})/)
        return match[1] if match

        nil
      end

      def to_pem
        {
          cert: @cert.to_pem,
          key: @key.to_pem
        }
      end

      private

      def carregar_certificado
        raise Errors::CertificateError, "Arquivo de certificado não encontrado: #{@path}" unless File.exist?(@path)

        begin
          conteudo = File.read(@path)

          # Tenta carregar como PKCS12 (.pfx)
          if @path.end_with?('.pfx', '.p12')
            pkcs12 = OpenSSL::PKCS12.new(conteudo, @password)
            @cert = pkcs12.certificate
            @key = pkcs12.key
          else
            # Tenta carregar como PEM
            @cert = OpenSSL::X509::Certificate.new(conteudo)
            @key = OpenSSL::PKey::RSA.new(conteudo, @password)
          end

          validar_certificado
        rescue OpenSSL::PKCS12::PKCS12Error => e
          raise Errors::CertificateError, "Erro ao carregar certificado PKCS12. Senha incorreta? #{e.message}"
        rescue OpenSSL::X509::CertificateError => e
          raise Errors::CertificateError, "Erro ao carregar certificado: #{e.message}"
        rescue OpenSSL::PKey::RSAError => e
          raise Errors::CertificateError, "Erro ao carregar chave privada: #{e.message}"
        end
      end

      def validar_certificado
        # Verifica se o certificado tem os componentes necessários
        raise Errors::CertificateError, 'Certificado inválido: faltando certificado' if @cert.nil?
        raise Errors::CertificateError, 'Certificado inválido: faltando chave privada' if @key.nil?

        # Verifica se está expirado
        raise Errors::CertificateError, 'Certificado está expirado' if expirado?

        # Verifica se a chave privada corresponde ao certificado
        unless @cert.check_private_key(@key)
          raise Errors::CertificateError, 'Chave privada não corresponde ao certificado'
        end

        # Aviso de vencimento próximo
        return unless dias_para_vencer <= 30

        warn "ATENÇÃO: Certificado vence em #{dias_para_vencer} dias!"
      end
    end
  end
end
