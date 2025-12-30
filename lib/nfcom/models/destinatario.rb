# frozen_string_literal: true

module Nfcom
  module Models
    # Representa o destinatário (cliente) da NF-COM
    #
    # O destinatário é o tomador do serviço de comunicação/telecomunicação,
    # podendo ser pessoa física (CPF) ou pessoa jurídica (CNPJ).
    #
    # @example Criar destinatário pessoa física
    #   destinatario = Nfcom::Models::Destinatario.new(
    #     cpf: '12345678901',
    #     razao_social: 'João da Silva',
    #     tipo_assinante: :residencial,
    #     email: 'joao@email.com',
    #     endereco: {
    #       logradouro: 'Rua das Flores',
    #       numero: '123',
    #       bairro: 'Centro',
    #       municipio: 'Recife',
    #       uf: 'PE',
    #       cep: '50000-000',
    #       codigo_municipio: '2611606'
    #     }
    #   )
    #
    # @example Criar destinatário pessoa jurídica
    #   destinatario = Nfcom::Models::Destinatario.new(
    #     cnpj: '12345678000100',
    #     razao_social: 'Empresa LTDA',
    #     tipo_assinante: :comercial,
    #     inscricao_estadual: '0123456789',
    #     email: 'contato@empresa.com',
    #     endereco: { ... }
    #   )
    #
    # @example Validar destinatário
    #   if destinatario.valido?
    #     puts "Destinatário válido"
    #   else
    #     puts "Erros: #{destinatario.erros.join(', ')}"
    #   end
    #
    # Tipos de assinante disponíveis:
    # - :comercial (1) - Estabelecimentos comerciais
    # - :industrial (2) - Indústrias
    # - :residencial (3) - Residências (padrão para provedores)
    # - :produtor_rural (4) - Produtores rurais
    # - :orgao_publico (5) - Órgãos públicos
    # - :prestador_servico (6) - Prestadores de serviço
    # - :concessionaria (7) - Concessionárias
    # - :outros (99) - Outros
    #
    # Atributos obrigatórios:
    # - CNPJ ou CPF (pelo menos um)
    # - razao_social (nome ou razão social)
    # - endereco completo
    #
    # Atributos opcionais:
    # - inscricao_estadual (apenas para PJ)
    # - email (recomendado para envio da nota)
    #
    # Validações automáticas:
    # - Validação de dígitos verificadores de CPF/CNPJ
    # - Rejeita CPF/CNPJ com todos dígitos iguais
    # - Valida campos obrigatórios do endereço
    class Destinatario
      include Utils::Helpers

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
        errors << 'CNPJ ou CPF é obrigatório' if cnpj.to_s.strip.empty? && cpf.to_s.strip.empty?
        errors << 'CNPJ inválido' if !cnpj.to_s.strip.empty? && !cnpj_valido?(cnpj)
        errors << 'CPF inválido' if !cpf.to_s.strip.empty? && !cpf_valido?(cpf)
        errors << 'Razão social é obrigatória' if razao_social.to_s.strip.empty?
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
    end
  end
end
