# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Nfcom::Models::Total do
  # Atributos básicos com impostos típicos
  let(:atributos_basicos) do
    {
      valor_servicos: 99.90,
      valor_desconto: 0.0,
      valor_outras_despesas: 0.0
    }
  end

  # Atributos completos com todos os impostos
  let(:atributos_completos) do
    {
      valor_servicos: 99.90,
      valor_desconto: 5.00,
      valor_outras_despesas: 2.50,
      icms_base_calculo: 99.90,
      icms_valor: 18.00,
      pis_valor: 0.65,
      cofins_valor: 3.00,
      fust_valor: 0.50,
      funttel_valor: 0.50
    }
  end

  describe '#initialize' do
    context 'com atributos válidos' do
      it 'define todos os atributos corretamente' do
        total = described_class.new(atributos_completos)

        aggregate_failures do
          expect(total.valor_servicos).to eq(99.90)
          expect(total.valor_desconto).to eq(5.00)
          expect(total.valor_outras_despesas).to eq(2.50)
          expect(total.icms_base_calculo).to eq(99.90)
          expect(total.icms_valor).to eq(18.00)
          expect(total.pis_valor).to eq(0.65)
          expect(total.cofins_valor).to eq(3.00)
          expect(total.fust_valor).to eq(0.50)
          expect(total.funttel_valor).to eq(0.50)
        end
      end
    end

    context 'com valores padrão' do
      it 'inicializa todos os valores como 0.0' do
        total = described_class.new

        aggregate_failures do
          expect(total.valor_desconto).to eq(0.0)
          expect(total.valor_outras_despesas).to eq(0.0)
          expect(total.icms_base_calculo).to eq(0.0)
          expect(total.icms_valor).to eq(0.0)
          expect(total.icms_desonerado).to eq(0.0)
          expect(total.fcp_valor).to eq(0.0)
          expect(total.pis_valor).to eq(0.0)
          expect(total.cofins_valor).to eq(0.0)
          expect(total.funttel_valor).to eq(0.0)
          expect(total.fust_valor).to eq(0.0)
          expect(total.pis_retido).to eq(0.0)
          expect(total.cofins_retido).to eq(0.0)
          expect(total.csll_retido).to eq(0.0)
          expect(total.irrf_retido).to eq(0.0)
        end
      end
    end

    context 'com valores de retenção' do
      it 'define valores retidos corretamente' do
        total = described_class.new(
          pis_retido: 0.10,
          cofins_retido: 0.50,
          csll_retido: 1.00,
          irrf_retido: 1.50
        )

        expect(total.pis_retido).to eq(0.10)
        expect(total.cofins_retido).to eq(0.50)
        expect(total.csll_retido).to eq(1.00)
        expect(total.irrf_retido).to eq(1.50)
      end
    end

    context 'com valores de ICMS desonerado e FCP' do
      it 'define valores opcionais corretamente' do
        total = described_class.new(
          icms_desonerado: 5.00,
          fcp_valor: 2.00
        )

        expect(total.icms_desonerado).to eq(5.00)
        expect(total.fcp_valor).to eq(2.00)
      end
    end
  end

  describe '#calcular_total' do
    it 'calcula total básico corretamente' do
      total = described_class.new(atributos_basicos)

      total.calcular_total
      expect(total.valor_total).to eq(99.90)
    end

    it 'subtrai descontos do valor de serviços' do
      total = described_class.new(atributos_basicos.merge(valor_desconto: 10.00))

      total.calcular_total
      expect(total.valor_total).to eq(89.90)
    end

    it 'adiciona outras despesas ao total' do
      total = described_class.new(atributos_basicos.merge(valor_outras_despesas: 5.00))

      total.calcular_total
      expect(total.valor_total).to eq(104.90)
    end

    it 'calcula total com todos os componentes' do
      total = described_class.new(
        valor_servicos: 100.00,
        valor_desconto: 10.00,
        valor_outras_despesas: 5.00
      )

      total.calcular_total
      expect(total.valor_total).to eq(95.00)
    end

    it 'lida com valores decimais precisamente' do
      total = described_class.new(
        valor_servicos: 99.90,
        valor_desconto: 5.45,
        valor_outras_despesas: 2.55
      )

      total.calcular_total
      expect(total.valor_total).to eq(97.00)
    end

    it 'atualiza valor_total quando chamado múltiplas vezes' do
      total = described_class.new(valor_servicos: 100.00)

      total.calcular_total
      expect(total.valor_total).to eq(100.00)

      total.valor_servicos = 200.00
      total.calcular_total
      expect(total.valor_total).to eq(200.00)
    end

    it 'lida com valores nil convertendo para 0' do
      total = described_class.new(
        valor_servicos: nil,
        valor_desconto: nil,
        valor_outras_despesas: nil
      )

      total.calcular_total
      expect(total.valor_total).to eq(0.0)
    end

    it 'permite resultado zero quando descontos igualam serviços' do
      total = described_class.new(
        valor_servicos: 100.00,
        valor_desconto: 100.00
      )

      total.calcular_total
      expect(total.valor_total).to eq(0.0)
    end
  end

  describe '#valor_liquido' do
    it 'retorna valor_total quando definido' do
      total = described_class.new(valor_total: 99.90)
      expect(total.valor_liquido).to eq(99.90)
    end

    it 'retorna 0.0 quando valor_total é nil' do
      total = described_class.new
      expect(total.valor_liquido).to eq(0.0)
    end

    it 'reflete cálculo automático do total' do
      total = described_class.new(
        valor_servicos: 100.00,
        valor_desconto: 10.00
      )
      total.calcular_total

      expect(total.valor_liquido).to eq(90.00)
    end
  end

  describe 'cenários de integração' do
    context 'para ISP típico - serviço isento de ICMS' do
      it 'calcula total sem impostos estaduais' do
        total = described_class.new(
          valor_servicos: 99.90,
          icms_base_calculo: 0.0,
          icms_valor: 0.0,
          pis_valor: 0.0,
          cofins_valor: 0.0,
          fust_valor: 0.50,
          funttel_valor: 0.50
        )

        total.calcular_total

        expect(total.valor_total).to eq(99.90)
        expect(total.icms_valor).to eq(0.0)
        expect(total.fust_valor).to eq(0.50)
        expect(total.funttel_valor).to eq(0.50)
      end
    end

    context 'para ISP com múltiplos serviços' do
      it 'agrega valores de vários itens' do
        # Simula agregação de 3 itens
        item1_valor = 50.00
        item2_valor = 30.00
        item3_valor = 19.90

        total = described_class.new(
          valor_servicos: item1_valor + item2_valor + item3_valor,
          valor_desconto: 0.0,
          valor_outras_despesas: 0.0
        )

        total.calcular_total
        expect(total.valor_total).to eq(99.90)
      end
    end

    context 'com desconto promocional' do
      it 'aplica desconto ao total' do
        total = described_class.new(
          valor_servicos: 99.90,
          valor_desconto: 10.00
        )

        total.calcular_total
        expect(total.valor_total).to eq(89.90)
      end
    end

    context 'com taxa de instalação' do
      it 'inclui despesas acessórias no total' do
        total = described_class.new(
          valor_servicos: 99.90,
          valor_outras_despesas: 50.00 # Taxa de instalação
        )

        total.calcular_total
        expect(total.valor_total).to eq(149.90)
      end
    end

    context 'para Simples Nacional' do
      it 'mantém impostos federais zerados' do
        total = described_class.new(
          valor_servicos: 99.90,
          icms_valor: 0.0,
          pis_valor: 0.0,
          cofins_valor: 0.0,
          fust_valor: 0.50,
          funttel_valor: 0.50
        )

        total.calcular_total

        expect(total.icms_valor).to eq(0.0)
        expect(total.pis_valor).to eq(0.0)
        expect(total.cofins_valor).to eq(0.0)
        expect(total.valor_total).to eq(99.90)
      end
    end

    context 'com retenção de tributos federais' do
      it 'registra valores retidos' do
        total = described_class.new(
          valor_servicos: 1000.00,
          pis_valor: 6.50,
          cofins_valor: 30.00,
          pis_retido: 6.50,
          cofins_retido: 30.00,
          csll_retido: 10.00,
          irrf_retido: 15.00
        )

        expect(total.pis_retido).to eq(6.50)
        expect(total.cofins_retido).to eq(30.00)
        expect(total.csll_retido).to eq(10.00)
        expect(total.irrf_retido).to eq(15.00)
      end
    end
  end

  describe 'validação de valores' do
    context 'com valores negativos' do
      it 'aceita valores negativos sem validação (validação é no Nota)' do
        total = described_class.new(
          valor_servicos: -10.00,
          icms_valor: -5.00
        )

        # Total model não valida - apenas armazena
        expect(total.valor_servicos).to eq(-10.00)
        expect(total.icms_valor).to eq(-5.00)
      end
    end

    context 'com strings numéricas' do
      it 'converte strings para float' do
        total = described_class.new(
          valor_servicos: '99.90',
          valor_desconto: '5.00'
        )

        total.calcular_total
        expect(total.valor_total).to eq(94.90)
      end
    end
  end

  describe 'precisão de cálculo' do
    context 'com valores de centavos' do
      it 'mantém precisão decimal correta' do
        total = described_class.new(
          valor_servicos: 99.99,
          valor_desconto: 0.09,
          valor_outras_despesas: 0.01
        )

        total.calcular_total
        expect(total.valor_total).to eq(99.91)
      end
    end

    context 'com cálculos que geram muitas casas decimais' do
      it 'calcula sem perda de precisão' do
        total = described_class.new(
          valor_servicos: 33.33,
          valor_desconto: 1.11,
          valor_outras_despesas: 0.22
        )

        total.calcular_total
        expect(total.valor_total).to eq(32.44)
      end
    end

    context 'com valores muito pequenos' do
      it 'lida com centavos corretamente' do
        total = described_class.new(
          valor_servicos: 0.10,
          valor_desconto: 0.05,
          valor_outras_despesas: 0.03
        )

        total.calcular_total
        expect(total.valor_total).to eq(0.08)
      end
    end
  end

  describe 'casos extremos' do
    context 'com todos os valores zero' do
      it 'resulta em total zero' do
        total = described_class.new

        total.calcular_total
        expect(total.valor_total).to eq(0.0)
      end
    end

    context 'com valor muito alto' do
      it 'lida com valores grandes' do
        total = described_class.new(
          valor_servicos: 9_999_999_999.99,
          valor_desconto: 1000.00
        )

        total.calcular_total
        expect(total.valor_total).to eq(9_999_998_999.99)
      end
    end

    context 'com recálculo após modificação' do
      it 'permite atualização de valores e recálculo' do
        total = described_class.new(valor_servicos: 100.00)
        total.calcular_total
        expect(total.valor_total).to eq(100.00)

        # Modificar valores
        total.valor_servicos = 200.00
        total.valor_desconto = 50.00

        total.calcular_total
        expect(total.valor_total).to eq(150.00)
      end
    end
  end

  describe 'agregação de impostos' do
    context 'com todos os impostos' do
      it 'armazena valores de ICMS' do
        total = described_class.new(
          icms_base_calculo: 100.00,
          icms_valor: 18.00,
          icms_desonerado: 2.00,
          fcp_valor: 1.00
        )

        expect(total.icms_base_calculo).to eq(100.00)
        expect(total.icms_valor).to eq(18.00)
        expect(total.icms_desonerado).to eq(2.00)
        expect(total.fcp_valor).to eq(1.00)
      end

      it 'armazena valores de impostos federais' do
        total = described_class.new(
          pis_valor: 0.65,
          cofins_valor: 3.00,
          fust_valor: 0.50,
          funttel_valor: 0.50
        )

        expect(total.pis_valor).to eq(0.65)
        expect(total.cofins_valor).to eq(3.00)
        expect(total.fust_valor).to eq(0.50)
        expect(total.funttel_valor).to eq(0.50)
      end

      it 'armazena todas as retenções' do
        total = described_class.new(
          pis_retido: 0.65,
          cofins_retido: 3.00,
          csll_retido: 1.00,
          irrf_retido: 1.50
        )

        expect(total.pis_retido).to eq(0.65)
        expect(total.cofins_retido).to eq(3.00)
        expect(total.csll_retido).to eq(1.00)
        expect(total.irrf_retido).to eq(1.50)
      end
    end
  end

  describe 'compatibilidade com Nota#recalcular_totais' do
    it 'aceita valores agregados de múltiplos itens' do
      # Simula o que Nota#recalcular_totais faz
      item1 = double(valor_total: 50.00, valor_desconto: 2.00, valor_outras_despesas: 1.00)
      item2 = double(valor_total: 49.90, valor_desconto: 3.00, valor_outras_despesas: 1.50)

      itens = [item1, item2]

      total = described_class.new
      total.valor_servicos = itens.sum(&:valor_total)
      total.valor_desconto = itens.sum(&:valor_desconto)
      total.valor_outras_despesas = itens.sum(&:valor_outras_despesas)
      total.calcular_total

      expect(total.valor_servicos).to eq(99.90)
      expect(total.valor_desconto).to eq(5.00)
      expect(total.valor_outras_despesas).to eq(2.50)
      expect(total.valor_total).to eq(97.40)
    end
  end
end
