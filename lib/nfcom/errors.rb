# frozen_string_literal: true

module Nfcom
  module Errors
    class Error < StandardError; end

    class ConfigurationError < Error; end
    class CertificateError < Error; end
    class ValidationError < Error; end
    class XmlError < Error; end
    class SefazError < Error; end
    class SefazIndisponivel < SefazError; end
    class NotaRejeitada < SefazError
      attr_reader :codigo, :motivo

      def initialize(codigo, motivo)
        @codigo = codigo
        @motivo = motivo
        super("Nota rejeitada [#{codigo}]: #{motivo}")
      end
    end
    class NotaDenegada < SefazError; end
    class TimeoutError < Error; end
  end
end
