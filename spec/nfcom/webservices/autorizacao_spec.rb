# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Nfcom::Webservices::Autorizacao do
  subject(:service) { described_class.new(configuration) }

  let(:logger) { instance_double(Logger, debug: nil, error: nil, warn: nil) }

  let(:configuration) do
    instance_double(
      Nfcom::Configuration,
      estado: 'SP',
      timeout: 5,
      log_level: :info,
      logger: logger,
      certificado_path: '/tmp/cert.pfx',
      certificado_senha: 'secret',
      webservice_url: webservice_url
    )
  end

  let(:webservice_url) { 'https://sefaz.sp.gov.br/nfcom' }
  let(:xml_assinado)   { '<xml>assinado</xml>' }
  let(:http)           { instance_double(Net::HTTP) }

  let(:soap_response_xml) do
    File.read(File.join(__dir__, '../../fixtures/responses/nfcom_100.xml'))
  end

  before do
    stub_certificate
    stub_xml_processing
    stub_http_client
  end

  describe '#enviar' do
    context 'when configuration is valid' do
      let(:soap_response_body) do
        <<~XML
          <?xml version="1.0" encoding="utf-8"?>
          <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
            <soap:Body>
              <nfcomResultMsg xmlns="http://www.portalfiscal.inf.br/nfcom/wsdl/NFComRecepcao">
                <retNFCom xmlns="http://www.portalfiscal.inf.br/nfcom" versao="1.00">
                  <cStat>100</cStat>
                  <xMotivo>Autorizado</xMotivo>
                  <protNFCom versao="1.00">
                    <infProt>
                      <nProt>123456</nProt>
                      <chNFCom>26260107159053000107620010000000000000000</chNFCom>
                      <dhRecbto>2026-01-16T09:00:00-03:00</dhRecbto>
                    </infProt>
                  </protNFCom>
                </retNFCom>
              </nfcomResultMsg>
            </soap:Body>
          </soap:Envelope>
        XML
      end

      it 'returns the full SOAP response as a Nokogiri::XML::Document' do
        http_response = http_success(body: soap_response_xml)
        allow(http).to receive(:request).and_return(http_response)

        result = service.enviar(xml_assinado)
        ns = { nfcom: 'http://www.portalfiscal.inf.br/nfcom' }

        expect(result).to be_a(Nokogiri::XML::Document)
        expect(result.at_xpath('//nfcom:cStat', ns).text).to eq('100')
        expect(result.at_xpath('//nfcom:xMotivo', ns).text).to eq('Autorizado')
        expect(result.at_xpath('//nfcom:protNFCom', ns)).not_to be_nil
        expect(http).to have_received(:request).once
      end
    end

    context 'when webservice URL is missing' do
      let(:webservice_url) { nil }

      it 'raises ConfigurationError' do
        expect { service.enviar(xml_assinado) }
          .to raise_error(Nfcom::Errors::ConfigurationError)
      end
    end

    context 'when a timeout occurs' do
      it 'raises TimeoutError' do
        allow(http).to receive(:request).and_raise(Net::ReadTimeout)

        expect { service.enviar(xml_assinado) }
          .to raise_error(Nfcom::Errors::TimeoutError, /Timeout na comunicação/)
      end
    end

    context 'when SEFAZ returns an HTTP error' do
      it 'raises SefazError' do
        response = instance_double(
          Net::HTTPInternalServerError,
          code: '500',
          message: 'Internal Server Error'
        )
        allow(http).to receive(:request).and_return(response)

        expect { service.enviar(xml_assinado) }
          .to raise_error(Nfcom::Errors::SefazError, /Erro HTTP 500/)
      end
    end
  end

  # ------------------------------------------------------------------
  # Helpers
  # ------------------------------------------------------------------

  def stub_certificate
    fake_cert = instance_double(OpenSSL::X509::Certificate)
    fake_key  = instance_double(OpenSSL::PKey::RSA)
    allow(OpenSSL::X509::Certificate).to receive(:new).and_return(fake_cert)
    allow(OpenSSL::PKey::RSA).to receive(:new).and_return(fake_key)

    allow(Nfcom::Utils::Certificate).to receive(:new).and_return(
      instance_double(Nfcom::Utils::Certificate, to_pem: { cert: 'CERT', key: 'KEY' })
    )
  end

  def stub_xml_processing
    allow(Nfcom::Utils::XmlCleaner).to receive(:clean).and_return('<xml>limpo</xml>')
    allow(Nfcom::Utils::Compressor).to receive(:gzip_base64).and_return('XML_GZIP')
  end

  def stub_http_client
    allow(Net::HTTP).to receive(:new).and_return(http)
    %i[use_ssl= verify_mode= open_timeout= read_timeout= cert= key=].each do |method|
      allow(http).to receive(method)
    end
  end

  def http_success(body:)
    response = Net::HTTPSuccess.new('1.1', '200', 'OK')
    allow(response).to receive(:body).and_return(body)
    response
  end
end
