# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Nfcom::Models::Nota do
  let(:classe_consumo_valida) do
    Nfcom::Models::Item::CLASSES_CONSUMO.values.first
  end

  let(:atributos_item_valido) do
    {
      codigo_servico: '0303',
      descricao: 'Plano Internet',
      classe_consumo: classe_consumo_valida,
      cfop: '5307',
      valor_unitario: 99.90
    }
  end

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
      competencia: '202401',
      codigo_barras: '83620000001599800186000000000000000000000000',
      valor_fatura: 100.00,
      data_vencimento: Date.today + 10
    )
  end

  let(:nota_completa) do
    nota = described_class.new(serie: 1, numero: 1)
    nota.emitente = emitente
    nota.destinatario = destinatario
    nota.fatura = fatura
    nota.add_item(atributos_item_valido)
    nota
  end

  let(:chave_valida) { '26260107159053000107620010000031981083465102' }

  describe '#initialize' do
    it 'cria uma nova nota com valores padrão' do
      nota = described_class.new

      aggregate_failures do
        expect(nota.serie).to eq(1)
        expect(nota.itens).to be_empty
        expect(nota.total).to be_a(Nfcom::Models::Total)
        expect(nota.finalidade).to eq(:normal)
        expect(nota.tipo_faturamento).to eq(Nfcom::Models::Nota::TIPO_FATURAMENTO[:normal])
        expect(nota.chave_nfcom_substituida).to be_nil
        expect(nota.motivo_substituicao).to be_nil
      end
    end
  end

  describe '#add_item' do
    let(:nota) { described_class.new }

    it 'adiciona um item à nota' do
      nota.add_item(atributos_item_valido)

      expect(nota.itens.size).to eq(1)
      expect(nota.itens.first.descricao).to eq('Plano Internet')
    end

    it 'atribui numero_item sequencialmente' do
      nota.add_item(atributos_item_valido.merge(descricao: 'Item 1', valor_unitario: 10))
      nota.add_item(atributos_item_valido.merge(descricao: 'Item 2', valor_unitario: 20))

      expect(nota.itens.map(&:numero_item)).to eq([1, 2])
    end

    it 'recalcula totais após adicionar itens' do
      nota.add_item(atributos_item_valido.merge(valor_unitario: 50.00))
      nota.add_item(atributos_item_valido.merge(valor_unitario: 30.00))

      aggregate_failures do
        expect(nota.total.valor_servicos).to eq(80.00)
        expect(nota.total.valor_total).to eq(80.00)
      end
    end
  end

  describe '#gerar_chave_acesso' do
    before { Nfcom.configure { |c| c.estado = 'PE' } }

    let(:nota) do
      described_class.new(
        serie: 1,
        numero: 1,
        data_emissao: Time.new(2022, 12, 1),
        emitente: Nfcom::Models::Emitente.new(cnpj: '12345678000100'),
        tipo_emissao: :normal
      )
    end

    it 'gera uma chave de acesso válida com 44 dígitos' do
      nota.gerar_chave_acesso

      aggregate_failures do
        expect(nota.chave_acesso).to match(/\A\d{44}\z/)
        expect(nota.chave_acesso[0..1]).to eq('26') # PE
        expect(nota.chave_acesso[20..21]).to eq('62') # Modelo NFCom
      end
    end

    it 'gera chaves únicas para diferentes notas' do
      nota1 = described_class.new(numero: 1, emitente: Nfcom::Models::Emitente.new(cnpj: '12345678000100'))
      nota2 = described_class.new(numero: 2, emitente: Nfcom::Models::Emitente.new(cnpj: '12345678000100'))

      nota1.gerar_chave_acesso
      nota2.gerar_chave_acesso

      expect(nota1.chave_acesso).not_to eq(nota2.chave_acesso)
    end
  end

  describe '#valida?' do
    context 'com dados válidos' do
      it 'é válida' do
        expect(nota_completa.valida?).to be true
      end
    end

    context 'sem emitente' do
      it 'é inválida e reporta erro' do
        nota = described_class.new(serie: 1, numero: 1)

        aggregate_failures do
          expect(nota.valida?).to be false
          expect(nota.erros).to include('Emitente é obrigatório')
        end
      end
    end

    context 'sem destinatário' do
      it 'é inválida e reporta erro' do
        nota = described_class.new(serie: 1, numero: 1)
        nota.emitente = emitente

        aggregate_failures do
          expect(nota.valida?).to be false
          expect(nota.erros).to include('Destinatário é obrigatório')
        end
      end
    end

    context 'sem itens' do
      it 'é inválida e reporta erro' do
        nota = described_class.new(serie: 1, numero: 1)
        nota.emitente = emitente
        nota.destinatario = destinatario
        nota.fatura = fatura

        aggregate_failures do
          expect(nota.valida?).to be false
          expect(nota.erros).to include('Deve haver pelo menos um item')
        end
      end
    end

    context 'sem fatura' do
      it 'é inválida e reporta erro' do
        nota = described_class.new(serie: 1, numero: 1)
        nota.emitente = emitente
        nota.destinatario = destinatario
        nota.add_item(atributos_item_valido)

        aggregate_failures do
          expect(nota.valida?).to be false
          expect(nota.erros).to include('Fatura é obrigatória')
        end
      end
    end
  end

  describe '#informacoes_adicionais=' do
    let(:nota) { described_class.new }

    it 'divide por quebras de linha em um array' do
      nota.informacoes_adicionais = "Linha 1\nLinha 2\nLinha 3"

      expect(nota.informacoes_adicionais).to eq(['Linha 1', 'Linha 2', 'Linha 3'])
    end

    it 'remove linhas vazias e faz trim de espaços' do
      nota.informacoes_adicionais = " Linha 1 \n\n Linha 2 \n "

      expect(nota.informacoes_adicionais).to eq(['Linha 1', 'Linha 2'])
    end

    it "limita a #{described_class::MAX_INF_CPL} entradas" do
      linhas = (1..10).map { |i| "Linha #{i}" }.join("\n")
      nota.informacoes_adicionais = linhas

      expect(nota.informacoes_adicionais.size).to eq(described_class::MAX_INF_CPL)
    end
  end

  describe 'finalidade :substituicao' do
    let(:nota_sub) do
      nota = nota_completa
      nota.finalidade = :substituicao
      nota
    end

    context 'sem chave_nfcom_substituida' do
      it 'é inválida e reporta erro' do
        nota_sub.motivo_substituicao = '01'

        aggregate_failures do
          expect(nota_sub.valida?).to be false
          expect(nota_sub.erros).to include('Chave da NFCom substituída é obrigatória para notas de substituição')
        end
      end
    end

    context 'sem motivo_substituicao' do
      it 'é inválida e reporta erro' do
        nota_sub.chave_nfcom_substituida = chave_valida

        aggregate_failures do
          expect(nota_sub.valida?).to be false
          expect(nota_sub.erros).to include('Motivo da substituição é obrigatório')
        end
      end
    end

    context 'com chave_nfcom_substituida inválida' do
      it 'é inválida e reporta erro' do
        nota_sub.chave_nfcom_substituida = '1234'
        nota_sub.motivo_substituicao = '01'

        aggregate_failures do
          expect(nota_sub.valida?).to be false
          expect(nota_sub.erros).to include('Chave da NFCom substituída inválida (deve ter 44 dígitos)')
        end
      end
    end

    context 'com chave e motivo válidos' do
      it 'é válida' do
        nota_sub.chave_nfcom_substituida = chave_valida
        nota_sub.motivo_substituicao = '01'

        expect(nota_sub.valida?).to be true
      end
    end

    context 'com finalidade :normal' do
      it 'não valida campos de substituição' do
        expect(nota_completa.erros).not_to include(
          'Chave da NFCom substituída é obrigatória para notas de substituição'
        )
      end
    end
  end

  describe '#finalidade_codigo' do
    it 'retorna 0 para :normal' do
      nota = described_class.new
      nota.finalidade = :normal

      expect(nota.finalidade_codigo).to eq(0)
    end

    it 'retorna 3 para :substituicao' do
      nota = described_class.new
      nota.finalidade = :substituicao

      expect(nota.finalidade_codigo).to eq(3)
    end

    it 'retorna 4 para :ajuste' do
      nota = described_class.new
      nota.finalidade = :ajuste

      expect(nota.finalidade_codigo).to eq(4)
    end
  end

  describe '#autorizada?' do
    it 'retorna false sem protocolo e data_autorizacao' do
      expect(nota_completa.autorizada?).to be false
    end

    it 'retorna true com protocolo e data_autorizacao preenchidos' do
      nota_completa.protocolo = '3262600017883755'
      nota_completa.data_autorizacao = Time.now

      expect(nota_completa.autorizada?).to be true
    end
  end
end
