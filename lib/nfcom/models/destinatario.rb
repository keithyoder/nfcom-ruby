# frozen_string_literal: true

module Nfcom
  module Models
    class Destinatario
      attr_accessor :cnpj, :cpf, :razao_social, :inscricao_estadual,
                    :tipo_assinante, :endereco, :email

      # Tipos de assinante
      TIPO_ASSINANTE = {
        comercial: 1,
        industrial: 2,
        residencial: 3,
        produtor_rural: 4,
        orgao_publico: 5,
        prestador_servico: 6,
        concessionaria: 7,
        outros: 99
      }.freeze

      def initialize(attributes = {})
        @endereco = Endereco.new
        @tipo_assinante = :residencial # padrão para provedor de internet
        
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
        errors << "CNPJ ou CPF é obrigatório" if cnpj.to_s.strip.empty? && cpf.to_s.strip.empty?
        errors << "CNPJ inválido" if !cnpj.to_s.strip.empty? && !cnpj_valido?
        errors << "CPF inválido" if !cpf.to_s.strip.empty? && !cpf_valido?
        errors << "Razão social é obrigatória" if razao_social.to_s.strip.empty?
        errors.concat(endereco.erros.map { |e| "Endereço: #{e}" }) unless endereco.valido?
        errors
      end

      def tipo_assinante_codigo
        TIPO_ASSINANTE[tipo_assinante] || TIPO_ASSINANTE[:residencial]
      end

      def pessoa_fisica?
        !cpf.to_s.strip.empty?
      end

      def pessoa_juridica?
        !cnpj.to_s.strip.empty?
      end

      private

      def cnpj_valido?
        return false if cnpj.nil?
        
        cnpj_limpo = cnpj.gsub(/\D/, '')
        return false if cnpj_limpo.length != 14
        return false if cnpj_limpo.chars.uniq.length == 1

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

      def cpf_valido?
        return false if cpf.nil?
        
        cpf_limpo = cpf.gsub(/\D/, '')
        return false if cpf_limpo.length != 11
        return false if cpf_limpo.chars.uniq.length == 1

        calc_digito = ->(numeros, peso_inicial) do
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
