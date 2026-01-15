# frozen_string_literal: true

module Nfcom
  module Models
    # Representa os valores totalizadores da NF-COM
    #
    # Esta classe agrega todos os valores da nota fiscal, incluindo valores
    # de serviços, descontos, impostos e o valor total da nota.
    #
    # Responsabilidades:
    # - Armazenar os valores totalizadores da nota
    # - Calcular o valor total da NF-COM
    # - Manter valores de impostos (preenchidos externamente ou derivados)
    #
    # Observações importantes:
    # - Esta classe NÃO calcula impostos por regra fiscal
    # - ICMS, PIS e COFINS devem ser informados pela camada de tributação
    # - O Total apenas consolida os valores
    #
    class Total
      attr_accessor :valor_servicos, :valor_desconto, :valor_outras_despesas,
                    :valor_total, :icms_base_calculo, :icms_valor,
                    :icms_desonerado, :fcp_valor,
                    :pis_valor, :cofins_valor,
                    :funttel_valor, :fust_valor,
                    :pis_retido, :cofins_retido, :csll_retido, :irrf_retido

      def initialize(attributes = {})
        @valor_desconto = 0.0
        @valor_outras_despesas = 0.0
        @icms_base_calculo = 0.0
        @icms_valor = 0.0
        @icms_desonerado = 0.0
        @fcp_valor = 0.0
        @pis_valor = 0.0
        @cofins_valor = 0.0
        @funttel_valor = 0.0
        @fust_valor = 0.0
        @pis_retido = 0.0
        @cofins_retido = 0.0
        @csll_retido = 0.0
        @irrf_retido = 0.0

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
