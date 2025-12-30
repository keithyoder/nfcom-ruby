# frozen_string_literal: true

module Nfcom
  module Models
    # Representa o endereço do emitente ou destinatário da NF-COM
    #
    # Esta classe é utilizada tanto pelo emitente quanto pelo destinatário
    # para armazenar as informações completas de endereço.
    #
    # @example Criar endereço completo
    #   endereco = Nfcom::Models::Endereco.new(
    #     logradouro: 'Rua das Flores',
    #     numero: '123',
    #     complemento: 'Sala 101',
    #     bairro: 'Centro',
    #     municipio: 'Recife',
    #     codigo_municipio: '2611606',
    #     uf: 'PE',
    #     cep: '50000-000',
    #     telefone: '(81) 3333-4444'
    #   )
    #
    # @example Criar endereço via hash no emitente/destinatário
    #   emitente = Nfcom::Models::Emitente.new(
    #     cnpj: '12345678000100',
    #     razao_social: 'Empresa LTDA',
    #     endereco: {
    #       logradouro: 'Av. Principal',
    #       numero: '1000',
    #       bairro: 'Jardim',
    #       municipio: 'Recife',
    #       uf: 'PE',
    #       cep: '51000-000',
    #       codigo_municipio: '2611606'
    #     }
    #   )
    #
    # @example Validar endereço
    #   if endereco.valido?
    #     puts "Endereço válido"
    #   else
    #     puts "Erros: #{endereco.erros.join(', ')}"
    #   end
    #
    # Atributos obrigatórios:
    # - logradouro (rua, avenida, etc)
    # - numero (número do imóvel)
    # - bairro (bairro/distrito)
    # - municipio (nome do município)
    # - codigo_municipio (código IBGE do município - 7 dígitos)
    # - uf (sigla do estado - 2 letras)
    # - cep (8 dígitos, com ou sem formatação)
    #
    # Atributos opcionais:
    # - complemento (apartamento, sala, bloco, etc)
    # - codigo_pais (padrão: 1058 para Brasil)
    # - pais (padrão: 'Brasil')
    # - telefone (com ou sem formatação)
    #
    # Validações automáticas:
    # - Valida presença de todos os campos obrigatórios
    # - Valida formato do CEP (deve ter 8 dígitos)
    #
    # @note O código do município (IBGE) pode ser consultado em:
    #   https://www.ibge.gov.br/explica/codigos-dos-municipios.php
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
        errors << 'Logradouro é obrigatório' if logradouro.to_s.strip.empty?
        errors << 'Número é obrigatório' if numero.to_s.strip.empty?
        errors << 'Bairro é obrigatório' if bairro.to_s.strip.empty?
        errors << 'Município é obrigatório' if municipio.to_s.strip.empty?
        errors << 'UF é obrigatório' if uf.to_s.strip.empty?
        errors << 'CEP é obrigatório' if cep.to_s.strip.empty?
        errors << 'CEP inválido' unless cep_valido?
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
