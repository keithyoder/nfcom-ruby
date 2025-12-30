# frozen_string_literal: true

module Nfcom
  # Representa os valores totalizadores da NF-COM
  #
  # Esta classe agrega todos os valores da nota fiscal, incluindo valores
  # de serviços, descontos, impostos e o valor total da nota.
  #
  # @example Totais calculados automaticamente pela Nota
  #   nota = Nfcom::Models::Nota.new
  #   nota.add_item(codigo_servico: '0303', descricao: 'Internet', valor_unitario: 99.90)
  #   nota.add_item(codigo_servico: '0304', descricao: 'TV', valor_unitario: 79.90)
  #
  #   # Total é atualizado automaticamente
  #   puts nota.total.valor_servicos  # => 179.80
  #   puts nota.total.valor_total     # => 179.80
  #
  # @example Nota com desconto
  #   nota = Nfcom::Models::Nota.new
  #   nota.add_item(
  #     codigo_servico: '0303',
  #     descricao: 'Internet',
  #     valor_unitario: 99.90,
  #     valor_desconto: 10.00
  #   )
  #
  #   puts nota.total.valor_servicos   # => 99.90
  #   puts nota.total.valor_desconto   # => 10.00
  #   puts nota.total.valor_total      # => 89.90
  #
  # @example Acessar totais da nota
  #   puts "Valor dos serviços: R$ #{nota.total.valor_servicos}"
  #   puts "Descontos: R$ #{nota.total.valor_desconto}"
  #   puts "Total da nota: R$ #{nota.total.valor_total}"
  #
  # Valores de serviços:
  # - valor_servicos - Soma de todos os itens (quantidade × valor_unitário)
  # - valor_desconto - Soma dos descontos de todos os itens
  # - valor_outras_despesas - Soma das outras despesas de todos os itens
  # - valor_total - Valor final da nota (serviços - descontos + outras despesas)
  #
  # Valores de impostos:
  # - icms_base_calculo - Base de cálculo do ICMS
  # - icms_valor - Valor do ICMS
  # - pis_valor - Valor do PIS
  # - cofins_valor - Valor do COFINS
  #
  # Cálculo do valor total:
  #   valor_total = valor_servicos - valor_desconto + valor_outras_despesas
  #
  # @note Esta classe é instanciada automaticamente pela Nota e seus valores
  #   são atualizados automaticamente ao adicionar ou remover itens.
  #
  # @note Os valores de impostos (ICMS, PIS, COFINS) devem ser preenchidos
  #   manualmente conforme a tributação aplicável ao provedor.
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
