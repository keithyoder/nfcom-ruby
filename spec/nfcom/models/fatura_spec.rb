# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Nfcom::Models::Fatura do
  describe '#initialize' do
    context 'com atributos válidos' do
      it 'define todos os atributos corretamente' do # rubocop:disable RSpec/MultipleExpectations
        fatura = described_class.new(
          competencia: '202601',
          data_vencimento: '2026-02-15',
          codigo_barras: '23793381286000000099901234567890123456789012',
          valor_fatura: 99.90,
          periodo_uso_inicio: '2026-01-01',
          periodo_uso_fim: '2026-01-31'
        )

        expect(fatura.competencia).to eq('202601')
        expect(fatura.data_vencimento).to eq('2026-02-15')
        expect(fatura.codigo_barras).to eq('23793381286000000099901234567890123456789012')
        expect(fatura.valor_fatura).to eq(99.90)
        expect(fatura.periodo_uso_inicio).to eq('2026-01-01')
        expect(fatura.periodo_uso_fim).to eq('2026-01-31')
      end

      it 'define valor_liquido igual a valor_fatura por padrão' do
        fatura = described_class.new(valor_fatura: 99.90)
        expect(fatura.valor_liquido).to eq(99.90)
      end

      it 'permite valor_liquido explícito sobrescrever o padrão' do
        fatura = described_class.new(
          valor_fatura: 99.90,
          valor_liquido: 89.90
        )
        expect(fatura.valor_liquido).to eq(89.90)
      end
    end

    context 'com atributos opcionais' do
      it 'define campos de débito automático' do
        fatura = described_class.new(
          codigo_debito_automatico: 'AUTO123',
          codigo_banco: '001',
          codigo_agencia: '1234'
        )

        expect(fatura.codigo_debito_automatico).to eq('AUTO123')
        expect(fatura.codigo_banco).to eq('001')
        expect(fatura.codigo_agencia).to eq('1234')
      end
    end
  end

  describe '#competencia=' do
    it 'aceita formato AAAAMM diretamente' do
      fatura = described_class.new(competencia: '202601')
      expect(fatura.competencia).to eq('202601')
    end

    it 'converte formato YYYY-MM para AAAAMM' do
      fatura = described_class.new(competencia: '2026-01')
      expect(fatura.competencia).to eq('202601')
    end

    it 'trata nil graciosamente' do
      fatura = described_class.new(competencia: nil)
      expect(fatura.competencia).to be_nil
    end

    it 'converte inteiro para string' do
      fatura = described_class.new(competencia: 202_601)
      expect(fatura.competencia).to eq('202601')
    end
  end

  describe '#valido?' do
    let(:atributos_validos) do
      {
        competencia: '202601',
        data_vencimento: '2026-02-15',
        codigo_barras: '23793381286000000099901234567890123456789012',
        valor_fatura: 99.90
      }
    end

    it 'retorna true para fatura válida' do
      fatura = described_class.new(atributos_validos)
      expect(fatura).to be_valido
    end

    it 'retorna false para fatura inválida' do
      fatura = described_class.new
      expect(fatura).not_to be_valido
    end
  end

  describe '#erros' do
    context 'quando valida competência' do
      it 'exige competência' do
        fatura = described_class.new(
          data_vencimento: '2026-02-15',
          codigo_barras: '123',
          valor_fatura: 99.90
        )
        expect(fatura.erros).to include('Competência é obrigatória')
      end

      it 'valida formato da competência (AAAAMM)' do
        fatura = described_class.new(
          competencia: '20261', # Apenas 5 dígitos
          data_vencimento: '2026-02-15',
          codigo_barras: '123',
          valor_fatura: 99.90
        )
        expect(fatura.erros).to include('Competência deve estar no formato AAAAMM (ex: 202601)')
      end

      it 'valida que o mês está entre 01-12' do
        fatura = described_class.new(
          competencia: '202613', # Mês inválido
          data_vencimento: '2026-02-15',
          codigo_barras: '123',
          valor_fatura: 99.90
        )
        expect(fatura.erros).to include('Competência deve estar no formato AAAAMM (ex: 202601)')
      end

      it 'rejeita mês 00' do
        fatura = described_class.new(
          competencia: '202600',
          data_vencimento: '2026-02-15',
          codigo_barras: '123',
          valor_fatura: 99.90
        )
        expect(fatura.erros).to include('Competência deve estar no formato AAAAMM (ex: 202601)')
      end

      it 'aceita competência válida' do
        fatura = described_class.new(
          competencia: '202601',
          data_vencimento: '2026-02-15',
          codigo_barras: '123',
          valor_fatura: 99.90
        )
        expect(fatura.erros).not_to include(match(/Competência/))
      end
    end

    context 'quando valida data_vencimento' do
      it 'exige data_vencimento' do
        fatura = described_class.new(
          competencia: '202601',
          codigo_barras: '123',
          valor_fatura: 99.90
        )
        expect(fatura.erros).to include('Data de vencimento é obrigatória')
      end

      it 'valida formato de data YYYY-MM-DD' do
        fatura = described_class.new(
          competencia: '202601',
          data_vencimento: '15/02/2026', # Formato errado
          codigo_barras: '123',
          valor_fatura: 99.90
        )
        expect(fatura.erros).to include('Data de vencimento deve estar no formato YYYY-MM-DD (ex: 2026-02-15)')
      end

      it 'valida que a data é realmente válida' do
        fatura = described_class.new(
          competencia: '202601',
          data_vencimento: '2026-02-30', # Data inválida
          codigo_barras: '123',
          valor_fatura: 99.90
        )
        expect(fatura.erros).to include('Data de vencimento deve estar no formato YYYY-MM-DD (ex: 2026-02-15)')
      end

      it 'aceita string de data válida' do
        fatura = described_class.new(
          competencia: '202601',
          data_vencimento: '2026-02-15',
          codigo_barras: '123',
          valor_fatura: 99.90
        )
        expect(fatura.erros).not_to include(match(/Data de vencimento/))
      end

      it 'aceita objeto Date' do
        fatura = described_class.new(
          competencia: '202601',
          data_vencimento: Date.new(2026, 2, 15),
          codigo_barras: '123',
          valor_fatura: 99.90
        )
        expect(fatura.erros).not_to include(match(/Data de vencimento/))
      end
    end

    context 'quando valida codigo_barras' do
      it 'exige codigo_barras' do
        fatura = described_class.new(
          competencia: '202601',
          data_vencimento: '2026-02-15',
          valor_fatura: 99.90
        )
        expect(fatura.erros).to include('Código de barras é obrigatório')
      end

      it 'valida comprimento máximo de 48 caracteres' do
        fatura = described_class.new(
          competencia: '202601',
          data_vencimento: '2026-02-15',
          codigo_barras: '1' * 49, # 49 caracteres
          valor_fatura: 99.90
        )
        expect(fatura.erros).to include('Código de barras deve ter no máximo 48 caracteres')
      end

      it 'aceita codigo_barras com 48 caracteres' do
        fatura = described_class.new(
          competencia: '202601',
          data_vencimento: '2026-02-15',
          codigo_barras: '1' * 48,
          valor_fatura: 99.90
        )
        expect(fatura.erros).not_to include(match(/Código de barras/))
      end

      it 'aceita codigo_barras mais curto' do
        fatura = described_class.new(
          competencia: '202601',
          data_vencimento: '2026-02-15',
          codigo_barras: '123456789',
          valor_fatura: 99.90
        )
        expect(fatura.erros).not_to include(match(/Código de barras/))
      end
    end

    context 'quando valida valor_fatura' do
      it 'exige valor_fatura' do
        fatura = described_class.new(
          competencia: '202601',
          data_vencimento: '2026-02-15',
          codigo_barras: '123'
        )
        expect(fatura.erros).to include('Valor da fatura é obrigatório')
      end

      it 'exige que valor_fatura seja maior que zero' do
        fatura = described_class.new(
          competencia: '202601',
          data_vencimento: '2026-02-15',
          codigo_barras: '123',
          valor_fatura: 0
        )
        expect(fatura.erros).to include('Valor da fatura deve ser maior que zero')
      end

      it 'rejeita valor_fatura negativo' do
        fatura = described_class.new(
          competencia: '202601',
          data_vencimento: '2026-02-15',
          codigo_barras: '123',
          valor_fatura: -10.00
        )
        expect(fatura.erros).to include('Valor da fatura deve ser maior que zero')
      end

      it 'aceita valor_fatura positivo' do
        fatura = described_class.new(
          competencia: '202601',
          data_vencimento: '2026-02-15',
          codigo_barras: '123',
          valor_fatura: 99.90
        )
        expect(fatura.erros).not_to include(match(/Valor da fatura/))
      end
    end

    context 'quando valida periodo_uso' do
      let(:atributos_base) do
        {
          competencia: '202601',
          data_vencimento: '2026-02-15',
          codigo_barras: '123',
          valor_fatura: 99.90
        }
      end

      it 'exige ambas as datas se uma for fornecida' do
        fatura = described_class.new(
          atributos_base.merge(periodo_uso_inicio: '2026-01-01')
        )
        expect(fatura.erros).to include('Período de uso: ambas as datas (início e fim) devem ser informadas')
      end

      it 'exige ambas as datas se apenas fim for fornecida' do
        fatura = described_class.new(
          atributos_base.merge(periodo_uso_fim: '2026-01-31')
        )
        expect(fatura.erros).to include('Período de uso: ambas as datas (início e fim) devem ser informadas')
      end

      it 'valida que início não é posterior ao fim' do
        fatura = described_class.new(
          atributos_base.merge(
            periodo_uso_inicio: '2026-01-31',
            periodo_uso_fim: '2026-01-01'
          )
        )
        expect(fatura.erros).to include('Período de uso: data inicial não pode ser posterior à data final')
      end

      it 'aceita periodo_uso válido com strings' do
        fatura = described_class.new(
          atributos_base.merge(
            periodo_uso_inicio: '2026-01-01',
            periodo_uso_fim: '2026-01-31'
          )
        )
        expect(fatura.erros).not_to include(match(/Período de uso/))
      end

      it 'aceita periodo_uso válido com objetos Date' do
        fatura = described_class.new(
          atributos_base.merge(
            periodo_uso_inicio: Date.new(2026, 1, 1),
            periodo_uso_fim: Date.new(2026, 1, 31)
          )
        )
        expect(fatura.erros).not_to include(match(/Período de uso/))
      end

      it 'aceita mesma data para início e fim' do
        fatura = described_class.new(
          atributos_base.merge(
            periodo_uso_inicio: '2026-01-15',
            periodo_uso_fim: '2026-01-15'
          )
        )
        expect(fatura.erros).not_to include(match(/Período de uso/))
      end

      it 'valida strings de data inválidas' do
        fatura = described_class.new(
          atributos_base.merge(
            periodo_uso_inicio: 'data-invalida',
            periodo_uso_fim: '2026-01-31'
          )
        )
        expect(fatura.erros).to include('Período de uso: datas inválidas')
      end
    end

    context 'quando valida debito_automatico' do
      let(:atributos_base) do
        {
          competencia: '202601',
          data_vencimento: '2026-02-15',
          codigo_barras: '123',
          valor_fatura: 99.90
        }
      end

      it 'exige codigo_banco quando debito_automatico está definido' do
        fatura = described_class.new(
          atributos_base.merge(
            codigo_debito_automatico: 'AUTO123',
            codigo_agencia: '1234'
          )
        )
        expect(fatura.erros).to include('Código do banco é obrigatório quando há débito automático')
      end

      it 'exige codigo_agencia quando debito_automatico está definido' do
        fatura = described_class.new(
          atributos_base.merge(
            codigo_debito_automatico: 'AUTO123',
            codigo_banco: '001'
          )
        )
        expect(fatura.erros).to include('Código da agência é obrigatório quando há débito automático')
      end

      it 'aceita informações completas de debito_automatico' do
        fatura = described_class.new(
          atributos_base.merge(
            codigo_debito_automatico: 'AUTO123',
            codigo_banco: '001',
            codigo_agencia: '1234'
          )
        )
        expect(fatura.erros).not_to include(match(/débito automático/))
      end

      it 'não exige banco/agencia quando debito_automatico não está definido' do
        fatura = described_class.new(atributos_base)
        expect(fatura.erros).not_to include(match(/débito automático/))
      end
    end

    context 'com múltiplos erros' do
      it 'retorna todos os erros de validação' do
        fatura = described_class.new
        errors = fatura.erros

        expect(errors).to include('Competência é obrigatória')
        expect(errors).to include('Data de vencimento é obrigatória')
        expect(errors).to include('Código de barras é obrigatório')
        expect(errors).to include('Valor da fatura é obrigatório')
        expect(errors.length).to eq(4)
      end
    end
  end

  describe 'cenários de integração' do
    context 'para faturamento mensal típico de ISP' do
      it 'valida fatura mensal completa' do
        fatura = described_class.new(
          competencia: '2026-01',
          data_vencimento: '2026-02-15',
          codigo_barras: '23793381286000000099901234567890123456789012',
          valor_fatura: 99.90,
          valor_liquido: 99.90,
          periodo_uso_inicio: '2026-01-01',
          periodo_uso_fim: '2026-01-31'
        )

        expect(fatura).to be_valido
        expect(fatura.competencia).to eq('202601')
      end
    end

    context 'com débito automático' do
      it 'valida fatura completa com débito em conta' do
        fatura = described_class.new(
          competencia: '202601',
          data_vencimento: '2026-02-15',
          codigo_barras: '23793381286000000099901234567890123456789012',
          valor_fatura: 99.90,
          codigo_debito_automatico: 'AUTO123',
          codigo_banco: '001',
          codigo_agencia: '1234-5'
        )

        expect(fatura).to be_valido
      end
    end

    context 'com desconto' do
      it 'aceita valor_liquido diferente de valor_fatura' do
        fatura = described_class.new(
          competencia: '202601',
          data_vencimento: '2026-02-15',
          codigo_barras: '23793381286000000099901234567890123456789012',
          valor_fatura: 99.90,
          valor_liquido: 89.90 # R$ 10 de desconto
        )

        expect(fatura).to be_valido
        expect(fatura.valor_fatura).to eq(99.90)
        expect(fatura.valor_liquido).to eq(89.90)
      end
    end
  end

  describe 'casos extremos' do
    context 'com strings vazias' do
      it 'trata como valores ausentes' do
        fatura = described_class.new(
          competencia: '',
          data_vencimento: '',
          codigo_barras: '',
          valor_fatura: nil
        )

        expect(fatura.erros).to include('Competência é obrigatória')
        expect(fatura.erros).to include('Data de vencimento é obrigatória')
        expect(fatura.erros).to include('Código de barras é obrigatório')
        expect(fatura.erros).to include('Valor da fatura é obrigatório')
      end
    end

    context 'com strings contendo apenas espaços' do
      it 'trata como valores ausentes' do
        fatura = described_class.new(
          competencia: '   ',
          data_vencimento: '   ',
          codigo_barras: '   ',
          valor_fatura: nil
        )

        expect(fatura.erros).to include('Competência é obrigatória')
        expect(fatura.erros).to include('Data de vencimento é obrigatória')
        expect(fatura.erros).to include('Código de barras é obrigatório')
      end
    end

    context 'com valor_fatura como string' do
      it 'converte para float' do
        fatura = described_class.new(
          competencia: '202601',
          data_vencimento: '2026-02-15',
          codigo_barras: '123',
          valor_fatura: '99.90'
        )

        expect(fatura).to be_valido
      end
    end
  end
end
