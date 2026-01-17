# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Nfcom::Validators::BusinessRules do
  describe '.validar' do
    let(:nota) do
      Nfcom::Models::Nota.new.tap do |n|
        n.total = Nfcom::Models::Total.new(
          valor_servicos: 100.00,
          valor_total: 100.00
        )
        n.itens = []
      end
    end

    let(:item_valido) do
      Nfcom::Models::Item.new(
        numero_item: 1,
        codigo_servico: '0303',
        descricao: 'Internet',
        classe_consumo: :nao_medido_internet,
        cfop: '5307',
        unidade: :un,
        quantidade: 1,
        valor_unitario: 100.00,
        valor_total: 100.00
      )
    end

    context 'quando a nota é válida' do
      before do
        nota.itens << item_valido
      end

      it 'retorna array de erros vazio' do
        erros = described_class.validar(nota)
        expect(erros).to be_empty
      end
    end

    context 'com validação de valor total' do
      it 'retorna erro quando valor total é zero' do
        nota.total.valor_total = 0.00
        nota.itens << item_valido

        erros = described_class.validar(nota)
        expect(erros).to include('Valor total da nota não pode ser zero')
      end

      it 'retorna erro quando valor total é negativo' do
        nota.total.valor_total = -50.00
        nota.itens << item_valido

        erros = described_class.validar(nota)
        expect(erros).to include('Valor total da nota não pode ser zero')
      end

      it 'aceita valor total positivo' do
        nota.total.valor_total = 100.00
        nota.itens << item_valido

        erros = described_class.validar(nota)
        expect(erros).not_to include(match(/Valor total da nota/))
      end
    end

    context 'com validação de soma dos itens' do
      it 'retorna erro quando soma dos itens não confere com total' do
        nota.total.valor_servicos = 100.00
        nota.itens << item_valido.dup.tap { |i| i.valor_total = 50.00 }

        erros = described_class.validar(nota)
        expect(erros).to include('Soma dos itens (50.0) não confere com total de serviços (100.0)')
      end

      it 'aceita diferença dentro da tolerância (0.01)' do
        nota.total.valor_servicos = 100.00
        nota.itens << item_valido.dup.tap { |i| i.valor_total = 100.005 }

        erros = described_class.validar(nota)
        expect(erros).not_to include(match(/Soma dos itens/))
      end

      it 'rejeita diferença fora da tolerância' do
        nota.total.valor_servicos = 100.00
        nota.itens << item_valido.dup.tap { |i| i.valor_total = 100.02 }

        erros = described_class.validar(nota)
        expect(erros).to include(match(/Soma dos itens/))
      end

      it 'valida corretamente com múltiplos itens' do
        nota.total.valor_servicos = 150.00
        nota.itens << item_valido.dup.tap do |i|
          i.numero_item = 1
          i.valor_total = 100.00
        end
        nota.itens << item_valido.dup.tap do |i|
          i.numero_item = 2
          i.valor_total = 50.00
        end

        erros = described_class.validar(nota)
        expect(erros).not_to include(match(/Soma dos itens/))
      end

      it 'detecta erro com múltiplos itens quando soma não confere' do
        nota.total.valor_servicos = 200.00
        nota.itens << item_valido.dup.tap do |i|
          i.numero_item = 1
          i.valor_total = 100.00
        end
        nota.itens << item_valido.dup.tap do |i|
          i.numero_item = 2
          i.valor_total = 50.00
        end

        erros = described_class.validar(nota)
        expect(erros).to include('Soma dos itens (150.0) não confere com total de serviços (200.0)')
      end
    end

    context 'com validação de código de serviço' do
      it 'aceita código 0303 (Internet)' do
        item = item_valido.dup
        item.codigo_servico = '0303'
        nota.itens << item

        erros = described_class.validar(nota)
        expect(erros).not_to include(match(/Código de serviço.*inválido/))
      end

      it 'aceita código 0304 (TV)' do
        item = item_valido.dup
        item.codigo_servico = '0304'
        nota.itens << item

        erros = described_class.validar(nota)
        expect(erros).not_to include(match(/Código de serviço.*inválido/))
      end

      it 'aceita código 0305 (Telefonia)' do
        item = item_valido.dup
        item.codigo_servico = '0305'
        nota.itens << item

        erros = described_class.validar(nota)
        expect(erros).not_to include(match(/Código de serviço.*inválido/))
      end

      it 'rejeita código inválido' do
        item = item_valido.dup
        item.codigo_servico = '9999'
        item.numero_item = 1
        nota.itens << item

        erros = described_class.validar(nota)
        expect(erros).to include('Código de serviço 9999 inválido para item 1')
      end

      it 'rejeita código vazio' do
        item = item_valido.dup
        item.codigo_servico = ''
        item.numero_item = 1
        nota.itens << item

        erros = described_class.validar(nota)
        expect(erros).to include('Código de serviço  inválido para item 1')
      end

      it 'valida múltiplos itens com códigos diferentes' do
        nota.total.valor_servicos = 150.00
        nota.itens << item_valido.dup.tap do |i|
          i.numero_item = 1
          i.codigo_servico = '0303'
          i.valor_total = 100.00
        end
        nota.itens << item_valido.dup.tap do |i|
          i.numero_item = 2
          i.codigo_servico = '0304'
          i.valor_total = 50.00
        end

        erros = described_class.validar(nota)
        expect(erros).not_to include(match(/Código de serviço.*inválido/))
      end

      it 'identifica item específico com código inválido entre vários' do
        nota.total.valor_servicos = 150.00
        nota.itens << item_valido.dup.tap do |i|
          i.numero_item = 1
          i.codigo_servico = '0303'
          i.valor_total = 100.00
        end
        nota.itens << item_valido.dup.tap do |i|
          i.numero_item = 2
          i.codigo_servico = '9999'
          i.valor_total = 50.00
        end

        erros = described_class.validar(nota)
        expect(erros).to include('Código de serviço 9999 inválido para item 2')
        expect(erros).not_to include(match(/Código de serviço 0303 inválido/))
      end
    end

    context 'com validação de CFOP' do
      describe 'CFOPs válidos dentro do estado (5300-5399)' do
        it 'aceita CFOP 5300' do
          item = item_valido.dup
          item.cfop = '5300'
          nota.itens << item

          erros = described_class.validar(nota)
          expect(erros).not_to include(match(/CFOP.*inválido/))
        end

        it 'aceita CFOP 5307 (padrão para comunicação)' do
          item = item_valido.dup
          item.cfop = '5307'
          nota.itens << item

          erros = described_class.validar(nota)
          expect(erros).not_to include(match(/CFOP.*inválido/))
        end

        it 'aceita CFOP 5399' do
          item = item_valido.dup
          item.cfop = '5399'
          nota.itens << item

          erros = described_class.validar(nota)
          expect(erros).not_to include(match(/CFOP.*inválido/))
        end
      end

      describe 'CFOPs válidos fora do estado (6300-6399)' do
        it 'aceita CFOP 6300' do
          item = item_valido.dup
          item.cfop = '6300'
          nota.itens << item

          erros = described_class.validar(nota)
          expect(erros).not_to include(match(/CFOP.*inválido/))
        end

        it 'aceita CFOP 6307 (padrão para comunicação)' do
          item = item_valido.dup
          item.cfop = '6307'
          nota.itens << item

          erros = described_class.validar(nota)
          expect(erros).not_to include(match(/CFOP.*inválido/))
        end

        it 'aceita CFOP 6399' do
          item = item_valido.dup
          item.cfop = '6399'
          nota.itens << item

          erros = described_class.validar(nota)
          expect(erros).not_to include(match(/CFOP.*inválido/))
        end
      end

      describe 'CFOPs inválidos' do
        it 'rejeita CFOP abaixo do range (5299)' do
          item = item_valido.dup
          item.cfop = '5299'
          item.numero_item = 1
          nota.itens << item

          erros = described_class.validar(nota)
          expect(erros).to include('CFOP 5299 inválido para item 1')
        end

        it 'rejeita CFOP acima do range (5400)' do
          item = item_valido.dup
          item.cfop = '5400'
          item.numero_item = 1
          nota.itens << item

          erros = described_class.validar(nota)
          expect(erros).to include('CFOP 5400 inválido para item 1')
        end

        it 'rejeita CFOP abaixo do range (6299)' do
          item = item_valido.dup
          item.cfop = '6299'
          item.numero_item = 1
          nota.itens << item

          erros = described_class.validar(nota)
          expect(erros).to include('CFOP 6299 inválido para item 1')
        end

        it 'rejeita CFOP acima do range (6400)' do
          item = item_valido.dup
          item.cfop = '6400'
          item.numero_item = 1
          nota.itens << item

          erros = described_class.validar(nota)
          expect(erros).to include('CFOP 6400 inválido para item 1')
        end

        it 'rejeita CFOP totalmente fora do range' do
          item = item_valido.dup
          item.cfop = '1000'
          item.numero_item = 1
          nota.itens << item

          erros = described_class.validar(nota)
          expect(erros).to include('CFOP 1000 inválido para item 1')
        end

        it 'rejeita CFOP vazio' do
          item = item_valido.dup
          item.cfop = ''
          item.numero_item = 1
          nota.itens << item

          erros = described_class.validar(nota)
          expect(erros).to include('CFOP  inválido para item 1')
        end
      end

      it 'valida múltiplos itens com CFOPs diferentes' do
        nota.total.valor_servicos = 150.00
        nota.itens << item_valido.dup.tap do |i|
          i.numero_item = 1
          i.cfop = '5307'
          i.valor_total = 100.00
        end
        nota.itens << item_valido.dup.tap do |i|
          i.numero_item = 2
          i.cfop = '6307'
          i.valor_total = 50.00
        end

        erros = described_class.validar(nota)
        expect(erros).not_to include(match(/CFOP.*inválido/))
      end

      it 'identifica item específico com CFOP inválido entre vários' do
        nota.total.valor_servicos = 150.00
        nota.itens << item_valido.dup.tap do |i|
          i.numero_item = 1
          i.cfop = '5307'
          i.valor_total = 100.00
        end
        nota.itens << item_valido.dup.tap do |i|
          i.numero_item = 2
          i.cfop = '1000'
          i.valor_total = 50.00
        end

        erros = described_class.validar(nota)
        expect(erros).to include('CFOP 1000 inválido para item 2')
        expect(erros).not_to include(match(/CFOP 5307 inválido/))
      end
    end

    context 'com validações combinadas' do
      it 'retorna múltiplos erros quando há várias violações' do
        nota.total.valor_total = 0.00
        nota.total.valor_servicos = 100.00
        item = item_valido.dup
        item.numero_item = 1
        item.valor_total = 50.00
        item.codigo_servico = '9999'
        item.cfop = '1000'
        nota.itens << item

        erros = described_class.validar(nota)
        expect(erros).to include('Valor total da nota não pode ser zero')
        expect(erros).to include(match(/Soma dos itens/))
        expect(erros).to include('Código de serviço 9999 inválido para item 1')
        expect(erros).to include('CFOP 1000 inválido para item 1')
      end

      it 'valida corretamente nota completa válida' do
        nota.total.valor_total = 150.00
        nota.total.valor_servicos = 150.00

        nota.itens << item_valido.dup.tap do |i|
          i.numero_item = 1
          i.codigo_servico = '0303'
          i.cfop = '5307'
          i.valor_total = 100.00
        end

        nota.itens << item_valido.dup.tap do |i|
          i.numero_item = 2
          i.codigo_servico = '0304'
          i.cfop = '6307'
          i.valor_total = 50.00
        end

        erros = described_class.validar(nota)
        expect(erros).to be_empty
      end
    end
  end

  describe '.codigo_servico_valido?' do
    it 'retorna true para 0303' do
      expect(described_class.codigo_servico_valido?('0303')).to be true
    end

    it 'retorna true para 0304' do
      expect(described_class.codigo_servico_valido?('0304')).to be true
    end

    it 'retorna true para 0305' do
      expect(described_class.codigo_servico_valido?('0305')).to be true
    end

    it 'retorna false para código inválido' do
      expect(described_class.codigo_servico_valido?('9999')).to be false
    end

    it 'retorna false para código vazio' do
      expect(described_class.codigo_servico_valido?('')).to be false
    end

    it 'retorna false para nil' do
      expect(described_class.codigo_servico_valido?(nil)).to be false
    end
  end

  describe '.cfop_valido?' do
    context 'com CFOPs dentro do estado (5300-5399)' do
      it 'retorna true para 5300' do
        expect(described_class.cfop_valido?('5300')).to be true
      end

      it 'retorna true para 5307' do
        expect(described_class.cfop_valido?('5307')).to be true
      end

      it 'retorna true para 5399' do
        expect(described_class.cfop_valido?('5399')).to be true
      end
    end

    context 'com CFOPs fora do estado (6300-6399)' do
      it 'retorna true para 6300' do
        expect(described_class.cfop_valido?('6300')).to be true
      end

      it 'retorna true para 6307' do
        expect(described_class.cfop_valido?('6307')).to be true
      end

      it 'retorna true para 6399' do
        expect(described_class.cfop_valido?('6399')).to be true
      end
    end

    context 'com CFOPs inválidos' do
      it 'retorna false para 5299' do
        expect(described_class.cfop_valido?('5299')).to be false
      end

      it 'retorna false para 5400' do
        expect(described_class.cfop_valido?('5400')).to be false
      end

      it 'retorna false para 6299' do
        expect(described_class.cfop_valido?('6299')).to be false
      end

      it 'retorna false para 6400' do
        expect(described_class.cfop_valido?('6400')).to be false
      end

      it 'retorna false para código fora dos ranges' do
        expect(described_class.cfop_valido?('1000')).to be false
      end

      it 'retorna false para string vazia' do
        expect(described_class.cfop_valido?('')).to be false
      end

      it 'retorna false para nil' do
        expect(described_class.cfop_valido?(nil)).to be false
      end
    end

    context 'com conversão de tipos' do
      it 'aceita CFOP como integer' do
        expect(described_class.cfop_valido?(5307)).to be true
      end

      it 'aceita CFOP como string' do
        expect(described_class.cfop_valido?('5307')).to be true
      end
    end
  end
end
