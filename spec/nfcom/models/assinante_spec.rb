# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Nfcom::Models::Assinante do
  describe '#initialize' do
    context 'quando inicializado com todos os atributos' do
      subject(:assinante) { described_class.new(attrs) }

      let(:attrs) do
        {
          codigo: 'ASS123',
          tipo: described_class::TIPO_COMERCIAL,
          tipo_servico: described_class::SERVICO_INTERNET,
          numero_contrato: 'CTR2024001',
          data_inicio_contrato: '2024-01-01',
          data_fim_contrato: '2025-01-01',
          terminal_principal: '81987654321',
          uf_terminal_principal: 'PE',
          terminais_adicionais: [
            { numero: '81912345678', uf: 'PE' }
          ]
        }
      end

      it 'atribui todos os valores corretamente' do
        aggregate_failures do
          expect(assinante.codigo).to eq('ASS123')
          expect(assinante.tipo).to eq(described_class::TIPO_COMERCIAL)
          expect(assinante.tipo_servico).to eq(described_class::SERVICO_INTERNET)
          expect(assinante.numero_contrato).to eq('CTR2024001')
          expect(assinante.data_inicio_contrato).to eq('2024-01-01')
          expect(assinante.data_fim_contrato).to eq('2025-01-01')
          expect(assinante.terminal_principal).to eq('81987654321')
          expect(assinante.uf_terminal_principal).to eq('PE')
          expect(assinante.terminais_adicionais).to eq([{ numero: '81912345678', uf: 'PE' }])
        end
      end
    end

    context 'quando inicializado sem atributos opcionais' do
      subject(:assinante) do
        described_class.new(
          codigo: 'ASS123',
          tipo: described_class::TIPO_RESIDENCIAL,
          tipo_servico: described_class::SERVICO_INTERNET
        )
      end

      it 'usa valores padrão e inicializa campos opcionais' do
        aggregate_failures do
          expect(assinante.tipo).to eq(described_class::TIPO_RESIDENCIAL)
          expect(assinante.tipo_servico).to eq(described_class::SERVICO_INTERNET)
          expect(assinante.terminais_adicionais).to eq([])
          expect(assinante.numero_contrato).to be_nil
          expect(assinante.data_inicio_contrato).to be_nil
          expect(assinante.data_fim_contrato).to be_nil
          expect(assinante.terminal_principal).to be_nil
          expect(assinante.uf_terminal_principal).to be_nil
        end
      end
    end
  end

  describe '#valido?' do
    context 'quando todos os campos obrigatórios estão preenchidos' do
      let(:assinante) do
        described_class.new(
          codigo: 'ASS123',
          tipo: described_class::TIPO_RESIDENCIAL,
          tipo_servico: described_class::SERVICO_INTERNET
        )
      end

      it 'retorna true' do
        expect(assinante.valido?).to be true
      end
    end

    context 'quando falta campo obrigatório' do
      let(:assinante_sem_codigo) do
        described_class.new(
          tipo: described_class::TIPO_RESIDENCIAL,
          tipo_servico: described_class::SERVICO_INTERNET
        )
      end

      it 'retorna false' do
        expect(assinante_sem_codigo.valido?).to be false
      end
    end
  end

  describe '#erros' do
    context 'para validações de campos obrigatórios' do
      context 'quando código está vazio' do
        let(:assinante) { described_class.new(codigo: '') }

        it 'retorna erro informando que código é obrigatório' do
          expect(assinante.erros).to include('Código do assinante é obrigatório')
        end
      end

      context 'quando tipo é nil' do
        let(:assinante) { described_class.new(codigo: 'ASS123', tipo: nil) }

        it 'retorna erro informando que tipo é obrigatório' do
          expect(assinante.erros).to include('Tipo de assinante é obrigatório')
        end
      end

      context 'quando tipo_servico é nil' do
        let(:assinante) { described_class.new(codigo: 'ASS123', tipo_servico: nil) }

        it 'retorna erro informando que tipo de serviço é obrigatório' do
          expect(assinante.erros).to include('Tipo de serviço é obrigatório')
        end
      end
    end

    context 'para validações de formato (ER)' do
      context 'quando código excede 30 caracteres (ER59)' do
        let(:codigo_longo) { 'A' * 31 }
        let(:assinante) do
          described_class.new(
            codigo: codigo_longo,
            tipo: described_class::TIPO_COMERCIAL,
            tipo_servico: described_class::SERVICO_INTERNET
          )
        end

        it 'retorna erro de validação' do
          expect(assinante.erros).to include(match(/Código do assinante inválido/))
        end
      end

      context 'quando código tem entre 1 e 30 caracteres (ER59)' do
        let(:assinante) do
          described_class.new(
            codigo: 'ASS123',
            tipo: described_class::TIPO_COMERCIAL,
            tipo_servico: described_class::SERVICO_INTERNET
          )
        end

        it 'não retorna erro de formato' do
          expect(assinante.erros).not_to include(match(/Código do assinante inválido/))
        end
      end

      context 'quando número do contrato excede 20 caracteres (ER60)' do
        let(:contrato_longo) { 'C' * 21 }
        let(:assinante) do
          described_class.new(
            codigo: 'ASS123',
            tipo: described_class::TIPO_COMERCIAL,
            tipo_servico: described_class::SERVICO_INTERNET,
            numero_contrato: contrato_longo
          )
        end

        it 'retorna erro de validação' do
          expect(assinante.erros).to include(match(/Número do contrato inválido/))
        end
      end

      context 'quando número do contrato tem até 20 caracteres (ER60)' do
        let(:assinante) do
          described_class.new(
            codigo: 'ASS123',
            tipo: described_class::TIPO_COMERCIAL,
            tipo_servico: described_class::SERVICO_INTERNET,
            numero_contrato: 'CTR2024001'
          )
        end

        it 'não retorna erro de formato' do
          expect(assinante.erros).not_to include(match(/Número do contrato inválido/))
        end
      end
    end

    context 'para validações de domínio' do
      context 'quando tipo de assinante é inválido (D18)' do
        let(:assinante) do
          described_class.new(
            codigo: 'ASS123',
            tipo: 999, # Valor inválido
            tipo_servico: described_class::SERVICO_INTERNET
          )
        end

        it 'retorna erro informando tipo inválido' do
          expect(assinante.erros).to include(match(/Tipo de assinante inválido/))
        end
      end

      context 'quando tipo de assinante é válido (D18)' do
        it 'não retorna erro de tipo para todos os valores válidos' do
          aggregate_failures do
            [1, 2, 3, 4, 5, 6, 7, 8, 99].each do |tipo_valido|
              assinante = described_class.new(
                codigo: 'ASS123',
                tipo: tipo_valido,
                tipo_servico: described_class::SERVICO_INTERNET
              )
              expect(assinante.erros).not_to include(match(/Tipo de assinante inválido/)),
                                             "falhou para tipo #{tipo_valido}"
            end
          end
        end
      end

      context 'quando tipo de serviço é inválido (D24)' do
        let(:assinante) do
          described_class.new(
            codigo: 'ASS123',
            tipo: described_class::TIPO_RESIDENCIAL,
            tipo_servico: 999 # Valor inválido
          )
        end

        it 'retorna erro informando tipo de serviço inválido' do
          expect(assinante.erros).to include(match(/Tipo de serviço inválido/))
        end
      end

      context 'quando tipo de serviço é válido (D24)' do
        it 'não retorna erro de tipo de serviço para todos os valores válidos' do
          aggregate_failures do
            [1, 2, 3, 4, 5, 6, 7].each do |servico_valido|
              assinante = described_class.new(
                codigo: 'ASS123',
                tipo: described_class::TIPO_RESIDENCIAL,
                tipo_servico: servico_valido
              )
              expect(assinante.erros).not_to include(match(/Tipo de serviço inválido/)),
                                             "falhou para serviço #{servico_valido}"
            end
          end
        end
      end

      context 'quando UF do terminal é inválida (D5)' do
        let(:assinante) do
          described_class.new(
            codigo: 'ASS123',
            tipo: described_class::TIPO_RESIDENCIAL,
            tipo_servico: described_class::SERVICO_INTERNET,
            terminal_principal: '81987654321',
            uf_terminal_principal: 'XX' # UF inválida
          )
        end

        it 'retorna erro informando UF inválida' do
          expect(assinante.erros).to include(match(/UF do terminal inválido/))
        end
      end

      context 'quando UF do terminal é válida (D5)' do
        let(:assinante) do
          described_class.new(
            codigo: 'ASS123',
            tipo: described_class::TIPO_RESIDENCIAL,
            tipo_servico: described_class::SERVICO_INTERNET,
            terminal_principal: '81987654321',
            uf_terminal_principal: 'PE'
          )
        end

        it 'não retorna erro de UF' do
          expect(assinante.erros).not_to include(match(/UF do terminal inválido/))
        end
      end
    end

    context 'para validações de datas (ER48)' do
      context 'quando data de início do contrato é inválida' do
        let(:assinante) do
          described_class.new(
            codigo: 'ASS123',
            tipo: described_class::TIPO_COMERCIAL,
            tipo_servico: described_class::SERVICO_INTERNET,
            data_inicio_contrato: '2024-13-01' # Mês inválido
          )
        end

        it 'retorna erro de formato de data' do
          expect(assinante.erros).to include(match(/Data de início inválido/))
        end
      end

      context 'quando data de fim do contrato é inválida' do
        let(:assinante) do
          described_class.new(
            codigo: 'ASS123',
            tipo: described_class::TIPO_COMERCIAL,
            tipo_servico: described_class::SERVICO_INTERNET,
            data_inicio_contrato: '2024-01-01',
            data_fim_contrato: '2024-02-31' # Dia inválido
          )
        end

        it 'retorna erro de formato de data' do
          expect(assinante.erros).to include(match(/Data de fim inválido/))
        end
      end

      context 'quando data de fim é anterior à data de início' do
        let(:assinante) do
          described_class.new(
            codigo: 'ASS123',
            tipo: described_class::TIPO_COMERCIAL,
            tipo_servico: described_class::SERVICO_INTERNET,
            data_inicio_contrato: '2024-12-01',
            data_fim_contrato: '2024-01-01'
          )
        end

        it 'retorna erro de lógica de data' do
          expect(assinante.erros).to include('Data de fim do contrato não pode ser anterior à data de início')
        end
      end

      context 'quando datas estão válidas' do
        let(:assinante) do
          described_class.new(
            codigo: 'ASS123',
            tipo: described_class::TIPO_COMERCIAL,
            tipo_servico: described_class::SERVICO_INTERNET,
            data_inicio_contrato: '2024-01-01',
            data_fim_contrato: '2025-01-01'
          )
        end

        it 'não retorna erros de data' do
          expect(assinante.erros).not_to include(match(/Data/))
        end
      end
    end

    context 'para validações de terminal (ER61)' do
      context 'quando terminal principal tem menos de 7 dígitos' do
        let(:assinante) do
          described_class.new(
            codigo: 'ASS123',
            tipo: described_class::TIPO_RESIDENCIAL,
            tipo_servico: described_class::SERVICO_INTERNET,
            terminal_principal: '123456',
            uf_terminal_principal: 'PE'
          )
        end

        it 'retorna erro de formato de telefone' do
          expect(assinante.erros).to include(match(/Terminal principal inválido/))
        end
      end

      context 'quando terminal principal tem mais de 12 dígitos' do
        let(:assinante) do
          described_class.new(
            codigo: 'ASS123',
            tipo: described_class::TIPO_RESIDENCIAL,
            tipo_servico: described_class::SERVICO_INTERNET,
            terminal_principal: '1234567890123',
            uf_terminal_principal: 'PE'
          )
        end

        it 'retorna erro de formato de telefone' do
          expect(assinante.erros).to include(match(/Terminal principal inválido/))
        end
      end

      context 'quando terminal principal tem entre 7 e 12 dígitos' do
        let(:assinante) do
          described_class.new(
            codigo: 'ASS123',
            tipo: described_class::TIPO_RESIDENCIAL,
            tipo_servico: described_class::SERVICO_INTERNET,
            terminal_principal: '81987654321',
            uf_terminal_principal: 'PE'
          )
        end

        it 'não retorna erro de formato' do
          expect(assinante.erros).not_to include(match(/Terminal principal inválido/))
        end
      end
    end

    context 'para validações condicionais de terminal' do
      context 'quando informou terminal mas não informou UF' do
        let(:assinante) do
          described_class.new(
            codigo: 'ASS123',
            tipo: described_class::TIPO_RESIDENCIAL,
            tipo_servico: described_class::SERVICO_INTERNET,
            terminal_principal: '81987654321'
          )
        end

        it 'retorna erro informando que UF é obrigatória' do
          expect(assinante.erros).to include('UF do terminal principal é obrigatória quando o número do terminal é informado')
        end
      end

      context 'quando informou UF mas não informou terminal' do
        let(:assinante) do
          described_class.new(
            codigo: 'ASS123',
            tipo: described_class::TIPO_RESIDENCIAL,
            tipo_servico: described_class::SERVICO_INTERNET,
            uf_terminal_principal: 'PE'
          )
        end

        it 'retorna erro informando que terminal é obrigatório' do
          expect(assinante.erros).to include('Número do terminal principal é obrigatório quando a UF é informada')
        end
      end

      context 'quando informou terminal e UF' do
        let(:assinante) do
          described_class.new(
            codigo: 'ASS123',
            tipo: described_class::TIPO_RESIDENCIAL,
            tipo_servico: described_class::SERVICO_INTERNET,
            terminal_principal: '81987654321',
            uf_terminal_principal: 'PE'
          )
        end

        it 'não retorna erros condicionais' do
          expect(assinante.erros).not_to include(match(/obrigatório/))
        end
      end

      context 'quando não informou nem terminal nem UF' do
        let(:assinante) do
          described_class.new(
            codigo: 'ASS123',
            tipo: described_class::TIPO_RESIDENCIAL,
            tipo_servico: described_class::SERVICO_INTERNET
          )
        end

        it 'não retorna erros condicionais' do
          expect(assinante.erros).not_to include(match(/terminal/i))
        end
      end
    end

    context 'para validações de terminais adicionais' do
      context 'quando terminal adicional não tem número' do
        let(:assinante) do
          described_class.new(
            codigo: 'ASS123',
            tipo: described_class::TIPO_COMERCIAL,
            tipo_servico: described_class::SERVICO_INTERNET,
            terminais_adicionais: [
              { numero: '', uf: 'PE' }
            ]
          )
        end

        it 'retorna erro informando que número é obrigatório' do
          expect(assinante.erros).to include('Terminal adicional 1: número é obrigatório')
        end
      end

      context 'quando terminal adicional não tem UF' do
        let(:assinante) do
          described_class.new(
            codigo: 'ASS123',
            tipo: described_class::TIPO_COMERCIAL,
            tipo_servico: described_class::SERVICO_INTERNET,
            terminais_adicionais: [
              { numero: '81987654321', uf: '' }
            ]
          )
        end

        it 'retorna erro informando que UF é obrigatória' do
          expect(assinante.erros).to include('Terminal adicional 1: UF é obrigatória')
        end
      end

      context 'quando terminal adicional tem formato de telefone inválido' do
        let(:assinante) do
          described_class.new(
            codigo: 'ASS123',
            tipo: described_class::TIPO_COMERCIAL,
            tipo_servico: described_class::SERVICO_INTERNET,
            terminais_adicionais: [
              { numero: '123', uf: 'PE' }
            ]
          )
        end

        it 'retorna erro de formato' do
          expect(assinante.erros).to include(match(/Terminal adicional 1 inválido/))
        end
      end

      context 'quando terminal adicional tem UF inválida' do
        let(:assinante) do
          described_class.new(
            codigo: 'ASS123',
            tipo: described_class::TIPO_COMERCIAL,
            tipo_servico: described_class::SERVICO_INTERNET,
            terminais_adicionais: [
              { numero: '81987654321', uf: 'XX' }
            ]
          )
        end

        it 'retorna erro de UF' do
          expect(assinante.erros).to include(match(/UF do terminal adicional 1 inválido/))
        end
      end

      context 'quando múltiplos terminais adicionais têm erros' do
        let(:assinante) do
          described_class.new(
            codigo: 'ASS123',
            tipo: described_class::TIPO_COMERCIAL,
            tipo_servico: described_class::SERVICO_INTERNET,
            terminais_adicionais: [
              { numero: '123', uf: 'PE' },
              { numero: '81987654321', uf: 'XX' }
            ]
          )
        end

        it 'retorna erros para ambos os terminais' do
          aggregate_failures do
            expect(assinante.erros).to include(match(/Terminal adicional 1 inválido/))
            expect(assinante.erros).to include(match(/UF do terminal adicional 2 inválido/))
          end
        end
      end

      context 'quando terminais adicionais estão válidos' do
        let(:assinante) do
          described_class.new(
            codigo: 'ASS123',
            tipo: described_class::TIPO_COMERCIAL,
            tipo_servico: described_class::SERVICO_INTERNET,
            terminais_adicionais: [
              { numero: '81987654321', uf: 'PE' },
              { numero: '81912345678', uf: 'RJ' }
            ]
          )
        end

        it 'não retorna erros de terminais adicionais' do
          expect(assinante.erros).not_to include(match(/Terminal adicional/))
        end
      end
    end

    context 'para assinante completamente válido' do
      let(:assinante) do
        described_class.new(
          codigo: 'ASS12345',
          tipo: described_class::TIPO_COMERCIAL,
          tipo_servico: described_class::SERVICO_INTERNET,
          numero_contrato: 'CTR2024001',
          data_inicio_contrato: '2024-01-01',
          data_fim_contrato: '2025-01-01',
          terminal_principal: '81987654321',
          uf_terminal_principal: 'PE',
          terminais_adicionais: [
            { numero: '81912345678', uf: 'PE' }
          ]
        )
      end

      it 'não retorna erros e é válido' do
        aggregate_failures do
          expect(assinante.erros).to be_empty
          expect(assinante.valido?).to be true
        end
      end
    end
  end
end
