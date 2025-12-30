# frozen_string_literal: true

require 'digest'

module Nfcom
  module Builder
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

        # Adiciona hash de segurança (CSC)
        if configuration.csc && configuration.csc_id
          hash_qrcode = gerar_hash_qrcode
          params[:cHashQRCode] = hash_qrcode
        end

        "#{base_url}?#{URI.encode_www_form(params)}"
      end

      def gerar_hash_qrcode
        # Hash = SHA-1(chave_acesso + "|" + versao_qrcode + "|" + ambiente + "|" + csc_id + "|" + csc)
        versao_qrcode = '1'
        
        string_hash = [
          nota.chave_acesso,
          versao_qrcode,
          configuration.ambiente_codigo,
          configuration.csc_id,
          configuration.csc
        ].join('|')

        Digest::SHA1.hexdigest(string_hash)
      end

      def gerar_qrcode_svg
        # TODO: Implementar geração de imagem SVG do QR Code
        # Pode usar gems como rqrcode ou similares
        raise NotImplementedError, "Geração de imagem QR Code não implementada ainda"
      end
    end
  end
end
