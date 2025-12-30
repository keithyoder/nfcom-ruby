# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Nfcom::Models::Nota do
  describe '#initialize' do
    it 'creates a new nota with default values' do
      nota = described_class.new
      
      expect(nota.serie).to eq(1)
      expect(nota.itens).to be_empty
      expect(nota.total).to be_a(Nfcom::Models::Total)
    end
  end

  describe '#add_item' do
    let(:nota) { described_class.new }

    it 'adds an item to the nota' do
      nota.add_item(
        codigo_servico: '0303',
        descricao: 'Plano Internet',
        classe_consumo: '0303',
        cfop: '5307',
        valor_unitario: 99.90
      )

      expect(nota.itens.size).to eq(1)
      expect(nota.itens.first.descricao).to eq('Plano Internet')
    end

    it 'sets the item number automatically' do
      nota.add_item(codigo_servico: '0303', descricao: 'Item 1', classe_consumo: '0303', cfop: '5307', valor_unitario: 10)
      nota.add_item(codigo_servico: '0303', descricao: 'Item 2', classe_consumo: '0303', cfop: '5307', valor_unitario: 20)

      expect(nota.itens[0].numero_item).to eq(1)
      expect(nota.itens[1].numero_item).to eq(2)
    end

    it 'recalculates totals after adding item' do
      nota.add_item(codigo_servico: '0303', descricao: 'Item 1', classe_consumo: '0303', cfop: '5307', valor_unitario: 50.00)
      nota.add_item(codigo_servico: '0303', descricao: 'Item 2', classe_consumo: '0303', cfop: '5307', valor_unitario: 30.00)

      expect(nota.total.valor_servicos).to eq(80.00)
      expect(nota.total.valor_total).to eq(80.00)
    end
  end

  describe '#gerar_chave_acesso' do
    let(:nota) do
      described_class.new(
        serie: 1,
        numero: 1,
        data_emissao: Time.new(2022, 12, 1)
      )
    end

    let(:emitente) do
      Nfcom::Models::Emitente.new(cnpj: '12345678000100')
    end

    before do
      Nfcom.configure do |config|
        config.estado = 'PE'
      end
      nota.emitente = emitente
    end

    it 'generates a valid access key' do
      nota.gerar_chave_acesso

      expect(nota.chave_acesso).to match(/\A\d{44}\z/)
      expect(nota.chave_acesso[0..1]).to eq('26') # PE
      expect(nota.chave_acesso[25..26]).to eq('62') # Modelo
    end

    it 'generates different keys for different notas' do
      nota1 = described_class.new(serie: 1, numero: 1, emitente: emitente)
      nota2 = described_class.new(serie: 1, numero: 2, emitente: emitente)

      nota1.gerar_chave_acesso
      nota2.gerar_chave_acesso

      expect(nota1.chave_acesso).not_to eq(nota2.chave_acesso)
    end
  end

  describe '#valida?' do
    let(:nota) { described_class.new(serie: 1, numero: 1) }
    let(:emitente) do
      Nfcom::Models::Emitente.new(
        cnpj: '12345678000195',
        razao_social: 'Empresa Teste',
        inscricao_estadual: '123456789',
        endereco: {
          logradouro: 'Rua Teste',
          numero: '123',
          bairro: 'Centro',
          municipio: 'Recife',
          uf: 'PE',
          cep: '50000-000',
          codigo_municipio: '2611606'
        }
      )
    end
    let(:destinatario) do
      Nfcom::Models::Destinatario.new(
        cpf: '12345678901',
        razao_social: 'Cliente Teste',
        endereco: {
          logradouro: 'Av Teste',
          numero: '456',
          bairro: 'Jardins',
          municipio: 'Recife',
          uf: 'PE',
          cep: '51000-000',
          codigo_municipio: '2611606'
        }
      )
    end

    context 'with valid data' do
      before do
        nota.emitente = emitente
        nota.destinatario = destinatario
        nota.add_item(
          codigo_servico: '0303',
          descricao: 'Serviço',
          classe_consumo: '0303',
          cfop: '5307',
          valor_unitario: 100
        )
      end

      it 'returns true' do
        expect(nota.valida?).to be true
      end
    end

    context 'without emitente' do
      it 'returns false and has errors' do
        expect(nota.valida?).to be false
        expect(nota.erros).to include('Emitente é obrigatório')
      end
    end

    context 'without items' do
      before do
        nota.emitente = emitente
        nota.destinatario = destinatario
      end

      it 'returns false and has errors' do
        expect(nota.valida?).to be false
        expect(nota.erros).to include('Deve haver pelo menos um item')
      end
    end
  end
end
