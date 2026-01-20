# frozen_string_literal: true

require 'spec_helper'
require 'rqrcode'

RSpec.describe Nfcom::Builder::Qrcode do
  let(:valid_chave) { '26220512345678000100620010000000011234567890' }
  let(:qr) { described_class.new(valid_chave, :homologacao) }

  describe '#initialize' do
    it 'raises error if chave is nil' do
      expect { described_class.new(nil, :producao) }
        .to raise_error(ArgumentError, /Chave de acesso não pode ser vazia/)
    end

    it 'raises error if chave is empty' do
      expect { described_class.new('  ', :producao) }
        .to raise_error(ArgumentError, /Chave de acesso não pode ser vazia/)
    end

    it 'raises error if chave is invalid format' do
      expect { described_class.new('invalid_chave', :producao) }
        .to raise_error(ArgumentError, /Chave de acesso inválida/)
    end

    it 'raises error if ambiente is invalid' do
      expect { described_class.new(valid_chave, :staging) }
        .to raise_error(ArgumentError, /Ambiente deve ser :producao ou :homologacao/)
    end
  end

  describe '#gerar_url' do
    it 'returns correct URL for homologacao' do
      qr = described_class.new(valid_chave, :homologacao)
      expected_url = "https://dfe-portal.svrs.rs.gov.br/nfcom/qrcode?chNFCom=#{valid_chave}&tpAmb=2"
      expect(qr.gerar_url).to eq(expected_url)
    end

    it 'returns correct URL for producao' do
      qr = described_class.new(valid_chave, :producao)
      expected_url = "https://dfe-portal.svrs.rs.gov.br/nfcom/qrcode?chNFCom=#{valid_chave}&tpAmb=1"
      expect(qr.gerar_url).to eq(expected_url)
    end
  end

  describe '#gerar_qrcode_svg' do
    it 'returns a valid SVG string' do
      svg = qr.gerar_qrcode_svg
      expect(svg).to start_with('<?xml')
      expect(svg).to include('<svg')
      expect(svg).to include('</svg>')
    end
  end
end
