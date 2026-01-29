# frozen_string_literal: true

RSpec.describe Nfcom::Models::Fatura::CodigoDeBarras do
  subject(:codigo) { described_class.new(valor) }

  let(:valor) do
    '23793381286000000099901234567890123456789012'
  end

  describe '#formato' do
    it 'detects 44-digit barcode format' do
      expect(codigo.formato).to eq(:formato_44)
    end
  end

  describe '#linha_digitavel' do
    it 'generates a valid linha digitavel for 44-digit code' do
      linha = codigo.linha_digitavel

      expect(linha).to be_a(String)
      expect(linha).to include('.')
      expect(linha.split.size).to eq(5)
    end
  end

  context 'with invalid barcode length' do
    let(:valor) { '123' }

    it 'raises an error' do
      expect { codigo.linha_digitavel }
        .to raise_error(ArgumentError)
    end
  end
end
