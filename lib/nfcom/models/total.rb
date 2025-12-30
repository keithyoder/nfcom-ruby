# frozen_string_literal: true

module Nfcom
  module Models
    class Total
      attr_accessor :valor_servicos, :valor_desconto, :valor_outras_despesas,
                    :valor_total, :icms_base_calculo, :icms_valor,
                    :pis_valor, :cofins_valor

      def initialize(attributes = {})
        @valor_desconto = 0.0
        @valor_outras_despesas = 0.0
        @icms_base_calculo = 0.0
        @icms_valor = 0.0
        @pis_valor = 0.0
        @cofins_valor = 0.0
        
        attributes.each do |key, value|
          send("#{key}=", value) if respond_to?("#{key}=")
        end
      end

      def calcular_total
        @valor_total = valor_servicos.to_f - 
                       valor_desconto.to_f + 
                       valor_outras_despesas.to_f
      end

      def valor_liquido
        valor_total.to_f
      end
    end
  end
end
