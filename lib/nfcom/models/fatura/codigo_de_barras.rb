# frozen_string_literal: true

module Nfcom
  module Models
    class Fatura
      class CodigoDeBarras
        attr_reader :valor

        def initialize(valor)
          @valor = valor.to_s.gsub(/\D/, '')
          validar!
        end

        def tamanho
          valor.length
        end

        def formato
          case tamanho
          when 44 then :formato_44
          when 48 then :formato_48
          else :desconhecido
          end
        end

        def linha_digitavel
          handler.linha_digitavel
        end

        def valido?
          true
        rescue ArgumentError
          false
        end

        private

        def handler
          @handler ||= case formato
                       when :formato_44
                         CodigoDeBarras::Formato44.new(valor)
                       when :formato_48
                         CodigoDeBarras::Formato48.new(valor)
                       else
                         raise ArgumentError, 'Formato de código de barras não suportado'
                       end
        end

        def validar!
          return if valor.match?(/\A\d+\z/)

          raise ArgumentError, 'Código de barras deve conter apenas números'
        end
      end
    end
  end
end
