# frozen_string_literal: true

module Nfcom
  module Models
    # Representa as informações de faturamento da NF-COM (grupo gFat)
    #
    # Este grupo contém as informações sobre o período de faturamento,
    # vencimento e valores da fatura.
    #
    # @example Criar fatura básica para ISP
    #   fatura = Nfcom::Models::Fatura.new(
    #     competencia: '2026-01',        # Aceita YYYY-MM ou AAAAMM
    #     data_vencimento: '2026-02-15', # Data de vencimento
    #     codigo_barras: '23793381286000000099901234567890123456789012',
    #     valor_fatura: 99.90
    #   )
    #
    # @example Fatura com período de uso
    #   fatura = Nfcom::Models::Fatura.new(
    #     competencia: '202601',
    #     data_vencimento: '2026-02-15',
    #     codigo_barras: '23793381286000000099901234567890123456789012',
    #     periodo_uso_inicio: '2026-01-01',
    #     periodo_uso_fim: '2026-01-31',
    #     valor_fatura: 99.90
    #   )
    #
    # Atributos obrigatórios:
    # - competencia (formato AAAAMM, ex: '202601' ou aceita '2026-01')
    # - data_vencimento (formato YYYY-MM-DD, ex: '2026-02-15')
    # - codigo_barras (linha digitável do boleto, 1-48 caracteres)
    # - valor_fatura (valor total da fatura)
    #
    # Atributos opcionais:
    # - valor_liquido (valor líquido após descontos)
    # - periodo_uso_inicio (início do período de uso - YYYY-MM-DD)
    # - periodo_uso_fim (fim do período de uso - YYYY-MM-DD)
    # - codigo_debito_automatico (código de autorização débito em conta)
    # - codigo_banco (número do banco - se houver débito automático)
    # - codigo_agencia (número da agência - se houver débito automático)
    class Fatura
      include Utils::Helpers

      attr_accessor :data_vencimento,              # dVencFat - YYYY-MM-DD
                    :codigo_barras,                # codBarras - OBRIGATÓRIO
                    :valor_fatura,                 # vFat - Valor total
                    :valor_liquido,                # vLiqFat - Valor líquido (opcional)
                    :periodo_uso_inicio,           # dPerUsoIni (opcional)
                    :periodo_uso_fim,              # dPerUsoFim (opcional)
                    :codigo_debito_automatico,     # codDebAuto (opcional)
                    :codigo_banco,                 # codBanco (opcional)
                    :codigo_agencia                # codAgencia (opcional)

      attr_reader :competencia                     # CompetFat - AAAAMM

      def initialize(attributes = {})
        attributes.each do |key, value|
          send("#{key}=", value) if respond_to?("#{key}=")
        end

        # Se valor_liquido não foi informado, usa o mesmo da fatura
        @valor_liquido ||= @valor_fatura
      end

      # Define a competência, aceitando tanto YYYY-MM quanto AAAAMM
      # @param value [String] Competência no formato YYYY-MM ou AAAAMM
      def competencia=(value)
        return if value.nil?

        # Se vier no formato YYYY-MM, converter para AAAAMM
        @competencia = if value.to_s.include?('-')
                         value.to_s.gsub('-', '')
                       else
                         value.to_s
                       end
      end

      def valido?
        erros.empty?
      end

      def erros # rubocop:disable Metrics/MethodLength
        errors = []

        # Validar competência
        if competencia.to_s.strip.empty?
          errors << 'Competência é obrigatória'
        elsif !competencia_valida?
          errors << 'Competência deve estar no formato AAAAMM (ex: 202601)'
        end

        # Validar data de vencimento
        if data_vencimento.to_s.strip.empty?
          errors << 'Data de vencimento é obrigatória'
        elsif !data_vencimento_valida?
          errors << 'Data de vencimento deve estar no formato YYYY-MM-DD (ex: 2026-02-15)'
        end

        # Validar código de barras (OBRIGATÓRIO)
        if codigo_barras.to_s.strip.empty?
          errors << 'Código de barras é obrigatório'
        elsif codigo_barras.to_s.length > 48
          errors << 'Código de barras deve ter no máximo 48 caracteres'
        end

        # Validar valor da fatura
        if valor_fatura.nil?
          errors << 'Valor da fatura é obrigatório'
        elsif valor_fatura.to_f <= 0
          errors << 'Valor da fatura deve ser maior que zero'
        end

        # Validar períodos de uso (se informados)
        if periodo_uso_inicio && periodo_uso_fim
          inicio = safe_to_date(periodo_uso_inicio)
          fim = safe_to_date(periodo_uso_fim)

          if inicio.nil? || fim.nil?
            errors << 'Período de uso: datas inválidas'
          elsif inicio > fim
            errors << 'Período de uso: data inicial não pode ser posterior à data final'
          end
        elsif periodo_uso_inicio || periodo_uso_fim
          errors << 'Período de uso: ambas as datas (início e fim) devem ser informadas'
        end

        # Validar débito automático (se informado)
        if codigo_debito_automatico
          errors << 'Código do banco é obrigatório quando há débito automático' if codigo_banco.to_s.strip.empty?
          errors << 'Código da agência é obrigatório quando há débito automático' if codigo_agencia.to_s.strip.empty?
        end

        errors
      end

      private

      def competencia_valida?
        return false unless competencia

        # Formato: AAAAMM (6 dígitos)
        return false unless competencia.to_s.match?(/^\d{6}$/)

        # Validar se o mês é válido (01-12)
        mes = competencia[-2..].to_i
        mes.between?(1, 12)
      end

      def data_vencimento_valida?
        return false unless data_vencimento

        # Se já é um Date, valida diretamente
        return true if data_vencimento.is_a?(Date)

        # Se é String, valida formato YYYY-MM-DD
        return false unless data_vencimento.to_s.match?(/^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$/)

        # Tentar fazer parse para validar se é uma data real
        Date.parse(data_vencimento.to_s)
        true
      rescue ArgumentError
        false
      end
    end
  end
end
