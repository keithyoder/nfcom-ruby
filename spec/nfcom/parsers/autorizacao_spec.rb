# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Nfcom::Parsers::Autorizacao do
  subject(:parser) { described_class.new(xml) }

  describe '#parse' do
    context 'quando autorizada (cStat 100)' do
      let(:xml) do
        <<~XML
          <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
            <soap:Body>
              <nfcomResultMsg xmlns="http://www.portalfiscal.inf.br/nfcom/wsdl/NFComRecepcao">
                <retNFCom xmlns="http://www.portalfiscal.inf.br/nfcom">
                  <cStat>100</cStat>
                  <xMotivo>Autorizado o uso da NFCom</xMotivo>
                  <protNFCom>
                    <nProt>3262600017883755</nProt>
                    <chNFCom>26260107159053000107620010000031981083465102</chNFCom>
                    <dhRecbto>2026-01-29T22:18:31-03:00</dhRecbto>
                  </protNFCom>
                </retNFCom>
              </nfcomResultMsg>
            </soap:Body>
          </soap:Envelope>
        XML
      end

      it 'retorna hash de sucesso com dados do protocolo' do
        result = parser.parse

        aggregate_failures do
          expect(result[:autorizada]).to be true
          expect(result[:protocolo]).to eq('3262600017883755')
          expect(result[:chave]).to eq('26260107159053000107620010000031981083465102')
          expect(result[:data_autorizacao]).to eq('2026-01-29T22:18:31-03:00')
          expect(result[:mensagem]).to eq('Autorizado o uso da NFCom')
        end
      end
    end

    context 'quando rejeitada (cStat != 100)' do
      let(:xml) do
        <<~XML
          <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
            <soap:Body>
              <nfcomResultMsg xmlns="http://www.portalfiscal.inf.br/nfcom/wsdl/NFComRecepcao">
                <retNFCom xmlns="http://www.portalfiscal.inf.br/nfcom">
                  <cStat>539</cStat>
                  <xMotivo>Duplicidade de NFCom</xMotivo>
                </retNFCom>
              </nfcomResultMsg>
            </soap:Body>
          </soap:Envelope>
        XML
      end

      it 'lança NotaRejeitada com código e motivo' do
        expect { parser.parse }.to raise_error(Nfcom::Errors::NotaRejeitada) do |e|
          expect(e.codigo).to eq('539')
          expect(e.motivo).to eq('Duplicidade de NFCom')
        end
      end
    end

    context 'quando resposta não contém retNFCom' do
      let(:xml) { '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"><soap:Body/></soap:Envelope>' }

      it 'lança NotaRejeitada com código 000' do
        expect { parser.parse }.to raise_error(Nfcom::Errors::NotaRejeitada) do |e|
          expect(e.codigo).to eq('000')
        end
      end
    end
  end
end
