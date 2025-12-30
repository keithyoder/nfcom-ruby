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

      # Valida CNPJ
      # @param cnpj [String] CNPJ com ou sem formatação
      # @return [Boolean] true se válido, false caso contrário
      def cnpj_valido?(cnpj) # rubocop:disable Metrics/AbcSize
        return false if cnpj.nil?

        cnpj_limpo = apenas_numeros(cnpj)
        return false if cnpj_limpo.length != 14
        return false if cnpj_limpo.chars.uniq.length == 1 # Todos dígitos iguais

        calc_digito = lambda do |numeros|
          multiplicadores = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
          soma = numeros.chars.each_with_index.sum { |d, i| d.to_i * multiplicadores[i + (13 - numeros.length)] }
          resto = soma % 11
          resto < 2 ? 0 : 11 - resto
        end

        base = cnpj_limpo[0..11]
        digito1 = calc_digito.call(base)
        digito2 = calc_digito.call(base + digito1.to_s)

        cnpj_limpo[-2].to_i == digito1 && cnpj_limpo[-1].to_i == digito2
      end

      # Valida CPF
      # @param cpf [String] CPF com ou sem formatação
      # @return [Boolean] true se válido, false caso contrário
      def cpf_valido?(cpf) # rubocop:disable Metrics/AbcSize
        return false if cpf.nil?

        cpf_limpo = apenas_numeros(cpf)
        return false if cpf_limpo.length != 11
        return false if cpf_limpo.chars.uniq.length == 1 # Todos dígitos iguais

        calc_digito = lambda do |numeros, peso_inicial|
          soma = numeros.chars.each_with_index.sum { |d, i| d.to_i * (peso_inicial - i) }
          resto = soma % 11
          resto < 2 ? 0 : 11 - resto
        end

        base = cpf_limpo[0..8]
        digito1 = calc_digito.call(base, 10)
        digito2 = calc_digito.call(base + digito1.to_s, 11)

        cpf_limpo[-2].to_i == digito1 && cpf_limpo[-1].to_i == digito2
      end
    end
  end
end
