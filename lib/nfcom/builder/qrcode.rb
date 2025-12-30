# frozen_string_literal: true

module Nfcom
  module Builder
    # Gera URL do QR Code para consulta da NF-COM
    #
    # Esta classe cria a URL de consulta que pode ser codificada em um QR Code,
    # permitindo que os clientes verifiquem a NF-COM diretamente no portal da SEFAZ.
    #
    # @example Gerar URL do QR Code
    #   nota = Nfcom::Models::Nota.new
    #   nota.chave_acesso = "26220512345678000100620010000000011234567890"
    #
    #   qrcode = Nfcom::Builder::Qrcode.new(nota, Nfcom.configuration)
    #   url = qrcode.gerar_url
    #   # => "https://nfcom-homologacao.sefaz.pe.gov.br/consulta?chNFCom=262205...&tpAmb=2"
    #
    # @example Gerar imagem do QR Code (ainda não implementado)
    #   svg = qrcode.gerar_qrcode_svg
    #   # => NotImplementedError
    #
    # A URL gerada contém:
    # - chNFCom: Chave de acesso da nota
    # - tpAmb: Código do ambiente (1=produção, 2=homologação)
    #
    class Qrcode
      attr_reader :nota, :configuration

      def initialize(nota, configuration)
        @nota = nota
        @configuration = configuration
      end

      def gerar_url
        # URL padrão da SEFAZ para consulta via QR Code
        base_url = if configuration.homologacao?
                     "https://nfcom-homologacao.sefaz.#{configuration.estado.downcase}.gov.br/consulta"
                   else
                     "https://nfcom.sefaz.#{configuration.estado.downcase}.gov.br/consulta"
                   end

        params = {
          chNFCom: nota.chave_acesso,
          tpAmb: configuration.ambiente_codigo
        }

        "#{base_url}?#{URI.encode_www_form(params)}"
      end

      def gerar_qrcode_svg
        # TODO: Implementar geração de imagem SVG do QR Code
        # Pode usar gems como rqrcode ou similares
        raise NotImplementedError, 'Geração de imagem QR Code não implementada ainda'
      end
    end
  end
end
