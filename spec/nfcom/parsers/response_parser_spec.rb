# frozen_string_literal: true

require 'spec_helper'
require 'net/http'

RSpec.describe Nfcom::Parsers::ResponseParser do
  subject(:parser) { described_class.new(http_response) }

  let(:http_response) { instance_double(Net::HTTPResponse, body: xml) }

  describe '#parse_autorizacao' do
    context 'when authorized (cStat = 100)' do
      let(:xml) do
        <<~XML
          <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
            <soap:Body>
              <retNFCom xmlns="http://www.portalfiscal.inf.br/nfcom">
                <cStat>100</cStat>
                <xMotivo>Autorizado o uso da NFCom</xMotivo>
                <protNFCom>
                  <nProt>123456789</nProt>
                  <chNFCom>ABC123</chNFCom>
                  <dhRecbto>2026-01-29T12:00:00</dhRecbto>
                </protNFCom>
              </retNFCom>
            </soap:Body>
          </soap:Envelope>
        XML
      end

      it 'returns a success hash' do
        result = parser.parse_autorizacao

        expect(result).to include(
          autorizada: true,
          protocolo: '123456789',
          chave: 'ABC123'
        )
      end
    end

    context 'when rejected (cStat != 100)' do
      let(:xml) do
        <<~XML
          <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
            <soap:Body>
              <retNFCom xmlns="http://www.portalfiscal.inf.br/nfcom">
                <cStat>539</cStat>
                <xMotivo>Duplicidade de NFCom</xMotivo>
              </retNFCom>
            </soap:Body>
          </soap:Envelope>
        XML
      end

      it 'raises NotaRejeitada with code and reason' do
        expect do
          parser.parse_autorizacao
        end.to raise_error(Nfcom::Errors::NotaRejeitada) { |e|
          expect(e.codigo).to eq('539')
          expect(e.motivo).to eq('Duplicidade de NFCom')
        }
      end
    end

    context 'when response is invalid XML' do
      let(:xml) { '<invalid />' }

      it 'raises NotaRejeitada with code 000' do
        expect do
          parser.parse_autorizacao
        end.to raise_error(Nfcom::Errors::NotaRejeitada) { |e|
          expect(e.codigo).to eq('000')
        }
      end
    end
  end
end
