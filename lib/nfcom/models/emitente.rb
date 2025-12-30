# frozen_string_literal: true

module Nfcom
  module Models
    class Emitente
      attr_accessor :cnpj, :razao_social, :nome_fantasia, :inscricao_estadual,
                    :inscricao_municipal, :cnae, :regime_tributario, :endereco

      def initialize(attributes = {})
        @endereco = Endereco.new
        attributes.each do |key, value|
          if key == :endereco && value.is_a?(Hash)
            @endereco = Endereco.new(value)
          elsif respond_to?("#{key}=")
            send("#{key}=", value)
          end
        end
      end

      def valido?
        erros.empty?
      end

      def erros
        errors = []
        errors << "CNPJ é obrigatório" if cnpj.to_s.strip.empty?
        errors << "CNPJ inválido" unless cnpj_valido?
        errors << "Razão social é obrigatória" if razao_social.to_s.strip.empty?
        errors << "Inscrição estadual é obrigatória" if inscricao_estadual.to_s.strip.empty?
        errors.concat(endereco.erros.map { |e| "Endereço: #{e}" }) unless endereco.valido?
        errors
      end

      private

      def cnpj_valido?
        return false if cnpj.nil?
        
        cnpj_limpo = cnpj.gsub(/\D/, '')
        return false if cnpj_limpo.length != 14
        return false if cnpj_limpo.chars.uniq.length == 1 # Todos dígitos iguais

        # Validação dos dígitos verificadores
        calc_digito = ->(numeros) do
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
    end
  end
end
