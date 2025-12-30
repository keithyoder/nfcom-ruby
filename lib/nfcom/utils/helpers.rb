# frozen_string_literal: true

module Nfcom
  module Utils
    module Helpers
      module_function

      # Formata valor decimal para uso no XML (2 casas decimais)
      def formatar_decimal(valor, casas = 2)
        format("%.#{casas}f", valor.to_f)
      end

      # Formata data/hora para padrão ISO 8601
      def formatar_data_hora(datetime)
        datetime.strftime('%Y-%m-%dT%H:%M:%S%:z')
      end

      # Remove caracteres não numéricos
      def apenas_numeros(texto)
        texto.to_s.gsub(/\D/, '')
      end

      # Limita texto ao tamanho máximo
      def limitar_texto(texto, tamanho_max)
        texto = texto.to_s
        texto.length > tamanho_max ? texto[0...tamanho_max] : texto
      end

      # Remove acentos e caracteres especiais
      def remover_acentos(texto)
        texto.to_s
          .unicode_normalize(:nfkd)
          .encode('ASCII', invalid: :replace, undef: :replace, replace: '')
          .gsub(/[^\w\s-]/, '')
      end

      # Valida se uma string está vazia
      def vazio?(texto)
        texto.to_s.strip.empty?
      end

      # Formata CNPJ
      def formatar_cnpj(cnpj)
        numeros = apenas_numeros(cnpj)
        return cnpj if numeros.length != 14
        
        "#{numeros[0..1]}.#{numeros[2..4]}.#{numeros[5..7]}/#{numeros[8..11]}-#{numeros[12..13]}"
      end

      # Formata CPF
      def formatar_cpf(cpf)
        numeros = apenas_numeros(cpf)
        return cpf if numeros.length != 11
        
        "#{numeros[0..2]}.#{numeros[3..5]}.#{numeros[6..8]}-#{numeros[9..10]}"
      end

      # Formata CEP
      def formatar_cep(cep)
        numeros = apenas_numeros(cep)
        return cep if numeros.length != 8
        
        "#{numeros[0..4]}-#{numeros[5..7]}"
      end

      # Gera ID único para elementos XML
      def gerar_id(prefixo = 'ID')
        "#{prefixo}#{Time.now.to_i}#{SecureRandom.hex(4)}"
      end
    end
  end
end
