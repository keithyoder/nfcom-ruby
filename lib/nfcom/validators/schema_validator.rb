# frozen_string_literal: true

module Nfcom
  module Validators
    # Validadores baseados no Schema NFCom v1.00
    # Expressões Regulares (ER) conforme documentação oficial SEFAZ
    module SchemaValidator # rubocop:disable Metrics/ModuleLength
      # Expressões Regulares do Schema NFCom
      REGEX_PATTERNS = {
        # ER1 - Data/hora no formato AAAA-MM-DDTHH:MM:SS+HH:MM
        er1: /
          \A
          (
            (20(([02468][048])|([13579][26]))-02-29) |
            (20[0-9][0-9])-
            (
              (((0[1-9])|(1[0-2]))-((0[1-9])|(1\d)|(2[0-8]))) |
              ((((0[13578])|(1[02]))-31)) |
              (((0[1,3-9])|(1[0-2]))-(29|30))
            )
          )
          T
          (20|21|22|23|[0-1]\d):
          [0-5]\d:
          [0-5]\d
          (
            [-,+](0[0-9]|10|11):00 |
            (\+(12):00)
          )
          \z
        /x,

        # ER2 - 7 dígitos (cNF, cMun, etc)
        er2: /\A[0-9]{7}\z/,

        # ER3 - Chave de acesso (44 dígitos)
        er3: /\A[0-9]{6}[A-Z0-9]{12}[0-9]{26}\z/,

        # ER7 - CNPJ (14 dígitos)
        er7: /\A[A-Z0-9]{12}[0-9]{2}\z/,

        # ER8 - CNPJ opcional (0 ou 14 dígitos)
        er8: /\A([0-9]{0}|[A-Z0-9]{12}[0-9]{2})\z/,

        # ER9 - CPF (11 dígitos)
        er9: /\A[0-9]{11}\z/,

        # ER11 - Alíquota ICMS (3,2)
        er11: /\A(0|0\.[0-9]{2}|[1-9]{1}[0-9]{0,2}(\.[0-9]{2})?)\z/,

        # ER16 - Percentual (3,2-4)
        er16: /\A(0|0\.[0-9]{2,4}|[1-9]{1}[0-9]{0,2}(\.[0-9]{2,4})?)\z/,

        # ER31 - Quantidade (11,0-4)
        er31: /\A[0-9]{1,11}(\.[0-9]{2,4})?\z/,

        # ER36 - Valor (13,2)
        er36: /\A(0|0\.[0-9]{2}|[1-9]{1}[0-9]{0,12}(\.[0-9]{2})?)\z/,

        # ER37 - Valor (13,2) - pode ser zero
        er37: /\A0\.[0-9]{2}|[1-9]{1}[0-9]{0,12}(\.[0-9]{2})?\z/,

        # ER39 - Valor (13,2-8)
        er39: /\A[0-9]{1,13}(\.[0-9]{2,8})?\z/,

        # ER41 - IE (0-14 dígitos ou ISENTO)
        er41: /\A([0-9]{0,14}|ISENTO)\z/,

        # ER42 - IE (2-14 dígitos)
        er42: /\A[0-9]{2,14}\z/,

        # ER43 - Número NF (1-9 dígitos, não pode começar com zero)
        er43: /\A[1-9]{1}[0-9]{0,8}\z/,

        # ER44 - Série (0 ou 1-999)
        er44: /\A(0|[1-9]{1}[0-9]{0,2})\z/,

        # ER47 - Texto geral (1-infinito caracteres, não pode ter apenas espaços)
        er47: /\A[^\r\n\t]*[!-ÿ][^\r\n\t]*\z/,

        # ER48 - Data AAAA-MM-DD
        er48: /
          \A
          (
            (20|19|18)(([02468][048])|([13579][26]))-02-29 |
            (20|19|18)[0-9][0-9]-
            (
              (((0[1-9])|(1[0-2]))-((0[1-9])|(1\d)|(2[0-8]))) |
              ((((0[13578])|(1[02]))-31)) |
              (((0[1,3-9])|(1[0-2]))-(29|30))
            )
          )
          \z
        /x,

        # ER57 - 1 dígito
        er57: /\A[0-9]{1}\z/,

        # ER58 - Texto (0 ou 2-20 caracteres)
        er58: /\A([!-ÿ]{0}|[!-ÿ]{2,20})?\z/,

        # ER59 - Texto (0 ou 1-30 caracteres)
        er59: /\A([!-ÿ]{0}|[!-ÿ]{1,30})?\z/,

        # ER60 - Texto (0 ou 1-20 caracteres)
        er60: /\A([!-ÿ]{0}|[!-ÿ]{1,20})?\z/,

        # ER61 - Telefone (7-12 dígitos)
        er61: /\A[0-9]{7,12}\z/,

        # ER62 - Número item (1-9999)
        er62: /\A[1-9]{1}[0-9]{0,3}\z/,

        # ER63 - Número (1-20 dígitos)
        er63: /\A[0-9]{1,20}\z/,

        # ER64 - Código barras (1-48 dígitos)
        er64: /\A[0-9]{1,48}\z/,

        # ER65 - ID com prefixo NFCom
        er65: /\ANFCom[0-9]{6}[A-Z0-9]{12}[0-9]{26}\z/,

        # ER67 - CEP (8 dígitos)
        er67: /\A[0-9]{8}\z/,

        # ER70 - Versão (1.00)
        er70: /\A1\.00\z/,

        # ER72 - Email
        er72: /\A[^@]+@[^.]+\..+\z/,

        # ER73 - CFOP
        er73: /\A[123567][0-9]([0-9][1-9]|[1-9][0-9])\z/,

        # ER74 - Competência (1-6 dígitos)
        er74: /\A[0-9]{1,6}\z/
      }.freeze

      # Valida um valor contra uma expressão regular do schema
      #
      # @param valor [String]
      # @param chave_regex [Symbol] Ex: :er2, :er7
      # @return [Boolean]
      def self.valido_por_schema?(valor, chave_regex)
        return false if valor.nil?

        pattern = REGEX_PATTERNS[chave_regex]
        return false unless pattern

        valor.to_s.match?(pattern)
      end

      # cNF (Código Numérico) – exatamente 7 dígitos
      def self.cnf_valido?(cnf)
        valido_por_schema?(cnf.to_s, :er2)
      end

      # CNPJ – apenas valida formato (14 dígitos)
      def self.cnpj_formato_valido?(cnpj)
        cnpj_limpo = cnpj.to_s.gsub(/\D/, '')
        cnpj_limpo.length == 14 && cnpj_limpo.match?(/\A[0-9]{14}\z/)
      end

      # CPF – apenas valida formato (11 dígitos)
      def self.cpf_formato_valido?(cpf)
        cpf_limpo = cpf.to_s.gsub(/\D/, '')
        valido_por_schema?(cpf_limpo, :er9)
      end

      # CEP – 8 dígitos
      def self.cep_valido?(cep)
        cep_limpo = cep.to_s.gsub(/\D/, '')
        valido_por_schema?(cep_limpo, :er67)
      end

      # Código de município (IBGE) – 7 dígitos
      def self.codigo_municipio_valido?(codigo)
        valido_por_schema?(codigo.to_s, :er2)
      end

      # Número da NF – 1 a 999.999.999
      def self.numero_nf_valido?(numero)
        valido_por_schema?(numero.to_s, :er43)
      end

      # Série da NF – 0 a 999
      def self.serie_valida?(serie)
        valido_por_schema?(serie.to_s, :er44)
      end

      # Email (opcional)
      def self.email_valido?(email)
        return true if email.nil? || email.to_s.strip.empty?

        valido_por_schema?(email.to_s, :er72)
      end

      # Telefone (opcional) – 7 a 12 dígitos
      def self.telefone_valido?(telefone)
        return true if telefone.nil? || telefone.to_s.strip.empty?

        telefone_limpo = telefone.to_s.gsub(/\D/, '')
        valido_por_schema?(telefone_limpo, :er61)
      end

      # CFOP
      def self.cfop_valido?(cfop)
        valido_por_schema?(cfop.to_s, :er73)
      end

      # Valor monetário (13,2)
      def self.valor_valido?(valor)
        valido_por_schema?(valor.to_s, :er36)
      end

      # Texto geral (não pode ser apenas espaços)
      def self.texto_valido?(texto, tamanho_max = nil)
        return false if texto.nil? || texto.to_s.strip.empty?
        return false if tamanho_max && texto.to_s.length > tamanho_max

        valido_por_schema?(texto.to_s, :er47)
      end

      # Chave de acesso – 44 dígitos
      def self.chave_acesso_valida?(chave)
        valido_por_schema?(chave.to_s, :er3)
      end

      # ID com prefixo NFCom
      def self.id_valido?(id)
        valido_por_schema?(id.to_s, :er65)
      end

      # Executa validações múltiplas e retorna mensagens de erro
      #
      # @param campos [Hash]
      # @return [Array<String>]
      def self.validar_campos(campos) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength
        erros = []

        campos.each do |campo, config|
          valor = config[:valor]
          validador = config[:validador]
          nome = config[:nome] || campo.to_s

          valido = case validador
                   when :cnf then cnf_valido?(valor)
                   when :cnpj then cnpj_formato_valido?(valor)
                   when :cpf then cpf_formato_valido?(valor)
                   when :cep then cep_valido?(valor)
                   when :municipio then codigo_municipio_valido?(valor)
                   when :numero_nf then numero_nf_valido?(valor)
                   when :serie then serie_valida?(valor)
                   when :email then email_valido?(valor)
                   when :telefone then telefone_valido?(valor)
                   when :cfop then cfop_valido?(valor)
                   when :valor then valor_valido?(valor)
                   when :texto then texto_valido?(valor, config[:max])
                   when :chave then chave_acesso_valida?(valor)
                   when :id then id_valido?(valor)
                   when Symbol then valido_por_schema?(valor, validador)
                   else true
                   end

          erros << "#{nome} inválido: '#{valor}'" unless valido
        end

        erros
      end
    end
  end
end
