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
    # @example Validar endereço
    #   if endereco.valido?
    #     puts "Endereço válido"
    #   else
    #     puts "Erros: #{endereco.erros.join(', ')}"
    #   end
    #
    # Atributos obrigatórios:
    # - logradouro (rua, avenida, etc) - 2-60 caracteres (ER47)
    # - numero (número do imóvel) - 1-60 caracteres (ER47)
    # - bairro (bairro/distrito) - 2-60 caracteres (ER47)
    # - municipio (nome do município) - 2-60 caracteres (ER47)
    # - codigo_municipio (código IBGE do município - 7 dígitos) (ER2)
    # - uf (sigla do estado - 2 letras) (D5)
    # - cep (8 dígitos) (ER67)
    #
    # Atributos opcionais:
    # - complemento (apartamento, sala, bloco, etc) - 1-60 caracteres (ER47)
    # - codigo_pais (padrão: 1058 para Brasil)
    # - pais (padrão: 'Brasil')
    # - telefone (7-12 dígitos) (ER61)
    # - email (ER72)
    #
    # @note O código do município (IBGE) pode ser consultado em:
    #   https://www.ibge.gov.br/explica/codigos-dos-municipios.php
    class Endereco
      include Utils::Helpers

      attr_accessor :logradouro, :numero, :complemento, :bairro,
                    :codigo_municipio, :municipio, :uf, :cep,
                    :codigo_pais, :pais, :telefone, :email

      def initialize(attributes = {})
        attributes.each do |key, value|
          send("#{key}=", value) if respond_to?("#{key}=")
        end
      end

      def valido?
        erros.empty?
      end

      def erros # rubocop:disable Metrics/MethodLength
        errors = []

        # Validações de campos obrigatórios
        errors << 'Logradouro é obrigatório' if logradouro.to_s.strip.empty?
        errors << 'Número é obrigatório' if numero.to_s.strip.empty?
        errors << 'Bairro é obrigatório' if bairro.to_s.strip.empty?
        errors << 'Município é obrigatório' if municipio.to_s.strip.empty?
        errors << 'Código do município é obrigatório' if codigo_municipio.to_s.strip.empty?
        errors << 'UF é obrigatório' if uf.to_s.strip.empty?
        errors << 'CEP é obrigatório' if cep.to_s.strip.empty?

        # Validações declarativas de formato/schema
        campos = {}

        # Campos obrigatórios - validar formato apenas se não estiverem vazios
        unless logradouro.to_s.strip.empty?
          campos[:logradouro] = { valor: logradouro, validador: :er47, nome: 'Logradouro', max: 60 }
        end

        campos[:numero] = { valor: numero, validador: :er47, nome: 'Número', max: 60 } unless numero.to_s.strip.empty?

        campos[:bairro] = { valor: bairro, validador: :er47, nome: 'Bairro', max: 60 } unless bairro.to_s.strip.empty?

        unless municipio.to_s.strip.empty?
          campos[:municipio] = { valor: municipio, validador: :er47, nome: 'Município', max: 60 }
        end

        unless codigo_municipio.to_s.strip.empty?
          campos[:codigo_municipio] = { valor: codigo_municipio, validador: :er2, nome: 'Código do município' }
        end

        campos[:uf] = { valor: uf, validador: :d5, nome: 'UF' } unless uf.to_s.strip.empty?

        unless cep.to_s.strip.empty?
          cep_limpo = apenas_numeros(cep)
          campos[:cep] = { valor: cep_limpo, validador: :er67, nome: 'CEP' }
        end

        # Campos opcionais - validar formato apenas se informados
        if complemento && !complemento.to_s.strip.empty?
          campos[:complemento] = { valor: complemento, validador: :er47, nome: 'Complemento', max: 60 }
        end

        if telefone && !telefone.to_s.strip.empty?
          telefone_limpo = apenas_numeros(telefone)
          campos[:telefone] = { valor: telefone_limpo, validador: :er61, nome: 'Telefone' }
        end

        campos[:email] = { valor: email, validador: :er72, nome: 'Email' } if email && !email.to_s.strip.empty?

        # Executar validações declarativas
        errors.concat(Validators::SchemaValidator.validar_campos(campos))

        errors
      end
    end
  end
end
