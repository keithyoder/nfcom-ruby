# frozen_string_literal: true

require 'uri'
require 'rqrcode'
require_relative '../validators/schema_validator'

module Nfcom
  module Builder
    # Gera a URL e SVG do QR Code para consulta da NF-COM.
    #
    # Esta classe cria a URL que será codificada em um QR Code, permitindo que os clientes
    # validem a NF-COM diretamente no portal da SEFAZ.
    #
    # A URL gerada contém os seguintes parâmetros:
    # - chNFCom: Chave de acesso da NF-COM
    # - tpAmb: Código do ambiente (1 = produção, 2 = homologação)
    class Qrcode
      # @return [String] chave de acesso da NF-COM
      attr_reader :chave

      # @return [Symbol] ambiente :producao ou :homologacao
      attr_reader :ambiente

      # Inicializa o gerador de QR Code
      #
      # @param chave [String] chave de acesso da NF-COM
      # @param ambiente [Symbol] :producao ou :homologacao
      #
      # @raise [ArgumentError] se algum argumento estiver ausente ou inválido
      def initialize(chave, ambiente)
        raise ArgumentError, 'Chave de acesso não pode ser vazia' if chave.nil? || chave.strip.empty?
        unless Nfcom::Validators::SchemaValidator.valido_por_schema?(chave, :er3)
          raise ArgumentError, "Chave de acesso inválida: #{chave}"
        end

        raise ArgumentError, 'Ambiente deve ser :producao ou :homologacao' unless %i[producao
                                                                                     homologacao].include?(ambiente)

        @chave = chave
        @ambiente = ambiente
      end

      # Gera a URL do QR Code
      #
      # @return [String] URL completa
      def gerar_url
        base_url = 'https://nfcom.svrs.rs.gov.br/nfcom/qrcode'
        tp_amb = ambiente == :homologacao ? 2 : 1

        "#{base_url}?#{URI.encode_www_form(chNFCom: chave, tpAmb: tp_amb)}"
      end

      # Gera a imagem SVG do QR Code
      #
      # @return [String] SVG do QR Code
      def gerar_qrcode_svg
        qr = RQRCode::QRCode.new(gerar_url)
        qr.as_svg(
          offset: 0,
          color: '000',
          shape_rendering: 'crispEdges',
          module_size: 6,
          standalone: true
        )
      end
    end
  end
end
