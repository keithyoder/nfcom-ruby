# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Nfcom::Validators::SchemaValidator do
  describe '.valido_por_schema?' do
    context 'com ER1 (data/hora ISO 8601)' do
      let(:pattern) { :er1 }

      it 'aceita data/hora válida com timezone' do
        expect(described_class.valido_por_schema?('2026-01-30T14:30:45-03:00', pattern)).to be true
        expect(described_class.valido_por_schema?('2026-12-31T23:59:59+00:00', pattern)).to be true
      end

      it 'aceita ano bissexto' do
        expect(described_class.valido_por_schema?('2024-02-29T12:00:00-03:00', pattern)).to be true
      end

      it 'rejeita data/hora inválida' do
        expect(described_class.valido_por_schema?('2026-02-29T14:30:45-03:00', pattern)).to be false # não bissexto
        expect(described_class.valido_por_schema?('2026-13-01T14:30:45-03:00', pattern)).to be false # mês inválido
        expect(described_class.valido_por_schema?('2026-01-32T14:30:45-03:00', pattern)).to be false # dia inválido
        expect(described_class.valido_por_schema?('2026-01-30 14:30:45', pattern)).to be false # formato errado
      end

      it 'rejeita valor nil' do
        expect(described_class.valido_por_schema?(nil, pattern)).to be false
      end
    end

    context 'com ER2 (7 dígitos)' do
      let(:pattern) { :er2 }

      it 'aceita exatamente 7 dígitos' do
        expect(described_class.valido_por_schema?('1234567', pattern)).to be true
        expect(described_class.valido_por_schema?('0000000', pattern)).to be true
        expect(described_class.valido_por_schema?('2611606', pattern)).to be true # código município
      end

      it 'rejeita quantidade diferente de 7 dígitos' do
        expect(described_class.valido_por_schema?('123456', pattern)).to be false
        expect(described_class.valido_por_schema?('12345678', pattern)).to be false
      end

      it 'rejeita caracteres não numéricos' do
        expect(described_class.valido_por_schema?('123456a', pattern)).to be false
        expect(described_class.valido_por_schema?('123-456', pattern)).to be false
      end
    end

    context 'com ER7 (CNPJ)' do
      let(:pattern) { :er7 }

      it 'aceita CNPJ no formato do schema' do
        expect(described_class.valido_por_schema?('12345678000100', pattern)).to be true
        expect(described_class.valido_por_schema?('00000000000000', pattern)).to be true
      end

      it 'rejeita formato inválido' do
        expect(described_class.valido_por_schema?('1234567800010', pattern)).to be false # 13 dígitos
        expect(described_class.valido_por_schema?('123456780001000', pattern)).to be false # 15 dígitos
        expect(described_class.valido_por_schema?('12.345.678/0001-00', pattern)).to be false # formatado
      end
    end

    context 'com ER9 (CPF)' do
      let(:pattern) { :er9 }

      it 'aceita CPF com 11 dígitos' do
        expect(described_class.valido_por_schema?('12345678901', pattern)).to be true
        expect(described_class.valido_por_schema?('00000000000', pattern)).to be true
      end

      it 'rejeita formato inválido' do
        expect(described_class.valido_por_schema?('1234567890', pattern)).to be false # 10 dígitos
        expect(described_class.valido_por_schema?('123456789012', pattern)).to be false # 12 dígitos
        expect(described_class.valido_por_schema?('123.456.789-01', pattern)).to be false # formatado
      end
    end

    context 'com ER36 (valor 13,2)' do
      let(:pattern) { :er36 }

      it 'aceita valores válidos' do
        expect(described_class.valido_por_schema?('0', pattern)).to be true
        expect(described_class.valido_por_schema?('0.00', pattern)).to be true
        expect(described_class.valido_por_schema?('99.90', pattern)).to be true
        expect(described_class.valido_por_schema?('1234567890123.99', pattern)).to be true
      end

      it 'rejeita valores inválidos' do
        expect(described_class.valido_por_schema?('99.999', pattern)).to be false # 3 decimais
        expect(described_class.valido_por_schema?('12345678901234.99', pattern)).to be false # 14 inteiros
        expect(described_class.valido_por_schema?('abc', pattern)).to be false
      end
    end

    context 'com ER43 (número NF - não pode começar com zero)' do
      let(:pattern) { :er43 }

      it 'aceita números válidos' do
        expect(described_class.valido_por_schema?('1', pattern)).to be true
        expect(described_class.valido_por_schema?('123', pattern)).to be true
        expect(described_class.valido_por_schema?('999999999', pattern)).to be true
      end

      it 'rejeita zero ou número começando com zero' do
        expect(described_class.valido_por_schema?('0', pattern)).to be false
        expect(described_class.valido_por_schema?('01', pattern)).to be false
        expect(described_class.valido_por_schema?('0123', pattern)).to be false
      end

      it 'rejeita mais de 9 dígitos' do
        expect(described_class.valido_por_schema?('1234567890', pattern)).to be false
      end
    end

    context 'com ER44 (série - 0 ou 1-999)' do
      let(:pattern) { :er44 }

      it 'aceita série válida' do
        expect(described_class.valido_por_schema?('0', pattern)).to be true
        expect(described_class.valido_por_schema?('1', pattern)).to be true
        expect(described_class.valido_por_schema?('999', pattern)).to be true
      end

      it 'rejeita série inválida' do
        expect(described_class.valido_por_schema?('01', pattern)).to be false # começando com zero (exceto zero sozinho)
        expect(described_class.valido_por_schema?('1000', pattern)).to be false # > 999
      end
    end

    context 'com ER47 (texto geral)' do
      let(:pattern) { :er47 }

      it 'aceita texto válido' do
        expect(described_class.valido_por_schema?('a', pattern)).to be true
        expect(described_class.valido_por_schema?('ABC', pattern)).to be true
        expect(described_class.valido_por_schema?('Texto com espaços', pattern)).to be true
        expect(described_class.valido_por_schema?('João da Silva', pattern)).to be true
      end

      it 'rejeita apenas espaços' do
        expect(described_class.valido_por_schema?('   ', pattern)).to be false
        expect(described_class.valido_por_schema?('', pattern)).to be false
      end

      it 'rejeita texto com quebras de linha ou tabs' do
        expect(described_class.valido_por_schema?("texto\ncom\nquebra", pattern)).to be false
        expect(described_class.valido_por_schema?("texto\tcom\ttab", pattern)).to be false
      end
    end

    context 'com ER48 (data AAAA-MM-DD)' do
      let(:pattern) { :er48 }

      it 'aceita data válida' do
        expect(described_class.valido_por_schema?('2026-01-30', pattern)).to be true
        expect(described_class.valido_por_schema?('2024-02-29', pattern)).to be true # bissexto
        expect(described_class.valido_por_schema?('1999-12-31', pattern)).to be true
      end

      it 'rejeita data inválida' do
        expect(described_class.valido_por_schema?('2026-02-29', pattern)).to be false # não bissexto
        expect(described_class.valido_por_schema?('2026-13-01', pattern)).to be false # mês inválido
        expect(described_class.valido_por_schema?('2026-01-32', pattern)).to be false # dia inválido
        expect(described_class.valido_por_schema?('26-01-30', pattern)).to be false # ano com 2 dígitos
        expect(described_class.valido_por_schema?('30/01/2026', pattern)).to be false # formato brasileiro
      end
    end

    context 'com ER61 (telefone 7-12 dígitos)' do
      let(:pattern) { :er61 }

      it 'aceita telefone válido' do
        expect(described_class.valido_por_schema?('1234567', pattern)).to be true # 7 dígitos
        expect(described_class.valido_por_schema?('81999887766', pattern)).to be true # 11 dígitos
        expect(described_class.valido_por_schema?('123456789012', pattern)).to be true # 12 dígitos
      end

      it 'rejeita telefone inválido' do
        expect(described_class.valido_por_schema?('123456', pattern)).to be false # 6 dígitos
        expect(described_class.valido_por_schema?('1234567890123', pattern)).to be false # 13 dígitos
        expect(described_class.valido_por_schema?('(81)99988-7766', pattern)).to be false # formatado
      end
    end

    context 'com ER67 (CEP - 8 dígitos)' do
      let(:pattern) { :er67 }

      it 'aceita CEP válido' do
        expect(described_class.valido_por_schema?('50000000', pattern)).to be true
        expect(described_class.valido_por_schema?('01310100', pattern)).to be true
      end

      it 'rejeita CEP inválido' do
        expect(described_class.valido_por_schema?('5000000', pattern)).to be false # 7 dígitos
        expect(described_class.valido_por_schema?('500000000', pattern)).to be false # 9 dígitos
        expect(described_class.valido_por_schema?('50000-000', pattern)).to be false # formatado
      end
    end
  end

  describe '.valido_por_dominio?' do
    context 'com D1 (códigos UF)' do
      let(:domain) { :d1 }

      it 'aceita código válido' do
        expect(described_class.valido_por_dominio?(26, domain, converter_para_int: true)).to be true # PE
        expect(described_class.valido_por_dominio?(35, domain, converter_para_int: true)).to be true # SP
        expect(described_class.valido_por_dominio?(33, domain, converter_para_int: true)).to be true # RJ
      end

      it 'rejeita código inválido' do
        expect(described_class.valido_por_dominio?(99, domain, converter_para_int: true)).to be false
        expect(described_class.valido_por_dominio?(0, domain, converter_para_int: true)).to be false
      end

      it 'funciona com strings quando converter_para_int é true' do
        expect(described_class.valido_por_dominio?('26', domain, converter_para_int: true)).to be true
        expect(described_class.valido_por_dominio?('99', domain, converter_para_int: true)).to be false
      end
    end

    context 'com D5 (siglas UF)' do
      let(:domain) { :d5 }

      it 'aceita sigla válida' do
        expect(described_class.valido_por_dominio?('PE', domain)).to be true
        expect(described_class.valido_por_dominio?('SP', domain)).to be true
        expect(described_class.valido_por_dominio?('RJ', domain)).to be true
      end

      it 'aceita sigla em minúscula (converte para maiúscula)' do
        expect(described_class.valido_por_dominio?('pe', domain)).to be true
        expect(described_class.valido_por_dominio?('sp', domain)).to be true
      end

      it 'rejeita sigla inválida' do
        expect(described_class.valido_por_dominio?('XX', domain)).to be false
        expect(described_class.valido_por_dominio?('ZZ', domain)).to be false
      end
    end

    context 'com D7 (tipo ambiente)' do
      let(:domain) { :d7 }

      it 'aceita valores válidos' do
        expect(described_class.valido_por_dominio?(1, domain, converter_para_int: true)).to be true # Produção
        expect(described_class.valido_por_dominio?(2, domain, converter_para_int: true)).to be true # Homologação
      end

      it 'rejeita valores inválidos' do
        expect(described_class.valido_por_dominio?(0, domain, converter_para_int: true)).to be false
        expect(described_class.valido_por_dominio?(3, domain, converter_para_int: true)).to be false
      end
    end

    context 'com D18 (tipos de assinante)' do
      let(:domain) { :d18 }

      it 'aceita tipos válidos' do
        expect(described_class.valido_por_dominio?(1, domain, converter_para_int: true)).to be true # Comercial
        expect(described_class.valido_por_dominio?(3, domain, converter_para_int: true)).to be true # Residencial
        expect(described_class.valido_por_dominio?(99, domain, converter_para_int: true)).to be true # Outros
      end

      it 'rejeita tipo inválido' do
        expect(described_class.valido_por_dominio?(10, domain, converter_para_int: true)).to be false
        expect(described_class.valido_por_dominio?(100, domain, converter_para_int: true)).to be false
      end
    end

    context 'com D24 (tipos de serviço)' do
      let(:domain) { :d24 }

      it 'aceita tipos válidos' do
        expect(described_class.valido_por_dominio?(1, domain, converter_para_int: true)).to be true # Telefonia
        expect(described_class.valido_por_dominio?(4, domain, converter_para_int: true)).to be true # Internet
        expect(described_class.valido_por_dominio?(7, domain, converter_para_int: true)).to be true # Vários
      end

      it 'rejeita tipo inválido' do
        expect(described_class.valido_por_dominio?(0, domain, converter_para_int: true)).to be false
        expect(described_class.valido_por_dominio?(8, domain, converter_para_int: true)).to be false
      end
    end

    it 'retorna false para valor nil' do
      expect(described_class.valido_por_dominio?(nil, :d1, converter_para_int: true)).to be false
    end
  end

  describe '.cnpj_formato_valido?' do
    it 'aceita CNPJ com 14 dígitos' do
      expect(described_class.cnpj_formato_valido?('12345678000100')).to be true
      expect(described_class.cnpj_formato_valido?('00000000000000')).to be true
    end

    it 'remove formatação antes de validar' do
      expect(described_class.cnpj_formato_valido?('12.345.678/0001-00')).to be true
    end

    it 'rejeita CNPJ com quantidade incorreta de dígitos' do
      expect(described_class.cnpj_formato_valido?('1234567800010')).to be false # 13 dígitos
      expect(described_class.cnpj_formato_valido?('123456780001000')).to be false # 15 dígitos
    end

    it 'rejeita CNPJ com caracteres não numéricos' do
      expect(described_class.cnpj_formato_valido?('1234567800010A')).to be false
    end
  end

  describe '.cpf_formato_valido?' do
    it 'aceita CPF com 11 dígitos' do
      expect(described_class.cpf_formato_valido?('12345678901')).to be true
      expect(described_class.cpf_formato_valido?('00000000000')).to be true
    end

    it 'remove formatação antes de validar' do
      expect(described_class.cpf_formato_valido?('123.456.789-01')).to be true
    end

    it 'rejeita CPF com quantidade incorreta de dígitos' do
      expect(described_class.cpf_formato_valido?('1234567890')).to be false # 10 dígitos
      expect(described_class.cpf_formato_valido?('123456789012')).to be false # 12 dígitos
    end
  end

  describe '.cep_valido?' do
    it 'aceita CEP com 8 dígitos' do
      expect(described_class.cep_valido?('50000000')).to be true
      expect(described_class.cep_valido?('01310100')).to be true
    end

    it 'remove formatação antes de validar' do
      expect(described_class.cep_valido?('50000-000')).to be true
    end

    it 'rejeita CEP com quantidade incorreta de dígitos' do
      expect(described_class.cep_valido?('5000000')).to be false # 7 dígitos
      expect(described_class.cep_valido?('500000000')).to be false # 9 dígitos
    end
  end

  describe '.telefone_valido?' do
    it 'aceita telefone com 7 a 12 dígitos' do
      expect(described_class.telefone_valido?('1234567')).to be true # 7 dígitos
      expect(described_class.telefone_valido?('81999887766')).to be true # 11 dígitos
      expect(described_class.telefone_valido?('123456789012')).to be true # 12 dígitos
    end

    it 'remove formatação antes de validar' do
      expect(described_class.telefone_valido?('(81) 99988-7766')).to be true
      expect(described_class.telefone_valido?('81 3333-4444')).to be true
    end

    it 'aceita telefone vazio ou nil (opcional)' do
      expect(described_class.telefone_valido?(nil)).to be true
      expect(described_class.telefone_valido?('')).to be true
      expect(described_class.telefone_valido?('   ')).to be true
    end

    it 'rejeita telefone com quantidade incorreta de dígitos' do
      expect(described_class.telefone_valido?('123456')).to be false # 6 dígitos
      expect(described_class.telefone_valido?('1234567890123')).to be false # 13 dígitos
    end
  end

  describe '.email_valido?' do
    it 'aceita email válido' do
      expect(described_class.email_valido?('usuario@exemplo.com')).to be true
      expect(described_class.email_valido?('teste@empresa.com.br')).to be true
      expect(described_class.email_valido?('nome.sobrenome@dominio.org')).to be true
    end

    it 'aceita email vazio ou nil (opcional)' do
      expect(described_class.email_valido?(nil)).to be true
      expect(described_class.email_valido?('')).to be true
      expect(described_class.email_valido?('   ')).to be true
    end

    it 'rejeita email sem @' do
      expect(described_class.email_valido?('usuario.exemplo.com')).to be false
    end

    it 'rejeita email sem domínio' do
      expect(described_class.email_valido?('usuario@')).to be false
    end

    it 'rejeita email sem ponto no domínio' do
      expect(described_class.email_valido?('usuario@exemplo')).to be false
    end
  end

  describe '.data_valida?' do
    it 'aceita data válida no formato AAAA-MM-DD' do
      expect(described_class.data_valida?('2026-01-30')).to be true
      expect(described_class.data_valida?('2024-02-29')).to be true # bissexto
      expect(described_class.data_valida?('1999-12-31')).to be true
    end

    it 'rejeita data inválida' do
      expect(described_class.data_valida?('2026-02-29')).to be false # não bissexto
      expect(described_class.data_valida?('2026-13-01')).to be false # mês inválido
      expect(described_class.data_valida?('2026-01-32')).to be false # dia inválido
    end

    it 'rejeita formato incorreto' do
      expect(described_class.data_valida?('30/01/2026')).to be false # formato brasileiro
      expect(described_class.data_valida?('26-01-30')).to be false # ano abreviado
    end

    it 'rejeita data vazia ou nil' do
      expect(described_class.data_valida?(nil)).to be false
      expect(described_class.data_valida?('')).to be false
      expect(described_class.data_valida?('   ')).to be false
    end
  end

  describe '.cst_icms_valido?' do
    it 'aceita CST válido do D11 (00)' do
      expect(described_class.cst_icms_valido?('00')).to be true
    end

    it 'aceita CST válido do D12 (20)' do
      expect(described_class.cst_icms_valido?('20')).to be true
    end

    it 'aceita CST válido do D13 (40, 41)' do
      expect(described_class.cst_icms_valido?('40')).to be true
      expect(described_class.cst_icms_valido?('41')).to be true
    end

    it 'aceita CST válido do D14 (51)' do
      expect(described_class.cst_icms_valido?('51')).to be true
    end

    it 'aceita CST válido do D15 (90)' do
      expect(described_class.cst_icms_valido?('90')).to be true
    end

    it 'completa com zero à esquerda se necessário' do
      expect(described_class.cst_icms_valido?(0)).to be true # vira '00'
      expect(described_class.cst_icms_valido?('0')).to be true # vira '00'
    end

    it 'rejeita CST inválido' do
      expect(described_class.cst_icms_valido?('10')).to be false
      expect(described_class.cst_icms_valido?('30')).to be false
      expect(described_class.cst_icms_valido?('99')).to be false
    end
  end

  describe '.validar_campos' do
    it 'retorna array vazio quando todos os campos são válidos' do
      campos = {
        uf: { valor: 'PE', validador: :d5, nome: 'UF' },
        cep: { valor: '50000000', validador: :cep, nome: 'CEP' },
        serie: { valor: '1', validador: :er44, nome: 'Série' }
      }

      erros = described_class.validar_campos(campos)
      expect(erros).to be_empty
    end

    it 'retorna erros quando campos são inválidos' do
      campos = {
        uf: { valor: 'XX', validador: :d5, nome: 'UF' },
        cep: { valor: '5000000', validador: :cep, nome: 'CEP' },
        serie: { valor: '01', validador: :er44, nome: 'Série' }
      }

      erros = described_class.validar_campos(campos)

      expect(erros).to include('UF inválido: \'XX\'')
      expect(erros).to include('CEP inválido: \'5000000\'')
      expect(erros).to include('Série inválido: \'01\'')
    end

    it 'valida usando padrão ER' do
      campos = {
        numero: { valor: '0', validador: :er43, nome: 'Número' }
      }

      erros = described_class.validar_campos(campos)
      expect(erros).to include('Número inválido: \'0\'')
    end

    it 'valida usando domínio D' do
      campos = {
        tipo_ambiente: { valor: 3, validador: :d7, nome: 'Tipo Ambiente' }
      }

      erros = described_class.validar_campos(campos)
      expect(erros).to include('Tipo Ambiente inválido: \'3\'')
    end

    it 'valida usando validadores nomeados' do
      campos = {
        cnpj: { valor: '1234567800010', validador: :cnpj, nome: 'CNPJ' },
        email: { valor: 'invalido', validador: :email, nome: 'Email' }
      }

      erros = described_class.validar_campos(campos)

      expect(erros).to include('CNPJ inválido: \'1234567800010\'')
      expect(erros).to include('Email inválido: \'invalido\'')
    end

    it 'usa nome do campo como padrão se nome não for especificado' do
      campos = {
        uf: { valor: 'XX', validador: :d5 }
      }

      erros = described_class.validar_campos(campos)
      expect(erros).to include('uf inválido: \'XX\'')
    end

    it 'valida múltiplos campos corretamente' do
      campos = {
        uf: { valor: 'PE', validador: :d5, nome: 'UF' },
        cep: { valor: '5000000', validador: :cep, nome: 'CEP' },
        telefone: { valor: '81999887766', validador: :telefone, nome: 'Telefone' },
        serie: { valor: '0', validador: :er44, nome: 'Série' }
      }

      erros = described_class.validar_campos(campos)

      expect(erros.size).to eq(1)
      expect(erros).to include('CEP inválido: \'5000000\'')
    end
  end

  describe '.texto_valido?' do
    it 'retorna true para texto válido' do
      expect(described_class.texto_valido?('Texto válido')).to be true
    end

    it 'retorna false para texto com espaços iniciais' do
      expect(described_class.texto_valido?('  Texto')).to be false
    end

    it 'retorna false para texto com espaços finais' do
      expect(described_class.texto_valido?('Texto  ')).to be false
    end

    it 'retorna false para nil' do
      expect(described_class.texto_valido?(nil)).to be false
    end

    it 'retorna false quando excede tamanho máximo' do
      expect(described_class.texto_valido?('Texto', 3)).to be false
    end
  end
end
