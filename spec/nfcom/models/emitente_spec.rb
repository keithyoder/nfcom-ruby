# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Nfcom::Models::Emitente do
  subject(:emitente) { described_class.new(atributos_validos) }

  let(:endereco_valido) do
    {
      logradouro: 'Rua Treze de Maio',
      numero: '5',
      bairro: 'Centro',
      municipio: 'Caruaru',
      uf: 'PE',
      cep: '55000-000',
      codigo_municipio: '2604106'
    }
  end

  let(:atributos_validos) do
    {
      cnpj: '00000000000191',
      razao_social: 'Provedor Internet LTDA',
      inscricao_estadual: '000000000',
      endereco: endereco_valido
    }
  end

  describe '#initialize' do
    it 'define regime tributário padrão como :normal' do
      expect(emitente.regime_tributario).to eq(:normal)
    end

    it 'cria um Endereco a partir de hash' do
      expect(emitente.endereco).to be_a(Nfcom::Models::Endereco)
      expect(emitente.endereco.logradouro).to eq('Rua Treze de Maio')
    end

    it 'aceita atributos opcionais' do
      emit = described_class.new(atributos_validos.merge(
                                   nome_fantasia: 'Meu Provedor',
                                   cnae: '6190-6/01',
                                   regime_tributario: :simples_nacional
                                 ))

      aggregate_failures do
        expect(emit.nome_fantasia).to eq('Meu Provedor')
        expect(emit.cnae).to eq('6190-6/01')
        expect(emit.regime_tributario).to eq(:simples_nacional)
      end
    end
  end

  describe '#regime_tributario_codigo' do
    it 'retorna 1 para simples_nacional' do
      emitente.regime_tributario = :simples_nacional
      expect(emitente.regime_tributario_codigo).to eq(1)
    end

    it 'retorna 2 para simples_excesso' do
      emitente.regime_tributario = :simples_excesso
      expect(emitente.regime_tributario_codigo).to eq(2)
    end

    it 'retorna 3 para normal' do
      emitente.regime_tributario = :normal
      expect(emitente.regime_tributario_codigo).to eq(3)
    end

    it 'retorna 3 para regime desconhecido' do
      emitente.regime_tributario = :desconhecido
      expect(emitente.regime_tributario_codigo).to eq(3)
    end
  end

  describe '#valido?' do
    context 'com atributos válidos' do
      it 'retorna true' do
        expect(emitente.valido?).to be true
      end
    end

    context 'com atributos inválidos' do
      it 'retorna false' do
        emitente.cnpj = nil
        expect(emitente.valido?).to be false
      end
    end
  end

  describe '#erros' do
    context 'com atributos válidos' do
      it 'retorna array vazio' do
        expect(emitente.erros).to be_empty
      end
    end

    context 'sem CNPJ' do
      it 'inclui erro de obrigatoriedade' do
        emitente.cnpj = nil
        expect(emitente.erros).to include('CNPJ é obrigatório')
      end
    end

    context 'com CNPJ inválido' do
      it 'inclui erro de CNPJ inválido' do
        emitente.cnpj = '12345678000100'
        expect(emitente.erros).to include('CNPJ inválido')
      end

      it 'rejeita CNPJ com todos os dígitos iguais' do
        emitente.cnpj = '11111111111111'
        expect(emitente.erros).to include('CNPJ inválido')
      end

      it 'rejeita CNPJ com menos de 14 dígitos' do
        emitente.cnpj = '1234567800010'
        expect(emitente.erros).to include('CNPJ inválido')
      end
    end

    context 'sem razão social' do
      it 'inclui erro de obrigatoriedade' do
        emitente.razao_social = ''
        expect(emitente.erros).to include('Razão social é obrigatória')
      end
    end

    context 'sem inscrição estadual' do
      it 'inclui erro de obrigatoriedade' do
        emitente.inscricao_estadual = nil
        expect(emitente.erros).to include('Inscrição estadual é obrigatória')
      end
    end

    context 'com endereço inválido' do
      it 'inclui erros prefixados com Endereço' do
        emitente.endereco.logradouro = nil
        expect(emitente.erros).to include(match(/^Endereço:/))
      end
    end

    context 'com múltiplos erros' do
      it 'retorna todos os erros' do
        emitente.cnpj = nil
        emitente.razao_social = ''
        emitente.inscricao_estadual = nil

        aggregate_failures do
          expect(emitente.erros).to include('CNPJ é obrigatório')
          expect(emitente.erros).to include('Razão social é obrigatória')
          expect(emitente.erros).to include('Inscrição estadual é obrigatória')
        end
      end
    end
  end
end
