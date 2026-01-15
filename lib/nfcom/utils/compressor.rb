# frozen_string_literal: true

require 'stringio'
require 'zlib'
require 'base64'

module Nfcom
  module Utils
    # Compressor/Decompressor para XML de NFCom
    #
    # Responsável por compactar e descompactar XMLs usando GZIP com
    # nível máximo de compressão, conforme exigido pela SEFAZ.
    class Compressor
      # Compacta XML e retorna Base64
      #
      # @param xml [String] XML a ser compactado
      # @return [String] String Base64 com XML compactado em GZIP
      def self.gzip_base64(xml)
        xml = xml.dup
        xml.sub!("\uFEFF", '') # remove BOM se existir

        io = StringIO.new
        # Nível 9 = compressão máxima (FORCE_GZIP do PHP)
        gz = Zlib::GzipWriter.new(io, Zlib::BEST_COMPRESSION)
        gz.write(xml)
        gz.close

        Base64.strict_encode64(io.string)
      end

      # Descompacta Base64+GZIP e retorna XML
      #
      # @param base64_data [String] String Base64 contendo XML compactado
      # @return [String] XML descompactado
      def self.ungzip_base64(base64_data)
        compressed_data = Base64.strict_decode64(base64_data)

        io = StringIO.new(compressed_data)
        gz = Zlib::GzipReader.new(io)
        xml = gz.read
        gz.close

        xml
      end
    end
  end
end
