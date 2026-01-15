# frozen_string_literal: true

module Nfcom
  module Models
    # Representa os dados do assinante do serviço de comunicação
    class Assinante
      attr_accessor :codigo,              # iCodAssinante - Código único (1-30 chars)
                    :tipo,                # tpAssinante - Tipo de assinante (1-8, 99)
                    :tipo_servico,        # tpServUtil - Tipo de serviço (1-7)
                    :numero_contrato,     # nContrato - Número do contrato (opcional)
                    :data_inicio_contrato, # dContratoIni - Data início (opcional)
                    :data_fim_contrato,   # dContratoFim - Data fim (opcional)
                    :terminal_principal,  # NroTermPrinc - Terminal principal (condicional)
                    :uf_terminal_principal, # cUFPrinc - UF do terminal (condicional)
                    :terminais_adicionais # Array de { numero:, uf: } (opcional)

      # Tipos de assinante (tpAssinante)
      TIPO_COMERCIAL = 1
      TIPO_INDUSTRIAL = 2
      TIPO_RESIDENCIAL = 3
      TIPO_PRODUTOR_RURAL = 4
      TIPO_ORGAO_PUBLICO = 5
      TIPO_PRESTADOR_TELECOM = 6
      TIPO_DIPLOMATICO = 7
      TIPO_RELIGIOSO = 8
      TIPO_OUTROS = 99

      # Tipos de serviço (tpServUtil)
      SERVICO_TELEFONIA = 1
      SERVICO_DADOS = 2
      SERVICO_TV = 3
      SERVICO_INTERNET = 4
      SERVICO_MULTIMIDIA = 5
      SERVICO_OUTROS = 6
      SERVICO_VARIOS = 7

      def initialize(attrs = {})
        @codigo = attrs[:codigo]
        @tipo = attrs[:tipo] || TIPO_RESIDENCIAL
        @tipo_servico = attrs[:tipo_servico] || SERVICO_INTERNET
        @numero_contrato = attrs[:numero_contrato]
        @data_inicio_contrato = attrs[:data_inicio_contrato]
        @data_fim_contrato = attrs[:data_fim_contrato]
        @terminal_principal = attrs[:terminal_principal]
        @uf_terminal_principal = attrs[:uf_terminal_principal]
        @terminais_adicionais = attrs[:terminais_adicionais] || []
      end

      def valido?
        return false if codigo.nil? || codigo.to_s.strip.empty?
        return false if tipo.nil?
        return false if tipo_servico.nil?

        # Se informou terminal principal, precisa informar UF
        return false if terminal_principal && !uf_terminal_principal

        true
      end
    end
  end
end
