# frozen_string_literal: true

require 'securerandom'

module Nfcom
  module Models
    # Representa uma Nota Fiscal de Comunicação (NF-COM) modelo 62.
    #
    # A Nota é o objeto principal da gem, responsável por agregar todas as
    # informações necessárias para a emissão da NF-COM:
    # emitente, destinatário, fatura, itens/serviços, totais e metadados fiscais.
    #
    # @example Criar uma nota completa
    #   nota = Nfcom::Models::Nota.new do |n|
    #     n.serie = 1
    #     n.numero = 1
    #
    #     # Emitente (provedor)
    #     n.emitente = Nfcom::Models::Emitente.new(
    #       cnpj: '12345678000100',
    #       razao_social: 'Provedor Internet LTDA',
    #       inscricao_estadual: '0123456789',
    #       endereco: { ... }
    #     )
    #
    #     # Destinatário (cliente)
    #     n.destinatario = Nfcom::Models::Destinatario.new(
    #       cpf: '12345678901',
    #       razao_social: 'João da Silva',
    #       endereco: { ... }
    #     )
    #
    #     # Fatura (obrigatória)
    #     n.fatura = Nfcom::Models::Fatura.new(
    #       valor_liquido: 99.90,
    #       data_vencimento: Date.today + 10
    #     )
    #
    #     # Adicionar serviços
    #     n.add_item(
    #       codigo_servico: '0303',
    #       descricao: 'Plano Fibra 100MB',
    #       classe_consumo: '0303',
    #       cfop: '5307',
    #       valor_unitario: 99.90
    #     )
    #   end
    #
    # @example Validar nota antes de emitir
    #   if nota.valida?
    #     puts 'Nota válida, pronta para emissão'
    #   else
    #     puts 'Erros encontrados:'
    #     nota.erros.each { |erro| puts "  - #{erro}" }
    #   end
    #
    # @example Emitir nota
    #   # A chave de acesso é gerada automaticamente
    #   nota.gerar_chave_acesso
    #
    #   # Enviar para a SEFAZ
    #   client = Nfcom::Client.new
    #   resultado = client.autorizar(nota)
    #
    #   if resultado[:autorizada]
    #     puts 'Nota autorizada!'
    #     puts "Chave: #{nota.chave_acesso}"
    #     puts "Protocolo: #{nota.protocolo}"
    #   end
    #
    # @example Adicionar múltiplos serviços
    #   nota.add_item(codigo_servico: '0303', descricao: 'Internet', valor_unitario: 99.90)
    #   nota.add_item(codigo_servico: '0304', descricao: 'TV', valor_unitario: 79.90)
    #   # O total é recalculado automaticamente
    #
    # @example Nota com informações adicionais
    #   nota.informacoes_adicionais = 'Cliente isento de ICMS conforme decreto XYZ'
    #
    # Tipos de Emissão:
    # - :normal (1)        - Emissão normal (padrão)
    # - :contingencia (2)  - Emissão em contingência (offline)
    #
    # Finalidades:
    # - :normal (0)         - Nota fiscal normal (padrão)
    # - :substituicao (3)   - Nota de substituição
    # - :ajuste (4)         - Nota de ajuste
    #
    # Tipos de Faturamento:
    # - :normal (0)         - Faturamento padrão
    # - :centralizado (1)   - Faturamento centralizado
    # - :cofaturamento (2)  - Cofaturamento
    #
    # Atributos obrigatórios:
    # - serie               - Série da nota (padrão: 1)
    # - numero              - Número sequencial da nota
    # - emitente            - Provedor / empresa emissora
    # - destinatario        - Cliente / tomador do serviço
    # - fatura              - Informações de cobrança (obrigatória)
    # - itens               - Pelo menos um item/serviço
    #
    # Atributos opcionais:
    # - data_emissao             - Data/hora de emissão (padrão: Time.now)
    # - tipo_emissao             - Tipo de emissão (padrão: :normal)
    # - finalidade               - Finalidade da nota (padrão: :normal)
    # - informacoes_adicionais   - Texto livre (até 5.000 caracteres)
    #
    # Atributos preenchidos após autorização:
    # - chave_acesso        - Chave de acesso (44 dígitos)
    # - codigo_verificacao  - Código numérico (cNF, 7 dígitos – usado no XML)
    # - protocolo           - Número do protocolo SEFAZ
    # - data_autorizacao    - Data/hora da autorização
    # - xml_autorizado      - XML completo autorizado pela SEFAZ
    #
    # Funcionalidades automáticas:
    # - Numeração sequencial dos itens
    # - Recalculo automático dos totais
    # - Geração da chave de acesso com dígito verificador
    # - Validação completa de todos os campos obrigatórios
    # - Validação em cascata (emitente, destinatário, fatura e itens)
    #
    # Validações realizadas:
    # - Presença de série, número, emitente, destinatário e fatura
    # - Existência de pelo menos um item
    # - Validação completa do emitente (CNPJ, IE, endereço)
    # - Validação completa do destinatário (CPF/CNPJ, endereço)
    # - Validação da fatura
    # - Validação individual de cada item
    #
    # @note Formato da chave de acesso (44 dígitos):
    #   UF (2) + AAMM (4) + CNPJ (14) + Modelo (2) + Série (3) +
    #   Número (9) + Tipo Emissão (1) + Código Numérico (8) + DV (1)
    #
    # @note Importante:
    #   - O campo cNF no XML possui 7 dígitos
    #   - Na chave de acesso, o código numérico é representado com 8 dígitos
    class Nota # rubocop:disable Metrics/ClassLength
      attr_accessor :serie, :numero, :data_emissao, :tipo_emissao, :fatura,
                    :finalidade, :emitente, :destinatario, :assinante, :itens, :total,
                    :informacoes_adicionais, :chave_acesso, :codigo_verificacao,
                    :protocolo, :data_autorizacao, :xml_autorizado,
                    :competencia_fatura, :data_vencimento, :valor_liquido_fatura

      attr_reader :metodo_pagamento, :tipo_faturamento

      def metodo_pagamento=(value)
        if value.is_a?(Symbol)
          unless METODOS_PAGAMENTO.key?(value)
            raise Errors::ValidationError,
                  "Método de pagamento inválido: #{value.inspect}. " \
                  "Valores válidos: #{METODOS_PAGAMENTO.keys.join(', ')}"
          end
          @metodo_pagamento = METODOS_PAGAMENTO[value]
        else
          value_str = value.to_s
          unless METODOS_PAGAMENTO.values.include?(value_str)
            raise Errors::ValidationError,
                  "Método de pagamento inválido: #{value.inspect}. " \
                  "Valores válidos: #{METODOS_PAGAMENTO.values.join(', ')}"
          end
          @metodo_pagamento = value_str
        end
      end

      def tipo_faturamento=(value)
        if value.is_a?(Symbol)
          unless TIPO_FATURAMENTO.key?(value)
            raise Errors::ValidationError,
                  "Tipo de faturamento inválido: #{value.inspect}. " \
                  "Valores válidos: #{TIPO_FATURAMENTO.keys.join(', ')}"
          end
          @tipo_faturamento = TIPO_FATURAMENTO[value]
        elsif value.is_a?(Integer) || value.is_a?(String)
          value_int = value.to_i
          unless TIPO_FATURAMENTO.values.include?(value_int)
            raise Errors::ValidationError,
                  "Tipo de faturamento inválido: #{value.inspect}. " \
                  "Valores válidos: #{TIPO_FATURAMENTO.values.join(', ')}"
          end
          @tipo_faturamento = value_int
        else
          raise Errors::ValidationError,
                'Tipo de faturamento deve ser Symbol, Integer ou String'
        end
      end

      METODOS_PAGAMENTO = {
        dinheiro: '01',
        cheque: '02',
        cartao_credito: '03',
        cartao_debito: '04',
        credito_loja: '05',
        vale_alimentacao: '10',
        vale_refeicao: '11',
        vale_presente: '12',
        vale_combustivel: '13',
        boleto_bancario: '15',
        deposito_bancario: '16',
        pix: '17',
        transferencia_bancaria: '18',
        programa_fidelidade: '19',
        sem_pagamento: '90',
        outros: '99'
      }.freeze

      TIPO_EMISSAO = {
        normal: 1,
        contingencia: 2
      }.freeze

      FINALIDADE = {
        normal: 0,
        substituicao: 3,
        ajuste: 4
      }.freeze

      TIPO_FATURAMENTO = {
        normal: 0,
        centralizado: 1,
        cofaturamento: 2
      }.freeze

      def initialize(attributes = {})
        @serie = Nfcom.configuration.serie_padrao || 1
        @data_emissao = Time.now
        @tipo_emissao = :normal
        send(:tipo_faturamento=, :normal)
        @finalidade = :normal
        @itens = []
        @total = Total.new

        attributes.each do |key, value|
          if key == :emitente && value.is_a?(Hash)
            @emitente = Emitente.new(value)
          elsif key == :fatura && value.is_a?(Hash)
            @fatura = Fatura.new(value)
          elsif key == :destinatario && value.is_a?(Hash)
            @destinatario = Destinatario.new(value)
          elsif respond_to?("#{key}=")
            send("#{key}=", value)
          end
        end

        yield self if block_given?
      end

      def add_item(attributes)
        item = if attributes.is_a?(Item)
                 attributes
               else
                 Item.new(attributes)
               end

        item.numero_item = itens.length + 1
        itens << item
        recalcular_totais
        item
      end

      def recalcular_totais
        @total.valor_servicos = itens.sum { |i| i.valor_total.to_f }
        @total.valor_desconto = itens.sum { |i| i.valor_desconto.to_f }
        @total.valor_outras_despesas = itens.sum { |i| i.valor_outras_despesas.to_f }
        @total.calcular_total
      end

      def gerar_chave_acesso
        # IMPORTANTE: Discrepância no schema NFCom:
        # - Campo cNF no XML: 7 dígitos (ER2)
        # - cNF na chave de acesso: 8 dígitos (para chave ter 44 dígitos no total)
        # Formato da chave: UFAnoMesCNPJModSerieNumTpEmissCodNumDV
        # UF(2) + AAMM(4) + CNPJ(14) + Mod(2) + Serie(3) + Num(9) + TpEmiss(1) + CodNum(8) + DV(1) = 44
        # Exemplo: 26 2601 07159053000107 62 001 000009670 1 01234567 9

        config = Nfcom.configuration
        uf = config.codigo_uf
        ano_mes = data_emissao.strftime('%y%m')
        cnpj = emitente.cnpj.gsub(/\D/, '')
        modelo = '62'
        serie_fmt = serie.to_s.rjust(3, '0')
        numero_fmt = numero.to_s.rjust(9, '0')
        tipo_emiss = tipo_emissao_codigo.to_s

        # Gera cNF com 7 dígitos (para o campo XML)
        codigo_numerico_7 = SecureRandom.random_number(10_000_000).to_s.rjust(7, '0')

        # Mas na chave usa 8 dígitos (padding à esquerda com zero)
        codigo_numerico_8 = codigo_numerico_7.rjust(8, '0')

        chave_sem_dv = "#{uf}#{ano_mes}#{cnpj}#{modelo}#{serie_fmt}#{numero_fmt}#{tipo_emiss}#{codigo_numerico_8}"
        dv = calcular_digito_verificador(chave_sem_dv)

        # Armazena o cNF de 7 dígitos (para o XML)
        @codigo_verificacao = codigo_numerico_7
        # Chave completa com 44 dígitos
        @chave_acesso = "#{chave_sem_dv}#{dv}"
      end

      def tipo_emissao_codigo
        TIPO_EMISSAO[tipo_emissao] || TIPO_EMISSAO[:normal]
      end

      def finalidade_codigo
        FINALIDADE[finalidade] || FINALIDADE[:normal]
      end

      def valida?
        erros.empty?
      end

      def erros # rubocop:disable Metrics/MethodLength
        errors = []
        errors << 'Série é obrigatória' if serie.nil?
        errors << 'Número é obrigatório' if numero.nil?
        errors << 'Emitente é obrigatório' if emitente.nil?
        errors << 'Destinatário é obrigatório' if destinatario.nil?
        errors << 'Deve haver pelo menos um item' if itens.empty?

        # Validações de schema (formato)
        errors << 'Série inválida (deve ser 0-999)' if serie && !serie.to_s.match?(/\A(0|[1-9]{1}[0-9]{0,2})\z/)

        if numero && !numero.to_s.match?(/\A[1-9]{1}[0-9]{0,8}\z/)
          errors << 'Número inválido (1-999999999, não pode começar com zero)'
        end

        if codigo_verificacao && codigo_verificacao.to_s.length != 7
          errors << "cNF inválido: deve ter exatamente 7 dígitos (campo XML), tem #{codigo_verificacao.to_s.length}"
        end

        if chave_acesso && !chave_acesso.to_s.match?(/\A[0-9]{44}\z/)
          errors << "Chave de acesso inválida (deve ter 44 dígitos, tem #{chave_acesso.to_s.length})"
        end

        errors.concat(emitente.erros.map { |e| "Emitente: #{e}" }) if emitente && !emitente.valido?
        errors.concat(destinatario.erros.map { |e| "Destinatário: #{e}" }) if destinatario && !destinatario.valido?

        itens.each_with_index do |item, i|
          errors.concat(item.erros.map { |e| "Item #{i + 1}: #{e}" }) unless item.valido?
        end

        if fatura.nil?
          errors << 'Fatura é obrigatória'
        elsif !fatura.valido?
          errors.concat(fatura.erros.map { |e| "Fatura: #{e}" })
        end

        errors
      end

      def autorizada?
        !protocolo.nil? && !data_autorizacao.nil?
      end

      private

      def calcular_digito_verificador(chave)
        # MÃ³dulo 11
        multiplicadores = [2, 3, 4, 5, 6, 7, 8, 9]
        soma = 0

        chave.reverse.chars.each_with_index do |digito, i|
          soma += digito.to_i * multiplicadores[i % 8]
        end

        resto = soma % 11
        dv = 11 - resto
        dv = 0 if dv >= 10
        dv
      end
    end
  end
end
