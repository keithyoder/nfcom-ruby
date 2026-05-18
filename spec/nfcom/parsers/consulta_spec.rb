# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Nfcom::Parsers::Consulta do
  subject(:parser) { described_class.new(xml) }

  describe '#parse' do
    context 'quando nota autorizada (cStat 100)' do
      let(:xml) do
        <<~XML
          <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
            <soap:Body>
              <nfcomResultMsg xmlns="http://www.portalfiscal.inf.br/nfcom/wsdl/NFComConsulta">
                <retConsSitNFCom xmlns="http://www.portalfiscal.inf.br/nfcom" versao="1.00">
                  <cStat>100</cStat>
                  <xMotivo>Autorizado o uso da NFCom</xMotivo>
                  <protNFCom versao="1.00">
                    <infProt>
                      <nProt>3262600017883755</nProt>
                      <dhRecbto>2026-01-29T22:18:31-03:00</dhRecbto>
                    </infProt>
                  </protNFCom>
                </retConsSitNFCom>
              </nfcomResultMsg>
            </soap:Body>
          </soap:Envelope>
        XML
      end

      it 'retorna situação autorizada com protocolo' do
        result = parser.parse

        aggregate_failures do
          expect(result[:codigo]).to eq('100')
          expect(result[:motivo]).to eq('Autorizado o uso da NFCom')
          expect(result[:situacao]).to eq('Autorizada')
          expect(result[:protocolo]).to eq('3262600017883755')
          expect(result[:data_autorizacao]).to eq('2026-01-29T22:18:31-03:00')
        end
      end
    end

    context 'quando nota cancelada (cStat 101)' do
      let(:xml) do
        <<~XML
          <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
            <soap:Body>
              <nfcomResultMsg xmlns="http://www.portalfiscal.inf.br/nfcom/wsdl/NFComConsulta">
                <retConsSitNFCom xmlns="http://www.portalfiscal.inf.br/nfcom" versao="1.00">
                  <cStat>101</cStat>
                  <xMotivo>Cancelamento de NFCom homologado</xMotivo>
                </retConsSitNFCom>
              </nfcomResultMsg>
            </soap:Body>
          </soap:Envelope>
        XML
      end

      it 'retorna situação cancelada sem protocolo' do
        result = parser.parse

        aggregate_failures do
          expect(result[:situacao]).to eq('Cancelada')
          expect(result[:protocolo]).to be_nil
        end
      end
    end

    context 'quando nota denegada (cStat 110)' do
      let(:xml) do
        <<~XML
          <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
            <soap:Body>
              <nfcomResultMsg xmlns="http://www.portalfiscal.inf.br/nfcom/wsdl/NFComConsulta">
                <retConsSitNFCom xmlns="http://www.portalfiscal.inf.br/nfcom" versao="1.00">
                  <cStat>110</cStat>
                  <xMotivo>Uso Denegado</xMotivo>
                </retConsSitNFCom>
              </nfcomResultMsg>
            </soap:Body>
          </soap:Envelope>
        XML
      end

      it 'retorna situação denegada' do
        expect(parser.parse[:situacao]).to eq('Denegada')
      end
    end

    context 'quando chave não encontrada (cStat desconhecido)' do
      let(:xml) do
        <<~XML
          <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
            <soap:Body>
              <nfcomResultMsg xmlns="http://www.portalfiscal.inf.br/nfcom/wsdl/NFComConsulta">
                <retConsSitNFCom xmlns="http://www.portalfiscal.inf.br/nfcom" versao="1.00">
                  <cStat>217</cStat>
                  <xMotivo>Rejeição: NFCom não encontrada</xMotivo>
                </retConsSitNFCom>
              </nfcomResultMsg>
            </soap:Body>
          </soap:Envelope>
        XML
      end

      it 'retorna situação desconhecida' do
        expect(parser.parse[:situacao]).to eq('Desconhecida')
      end
    end

    context 'quando resposta não contém retConsSitNFCom' do
      let(:xml) { '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"><soap:Body/></soap:Envelope>' }

      it 'lança SefazError' do
        expect { parser.parse }.to raise_error(Nfcom::Errors::SefazError, /inválida/)
      end
    end
  end
end
