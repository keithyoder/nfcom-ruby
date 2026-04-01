# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Nfcom::Webservices::Status do
  subject(:webservice) { described_class.new(configuration) }

  include_context 'com certificado mockado'
  include_context 'com configuração padrão'

  let(:soap_action) { 'http://www.portalfiscal.inf.br/nfcom/wsdl/NFComStatusServico/nfcomStatusServicoNF' }
  let(:url) { 'https://nfcom.svrs.rs.gov.br/WS/NFComStatusServico/NFComStatusServico.asmx' }
  let(:url_homologacao) { 'https://nfcom-homologacao.svrs.rs.gov.br/WS/NFComStatusServico/NFComStatusServico.asmx' }

  let(:resposta_sucesso) do
    <<~XML
      <?xml version="1.0" encoding="utf-8"?>
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

  describe '#verificar' do
    context 'quando a comunicação é bem-sucedida' do
      before do
        stub_request(:post, url)
          .with(headers: { 'Content-Type' => %r{NFComStatusServico/nfcomStatusServicoNF} })
          .to_return(status: 200, body: resposta_sucesso)
      end

      it 'retorna o XML bruto da resposta SOAP' do
        expect(webservice.verificar).to include('retConsStatServNFCom')
      end

      it 'envia o envelope com o body correto' do
        webservice.verificar

        expect(WebMock).to(have_requested(:post, url).with do |req|
          aggregate_failures do
            expect(req.body).to include('nfcomDadosMsg')
            expect(req.body).to include('consStatServNFCom')
            expect(req.body).to include('xServ>STATUS<')
            expect(req.body).to include('tpAmb>1<')
          end
        end)
      end

      it 'envia a SOAPAction correta' do
        webservice.verificar

        expect(WebMock).to have_requested(:post, url).with(
          headers: { 'Content-Type' => /#{Regexp.escape(soap_action)}/ }
        )
      end
    end

    context 'quando a URL de status não está configurada' do
      before { allow(configuration).to receive(:webservice_url).with(:status).and_return(nil) }

      it 'lança ConfigurationError' do
        expect { webservice.verificar }.to raise_error(
          Nfcom::Errors::ConfigurationError,
          /URL de status não configurada/
        )
      end
    end

    context 'quando a SEFAZ retorna erro HTTP' do
      before { stub_request(:post, url).to_return(status: 500, body: 'Internal Server Error') }

      it 'lança SefazError' do
        expect { webservice.verificar }.to raise_error(Nfcom::Errors::SefazError, /Erro HTTP 500/)
      end
    end

    context 'quando ocorre timeout' do
      before { stub_request(:post, url).to_timeout }

      it 'lança TimeoutError' do
        expect { webservice.verificar }.to raise_error(Nfcom::Errors::TimeoutError)
      end
    end
  end

  describe '#build_status_body (via verificar)' do
    before do
      stub_request(:post, url).to_return(status: 200, body: resposta_sucesso)
    end

    it 'inclui o namespace correto do serviço' do
      webservice.verificar

      expect(WebMock).to(have_requested(:post, url).with do |req|
        expect(req.body).to include('xmlns="http://www.portalfiscal.inf.br/nfcom/wsdl/NFComStatusServico"')
      end)
    end

    it 'inclui versao 1.00 no consStatServNFCom' do
      webservice.verificar

      expect(WebMock).to(have_requested(:post, url).with do |req|
        expect(req.body).to include('versao="1.00"')
      end)
    end

    context 'dado ambiente de homologação' do
      before do
        configuration.ambiente = :homologacao
        stub_request(:post, url_homologacao).to_return(status: 200, body: resposta_sucesso)
      end

      it 'envia tpAmb 2' do
        webservice.verificar

        expect(WebMock).to(have_requested(:post, url_homologacao).with do |req|
          expect(req.body).to include('tpAmb>2<')
        end)
      end
    end
  end
end
