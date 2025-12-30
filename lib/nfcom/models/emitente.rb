# frozen_string_literal: true

module Nfcom
  module Models
    # Representa o emitente da NF-COM
    #
    # O emitente é a empresa prestadora do serviço de comunicação que está
    # emitindo a nota fiscal. Deve ser sempre pessoa jurídica (CNPJ).
    #
    # @example Criar emitente completo
    #   emitente = Nfcom::Models::Emitente.new(
    #     cnpj: '12345678000100',
    #     razao_social: 'Provedor Internet LTDA',
    #     nome_fantasia: 'Meu Provedor',
    #     inscricao_estadual: '0123456789',
    #     inscricao_municipal: '987654',
    #     cnae: '6190-6/01',
    #     regime_tributario: 1,
    #     endereco: {
    #       logradouro: 'Av. Principal',
    #       numero: '1000',
    #       complemento: 'Sala 101',
    #       bairro: 'Centro',
    #       municipio: 'Recife',
    #       uf: 'PE',
    #       cep: '50000-000',
    #       codigo_municipio: '2611606'
    #     }
    #   )
    #
    # @example Validar emitente
    #   if emitente.valido?
    #     puts "Emitente válido"
    #   else
    #     puts "Erros: #{emitente.erros.join(', ')}"
    #   end
    #
    # Atributos obrigatórios:
    # - cnpj (14 dígitos, com validação)
    # - razao_social (razão social da empresa)
    #   - inscricao_estadual (IE do estado)
    # - endereco completo
    #
    # Atributos opcionais:
    # - nome_fantasia (nome de fantasia/comercial)
    # - inscricao_municipal (IM do município)
    # - cnae (classificação da atividade econômica)
    # - regime_tributario (1=Simples Nacional, 3=Normal)
    #
    # Validações automáticas:
    # - Validação de dígitos verificadores do CNPJ
    # - Rejeita CNPJ com todos dígitos iguais
    # - Valida presença de campos obrigatórios
    # - Valida campos obrigatórios do endereço
    #
    # @note O emitente deve estar cadastrado e credenciado na SEFAZ para
    #   emissão de NF-COM antes de usar esta gem.
    class Emitente
      include Utils::Helpers

      attr_accessor :cnpj, :razao_social, :nome_fantasia, :inscricao_estadual,
                    :inscricao_municipal, :cnae, :regime_tributario, :endereco

      def initialize(attributes = {})
        @endereco = Endereco.new
        attributes.each do |key, value|
          if key == :endereco && value.is_a?(Hash)
            @endereco = Endereco.new(value)
          elsif respond_to?("#{key}=")
            send("#{key}=", value)
          end
        end
      end

      def valido?
        erros.empty?
      end

      def erros
        errors = []
        errors << 'CNPJ é obrigatório' if cnpj.to_s.strip.empty?
        errors << 'CNPJ inválido' unless cnpj_valido?(cnpj)
        errors << 'Razão social é obrigatória' if razao_social.to_s.strip.empty?
        errors << 'Inscrição estadual é obrigatória' if inscricao_estadual.to_s.strip.empty?
        errors.concat(endereco.erros.map { |e| "Endereço: #{e}" }) unless endereco.valido?
        errors
      end
    end
  end
end
