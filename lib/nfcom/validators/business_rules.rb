# frozen_string_literal: true

module Nfcom
  module Validators
    class BusinessRules
      def self.validar(nota) # rubocop:disable Metrics/AbcSize
        erros = []

        # Valida valores
        erros << 'Valor total da nota não pode ser zero' if nota.total.valor_total.to_f <= 0

        # Valida soma dos itens
        soma_itens = nota.itens.sum { |i| i.valor_total.to_f }
        if (soma_itens - nota.total.valor_servicos.to_f).abs > 0.01
          erros << "Soma dos itens (#{soma_itens}) não confere com total de serviços (#{nota.total.valor_servicos})"
        end

        nota.itens.each do |item|
          # Valida códigos de serviço para provedor de internet
          unless codigo_servico_valido?(item.codigo_servico)
            erros << "Código de serviço #{item.codigo_servico} inválido para item #{item.numero_item}"
          end
          # Valida CFOP
          erros << "CFOP #{item.cfop} inválido para item #{item.numero_item}" unless cfop_valido?(item.cfop)
        end

        erros
      end

      def self.codigo_servico_valido?(codigo)
        # Códigos válidos para telecomunicações/internet
        validos = %w[0303 0304 0305]
        validos.include?(codigo.to_s)
      end

      def self.cfop_valido?(cfop)
        # CFOPs comuns para serviços de comunicação
        # 5300-5399: Prestações de serviços dentro do estado
        # 6300-6399: Prestações de serviços fora do estado
        cfop_num = cfop.to_s.to_i
        cfop_num.between?(5300, 5399) || cfop_num.between?(6300, 6399)
      end
    end
  end
end
