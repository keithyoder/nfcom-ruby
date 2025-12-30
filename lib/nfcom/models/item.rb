# frozen_string_literal: true

module Nfcom
  module Models
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
        errors << "Código de serviço é obrigatório" if codigo_servico.to_s.strip.empty?
        errors << "Descrição é obrigatória" if descricao.to_s.strip.empty?
        errors << "Classe de consumo é obrigatória" if classe_consumo.to_s.strip.empty?
        errors << "CFOP é obrigatório" if cfop.to_s.strip.empty?
        errors << "Valor unitário deve ser maior que zero" if valor_unitario.to_f <= 0
        errors << "Quantidade deve ser maior que zero" if quantidade.to_f <= 0
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
