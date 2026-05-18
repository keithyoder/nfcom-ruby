# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Nfcom::Models::Destinatario do
  let(:endereco_valido) do
    {
      logradouro: 'Rua das Flores',
      numero: '123',
      bairro: 'Centro',
      municipio: 'Recife',
      uf: 'PE',
      cep: '50000-000',
      codigo_municipio: '2611606'
    }
  end

  let(:atributos_pf) do
    {
      cpf: '529.982.247-25',
      razao_social: 'João da Silva',
      endereco: endereco_valido
    }
  end

  let(:atributos_pj) do
    {
      cnpj: '00000000000191',
      razao_social: 'Empresa LTDA',
      inscricao_estadual: '000000000',
      endereco: endereco_valido
    }
  end

  describe '#initialize' do
    it 'define tipo_assinante padrão como :residencial' do
      dest = described_class.new(atributos_pf)
      expect(dest.tipo_assinante).to eq(:residencial)
    end

    it 'cria um Endereco a partir de hash' do
      dest = described_class.new(atributos_pf)
      expect(dest.endereco).to be_a(Nfcom::Models::Endereco)
      expect(dest.endereco.logradouro).to eq('Rua das Flores')
    end
  end

  describe '#tipo_assinante_codigo' do
    subject(:dest) { described_class.new(atributos_pf) }

    {
      comercial: 1,
      industrial: 2,
      residencial: 3,
      produtor_rural: 4,
      orgao_publico: 5,
      prestador_servico: 6,
      concessionaria: 7,
      outros: 99
    }.each do |tipo, codigo|
      it "retorna #{codigo} para #{tipo}" do
        dest.tipo_assinante = tipo
        expect(dest.tipo_assinante_codigo).to eq(codigo)
      end
    end

    it 'retorna 3 para tipo desconhecido' do
      dest.tipo_assinante = :desconhecido
      expect(dest.tipo_assinante_codigo).to eq(3)
    end
  end

  describe '#pessoa_fisica?' do
    it 'retorna true quando CPF preenchido' do
      expect(described_class.new(atributos_pf).pessoa_fisica?).to be true
    end

    it 'retorna false quando apenas CNPJ preenchido' do
      expect(described_class.new(atributos_pj).pessoa_fisica?).to be false
    end
  end

  describe '#pessoa_juridica?' do
    it 'retorna true quando CNPJ preenchido' do
      expect(described_class.new(atributos_pj).pessoa_juridica?).to be true
    end

    it 'retorna false quando apenas CPF preenchido' do
      expect(described_class.new(atributos_pf).pessoa_juridica?).to be false
    end
  end

  describe '#valido?' do
    it 'retorna true para pessoa física válida' do
      expect(described_class.new(atributos_pf).valido?).to be true
    end

    it 'retorna true para pessoa jurídica válida' do
      expect(described_class.new(atributos_pj).valido?).to be true
    end

    it 'retorna false sem documento' do
      dest = described_class.new(atributos_pf.merge(cpf: nil))
      expect(dest.valido?).to be false
    end
  end

  describe '#erros' do
    context 'com atributos válidos' do
      it 'retorna array vazio para PF' do
        expect(described_class.new(atributos_pf).erros).to be_empty
      end

      it 'retorna array vazio para PJ' do
        expect(described_class.new(atributos_pj).erros).to be_empty
      end
    end

    context 'sem documento' do
      it 'exige CNPJ ou CPF' do
        dest = described_class.new(atributos_pf.merge(cpf: nil))
        expect(dest.erros).to include('CNPJ ou CPF é obrigatório')
      end
    end

    context 'com CPF inválido' do
      it 'inclui erro de CPF inválido' do
        dest = described_class.new(atributos_pf.merge(cpf: '111.111.111-11'))
        expect(dest.erros).to include('CPF inválido')
      end

      it 'rejeita CPF com todos os dígitos iguais' do
        dest = described_class.new(atributos_pf.merge(cpf: '00000000000'))
        expect(dest.erros).to include('CPF inválido')
      end
    end

    context 'com CNPJ inválido' do
      it 'inclui erro de CNPJ inválido' do
        dest = described_class.new(atributos_pj.merge(cnpj: '12345678000100'))
        expect(dest.erros).to include('CNPJ inválido')
      end
    end

    context 'sem razão social' do
      it 'inclui erro de obrigatoriedade' do
        dest = described_class.new(atributos_pf.merge(razao_social: ''))
        expect(dest.erros).to include('Razão social é obrigatória')
      end
    end

    context 'com email inválido' do
      it 'inclui erro de formato' do
        dest = described_class.new(atributos_pf.merge(email: 'email-invalido'))
        expect(dest.erros).to include(match(/Email/))
      end
    end

    context 'com email válido' do
      it 'não inclui erro de email' do
        dest = described_class.new(atributos_pf.merge(email: 'joao@provedor.com.br'))
        expect(dest.erros).not_to include(match(/Email/))
      end
    end

    context 'com endereço inválido' do
      it 'inclui erros prefixados com Endereço' do
        dest = described_class.new(atributos_pf)
        dest.endereco.logradouro = nil
        expect(dest.erros).to include(match(/^Endereço:/))
      end
    end

    context 'com múltiplos erros' do
      it 'retorna todos os erros' do
        dest = described_class.new(cpf: nil, cnpj: nil, razao_social: '', endereco: endereco_valido)

        aggregate_failures do
          expect(dest.erros).to include('CNPJ ou CPF é obrigatório')
          expect(dest.erros).to include('Razão social é obrigatória')
        end
      end
    end
  end
end
