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
    # - valor_total = (quantidade x valor_unitario) - valor_desconto + valor_outras_despesas
    # - O número do item é atribuído automaticamente ao adicionar na nota
    #
    # Validações automáticas:
    # - Todos os campos obrigatórios devem estar presentes
    # - Valor unitário deve ser maior que zero
    # - Quantidade deve ser maior que zero
    class Item # rubocop:disable Metrics/ClassLength
      attr_accessor :numero_item, :codigo_servico, :descricao,
                    :quantidade, :valor_unitario, :valor_total,
                    :valor_desconto, :valor_outras_despesas,
                    :cfop, :codigo_beneficio_fiscal

      attr_reader :classe_consumo, :unidade

      def classe_consumo=(value)
        if value.is_a?(Symbol)
          unless CLASSES_CONSUMO.key?(value)
            raise Nfcom::Errors::ValidationError,
                  "Classe de consumo inválida: #{value.inspect}. " \
                  "Valores válidos: #{CLASSES_CONSUMO.keys.join(', ')}"
          end
          @classe_consumo = CLASSES_CONSUMO[value]
        else
          value_str = value.to_s
          unless CLASSES_CONSUMO.values.include?(value_str)
            raise Nfcom::Errors::ValidationError,
                  "Classe de consumo inválida: #{value.inspect}. " \
                  "Valores válidos: #{CLASSES_CONSUMO.values.join(', ')}"
          end
          @classe_consumo = value_str
        end
      end

      def unidade=(value)
        if value.is_a?(Symbol)
          unless UNIDADES_MEDIDA.key?(value)
            raise Nfcom::Errors::ValidationError,
                  "Unidade de medida inválida: #{value.inspect}. " \
                  "Valores válidos: #{UNIDADES_MEDIDA.keys.join(', ')}"
          end
          @unidade = UNIDADES_MEDIDA[value]
        else
          value_int = value.to_i
          unless UNIDADES_MEDIDA.values.include?(value_int)
            raise Nfcom::Errors::ValidationError,
                  "Unidade de medida inválida: #{value.inspect}. " \
                  "Valores válidos: #{UNIDADES_MEDIDA.values.join(', ')}"
          end
          @unidade = value_int
        end
      end

      # Códigos de serviço principais para provedor de internet
      CODIGOS_SERVICO = {
        internet: '0303',
        tv_assinatura: '0304',
        telefonia: '0305'
      }.freeze

      CLASSES_CONSUMO = {
        # Grupo 010 - Assinatura
        assinatura_telefonia: '0100101',
        assinatura_dados: '0100201',
        assinatura_tv: '0100301',
        assinatura_multimidia: '0100401',

        # Grupo 020 - Habilitação
        habilitacao_telefonia: '0200101',
        habilitacao_dados: '0200201',
        habilitacao_tv: '0200301',

        # Grupo 030 - Serviço Medido
        medido_chamadas_locais: '0300101',
        medido_longa_distancia_nacional: '0300102',
        medido_longa_distancia_internacional: '0300103',
        medido_roaming_originadas: '0300104',
        medido_roaming_recebidas: '0300105',
        medido_adicional_chamada: '0300106',
        medido_numeros_especiais: '0300107',
        medido_sms: '0300108',
        medido_mms: '0300109',
        medido_dados: '0300201',
        medido_pay_per_view: '0300301',
        medido_multimidia: '0300401',

        # Grupo 040 - Serviço Não Medido
        nao_medido_telefonia: '0400101',
        nao_medido_dados: '0400201',
        nao_medido_tv: '0400301',
        nao_medido_internet: '0400401',
        nao_medido_multimidia: '0400501',

        # Grupo 045 - Serviços Combinados
        combinados_voz_dados_mensagens: '0450101',

        # Grupo 050 - Serviço Pré-pago
        prepago_cartao_telefone_fixo: '0500101',
        prepago_recarga_fixo: '0500102',
        prepago_recarga_movel: '0500201',
        prepago_recarga_scm: '0500301',
        prepago_recarga_tv: '0500401',
        prepago_antecipacao: '0500501',
        prepago_repasse: '0500601',

        # Grupo 060 - Outros Serviços
        outros_facilidades: '0600101',
        outros_streaming: '0600201',
        outros_rastreamento: '0600301',
        outros_publicidade: '0600401',
        outros_publicidade_radio_tv: '0600402',
        outros_gerais: '0600501',
        outros_valor_adicionado: '0600601',

        # Grupo 070 - Cessão Meios de Rede
        cessao_interconexao: '0700101',
        cessao_roaming: '0700201',
        cessao_eild: '0700301',
        cessao_icms_proporcional: '0700401',
        cessao_icms_consumo_proprio: '0700501',
        cessao_icms_complementar: '0700601',

        # Grupo 080 - Disponibilização de Equipamentos
        equip_telefone: '0800101',
        equip_identificador: '0800201',
        equip_modem: '0800301',
        equip_rack: '0800401',
        equip_sala: '0800501',
        equip_roteador: '0800601',
        equip_servidor: '0800701',
        equip_multiplexador: '0800801',
        equip_decodificador: '0800901',
        equip_outros: '0801001',
        equip_fibra_apagada: '0801101',
        equip_capacidade_satelital: '0801201',
        equip_antenas: '0801301',
        equip_dutos_postes: '0801401',

        # Grupo 100 - Cobrança Própria
        cobranca_seguros: '1000101',
        cobranca_parcelamento: '1000201',
        cobranca_juros: '1000301',
        cobranca_multa_mora: '1000401',
        cobranca_multa_fidelizacao: '1000402',
        cobranca_meses_anteriores: '1000501',
        cobranca_correcao_monetaria: '1000601',
        cobranca_taxas: '1000701',
        cobranca_adiantamento_radiodifusao: '1000801',
        cobranca_venda_mercadorias: '1000901',

        # Grupo 110 - Cobrança de Terceiros
        terceiros_servicos: '1100101',
        terceiros_seguros: '1100201',
        terceiros_juros: '1100301',
        terceiros_multa: '1100401',
        terceiros_meses_anteriores: '1100501',
        terceiros_correcao: '1100601',
        terceiros_doacoes: '1100701',
        terceiros_equipamentos: '1100801',
        terceiros_venda_mercadorias: '1100901',

        # Grupo 120 - Cobrança Centralizada
        centralizada_item: '1200101',

        # Grupo 130 - Cofaturamento
        cofaturamento_item: '1300101',

        # Grupo 590 - Deduções
        deducao_impugnacao: '5900101',
        deducao_ajuste: '5900201',
        deducao_multa_interrupcao: '5900301',
        deducao_pagamento_duplicidade: '5900401',
        deducao_outras: '5900501'
      }.freeze

      UNIDADES_MEDIDA = {
        minuto: 1,  # Minuto
        mb: 2,      # Megabyte
        gb: 3,      # Gigabyte
        un: 4       # Unidade/Unit (padrão para assinaturas)
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
        erros = []
        erros << 'Código de serviço é obrigatório' if codigo_servico.to_s.strip.empty?
        erros << 'Descrição é obrigatória' if descricao.to_s.strip.empty?
        erros << 'Classe de consumo é obrigatória' if classe_consumo.to_s.strip.empty?

        classes_validos = CLASSES_CONSUMO.values
        unless classes_validos.include?(classe_consumo.to_s)
          erros << "Classe de consumo inválida. Use um dos valores: #{classes_validos.join(', ')}"
        end

        erros << 'CFOP é obrigatório' if cfop.to_s.strip.empty?
        erros << 'Valor unitário deve ser maior que zero' if valor_unitario.to_f <= 0
        erros << 'Quantidade deve ser maior que zero' if quantidade.to_f <= 0
        erros
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
