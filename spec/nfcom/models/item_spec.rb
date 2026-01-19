# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Nfcom::Models::Item do
  describe '#initialize' do
    context 'com valores padrão' do
      subject(:item) { described_class.new }

      it 'define valores padrão corretos' do
        aggregate_failures do
          expect(item.unidade).to eq(4)
          expect(item.quantidade).to eq(1)
          expect(item.valor_desconto).to eq(0.0)
          expect(item.valor_outras_despesas).to eq(0.0)
        end
      end

      it 'calcula valor_total como 0.0 quando não há valor_unitario' do
        expect(item.valor_total).to eq(0.0)
      end
    end

    context 'com atributos fornecidos' do
      subject(:item) { described_class.new(atributos) }

      let(:atributos) do
        {
          codigo_servico: '0303',
          descricao: 'Plano Fibra 100MB',
          classe_consumo: :assinatura_multimidia,
          cfop: '5307',
          unidade: :un,
          quantidade: 1,
          valor_unitario: 99.90
        }
      end

      it 'define todos os atributos corretamente' do
        aggregate_failures do
          expect(item.codigo_servico).to eq('0303')
          expect(item.descricao).to eq('Plano Fibra 100MB')
          expect(item.classe_consumo).to eq('0100401')
          expect(item.cfop).to eq('5307')
          expect(item.unidade).to eq(4)
          expect(item.quantidade).to eq(1)
          expect(item.valor_unitario).to eq(99.90)
        end
      end

      it 'calcula valor_total automaticamente' do
        expect(item.valor_total).to eq(99.90)
      end
    end

    context 'com desconto' do
      subject(:item) { described_class.new(atributos) }

      let(:atributos) do
        {
          codigo_servico: '0303',
          descricao: 'Plano Premium',
          classe_consumo: :assinatura_multimidia,
          cfop: '5307',
          quantidade: 1,
          valor_unitario: 149.90,
          valor_desconto: 20.00
        }
      end

      it 'calcula valor_total com desconto' do
        expect(item.valor_total).to eq(129.90)
      end
    end

    context 'com outras despesas' do
      subject(:item) { described_class.new(atributos) }

      let(:atributos) do
        {
          codigo_servico: '0303',
          descricao: 'Internet',
          classe_consumo: :assinatura_multimidia,
          cfop: '5307',
          quantidade: 1,
          valor_unitario: 99.90,
          valor_outras_despesas: 5.00
        }
      end

      it 'calcula valor_total com outras despesas' do
        expect(item.valor_total).to eq(104.90)
      end
    end
  end

  describe '#classe_consumo=' do
    subject(:item) { described_class.new }

    context 'quando recebe um símbolo válido' do
      it 'converte para o código correto' do
        item.classe_consumo = :assinatura_multimidia
        expect(item.classe_consumo).to eq('0100401')
      end

      it 'aceita todos os símbolos válidos' do
        aggregate_failures do
          item.classe_consumo = :assinatura_telefonia
          expect(item.classe_consumo).to eq('0100101')

          item.classe_consumo = :nao_medido_internet
          expect(item.classe_consumo).to eq('0400401')
        end
      end
    end

    context 'quando recebe uma string válida' do
      it 'aceita o código diretamente' do
        item.classe_consumo = '0100401'
        expect(item.classe_consumo).to eq('0100401')
      end
    end

    context 'quando recebe um valor inválido' do
      it 'aceita o valor mas falha na validação (símbolo inválido)' do
        item.classe_consumo = :invalido
        expect(item).not_to be_valido
        expect(item.erros).to include(match(/Classe de consumo/))
      end

      it 'aceita o valor mas falha na validação (código inválido)' do
        item.classe_consumo = '9999999'
        expect(item).not_to be_valido
        expect(item.erros).to include(match(/Classe de consumo/))
      end
    end
  end

  describe '#unidade=' do
    subject(:item) { described_class.new }

    context 'quando recebe um símbolo válido' do
      it 'converte para o código correto' do
        aggregate_failures do
          item.unidade = :minuto
          expect(item.unidade).to eq(1)

          item.unidade = :mb
          expect(item.unidade).to eq(2)

          item.unidade = :gb
          expect(item.unidade).to eq(3)

          item.unidade = :un
          expect(item.unidade).to eq(4)
        end
      end
    end

    context 'quando recebe um inteiro válido' do
      it 'aceita o código diretamente' do
        item.unidade = 4
        expect(item.unidade).to eq(4)
      end
    end

    context 'quando recebe um valor inválido' do
      it 'aceita o valor mas falha na validação (símbolo inválido)' do
        item.unidade = :invalido
        expect(item).not_to be_valido
        expect(item.erros).to include(match(/Unidade de medida/))
      end

      it 'aceita o valor mas falha na validação (código inválido)' do
        item.unidade = 99
        expect(item).not_to be_valido
        expect(item.erros).to include(match(/Unidade de medida/))
      end
    end
  end

  describe '#valido?' do
    context 'com item válido' do
      let(:item) do
        described_class.new(
          codigo_servico: '0303',
          descricao: 'Internet 100MB',
          classe_consumo: :assinatura_multimidia,
          cfop: '5307',
          valor_unitario: 99.90,
          quantidade: 1
        )
      end

      it 'retorna true' do
        expect(item).to be_valido
      end
    end

    context 'com item inválido' do
      let(:item) { described_class.new }

      it 'retorna false' do
        expect(item).not_to be_valido
      end
    end
  end

  describe '#erros' do
    context 'quando campos obrigatórios estão ausentes' do
      let(:item) { described_class.new }

      it 'retorna erros para todos os campos obrigatórios' do
        errors = item.erros

        aggregate_failures do
          expect(errors).to include('Código de serviço é obrigatório')
          expect(errors).to include('Descrição é obrigatória')
          expect(errors).to include('Classe de consumo é obrigatória')
          expect(errors).to include('CFOP é obrigatório')
          expect(errors).to include('Valor unitário é obrigatório')
          expect(errors.length).to eq(6)
        end
      end
    end

    context 'quando valida codigo_servico' do
      let(:base_attrs) do
        {
          descricao: 'Plano',
          classe_consumo: :assinatura_multimidia,
          cfop: '5307',
          valor_unitario: 99.90,
          quantidade: 1
        }
      end

      it 'exige codigo_servico' do
        item = described_class.new(base_attrs)
        expect(item.erros).to include('Código de serviço é obrigatório')
      end

      it 'valida formato (ER47)' do
        item = described_class.new(base_attrs.merge(codigo_servico: '0303'))
        expect(item.erros).not_to include(match(/Código de serviço/))
      end

      it 'aceita até 60 caracteres' do
        codigo_longo = 'A' * 60
        item = described_class.new(base_attrs.merge(codigo_servico: codigo_longo))
        expect(item.erros).not_to include(match(/Código de serviço/))
      end
    end

    context 'quando valida descricao' do
      let(:base_attrs) do
        {
          codigo_servico: '0303',
          classe_consumo: :assinatura_multimidia,
          cfop: '5307',
          valor_unitario: 99.90,
          quantidade: 1
        }
      end

      it 'exige descricao' do
        item = described_class.new(base_attrs)
        expect(item.erros).to include('Descrição é obrigatória')
      end

      it 'valida formato (ER47)' do
        item = described_class.new(base_attrs.merge(descricao: 'Plano Internet'))
        expect(item.erros).not_to include(match(/Descrição/))
      end

      it 'aceita até 120 caracteres' do
        descricao_longa = 'Plano ' + ('A' * 114)
        item = described_class.new(base_attrs.merge(descricao: descricao_longa))
        expect(item.erros).not_to include(match(/Descrição/))
      end
    end

    context 'quando valida classe_consumo' do
      let(:base_attrs) do
        {
          codigo_servico: '0303',
          descricao: 'Plano',
          cfop: '5307',
          valor_unitario: 99.90,
          quantidade: 1
        }
      end

      it 'exige classe_consumo' do
        item = described_class.new(base_attrs)
        expect(item.erros).to include('Classe de consumo é obrigatória')
      end

      it 'valida formato de 7 dígitos (ER2)' do
        item = described_class.new(base_attrs.merge(classe_consumo: '0100401'))
        expect(item.erros).not_to include(match(/Classe de consumo/))
      end

      it 'rejeita código com menos de 7 dígitos' do
        item = described_class.new(base_attrs.merge(classe_consumo: '123456'))
        expect(item.erros).to include(match(/Classe de consumo inválido/))
      end

      it 'rejeita código com mais de 7 dígitos' do
        item = described_class.new(base_attrs.merge(classe_consumo: '12345678'))
        expect(item.erros).to include(match(/Classe de consumo inválido/))
      end
    end

    context 'quando valida cfop' do
      let(:base_attrs) do
        {
          codigo_servico: '0303',
          descricao: 'Plano',
          classe_consumo: :assinatura_multimidia,
          valor_unitario: 99.90,
          quantidade: 1
        }
      end

      it 'exige cfop' do
        item = described_class.new(base_attrs)
        expect(item.erros).to include('CFOP é obrigatório')
      end

      it 'valida formato (ER73)' do
        item = described_class.new(base_attrs.merge(cfop: '5307'))
        expect(item.erros).not_to include(match(/CFOP/))
      end

      it 'aceita CFOPs válidos de serviço' do
        aggregate_failures do
          %w[5307 6307 5351 6351].each do |cfop|
            item = described_class.new(base_attrs.merge(cfop: cfop))
            expect(item.erros).not_to include(match(/CFOP/)), "falhou para CFOP #{cfop}"
          end
        end
      end

      it 'rejeita CFOP inválido' do
        item = described_class.new(base_attrs.merge(cfop: '9999'))
        expect(item.erros).to include(match(/CFOP inválido/))
      end
    end

    context 'quando valida unidade' do
      let(:base_attrs) do
        {
          codigo_servico: '0303',
          descricao: 'Plano',
          classe_consumo: :assinatura_multimidia,
          cfop: '5307',
          valor_unitario: 99.90,
          quantidade: 1
        }
      end

      it 'aceita unidade válida (D8: 1, 2, 3, 4)' do
        aggregate_failures do
          [1, 2, 3, 4].each do |unidade_codigo|
            item = described_class.new(base_attrs.merge(unidade: unidade_codigo))
            expect(item.erros).not_to include(match(/Unidade/)), "falhou para unidade #{unidade_codigo}"
          end
        end
      end

      it 'rejeita unidade inválida' do
        item = described_class.new(base_attrs.merge(unidade: 99))
        expect(item).not_to be_valido
        expect(item.erros).to include(match(/Unidade de medida/))
      end
    end

    context 'quando valida quantidade' do
      let(:base_attrs) do
        {
          codigo_servico: '0303',
          descricao: 'Plano',
          classe_consumo: :assinatura_multimidia,
          cfop: '5307',
          valor_unitario: 99.90
        }
      end

      it 'exige quantidade' do
        item = described_class.new(base_attrs.merge(quantidade: nil))
        expect(item.erros).to include('Quantidade é obrigatória')
      end

      it 'rejeita quantidade zero' do
        item = described_class.new(base_attrs.merge(quantidade: 0))
        expect(item.erros).to include('Quantidade deve ser maior que zero')
      end

      it 'rejeita quantidade negativa' do
        item = described_class.new(base_attrs.merge(quantidade: -1))
        expect(item.erros).to include('Quantidade deve ser maior que zero')
      end

      it 'aceita quantidade válida (ER31)' do
        item = described_class.new(base_attrs.merge(quantidade: 1.5))
        expect(item.erros).not_to include(match(/Quantidade/))
      end

      it 'aceita quantidade com até 4 decimais' do
        item = described_class.new(base_attrs.merge(quantidade: 1.2345))
        expect(item.erros).not_to include(match(/Quantidade/))
      end
    end

    context 'quando valida valor_unitario' do
      let(:base_attrs) do
        {
          codigo_servico: '0303',
          descricao: 'Plano',
          classe_consumo: :assinatura_multimidia,
          cfop: '5307',
          quantidade: 1
        }
      end

      it 'exige valor_unitario' do
        item = described_class.new(base_attrs)
        expect(item.erros).to include('Valor unitário é obrigatório')
      end

      it 'rejeita valor zero' do
        item = described_class.new(base_attrs.merge(valor_unitario: 0))
        expect(item.erros).to include('Valor unitário deve ser maior que zero')
      end

      it 'rejeita valor negativo' do
        item = described_class.new(base_attrs.merge(valor_unitario: -99.90))
        expect(item.erros).to include('Valor unitário deve ser maior que zero')
      end

      it 'aceita valor válido (ER39)' do
        item = described_class.new(base_attrs.merge(valor_unitario: 99.90))
        expect(item.erros).not_to include(match(/Valor unitário/))
      end

      it 'aceita valores com até 8 decimais' do
        item = described_class.new(base_attrs.merge(valor_unitario: 99.12345678))
        expect(item.erros).not_to include(match(/Valor unitário/))
      end
    end

    context 'quando valida campos opcionais' do
      let(:base_attrs) do
        {
          codigo_servico: '0303',
          descricao: 'Plano',
          classe_consumo: :assinatura_multimidia,
          cfop: '5307',
          quantidade: 1,
          valor_unitario: 99.90
        }
      end

      it 'aceita valor_desconto válido (ER37)' do
        item = described_class.new(base_attrs.merge(valor_desconto: 10.00))
        expect(item.erros).not_to include(match(/desconto/))
      end

      it 'aceita valor_outras_despesas válido (ER37)' do
        item = described_class.new(base_attrs.merge(valor_outras_despesas: 5.00))
        expect(item.erros).not_to include(match(/outras despesas/))
      end

      it 'não valida campos opcionais quando zero' do
        item = described_class.new(base_attrs.merge(
                                     valor_desconto: 0,
                                     valor_outras_despesas: 0
                                   ))
        expect(item).to be_valido
      end
    end

    context 'com item completamente válido' do
      let(:item) do
        described_class.new(
          codigo_servico: '0303',
          descricao: 'Plano Fibra 100MB',
          classe_consumo: :assinatura_multimidia,
          cfop: '5307',
          unidade: :un,
          quantidade: 1,
          valor_unitario: 99.90,
          valor_desconto: 10.00,
          valor_outras_despesas: 2.00
        )
      end

      it 'não retorna erros' do
        expect(item.erros).to be_empty
        expect(item).to be_valido
      end
    end
  end

  describe '#calcular_valor_total' do
    context 'com valor simples' do
      let(:item) do
        described_class.new(
          codigo_servico: '0303',
          descricao: 'Plano',
          classe_consumo: :assinatura_multimidia,
          cfop: '5307',
          quantidade: 1,
          valor_unitario: 99.90
        )
      end

      it 'calcula corretamente' do
        expect(item.valor_total).to eq(99.90)
      end
    end

    context 'com múltiplas quantidades' do
      let(:item) do
        described_class.new(
          codigo_servico: '0303',
          descricao: 'Plano',
          classe_consumo: :assinatura_multimidia,
          cfop: '5307',
          quantidade: 3,
          valor_unitario: 50.00
        )
      end

      it 'multiplica quantidade por valor unitário' do
        expect(item.valor_total).to eq(150.00)
      end
    end

    context 'com desconto' do
      let(:item) do
        described_class.new(
          codigo_servico: '0303',
          descricao: 'Plano',
          classe_consumo: :assinatura_multimidia,
          cfop: '5307',
          quantidade: 1,
          valor_unitario: 99.90,
          valor_desconto: 20.00
        )
      end

      it 'subtrai o desconto' do
        expect(item.valor_total).to eq(79.90)
      end
    end

    context 'com outras despesas' do
      let(:item) do
        described_class.new(
          codigo_servico: '0303',
          descricao: 'Plano',
          classe_consumo: :assinatura_multimidia,
          cfop: '5307',
          quantidade: 1,
          valor_unitario: 99.90,
          valor_outras_despesas: 5.00
        )
      end

      it 'adiciona outras despesas' do
        expect(item.valor_total).to eq(104.90)
      end
    end

    context 'com cálculo completo' do
      let(:item) do
        described_class.new(
          codigo_servico: '0303',
          descricao: 'Plano',
          classe_consumo: :assinatura_multimidia,
          cfop: '5307',
          quantidade: 2,
          valor_unitario: 100.00,
          valor_desconto: 30.00,
          valor_outras_despesas: 10.00
        )
      end

      it 'calcula: (qtd * unitario) - desconto + despesas' do
        # (2 * 100) - 30 + 10 = 180
        expect(item.valor_total).to eq(180.00)
      end
    end

    context 'quando recalculado' do
      let(:item) do
        described_class.new(
          codigo_servico: '0303',
          descricao: 'Plano',
          classe_consumo: :assinatura_multimidia,
          cfop: '5307',
          quantidade: 1,
          valor_unitario: 99.90
        )
      end

      it 'atualiza o valor_total' do
        expect(item.valor_total).to eq(99.90)

        item.quantidade = 2
        item.calcular_valor_total

        expect(item.valor_total).to eq(199.80)
      end
    end
  end

  describe '#valor_liquido' do
    let(:item) do
      described_class.new(
        codigo_servico: '0303',
        descricao: 'Plano',
        classe_consumo: :assinatura_multimidia,
        cfop: '5307',
        quantidade: 1,
        valor_unitario: 99.90
      )
    end

    it 'retorna o valor_total' do
      expect(item.valor_liquido).to eq(item.valor_total)
    end
  end

  describe 'constantes' do
    it 'define CODIGOS_SERVICO' do
      expect(described_class::CODIGOS_SERVICO).to include(
        internet: '0303',
        tv_assinatura: '0304',
        telefonia: '0305'
      )
    end

    it 'define CLASSES_CONSUMO com todos os grupos' do
      expect(described_class::CLASSES_CONSUMO.keys).to include(
        :assinatura_multimidia,
        :nao_medido_internet,
        :prepago_recarga_movel
      )
    end

    it 'define UNIDADES_MEDIDA' do
      expect(described_class::UNIDADES_MEDIDA).to eq(
        minuto: 1,
        mb: 2,
        gb: 3,
        un: 4
      )
    end
  end

  describe 'cenários de integração' do
    context 'para item de internet básico' do
      let(:item) do
        described_class.new(
          codigo_servico: '0303',
          descricao: 'Internet Fibra 100MB',
          classe_consumo: :assinatura_multimidia,
          cfop: '5307',
          unidade: :un,
          quantidade: 1,
          valor_unitario: 99.90
        )
      end

      it 'cria item válido' do
        expect(item).to be_valido
        expect(item.valor_total).to eq(99.90)
      end
    end

    context 'para item de TV por assinatura' do
      let(:item) do
        described_class.new(
          codigo_servico: '0304',
          descricao: 'TV Premium HD',
          classe_consumo: :assinatura_tv,
          cfop: '5307',
          unidade: :un,
          quantidade: 1,
          valor_unitario: 79.90
        )
      end

      it 'cria item válido' do
        expect(item).to be_valido
        expect(item.classe_consumo).to eq('0100301')
      end
    end

    context 'para item com desconto promocional' do
      let(:item) do
        described_class.new(
          codigo_servico: '0303',
          descricao: 'Plano 200MB - Promoção',
          classe_consumo: :assinatura_multimidia,
          cfop: '5307',
          quantidade: 1,
          valor_unitario: 149.90,
          valor_desconto: 50.00
        )
      end

      it 'aplica desconto corretamente' do
        expect(item).to be_valido
        expect(item.valor_total).to eq(99.90)
      end
    end

    context 'para item com várias unidades' do
      let(:item) do
        described_class.new(
          codigo_servico: '0303',
          descricao: 'Equipamento Router',
          classe_consumo: :equip_roteador,
          cfop: '5307',
          unidade: :un,
          quantidade: 5,
          valor_unitario: 150.00
        )
      end

      it 'multiplica quantidade corretamente' do
        expect(item).to be_valido
        expect(item.valor_total).to eq(750.00)
      end
    end
  end
end
