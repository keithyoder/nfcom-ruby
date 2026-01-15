# frozen_string_literal: true

module Nfcom
  module Validators
    # Validadores baseados no Schema NFCom v1.00
    # Expressões Regulares (ER) conforme documentação oficial SEFAZ
    module SchemaValidator
      # Expressões Regulares do Schema NFCom
      REGEX_PATTERNS = {
        # ER1 - Data/hora no formato AAAA-MM-DDTHH:MM:SS+HH:MM
        er1: /\A(((20(([02468][048])|([13579][26]))-02-29))|(20[0-9][0-9])-((((0[1-9])|(1[0-2]))-((0[1-9])|(1\d)|(2[0-8])))|((((0[13578])|(1[02]))-31)|(((0[1,3-9])|(1[0-2]))-(29|30)))))T(20|21|22|23|[0-1]\d):[0-5]\d:[0-5]\d([-,+](0[0-9]|10|11):00|(\+(12):00))\z/,

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
        er47: /\A[!-ÿ]{1}[ -ÿ]{0,}[!-ÿ]{1}|[!-ÿ]{1}\z/,

        # ER48 - Data AAAA-MM-DD
        er48: /\A((((20|19|18)(([02468][048])|([13579][26]))-02-29))|((20|19|18)[0-9][0-9])-((((0[1-9])|(1[0-2]))-((0[1-9])|(1\d)|(2[0-8])))|((((0[13578])|(1[02]))-31)|(((0[1,3-9])|(1[0-2]))-(29|30)))))\z/,

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

      # Valida um valor contra uma expressão regular específica
      # @param value [String] Valor a ser validado
      # @param pattern_key [Symbol] Chave da expressão regular (ex: :er2, :er7)
      # @return [Boolean] true se válido, false caso contrário
      def self.validate(value, pattern_key)
        return false if value.nil?

        pattern = REGEX_PATTERNS[pattern_key]
        return false unless pattern

        value.to_s.match?(pattern)
      end

      # Valida cNF (Código Numérico) - deve ter exatamente 7 dígitos
      # @param cnf [String, Integer] Código numérico
      # @return [Boolean] true se válido
      def self.validate_cnf(cnf)
        validate(cnf.to_s, :er2)
      end

      # Valida CNPJ - 14 dígitos
      # @param cnpj [String] CNPJ
      # @return [Boolean] true se válido
      def self.validate_cnpj_format(cnpj)
        # Remove formatação
        cnpj_limpo = cnpj.to_s.gsub(/\D/, '')
        # Valida formato (14 dígitos numéricos)
        cnpj_limpo.length == 14 && cnpj_limpo.match?(/\A[0-9]{14}\z/)
      end

      # Valida CPF - 11 dígitos
      # @param cpf [String] CPF
      # @return [Boolean] true se válido
      def self.validate_cpf_format(cpf)
        # Remove formatação
        cpf_limpo = cpf.to_s.gsub(/\D/, '')
        validate(cpf_limpo, :er9)
      end

      # Valida CEP - 8 dígitos
      # @param cep [String] CEP
      # @return [Boolean] true se válido
      def self.validate_cep(cep)
        # Remove formatação
        cep_limpo = cep.to_s.gsub(/\D/, '')
        validate(cep_limpo, :er67)
      end

      # Valida código de município - 7 dígitos
      # @param codigo [String, Integer] Código IBGE
      # @return [Boolean] true se válido
      def self.validate_codigo_municipio(codigo)
        validate(codigo.to_s, :er2)
      end

      # Valida número da nota fiscal - 1 a 999999999
      # @param numero [String, Integer] Número da NF
      # @return [Boolean] true se válido
      def self.validate_numero_nf(numero)
        validate(numero.to_s, :er43)
      end

      # Valida série - 0 a 999
      # @param serie [String, Integer] Série
      # @return [Boolean] true se válido
      def self.validate_serie(serie)
        validate(serie.to_s, :er44)
      end

      # Valida email
      # @param email [String] Email
      # @return [Boolean] true se válido
      def self.validate_email(email)
        return true if email.nil? || email.to_s.strip.empty? # Email é opcional

        validate(email.to_s, :er72)
      end

      # Valida telefone - 7 a 12 dígitos
      # @param telefone [String] Telefone
      # @return [Boolean] true se válido
      def self.validate_telefone(telefone)
        return true if telefone.nil? || telefone.to_s.strip.empty? # Telefone é opcional

        telefone_limpo = telefone.to_s.gsub(/\D/, '')
        validate(telefone_limpo, :er61)
      end

      # Valida CFOP - formato específico
      # @param cfop [String] CFOP
      # @return [Boolean] true se válido
      def self.validate_cfop(cfop)
        validate(cfop.to_s, :er73)
      end

      # Valida valor monetário (13,2)
      # @param valor [String, Numeric] Valor
      # @return [Boolean] true se válido
      def self.validate_valor(valor)
        validate(valor.to_s, :er36)
      end

      # Valida texto geral (não pode ter apenas espaços)
      # @param texto [String] Texto
      # @param tamanho_max [Integer] Tamanho máximo
      # @return [Boolean] true se válido
      def self.validate_texto(texto, tamanho_max = nil)
        return false if texto.nil? || texto.to_s.strip.empty?
        return false if tamanho_max && texto.to_s.length > tamanho_max

        validate(texto.to_s, :er47)
      end

      # Valida chave de acesso completa (44 dígitos)
      # @param chave [String] Chave de acesso
      # @return [Boolean] true se válido
      def self.validate_chave_acesso(chave)
        validate(chave.to_s, :er3)
      end

      # Valida ID (com prefixo NFCom)
      # @param id [String] ID
      # @return [Boolean] true se válido
      def self.validate_id(id)
        validate(id.to_s, :er65)
      end

      # Lista todos os erros de validação de um hash de campos
      # @param campos [Hash] Hash com campos e valores
      # @return [Array<String>] Array de mensagens de erro
      def self.validar_campos(campos)
        erros = []

        campos.each do |campo, config|
          valor = config[:valor]
          validador = config[:validador]
          nome = config[:nome] || campo.to_s

          resultado = case validador
                      when :cnf then validate_cnf(valor)
                      when :cnpj then validate_cnpj_format(valor)
                      when :cpf then validate_cpf_format(valor)
                      when :cep then validate_cep(valor)
                      when :municipio then validate_codigo_municipio(valor)
                      when :numero_nf then validate_numero_nf(valor)
                      when :serie then validate_serie(valor)
                      when :email then validate_email(valor)
                      when :telefone then validate_telefone(valor)
                      when :cfop then validate_cfop(valor)
                      when :valor then validate_valor(valor)
                      when :texto then validate_texto(valor, config[:max])
                      when :chave then validate_chave_acesso(valor)
                      when :id then validate_id(valor)
                      when Symbol then validate(valor, validador)
                      else true
                      end

          erros << "#{nome} inválido: '#{valor}'" unless resultado
        end

        erros
      end
    end
  end
end
