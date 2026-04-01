# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Nfcom::Parsers::Inutilizacao do
  subject(:parser) { described_class.new(xml) }

  describe '#parse' do
    context 'quando inutilização homologada (cStat 102)' do
      let(:xml) do
        <<~XML
          <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
            <soap:Body>
              <nfcomResultMsg xmlns="http://www.portalfiscal.inf.br/nfcom/wsdl/nfcomInutilizacao">
                <retInutNFCom xmlns="http://www.portalfiscal.inf.br/nfcom" versao="1.00">
                  <infInut>
                    <cStat>102</cStat>
                    <xMotivo>Inutilização de número homologado</xMotivo>
                    <nProt>3262600017883755</nProt>
                  </infInut>
                </retInutNFCom>
              </nfcomResultMsg>
            </soap:Body>
          </soap:Envelope>
        XML
      end

      it 'retorna inutilizada true com protocolo' do
        result = parser.parse

        aggregate_failures do
          expect(result[:inutilizada]).to be true
          expect(result[:codigo]).to eq('102')
          expect(result[:motivo]).to eq('Inutilização de número homologado')
          expect(result[:protocolo]).to eq('3262600017883755')
        end
      end
    end

    context 'quando rejeitada (cStat != 102)' do
      let(:xml) do
        <<~XML
          <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
            <soap:Body>
              <nfcomResultMsg xmlns="http://www.portalfiscal.inf.br/nfcom/wsdl/nfcomInutilizacao">
                <retInutNFCom xmlns="http://www.portalfiscal.inf.br/nfcom" versao="1.00">
                  <infInut>
                    <cStat>532</cStat>
                    <xMotivo>Rejeição: Número NFCom já utilizado</xMotivo>
                  </infInut>
                </retInutNFCom>
              </nfcomResultMsg>
            </soap:Body>
          </soap:Envelope>
        XML
      end

      it 'retorna inutilizada false sem protocolo' do
        result = parser.parse

        aggregate_failures do
          expect(result[:inutilizada]).to be false
          expect(result[:codigo]).to eq('532')
          expect(result[:protocolo]).to be_nil
        end
      end
    end

    context 'quando resposta não contém retInutNFCom' do
      let(:xml) { '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"><soap:Body/></soap:Envelope>' }

      it 'lança SefazError' do
        expect { parser.parse }.to raise_error(Nfcom::Errors::SefazError, /inválida/)
      end
    end
  end
end
