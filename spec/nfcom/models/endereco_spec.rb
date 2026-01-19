# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Nfcom::Models::Endereco do
  # Atributos básicos válidos
  let(:atributos_validos) do
    {
      logradouro: 'Rua das Flores',
      numero: '123',
      bairro: 'Centro',
      codigo_municipio: '2611606',
      municipio: 'Recife',
      uf: 'PE',
      cep: '50000000'
    }
  end

  # Atributos completos com campos opcionais
  let(:atributos_completos) do
    atributos_validos.merge(
      complemento: 'Apto 101',
      codigo_pais: 1058,
      pais: 'Brasil',
      telefone: '81999887766',
      email: 'contato@empresa.com.br'
    )
  end

  describe '#initialize' do
    context 'com atributos válidos' do
      it 'define todos os atributos corretamente' do
        endereco = described_class.new(atributos_completos)

        aggregate_failures do
          expect(endereco.logradouro).to eq('Rua das Flores')
          expect(endereco.numero).to eq('123')
          expect(endereco.complemento).to eq('Apto 101')
          expect(endereco.bairro).to eq('Centro')
          expect(endereco.codigo_municipio).to eq('2611606')
          expect(endereco.municipio).to eq('Recife')
          expect(endereco.uf).to eq('PE')
          expect(endereco.cep).to eq('50000000')
          expect(endereco.codigo_pais).to eq(1058)
          expect(endereco.pais).to eq('Brasil')
          expect(endereco.telefone).to eq('81999887766')
          expect(endereco.email).to eq('contato@empresa.com.br')
        end
      end
    end

    context 'com atributos mínimos' do
      it 'define apenas campos obrigatórios' do
        endereco = described_class.new(atributos_validos)

        aggregate_failures do
          expect(endereco.logradouro).to eq('Rua das Flores')
          expect(endereco.numero).to eq('123')
          expect(endereco.bairro).to eq('Centro')
          expect(endereco.codigo_municipio).to eq('2611606')
          expect(endereco.municipio).to eq('Recife')
          expect(endereco.uf).to eq('PE')
          expect(endereco.cep).to eq('50000000')
        end
      end
    end

    context 'com valores padrão' do
      it 'inicializa sem atributos definidos' do
        endereco = described_class.new

        expect(endereco.logradouro).to be_nil
        expect(endereco.numero).to be_nil
        expect(endereco.complemento).to be_nil
      end
    end
  end

  describe '#valido?' do
    it 'retorna true para endereço válido' do
      endereco = described_class.new(atributos_validos)
      expect(endereco).to be_valido
    end

    it 'retorna false para endereço inválido' do
      endereco = described_class.new
      expect(endereco).not_to be_valido
    end
  end

  describe '#erros' do
    context 'quando valida logradouro' do
      it 'exige logradouro' do
        endereco = described_class.new(atributos_validos.reject { |k, _| k == :logradouro })
        expect(endereco.erros).to include('Logradouro é obrigatório')
      end

      it 'trata string vazia como ausente' do
        endereco = described_class.new(atributos_validos.merge(logradouro: ''))
        expect(endereco.erros).to include('Logradouro é obrigatório')
      end

      it 'trata string com apenas espaços como ausente' do
        endereco = described_class.new(atributos_validos.merge(logradouro: '   '))
        expect(endereco.erros).to include('Logradouro é obrigatório')
      end

      it 'aceita logradouro válido' do
        endereco = described_class.new(atributos_validos)
        expect(endereco.erros).not_to include(match(/Logradouro/))
      end

      it 'aceita logradouro com um caractere (ER47 permite)' do
        endereco = described_class.new(atributos_validos.merge(logradouro: 'A'))
        expect(endereco.erros).not_to include(match(/Logradouro inválido/))
      end

      it 'aceita logradouro com 2 caracteres (ER47)' do
        endereco = described_class.new(atributos_validos.merge(logradouro: 'Av'))
        expect(endereco.erros).not_to include(match(/Logradouro inválido/))
      end
    end

    context 'quando valida numero' do
      it 'exige numero' do
        endereco = described_class.new(atributos_validos.reject { |k, _| k == :numero })
        expect(endereco.erros).to include('Número é obrigatório')
      end

      it 'aceita string vazia como ausente' do
        endereco = described_class.new(atributos_validos.merge(numero: ''))
        expect(endereco.erros).to include('Número é obrigatório')
      end

      it 'aceita "S/N" para endereços sem número' do
        endereco = described_class.new(atributos_validos.merge(numero: 'S/N'))
        expect(endereco.erros).not_to include(match(/Número/))
      end

      it 'aceita número numérico' do
        endereco = described_class.new(atributos_validos)
        expect(endereco.erros).not_to include(match(/Número/))
      end

      it 'aceita número com letra' do
        endereco = described_class.new(atributos_validos.merge(numero: '123-A'))
        expect(endereco.erros).not_to include(match(/Número/))
      end
    end

    context 'quando valida bairro' do
      it 'exige bairro' do
        endereco = described_class.new(atributos_validos.reject { |k, _| k == :bairro })
        expect(endereco.erros).to include('Bairro é obrigatório')
      end

      it 'aceita bairro válido' do
        endereco = described_class.new(atributos_validos)
        expect(endereco.erros).not_to include(match(/Bairro/))
      end

      it 'aceita bairro com um caractere (ER47 permite)' do
        endereco = described_class.new(atributos_validos.merge(bairro: 'C'))
        expect(endereco.erros).not_to include(match(/Bairro inválido/))
      end
    end

    context 'quando valida municipio' do
      it 'exige municipio' do
        endereco = described_class.new(atributos_validos.reject { |k, _| k == :municipio })
        expect(endereco.erros).to include('Município é obrigatório')
      end

      it 'aceita municipio válido' do
        endereco = described_class.new(atributos_validos)
        expect(endereco.erros).not_to include(match(/Município/))
      end

      it 'aceita município com um caractere (ER47 permite)' do
        endereco = described_class.new(atributos_validos.merge(municipio: 'R'))
        expect(endereco.erros).not_to include(match(/Município inválido/))
      end
    end

    context 'quando valida codigo_municipio' do
      it 'exige codigo_municipio' do
        endereco = described_class.new(atributos_validos.reject { |k, _| k == :codigo_municipio })
        expect(endereco.erros).to include('Código do município é obrigatório')
      end

      it 'aceita código IBGE de 7 dígitos (ER2)' do
        endereco = described_class.new(atributos_validos)
        expect(endereco.erros).not_to include(match(/Código do município/))
      end

      it 'rejeita código com menos de 7 dígitos (ER2)' do
        endereco = described_class.new(atributos_validos.merge(codigo_municipio: '123456'))
        expect(endereco.erros).to include(match(/Código do município inválido/))
      end

      it 'rejeita código com mais de 7 dígitos (ER2)' do
        endereco = described_class.new(atributos_validos.merge(codigo_municipio: '12345678'))
        expect(endereco.erros).to include(match(/Código do município inválido/))
      end
    end

    context 'quando valida uf' do
      it 'exige uf' do
        endereco = described_class.new(atributos_validos.reject { |k, _| k == :uf })
        expect(endereco.erros).to include('UF é obrigatório')
      end

      it 'aceita uf válida (D5)' do
        endereco = described_class.new(atributos_validos)
        expect(endereco.erros).not_to include(match(/UF/))
      end

      it 'rejeita uf inválida (D5)' do
        endereco = described_class.new(atributos_validos.merge(uf: 'XX'))
        expect(endereco.erros).to include(match(/UF inválido/))
      end
    end

    context 'quando valida cep' do
      it 'exige cep' do
        endereco = described_class.new(atributos_validos.reject { |k, _| k == :cep })
        expect(endereco.erros).to include('CEP é obrigatório')
      end

      it 'valida formato do CEP (8 dígitos) (ER67)' do
        endereco = described_class.new(atributos_validos.merge(cep: '5000'))
        expect(endereco.erros).to include(match(/CEP inválido/))
      end

      it 'aceita CEP sem formatação (8 dígitos)' do
        endereco = described_class.new(atributos_validos)
        expect(endereco.erros).not_to include(match(/CEP/))
      end

      it 'aceita CEP com formatação (remove não dígitos)' do
        endereco = described_class.new(atributos_validos.merge(cep: '50000-000'))
        expect(endereco.erros).not_to include(match(/CEP/))
      end

      it 'rejeita CEP com mais de 8 dígitos' do
        endereco = described_class.new(atributos_validos.merge(cep: '500000000'))
        expect(endereco.erros).to include(match(/CEP inválido/))
      end

      it 'rejeita CEP com menos de 8 dígitos' do
        endereco = described_class.new(atributos_validos.merge(cep: '5000000'))
        expect(endereco.erros).to include(match(/CEP inválido/))
      end
    end

    context 'com múltiplos erros' do
      it 'retorna todos os erros de validação' do
        endereco = described_class.new
        erros = endereco.erros

        aggregate_failures do
          expect(erros).to include('Logradouro é obrigatório')
          expect(erros).to include('Número é obrigatório')
          expect(erros).to include('Bairro é obrigatório')
          expect(erros).to include('Município é obrigatório')
          expect(erros).to include('Código do município é obrigatório')
          expect(erros).to include('UF é obrigatório')
          expect(erros).to include('CEP é obrigatório')
          expect(erros.length).to eq(7)
        end
      end
    end
  end

  describe 'campos opcionais' do
    context 'com complemento' do
      it 'aceita nil' do
        endereco = described_class.new(atributos_validos)
        expect(endereco).to be_valido
        expect(endereco.complemento).to be_nil
      end

      it 'aceita valor quando fornecido' do
        endereco = described_class.new(atributos_validos.merge(complemento: 'Apto 101'))
        expect(endereco).to be_valido
        expect(endereco.complemento).to eq('Apto 101')
      end

      it 'aceita complemento com um caractere (ER47 permite)' do
        endereco = described_class.new(atributos_validos.merge(complemento: 'A'))
        expect(endereco).to be_valido
      end
    end

    context 'com codigo_pais e pais' do
      it 'aceita valores padrão nil' do
        endereco = described_class.new(atributos_validos)
        expect(endereco).to be_valido
        expect(endereco.codigo_pais).to be_nil
        expect(endereco.pais).to be_nil
      end

      it 'aceita código BACEN do Brasil (1058)' do
        endereco = described_class.new(atributos_completos)
        expect(endereco.codigo_pais).to eq(1058)
        expect(endereco.pais).to eq('Brasil')
      end
    end

    context 'com telefone' do
      it 'aceita nil' do
        endereco = described_class.new(atributos_validos)
        expect(endereco).to be_valido
        expect(endereco.telefone).to be_nil
      end

      it 'aceita telefone válido (ER61)' do
        endereco = described_class.new(atributos_completos)
        expect(endereco).to be_valido
        expect(endereco.telefone).to eq('81999887766')
      end

      it 'aceita telefone com formatação (limpa antes de validar)' do
        endereco = described_class.new(atributos_validos.merge(telefone: '(81) 9 9988-7766'))
        expect(endereco).to be_valido
      end

      it 'rejeita telefone com menos de 7 dígitos (ER61)' do
        endereco = described_class.new(atributos_validos.merge(telefone: '123456'))
        expect(endereco.erros).to include(match(/Telefone inválido/))
      end

      it 'rejeita telefone com mais de 12 dígitos (ER61)' do
        endereco = described_class.new(atributos_validos.merge(telefone: '1234567890123'))
        expect(endereco.erros).to include(match(/Telefone inválido/))
      end
    end

    context 'com email' do
      it 'aceita nil' do
        endereco = described_class.new(atributos_validos)
        expect(endereco).to be_valido
        expect(endereco.email).to be_nil
      end

      it 'aceita email válido (ER72)' do
        endereco = described_class.new(atributos_validos.merge(email: 'contato@empresa.com.br'))
        expect(endereco).to be_valido
        expect(endereco.email).to eq('contato@empresa.com.br')
      end

      it 'rejeita email inválido sem @ (ER72)' do
        endereco = described_class.new(atributos_validos.merge(email: 'emailinvalido'))
        expect(endereco.erros).to include(match(/Email inválido/))
      end

      it 'rejeita email inválido sem domínio (ER72)' do
        endereco = described_class.new(atributos_validos.merge(email: 'usuario@'))
        expect(endereco.erros).to include(match(/Email inválido/))
      end
    end
  end

  describe 'cenários de integração' do
    context 'para endereço de emitente' do
      it 'cria endereço comercial completo' do
        atributos_comerciais = atributos_validos.merge(
          logradouro: 'Av. Empresarial',
          numero: '1000',
          complemento: 'Sala 101',
          bairro: 'Distrito Industrial',
          telefone: '8133334444',
          email: 'contato@empresa.com'
        )

        endereco = described_class.new(atributos_comerciais)
        expect(endereco).to be_valido
      end
    end

    context 'para endereço de destinatário pessoa física' do
      it 'cria endereço residencial' do
        endereco = described_class.new(atributos_validos)
        expect(endereco).to be_valido
      end
    end

    context 'para endereço rural sem número' do
      it 'aceita S/N para propriedades rurais' do
        atributos_rurais = atributos_validos.merge(
          logradouro: 'Sítio Boa Vista',
          numero: 'S/N',
          bairro: 'Zona Rural'
        )

        endereco = described_class.new(atributos_rurais)
        expect(endereco).to be_valido
      end
    end

    context 'com complemento detalhado' do
      it 'aceita informações complementares complexas' do
        atributos_detalhados = atributos_validos.merge(
          logradouro: 'Rua Principal',
          numero: '500',
          complemento: 'Edifício Torre Sul, Bloco B, Apto 1502',
          bairro: 'Boa Viagem',
          cep: '51020000'
        )

        endereco = described_class.new(atributos_detalhados)
        expect(endereco).to be_valido
        expect(endereco.complemento.length).to be > 20
      end
    end

    context 'para diferentes estados' do
      it 'aceita endereço de São Paulo' do
        atributos_sp = atributos_validos.merge(
          logradouro: 'Av. Paulista',
          numero: '1000',
          bairro: 'Bela Vista',
          codigo_municipio: '3550308',
          municipio: 'São Paulo',
          uf: 'SP',
          cep: '01310100'
        )

        endereco = described_class.new(atributos_sp)
        expect(endereco).to be_valido
        expect(endereco.uf).to eq('SP')
      end

      it 'aceita endereço do Rio de Janeiro' do
        atributos_rj = atributos_validos.merge(
          logradouro: 'Av. Atlântica',
          numero: '2000',
          bairro: 'Copacabana',
          codigo_municipio: '3304557',
          municipio: 'Rio de Janeiro',
          uf: 'RJ',
          cep: '22021001'
        )

        endereco = described_class.new(atributos_rj)
        expect(endereco).to be_valido
        expect(endereco.uf).to eq('RJ')
      end
    end

    context 'com código de município IBGE' do
      it 'valida código de 7 dígitos' do
        endereco = described_class.new(atributos_validos)
        expect(endereco.codigo_municipio).to eq('2611606')
        expect(endereco.codigo_municipio.length).to eq(7)
      end
    end
  end

  describe 'formatação de CEP' do
    context 'quando remove formatação' do
      it 'remove hífen do CEP' do
        endereco = described_class.new(atributos_validos.merge(cep: '50000-000'))
        expect(endereco).to be_valido
      end

      it 'remove pontos do CEP' do
        endereco = described_class.new(atributos_validos.merge(cep: '50.000-000'))
        expect(endereco).to be_valido
      end
    end
  end

  describe 'validação de strings vazias' do
    context 'com strings vazias' do
      it 'trata como valores ausentes' do
        atributos_vazios = {
          logradouro: '',
          numero: '',
          bairro: '',
          codigo_municipio: '',
          municipio: '',
          uf: '',
          cep: ''
        }

        endereco = described_class.new(atributos_vazios)

        aggregate_failures do
          expect(endereco.erros).to include('Logradouro é obrigatório')
          expect(endereco.erros).to include('Número é obrigatório')
          expect(endereco.erros).to include('Bairro é obrigatório')
          expect(endereco.erros).to include('Código do município é obrigatório')
          expect(endereco.erros).to include('Município é obrigatório')
          expect(endereco.erros).to include('UF é obrigatório')
          expect(endereco.erros).to include('CEP é obrigatório')
        end
      end
    end

    context 'com strings contendo apenas espaços' do
      it 'trata como valores ausentes' do
        atributos_espacos = {
          logradouro: '   ',
          numero: '   ',
          bairro: '   ',
          codigo_municipio: '   ',
          municipio: '   ',
          uf: '   ',
          cep: '   '
        }

        endereco = described_class.new(atributos_espacos)
        expect(endereco.erros.length).to be >= 7
      end
    end
  end

  describe 'casos extremos' do
    context 'com nomes muito longos' do
      it 'aceita logradouro extenso' do
        atributos_extensos = atributos_validos.merge(
          logradouro: 'Avenida Engenheiro Domingos Ferreira da Silva'
        )

        endereco = described_class.new(atributos_extensos)
        expect(endereco).to be_valido
      end

      it 'aceita bairro com nome composto' do
        atributos_composto = atributos_validos.merge(
          bairro: 'Jardim São José dos Campos'
        )

        endereco = described_class.new(atributos_composto)
        expect(endereco).to be_valido
      end

      it 'aceita município com nome composto' do
        atributos_municipio_composto = atributos_validos.merge(
          codigo_municipio: '2505501',
          municipio: 'Governador Dix-Sept Rosado',
          uf: 'RN',
          cep: '59500000'
        )

        endereco = described_class.new(atributos_municipio_composto)
        expect(endereco).to be_valido
      end
    end

    context 'com números especiais' do
      it 'aceita "0" como número' do
        endereco = described_class.new(atributos_validos.merge(numero: '0'))
        expect(endereco).to be_valido
      end

      it 'aceita número com KM' do
        atributos_km = atributos_validos.merge(
          logradouro: 'BR-232',
          numero: 'KM 14',
          bairro: 'Zona Rural'
        )

        endereco = described_class.new(atributos_km)
        expect(endereco).to be_valido
      end
    end

    context 'com CEP de zeros' do
      it 'aceita CEP com zeros à esquerda' do
        atributos_brasilia = atributos_validos.merge(
          logradouro: 'Praça dos Três Poderes',
          numero: 'S/N',
          bairro: 'Zona Cívico-Administrativa',
          codigo_municipio: '5300108',
          municipio: 'Brasília',
          uf: 'DF',
          cep: '01310924'
        )

        endereco = described_class.new(atributos_brasilia)
        expect(endereco).to be_valido
      end
    end
  end

  describe 'compatibilidade com Emitente e Destinatario' do
    it 'funciona como endereço de emitente' do
      atributos_emitente = atributos_validos.merge(
        logradouro: 'Rua Comercial',
        numero: '1000',
        complemento: 'Sala 5',
        telefone: '8133334444',
        email: 'contato@empresa.com'
      )

      endereco = described_class.new(atributos_emitente)
      expect(endereco).to be_valido
      expect(endereco.logradouro).to eq('Rua Comercial')
    end

    it 'funciona como endereço de destinatário com país' do
      atributos_dest = atributos_validos.merge(
        logradouro: 'Rua Residencial',
        bairro: 'Jardim',
        codigo_pais: 1058,
        pais: 'Brasil'
      )

      endereco = described_class.new(atributos_dest)
      expect(endereco).to be_valido
      expect(endereco.codigo_pais).to eq(1058)
      expect(endereco.pais).to eq('Brasil')
    end
  end

  describe 'todos os estados brasileiros' do
    %w[AC AL AP AM BA CE DF ES GO MA MT MS MG PA PB PR PE PI RJ RN RS RO RR SC SP SE TO].each do |uf|
      it "aceita UF #{uf}" do
        endereco = described_class.new(atributos_validos.merge(uf: uf))
        expect(endereco).to be_valido
        expect(endereco.uf).to eq(uf)
      end
    end
  end

  describe 'integração com hash' do
    it 'inicializa a partir de hash' do
      endereco = described_class.new(atributos_completos)

      expect(endereco.logradouro).to eq('Rua das Flores')
      expect(endereco.numero).to eq('123')
      expect(endereco.complemento).to eq('Apto 101')
    end

    it 'ignora chaves desconhecidas no hash' do
      atributos_com_extra = atributos_validos.merge(campo_invalido: 'valor ignorado')
      expect { described_class.new(atributos_com_extra) }.not_to raise_error
    end
  end
end
