# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Nfcom::Models::Nota do
  let(:classe_consumo_valida) do
    Nfcom::Models::Item::CLASSES_CONSUMO.values.first
  end

  describe '#initialize' do
    it 'cria uma nova nota com valores padrão' do
      nota = described_class.new

      expect(nota.serie).to eq(1)
      expect(nota.itens).to be_empty
      expect(nota.total).to be_a(Nfcom::Models::Total)
      expect(nota.tipo_faturamento).to eq(
        Nfcom::Models::Nota::TIPO_FATURAMENTO[:normal]
      )
    end
  end

  describe '#add_item' do
    let(:nota) { described_class.new }

    it 'adiciona um item à nota' do
      nota.add_item(
        codigo_servico: '0303',
        descricao: 'Plano Internet',
        classe_consumo: classe_consumo_valida,
        cfop: '5307',
        valor_unitario: 99.90
      )

      expect(nota.itens.size).to eq(1)
      expect(nota.itens.first.descricao).to eq('Plano Internet')
    end

    it 'atribui numero_item sequencialmente' do
      nota.add_item(
        codigo_servico: '0303',
        descricao: 'Item 1',
        classe_consumo: classe_consumo_valida,
        cfop: '5307',
        valor_unitario: 10
      )

      nota.add_item(
        codigo_servico: '0303',
        descricao: 'Item 2',
        classe_consumo: classe_consumo_valida,
        cfop: '5307',
        valor_unitario: 20
      )

      expect(nota.itens.map(&:numero_item)).to eq([1, 2])
    end

    it 'recalcula totais após adicionar itens' do
      nota.add_item(
        codigo_servico: '0303',
        descricao: 'Item 1',
        classe_consumo: classe_consumo_valida,
        cfop: '5307',
        valor_unitario: 50.00
      )

      nota.add_item(
        codigo_servico: '0303',
        descricao: 'Item 2',
        classe_consumo: classe_consumo_valida,
        cfop: '5307',
        valor_unitario: 30.00
      )

      expect(nota.total.valor_servicos).to eq(80.00)
      expect(nota.total.valor_total).to eq(80.00)
    end
  end

  describe '#gerar_chave_acesso' do
    let(:emitente) do
      Nfcom::Models::Emitente.new(cnpj: '12345678000100')
    end

    let(:nota) do
      described_class.new(
        serie: 1,
        numero: 1,
        data_emissao: Time.new(2022, 12, 1),
        emitente: emitente,
        tipo_emissao: :normal
      )
    end

    before do
      Nfcom.configure { |c| c.estado = 'PE' }
    end

    it 'gera uma chave de acesso válida com 44 dígitos' do
      nota.gerar_chave_acesso

      expect(nota.chave_acesso).to match(/\A\d{44}\z/)
      expect(nota.chave_acesso[0..1]).to eq('26') # PE
      expect(nota.chave_acesso[20..21]).to eq('62') # Modelo NFCom
    end

    it 'gera chaves únicas para diferentes notas' do
      nota1 = described_class.new(numero: 1, emitente: emitente)
      nota2 = described_class.new(numero: 2, emitente: emitente)

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
        cpf: '12345678909',
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

    let(:fatura) do
      Nfcom::Models::Fatura.new(
        valor_liquido: 100.00,
        data_vencimento: Date.today + 10
      )
    end

    context 'com dados válidos' do
      before do
        nota.emitente = emitente
        nota.destinatario = destinatario
        nota.fatura = fatura
        nota.tipo_faturamento = :normal

        nota.fatura = Nfcom::Models::Fatura.new(
          competencia: '202401',
          codigo_barras: '83620000001599800186000000000000000000000000',
          valor_fatura: 100.00,
          data_vencimento: Date.today + 10
        )

        nota.add_item(
          codigo_servico: '0303',
          descricao: 'Serviço',
          classe_consumo: classe_consumo_valida,
          cfop: '5307',
          valor_unitario: 100
        )
      end

      it 'é válida' do
        expect(nota.valida?).to be true
      end
    end

    context 'sem emitente' do
      it 'é inválida e reporta erro' do
        expect(nota.valida?).to be false
        expect(nota.erros).to include('Emitente é obrigatório')
      end
    end

    context 'sem itens' do
      before do
        nota.emitente = emitente
        nota.destinatario = destinatario
        nota.fatura = fatura
      end

      it 'é inválida e reporta erro' do
        expect(nota.valida?).to be false
        expect(nota.erros).to include('Deve haver pelo menos um item')
      end
    end
  end
end
