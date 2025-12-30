# frozen_string_literal: true

require 'securerandom'

module Nfcom
  module Models
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
        codigo_numerico = SecureRandom.random_number(100000000).to_s.rjust(8, '0')
        
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
        errors << "Série é obrigatória" if serie.nil?
        errors << "Número é obrigatório" if numero.nil?
        errors << "Emitente é obrigatório" if emitente.nil?
        errors << "Destinatário é obrigatório" if destinatario.nil?
        errors << "Deve haver pelo menos um item" if itens.empty?
        
        errors.concat(emitente.erros.map { |e| "Emitente: #{e}" }) if emitente && !emitente.valido?
        errors.concat(destinatario.erros.map { |e| "Destinatário: #{e}" }) if destinatario && !destinatario.valido?
        
        itens.each_with_index do |item, i|
          errors.concat(item.erros.map { |e| "Item #{i+1}: #{e}" }) unless item.valido?
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
