# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Nfcom::Parsers::Status do
  subject(:parser) { described_class.new(xml) }

  describe '#parse' do
    context 'quando serviço em operação (cStat 107)' do
      let(:xml) do
        <<~XML
          <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
            <soap:Body>
              <nfcomResultMsg xmlns="http://www.portalfiscal.inf.br/nfcom/wsdl/NFComStatusServico">
                <retConsStatServNFCom xmlns="http://www.portalfiscal.inf.br/nfcom" versao="1.00">
                  <tpAmb>1</tpAmb>
                  <verAplic>RS20240708154558</verAplic>
                  <cStat>107</cStat>
                  <xMotivo>Serviço em Operação</xMotivo>
                  <cUF>26</cUF>
                  <dhRecbto>2026-04-01T09:53:30-03:00</dhRecbto>
                  <tMed>1</tMed>
                </retConsStatServNFCom>
              </nfcomResultMsg>
            </soap:Body>
          </soap:Envelope>
        XML
      end

      it 'retorna online true com dados do status' do
        result = parser.parse

        aggregate_failures do
          expect(result[:online]).to be true
          expect(result[:codigo]).to eq('107')
          expect(result[:motivo]).to eq('Serviço em Operação')
          expect(result[:tempo_medio]).to eq('1')
          expect(result[:data_hora]).to eq('2026-04-01T09:53:30-03:00')
        end
      end
    end

    context 'quando serviço fora de operação (cStat != 107)' do
      let(:xml) do
        <<~XML
          <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
            <soap:Body>
              <nfcomResultMsg xmlns="http://www.portalfiscal.inf.br/nfcom/wsdl/NFComStatusServico">
                <retConsStatServNFCom xmlns="http://www.portalfiscal.inf.br/nfcom" versao="1.00">
                  <cStat>108</cStat>
                  <xMotivo>Serviço Paralisado Momentaneamente</xMotivo>
                  <dhRecbto>2026-04-01T09:53:30-03:00</dhRecbto>
                  <tMed>0</tMed>
                </retConsStatServNFCom>
              </nfcomResultMsg>
            </soap:Body>
          </soap:Envelope>
        XML
      end

      it 'retorna online false' do
        result = parser.parse

        aggregate_failures do
          expect(result[:online]).to be false
          expect(result[:codigo]).to eq('108')
          expect(result[:motivo]).to eq('Serviço Paralisado Momentaneamente')
        end
      end
    end

    context 'quando resposta não contém retConsStatServNFCom' do
      let(:xml) { '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"><soap:Body/></soap:Envelope>' }

      it 'lança SefazError' do
        expect { parser.parse }.to raise_error(Nfcom::Errors::SefazError, /inválida/)
      end
    end
  end
end
