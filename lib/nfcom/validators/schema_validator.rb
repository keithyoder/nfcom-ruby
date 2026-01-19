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

      DOMAINS = {
        # D1 - Códigos UF (IBGE)
        d1: [11, 12, 13, 14, 15, 16, 17, 21, 22, 23, 24, 25, 26, 27, 28, 29,
             31, 32, 33, 35, 41, 42, 43, 50, 51, 52, 53],

        # D4 - Modelo NFCom
        d4: [62],

        # D5 - Siglas UF
        d5: %w[AC AL AM AP BA CE DF ES GO MA MG MS MT PA PB PE PI PR RJ RN RO RR RS SC SE SP TO],

        # D7 - Tipo de Ambiente (tpAmb)
        d7: [1, 2], # 1=Produção, 2=Homologação

        # D8 - Valores 1-4 (usado em vários campos como uMed)
        d8: [1, 2, 3, 4],

        # D10 - Indicador booleano
        d10: [1],

        # D11 - CST ICMS - Tributação normal
        d11: ['00'],

        # D12 - CST ICMS - Tributação com redução de BC
        d12: ['20'],

        # D13 - CST ICMS - Isenta/Não tributada
        d13: %w[40 41],

        # D14 - CST ICMS - Diferimento
        d14: ['51'],

        # D15 - CST ICMS - Outros
        d15: ['90'],

        # D16 - CST PIS/COFINS
        d16: %w[01 02 06 07 08 09 49],

        # D18 - Tipos de assinante
        d18: [1, 2, 3, 4, 5, 6, 7, 8, 99],

        # D19 - Finalidade da NFCom (finNFCom)
        d19: [0, 3, 4], # 0=Normal, 3=Substituição, 4=Ajuste

        # D20 - Tipo de Faturamento (tpFat)
        d20: [0, 1, 2], # 0=Normal, 1=Centralizado, 2=Cofaturamento

        # D22 - Indicador IE Destinatário (indIEDest)
        d22: [1, 2, 9], # 1=Contribuinte, 2=Isento, 9=Não Contribuinte

        # D23 - Código Regime Tributário (CRT)
        d23: [1, 2, 3], # 1=Simples Nacional, 2=Simples Excesso, 3=Normal

        # D24 - Tipos de serviço utilizado
        d24: [1, 2, 3, 4, 5, 6, 7],

        # D25 - Modelo documento (NF21/22)
        d25: [21, 22],

        # D26 - Motivo de substituição
        d26: %w[01 02 03 04 05]
      }.freeze

      def self.valido_por_schema?(valor, chave_regex)
        return false if valor.nil?

        pattern = REGEX_PATTERNS[chave_regex]
        return false unless pattern

        valor.to_s.match?(pattern)
      end

      # Valida um valor contra um domínio
      def self.valido_por_dominio?(valor, chave_dominio, converter_para_int: false)
        return false if valor.nil?

        dominio = DOMAINS[chave_dominio]
        return false unless dominio

        valor_comparar = converter_para_int ? valor.to_i : valor.to_s.upcase
        dominio.include?(valor_comparar)
      end

      # Validadores complexos que fazem mais do que checar pattern/domain

      def self.cnpj_formato_valido?(cnpj)
        cnpj_limpo = cnpj.to_s.gsub(/\D/, '')
        cnpj_limpo.length == 14 && cnpj_limpo.match?(/\A[0-9]{14}\z/)
      end

      def self.cpf_formato_valido?(cpf)
        cpf_limpo = cpf.to_s.gsub(/\D/, '')
        valido_por_schema?(cpf_limpo, :er9)
      end

      def self.cep_valido?(cep)
        cep_limpo = cep.to_s.gsub(/\D/, '')
        valido_por_schema?(cep_limpo, :er67)
      end

      def self.telefone_valido?(telefone)
        return true if telefone.nil? || telefone.to_s.strip.empty?

        telefone_limpo = telefone.to_s.gsub(/\D/, '')
        valido_por_schema?(telefone_limpo, :er61)
      end

      def self.email_valido?(email)
        return true if email.nil? || email.to_s.strip.empty?

        valido_por_schema?(email.to_s, :er72)
      end

      def self.texto_valido?(texto, tamanho_max = nil)
        return false if texto.nil? || texto.to_s.strip.empty?
        return false if tamanho_max && texto.to_s.length > tamanho_max

        valido_por_schema?(texto.to_s, :er47)
      end

      def self.data_valida?(data)
        return false if data.nil? || data.to_s.strip.empty?

        valido_por_schema?(data.to_s, :er48)
      end

      def self.cst_icms_valido?(cst)
        cst_str = cst.to_s.rjust(2, '0')
        DOMAINS[:d11].include?(cst_str) ||
          DOMAINS[:d12].include?(cst_str) ||
          DOMAINS[:d13].include?(cst_str) ||
          DOMAINS[:d14].include?(cst_str) ||
          DOMAINS[:d15].include?(cst_str)
      end

      # Executa validações múltiplas e retorna mensagens de erro
      def self.validar_campos(campos) # rubocop:disable Metrics/MethodLength
        erros = []

        campos.each do |campo, config|
          valor = config[:valor]
          validador = config[:validador]
          nome = config[:nome] || campo.to_s

          valido = if validador.to_s.start_with?('er')
                     # ER pattern: :er48, :er59, etc.
                     valido_por_schema?(valor, validador)
                   elsif validador.to_s.start_with?('d')
                     # Domain: :d18, :d24, etc.
                     # Assume integer domains unless the domain contains strings
                     sample = DOMAINS[validador]&.first
                     converter_para_int = sample.is_a?(Integer)
                     valido_por_dominio?(valor, validador, converter_para_int: converter_para_int)
                   else
                     # Named validator methods
                     case validador
                     when :cnpj then cnpj_formato_valido?(valor)
                     when :cpf then cpf_formato_valido?(valor)
                     when :cep then cep_valido?(valor)
                     when :telefone then telefone_valido?(valor)
                     when :email then email_valido?(valor)
                     when :texto then texto_valido?(valor, config[:max])
                     when :data then data_valida?(valor)
                     when :cst_icms then cst_icms_valido?(valor)
                     else true
                     end
                   end

          erros << "#{nome} inválido: '#{valor}'" unless valido
        end

        erros
      end
    end
  end
end
