# frozen_string_literal: true

module Nfcom
  module Models
    # Representa um item (serviço) da NF-COM
    #
    # Cada item correspone a um serviço de comunicação/telecomunicação
    # prestado ao cliente, como plano de internet, TV por assinatura, etc.
    #
    # @example Adicionar item de internet à nota
    #   nota = Nfcom::Models::Nota.new
    #
    #   nota.add_item(
    #     codigo_servico: '0303',
    #     descricao: 'Plano Fibra 100MB',
    #     classe_consumo: '0303',
    #     cfop: '5307',
    #     unidade: 'UN',
    #     quantidade: 1,
    #     valor_unitario: 99.90
    #   )
    #
    # @example Item com desconto
    #   nota.add_item(
    #     codigo_servico: '0303',
    #     descricao: 'Plano Fibra 200MB',
    #     classe_consumo: '0303',
    #     cfop: '5307',
    #     valor_unitario: 149.90,
    #     valor_desconto: 20.00  # Desconto promocional
    #   )
    #   # Valor total = 149.90 - 20.00 = 129.90
    #
    # @example Múltiplos serviços na mesma nota
    #   # Internet
    #   nota.add_item(
    #     codigo_servico: '0303',
    #     descricao: 'Internet 100MB',
    #     classe_consumo: '0303',
    #     cfop: '5307',
    #     valor_unitario: 99.90
    #   )
    #
    #   # TV por assinatura
    #   nota.add_item(
    #     codigo_servico: '0304',
    #     descricao: 'TV Premium',
    #     classe_consumo: '0304',
    #     cfop: '5307',
    #     valor_unitario: 79.90
    #   )
    #
    # Códigos de Serviço (Telecomunicações):
    # - '0303' - Serviço de Internet
    # - '0304' - TV por Assinatura
    # - '0305' - Telefonia
    #
    # Classes de Consumo (mesmos códigos):
    # - '0303' - Internet
    # - '0304' - TV
    # - '0305' - Telefonia
    #
    # CFOPs comuns:
    # - '5307' - Prestação de serviço de comunicação (dentro do estado)
    # - '6307' - Prestação de serviço de comunicação (fora do estado)
    #
    # Atributos obrigatórios:
    # - codigo_servico (código do serviço de telecomunicação)
    # - descricao (descrição do serviço/plano)
    # - classe_consumo (classificação do consumo)
    # - cfop (Código Fiscal de Operações)
    # - valor_unitario (valor do serviço, maior que zero)
    # - quantidade (quantidade de unidades, padrão: 1)
    #
    # Atributos opcionais:
    # - valor_desconto (desconto aplicado, padrão: 0.00)
    # - valor_outras_despesas (outras despesas acessórias, padrão: 0.00)
    # - unidade (unidade de medida, padrão: 'UN')
    # - codigo_beneficio_fiscal (código de benefício fiscal, se aplicável)
    #
    # Cálculo automático:
    # - valor_total = (quantidade × valor_unitario) - valor_desconto + valor_outras_despesas
    # - O número do item é atribuído automaticamente ao adicionar na nota
    #
    # Validações automáticas:
    # - Todos os campos obrigatórios devem estar presentes
    # - Valor unitário deve ser maior que zero
    # - Quantidade deve ser maior que zero
    class Item
      attr_accessor :numero_item, :codigo_servico, :descricao, :classe_consumo,
                    :unidade, :quantidade, :valor_unitario, :valor_total,
                    :valor_desconto, :valor_outras_despesas,
                    :cfop, :codigo_beneficio_fiscal

      # Códigos de serviço principais para provedor de internet
      CODIGOS_SERVICO = {
        internet: '0303',
        tv_assinatura: '0304',
        telefonia: '0305'
      }.freeze

      # Classes de consumo para provedor de internet
      CLASSES_CONSUMO = {
        internet: '0303',
        tv: '0304',
        telefonia: '0305'
      }.freeze

      def initialize(attributes = {})
        @unidade = 'UN'
        @quantidade = 1
        @valor_desconto = 0.0
        @valor_outras_despesas = 0.0

        attributes.each do |key, value|
          send("#{key}=", value) if respond_to?("#{key}=")
        end

        calcular_valor_total if @valor_total.nil?
      end

      def valido?
        erros.empty?
      end

      def erros
        errors = []
        errors << 'Código de serviço é obrigatório' if codigo_servico.to_s.strip.empty?
        errors << 'Descrição é obrigatória' if descricao.to_s.strip.empty?
        errors << 'Classe de consumo é obrigatória' if classe_consumo.to_s.strip.empty?
        errors << 'CFOP é obrigatório' if cfop.to_s.strip.empty?
        errors << 'Valor unitário deve ser maior que zero' if valor_unitario.to_f <= 0
        errors << 'Quantidade deve ser maior que zero' if quantidade.to_f <= 0
        errors
      end

      def calcular_valor_total
        @valor_total = (quantidade.to_f * valor_unitario.to_f) -
                       valor_desconto.to_f +
                       valor_outras_despesas.to_f
      end

      def valor_liquido
        valor_total.to_f - valor_desconto.to_f
      end
    end
  end
end
