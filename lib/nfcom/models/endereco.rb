# frozen_string_literal: true

module Nfcom
  module Models
    class Endereco
      attr_accessor :logradouro, :numero, :complemento, :bairro,
                    :codigo_municipio, :municipio, :uf, :cep,
                    :codigo_pais, :pais, :telefone

      def initialize(attributes = {})
        attributes.each do |key, value|
          send("#{key}=", value) if respond_to?("#{key}=")
        end
      end

      def valido?
        erros.empty?
      end

      def erros
        errors = []
        errors << "Logradouro é obrigatório" if logradouro.to_s.strip.empty?
        errors << "Número é obrigatório" if numero.to_s.strip.empty?
        errors << "Bairro é obrigatório" if bairro.to_s.strip.empty?
        errors << "Município é obrigatório" if municipio.to_s.strip.empty?
        errors << "UF é obrigatório" if uf.to_s.strip.empty?
        errors << "CEP é obrigatório" if cep.to_s.strip.empty?
        errors << "CEP inválido" unless cep_valido?
        errors
      end

      private

      def cep_valido?
        return false if cep.nil?
        cep.gsub(/\D/, '').length == 8
      end
    end
  end
end
