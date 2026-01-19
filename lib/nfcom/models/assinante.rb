# frozen_string_literal: true

module Nfcom
  module Models
    # Representa os dados do assinante do serviço de comunicação
    class Assinante
      include Utils::Helpers

      attr_accessor :codigo,                # iCodAssinante - Código único (1-30 chars)
                    :tipo,                  # tpAssinante - Tipo de assinante (1-8, 99)
                    :tipo_servico,          # tpServUtil - Tipo de serviço (1-7)
                    :numero_contrato,       # nContrato - Número do contrato (opcional)
                    :data_inicio_contrato,  # dContratoIni - Data início (opcional)
                    :data_fim_contrato,     # dContratoFim - Data fim (opcional)
                    :terminal_principal,    # NroTermPrinc - Terminal principal (condicional)
                    :uf_terminal_principal, # cUFPrinc - UF do terminal (condicional)
                    :terminais_adicionais   # Array de { numero:, uf: } (opcional)

      # Tipos de assinante (tpAssinante) - Domain D18
      TIPO_COMERCIAL = 1
      TIPO_INDUSTRIAL = 2
      TIPO_RESIDENCIAL = 3
      TIPO_PRODUTOR_RURAL = 4
      TIPO_ORGAO_PUBLICO = 5
      TIPO_PRESTADOR_TELECOM = 6
      TIPO_DIPLOMATICO = 7
      TIPO_RELIGIOSO = 8
      TIPO_OUTROS = 99

      # Tipos de serviço (tpServUtil) - Domain D24
      SERVICO_TELEFONIA = 1
      SERVICO_DADOS = 2
      SERVICO_TV = 3
      SERVICO_INTERNET = 4
      SERVICO_MULTIMIDIA = 5
      SERVICO_OUTROS = 6
      SERVICO_VARIOS = 7

      def initialize(attrs = {})
        @codigo = attrs[:codigo]
        @tipo = attrs[:tipo]
        @tipo_servico = attrs[:tipo_servico]
        @numero_contrato = attrs[:numero_contrato]
        @data_inicio_contrato = attrs[:data_inicio_contrato]
        @data_fim_contrato = attrs[:data_fim_contrato]
        @terminal_principal = attrs[:terminal_principal]
        @uf_terminal_principal = attrs[:uf_terminal_principal]
        @terminais_adicionais = attrs[:terminais_adicionais] || []
      end

      def valido?
        erros.empty?
      end

      def erros # rubocop:disable Metrics/MethodLength
        errors = []

        # Validações de campos obrigatórios
        errors << 'Código do assinante é obrigatório' if codigo.to_s.strip.empty?
        errors << 'Tipo de assinante é obrigatório' if tipo.nil?
        errors << 'Tipo de serviço é obrigatório' if tipo_servico.nil?

        # Validações declarativas de formato/schema
        campos = {
          codigo: { valor: codigo, validador: :er59, nome: 'Código do assinante' }
        }

        # Só valida tipo se não for nil (já checado acima)
        campos[:tipo] = { valor: tipo, validador: :d18, nome: 'Tipo de assinante' } unless tipo.nil?
        unless tipo_servico.nil?
          campos[:tipo_servico] =
            { valor: tipo_servico, validador: :d24, nome: 'Tipo de serviço' }
        end

        # Adicionar campos opcionais apenas se informados
        if numero_contrato && !numero_contrato.to_s.strip.empty?
          campos[:numero_contrato] = { valor: numero_contrato, validador: :er60, nome: 'Número do contrato' }
        end

        if data_inicio_contrato && !data_inicio_contrato.to_s.strip.empty?
          campos[:data_inicio] = { valor: data_inicio_contrato, validador: :er48, nome: 'Data de início' }
        end

        if data_fim_contrato && !data_fim_contrato.to_s.strip.empty?
          campos[:data_fim] = { valor: data_fim_contrato, validador: :er48, nome: 'Data de fim' }
        end

        # Executar validações declarativas
        errors.concat(Validators::SchemaValidator.validar_campos(campos))

        # Validação lógica: data fim >= data início
        if data_inicio_contrato && data_fim_contrato &&
           !data_inicio_contrato.to_s.strip.empty? && !data_fim_contrato.to_s.strip.empty?
          begin
            inicio = Date.parse(data_inicio_contrato.to_s)
            fim = Date.parse(data_fim_contrato.to_s)
            errors << 'Data de fim do contrato não pode ser anterior à data de início' if fim < inicio
          rescue ArgumentError
            # Erro de parsing já foi capturado pelas validações declarativas
          end
        end

        # Validações de terminal principal (condicional)
        if terminal_principal && !terminal_principal.to_s.strip.empty?
          # Se informou terminal, UF é obrigatória
          if uf_terminal_principal.to_s.strip.empty?
            errors << 'UF do terminal principal é obrigatória quando o número do terminal é informado'
          else
            # Validar formato do terminal e UF
            campos_terminal = {
              terminal: { valor: terminal_principal, validador: :telefone, nome: 'Terminal principal' },
              uf_terminal: { valor: uf_terminal_principal, validador: :d5, nome: 'UF do terminal' }
            }
            errors.concat(Validators::SchemaValidator.validar_campos(campos_terminal))
          end
        elsif uf_terminal_principal && !uf_terminal_principal.to_s.strip.empty?
          # Se informou UF mas não informou terminal
          errors << 'Número do terminal principal é obrigatório quando a UF é informada'
        end

        # Validações de terminais adicionais
        terminais_adicionais&.each_with_index do |terminal, index|
          if terminal[:numero].to_s.strip.empty?
            errors << "Terminal adicional #{index + 1}: número é obrigatório"
          else
            campos_adicional = {
              numero: { valor: terminal[:numero], validador: :telefone, nome: "Terminal adicional #{index + 1}" }
            }
            errors.concat(Validators::SchemaValidator.validar_campos(campos_adicional))
          end

          if terminal[:uf].to_s.strip.empty?
            errors << "Terminal adicional #{index + 1}: UF é obrigatória"
          else
            campos_uf = {
              uf: { valor: terminal[:uf], validador: :d5, nome: "UF do terminal adicional #{index + 1}" }
            }
            errors.concat(Validators::SchemaValidator.validar_campos(campos_uf))
          end
        end

        errors
      end
    end
  end
end
