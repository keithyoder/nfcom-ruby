# frozen_string_literal: true

module Nfcom
  module Models
    class Fatura
      class CodigoDeBarras
        class Formato44
          def initialize(valor)
            @valor = valor
            validar!
          end

          def linha_digitavel
            [
              campo(@valor[0, 4] + @valor[19, 5]),
              campo(@valor[24, 10]),
              campo(@valor[34, 10]),
              @valor[4],
              @valor[5, 14]
            ].join(' ')
          end

          private

          def campo(valor)
            "#{valor[0, 5]}.#{valor[5, 5]}#{modulo10(valor)}"
          end

          def modulo10(numero)
            soma = 0
            multiplicador = 2

            numero.reverse.each_char do |char|
              v = char.to_i * multiplicador
              v -= 9 if v > 9
              soma += v
              multiplicador = multiplicador == 2 ? 1 : 2
            end

            (10 - (soma % 10)) % 10
          end

          def validar!
            return if @valor.match?(/\A\d{44}\z/)

            raise ArgumentError, 'Código de barras (44) inválido'
          end
        end
      end
    end
  end
end
