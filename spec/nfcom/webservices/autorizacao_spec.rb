# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Nfcom::Webservices::Autorizacao do
  subject(:webservice) { described_class.new(configuration) }

  include_context 'com certificado mockado'
  include_context 'com configuração padrão'

  let(:url) { 'https://nfcom.svrs.rs.gov.br/WS/NFComRecepcao/NFComRecepcao.asmx' }
  let(:xml_assinado) { '<NFCom xmlns="http://www.portalfiscal.inf.br/nfcom"><infNFCom/></NFCom>' }

  let(:resposta_sucesso) do
    <<~XML
      <?xml version="1.0" encoding="utf-8"?>
      <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
        <soap:Body>
          <nfcomResultMsg xmlns="http://www.portalfiscal.inf.br/nfcom/wsdl/NFComRecepcao">
            <retNFCom xmlns="http://www.portalfiscal.inf.br/nfcom" versao="1.00">
              <cStat>100</cStat>
              <xMotivo>Autorizado o uso da NFCom</xMotivo>
              <protNFCom versao="1.00">
                <infProt>
                  <nProt>3262600017883755</nProt>
                  <chNFCom>26260107159053000107620010000031981083465102</chNFCom>
                  <dhRecbto>2026-01-29T22:18:31-03:00</dhRecbto>
                </infProt>
              </protNFCom>
            </retNFCom>
          </nfcomResultMsg>
        </soap:Body>
      </soap:Envelope>
    XML
  end

  describe '#enviar' do
    context 'quando a comunicação é bem-sucedida' do
      before do
        stub_request(:post, url)
          .with(headers: { 'Content-Type' => %r{NFComRecepcao/nfcomRecepcao} })
          .to_return(status: 200, body: resposta_sucesso)
      end

      it 'retorna o XML bruto da resposta SOAP' do
        expect(webservice.enviar(xml_assinado)).to include('retNFCom')
      end

      it 'envia o envelope com o body correto' do
        webservice.enviar(xml_assinado)

        expect(WebMock).to(have_requested(:post, url).with do |req|
          aggregate_failures do
            expect(req.body).to include('nfcomDadosMsg')
            expect(req.body).to include('xmlns="http://www.portalfiscal.inf.br/nfcom/wsdl/NFComRecepcao"')
          end
        end)
      end

      it 'comprime o XML antes de enviar' do
        webservice.enviar(xml_assinado)

        expect(WebMock).to(have_requested(:post, url).with do |req|
          # O body deve conter base64 comprimido, não XML legível
          expect(req.body).not_to include('<NFCom')
        end)
      end
    end

    context 'quando a URL de recepção não está configurada' do
      before { allow(configuration).to receive(:webservice_url).with(:recepcao).and_return(nil) }

      it 'lança ConfigurationError' do
        expect { webservice.enviar(xml_assinado) }.to raise_error(
          Nfcom::Errors::ConfigurationError,
          /URL de recepção não configurada/
        )
      end
    end

    context 'quando a SEFAZ retorna erro HTTP' do
      before { stub_request(:post, url).to_return(status: 500, body: 'Internal Server Error') }

      it 'lança SefazError' do
        expect { webservice.enviar(xml_assinado) }.to raise_error(
          Nfcom::Errors::SefazError,
          /Erro HTTP 500/
        )
      end
    end

    context 'quando ocorre timeout' do
      before { stub_request(:post, url).to_timeout }

      it 'lança TimeoutError' do
        expect { webservice.enviar(xml_assinado) }.to raise_error(Nfcom::Errors::TimeoutError)
      end
    end
  end
end
