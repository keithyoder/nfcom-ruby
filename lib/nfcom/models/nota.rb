# frozen_string_literal: true

require 'securerandom'

module Nfcom
  module Models
    # Representa uma Nota Fiscal de Comunicação (NF-COM) modelo 62
    #
    # A Nota é o objeto principal da gem, agregando todas as informações
    # necessárias para emissão: emitente, destinatário, itens/serviços e totalizadores.
    #
    # @example Criar nota completa
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
    #     puts "Nota válida, pronta para emissão"
    #   else
    #     puts "Erros encontrados:"
    #     nota.erros.each { |erro| puts "  - #{erro}" }
    #   end
    #
    # @example Emitir nota
    #   # A chave de acesso é gerada automaticamente
    #   nota.gerar_chave_acesso
    #
    #   # Enviar para SEFAZ
    #   client = Nfcom::Client.new
    #   resultado = client.autorizar(nota)
    #
    #   if resultado[:autorizada]
    #     puts "Nota autorizada!"
    #     puts "Chave: #{nota.chave_acesso}"
    #     puts "Protocolo: #{nota.protocolo}"
    #   end
    #
    # @example Adicionar múltiplos serviços
    #   nota.add_item(codigo_servico: '0303', descricao: 'Internet', valor_unitario: 99.90)
    #   nota.add_item(codigo_servico: '0304', descricao: 'TV', valor_unitario: 79.90)
    #   # Total é recalculado automaticamente
    #
    # @example Nota com informações adicionais
    #   nota.informacoes_adicionais = "Cliente isento de ICMS conforme decreto XYZ"
    #
    # Tipos de Emissão:
    # - :normal (1) - Emissão normal (padrão)
    # - :contingencia (2) - Emissão em contingência (offline)
    #
    # Finalidades:
    # - :normal (1) - Nota fiscal normal (padrão)
    # - :complementar (2) - Nota complementar
    # - :ajuste (3) - Nota de ajuste
    # - :devolucao (4) - Nota de devolução
    #
    # Atributos obrigatórios:
    # - serie (série da nota, padrão: 1)
    # - numero (número sequencial da nota)
    # - emitente (provedor/empresa)
    # - destinatario (cliente/tomador do serviço)
    # - itens (pelo menos um item/serviço)
    #
    # Atributos opcionais:
    # - data_emissao (padrão: Time.now)
    # - tipo_emissao (padrão: :normal)
    # - finalidade (padrão: :normal)
    # - informacoes_adicionais (texto livre até 5000 caracteres)
    #
    # Atributos preenchidos após autorização:
    # - chave_acesso (44 dígitos, gerada automaticamente)
    # - codigo_verificacao (8 dígitos aleatórios)
    # - protocolo (número do protocolo da SEFAZ)
    # - data_autorizacao (data/hora da autorização)
    # - xml_autorizado (XML completo com assinatura e protocolo)
    #
    # Funcionalidades automáticas:
    # - Numeração sequencial de itens ao adicionar
    # - Recálculo automático de totais ao adicionar/remover itens
    # - Geração da chave de acesso (44 dígitos com DV)
    # - Validação completa de todos os campos obrigatórios
    # - Validação em cascata (emitente, destinatário, itens)
    #
    # Validações realizadas:
    # - Presença de série, número, emitente e destinatário
    # - Pelo menos um item na nota
    # - Validação completa do emitente (CNPJ, IE, endereço)
    # - Validação completa do destinatário (CPF/CNPJ, endereço)
    # - Validação de cada item (código serviço, CFOP, valores)
    #
    # @note A chave de acesso é gerada no formato:
    #   UF (2) + AAMM (4) + CNPJ (14) + Modelo (2) + Série (3) +
    #   Número (9) + Código Numérico (8) + DV (1) = 44 dígitos
    class Nota
      attr_accessor :serie, :numero, :data_emissao, :tipo_emissao,
                    :finalidade, :emitente, :destinatario, :itens, :total,
                    :informacoes_adicionais, :chave_acesso, :codigo_verificacao,
                    :protocolo, :data_autorizacao, :xml_autorizado

      # Tipo de emissão
      TIPO_EMISSAO = {
        normal: 1,
        contingencia: 2
      }.freeze

      # Finalidade
      FINALIDADE = {
        normal: 1,
        complementar: 2,
        ajuste: 3,
        devolucao: 4
      }.freeze

      def initialize(attributes = {})
        @serie = Nfcom.configuration.serie_padrao || 1
        @data_emissao = Time.now
        @tipo_emissao = :normal
        @finalidade = :normal
        @itens = []
        @total = Total.new

        attributes.each do |key, value|
          if key == :emitente && value.is_a?(Hash)
            @emitente = Emitente.new(value)
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
        # Formato da chave: UFAnoMesCNPJModSerieNumCodNumDV
        # Exemplo: 26 2212 12345678000100 62 001 000000001 12345678 9

        config = Nfcom.configuration
        uf = config.codigo_uf
        ano_mes = data_emissao.strftime('%y%m')
        cnpj = emitente.cnpj.gsub(/\D/, '')
        modelo = '62'
        serie_fmt = serie.to_s.rjust(3, '0')
        numero_fmt = numero.to_s.rjust(9, '0')
        codigo_numerico = SecureRandom.random_number(100_000_000).to_s.rjust(8, '0')

        chave_sem_dv = "#{uf}#{ano_mes}#{cnpj}#{modelo}#{serie_fmt}#{numero_fmt}#{codigo_numerico}"
        dv = calcular_digito_verificador(chave_sem_dv)

        @codigo_verificacao = codigo_numerico
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

      def erros
        errors = []
        errors << 'Série é obrigatória' if serie.nil?
        errors << 'Número é obrigatório' if numero.nil?
        errors << 'Emitente é obrigatório' if emitente.nil?
        errors << 'Destinatário é obrigatório' if destinatario.nil?
        errors << 'Deve haver pelo menos um item' if itens.empty?

        errors.concat(emitente.erros.map { |e| "Emitente: #{e}" }) if emitente && !emitente.valido?
        errors.concat(destinatario.erros.map { |e| "Destinatário: #{e}" }) if destinatario && !destinatario.valido?

        itens.each_with_index do |item, i|
          errors.concat(item.erros.map { |e| "Item #{i + 1}: #{e}" }) unless item.valido?
        end

        errors
      end

      def autorizada?
        !protocolo.nil? && !data_autorizacao.nil?
      end

      private

      def calcular_digito_verificador(chave)
        # Módulo 11
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
