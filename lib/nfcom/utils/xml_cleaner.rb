# frozen_string_literal: true

module Nfcom
  module Utils
    # Limpeza de XML para envio à SEFAZ
    #
    # Remove caracteres de controle, BOMs, declarações XML e formatação
    # desnecessária do XML antes do envio para a SEFAZ.
    class XmlCleaner
      class << self
        # Limpa XML removendo BOMs, declarações e formatação
        #
        # @param xml [String] XML a ser limpo
        # @return [String] XML limpo e pronto para envio
        def clean(xml)
          xml = xml.dup

          # Trabalha com encoding binário primeiro para remover BOMs
          xml.force_encoding('BINARY')

          # Remove BOM (Byte Order Mark) - UTF-8
          bom_utf8 = "\xEF\xBB\xBF".dup.force_encoding('BINARY')
          xml.sub!(bom_utf8, '') if xml.start_with?(bom_utf8)

          # Remove BOM variants (UTF-16)
          bom_utf16_le = "\xFF\xFE".dup.force_encoding('BINARY')
          xml.sub!(bom_utf16_le, '') if xml.start_with?(bom_utf16_le)

          bom_utf16_be = "\xFE\xFF".dup.force_encoding('BINARY')
          xml.sub!(bom_utf16_be, '') if xml.start_with?(bom_utf16_be)

          # Agora converte para UTF-8
          xml.force_encoding('UTF-8')

          # Remove declaração XML e espaços após ela
          xml.sub!(/\A<\?xml[^?]*\?>\s*/, '')

          # Remove carriage returns (Windows line endings)
          xml.gsub!("\r", '')

          # Remove espaços/tabs no início de cada linha (multiline mode)
          xml.gsub!(/^[ \t]+/m, '')

          # Remove espaços/tabs no fim de cada linha (multiline mode)
          xml.gsub!(/[ \t]+$/m, '')

          # Remove múltiplas linhas vazias, deixando apenas uma
          xml.gsub!(/\n\n+/, "\n")

          # Remove espaços entre tags (> <) mas mantém conteúdo
          xml.gsub!(/>\s+</, '><')

          # Trim geral (remove espaços início/fim)
          xml.strip!

          # Remove qualquer caracter de controle invisível (exceto \n)
          control_chars_str = (0x00..0x08).map(&:chr).join +
                              (0x0B..0x0C).map(&:chr).join +
                              (0x0E..0x1F).map(&:chr).join +
                              0x7F.chr
          xml.delete!(control_chars_str)

          xml
        end
      end
    end
  end
end
