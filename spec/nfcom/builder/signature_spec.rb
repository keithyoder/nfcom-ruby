# frozen_string_literal: true

require 'spec_helper'
require 'openssl'
require 'tmpdir'

RSpec.describe Nfcom::Builder::Signature do
  # ---------------------------------------------------------------------------
  # Certificado auto-assinado gerado em memória — sem fixture em disco,
  # sem dados reais de produção.
  # ---------------------------------------------------------------------------
  let(:chave_privada) { OpenSSL::PKey::RSA.generate(2048) }

  let(:certificado) do
    cert = OpenSSL::X509::Certificate.new
    cert.version   = 2
    cert.serial    = 1
    cert.subject   = OpenSSL::X509::Name.parse('/CN=Teste NFCom/O=Teste/C=BR')
    cert.issuer    = cert.subject
    cert.public_key = chave_privada.public_key
    cert.not_before = Time.now - 60
    cert.not_after  = Time.now + (365 * 24 * 3600) # 1 year
    cert.sign(chave_privada, OpenSSL::Digest.new('SHA256'))
    cert
  end

  let(:pfx_path) do
    pfx = OpenSSL::PKCS12.create('senha_teste', 'teste', chave_privada, certificado)
    path = File.join(Dir.tmpdir, 'teste_nfcom.pfx')
    File.binwrite(path, pfx.to_der)
    path
  end

  let(:configuration) do
    config = Nfcom::Configuration.new
    config.certificado_path  = pfx_path
    config.certificado_senha = 'senha_teste'
    config.estado            = 'PE'
    config.ambiente          = :homologacao
    config
  end

  let(:assinador) { described_class.new(configuration) }

  let(:xml_valido) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <NFCom xmlns="http://www.portalfiscal.inf.br/nfcom">
        <infNFCom versao="1.00" Id="NFCom26220512345678000100620010000000011234567890">
          <ide>
            <cUF>26</cUF>
            <mod>62</mod>
          </ide>
        </infNFCom>
      </NFCom>
    XML
  end

  after { FileUtils.rm_f(pfx_path) }

  # ---------------------------------------------------------------------------

  describe '#assinar' do
    subject(:xml_assinado) { assinador.assinar(xml_valido) }

    it 'retorna uma string XML' do
      expect(xml_assinado).to be_a(String)
    end

    it 'inclui o elemento Signature' do
      doc = Nokogiri::XML(xml_assinado)
      signature = doc.at_xpath('//ds:Signature', 'ds' => 'http://www.w3.org/2000/09/xmldsig#')

      expect(signature).not_to be_nil
    end

    it 'inclui SignedInfo com os algoritmos corretos' do
      doc = Nokogiri::XML(xml_assinado)
      ns  = { 'ds' => 'http://www.w3.org/2000/09/xmldsig#' }

      aggregate_failures do
        canon_method = doc.at_xpath('//ds:CanonicalizationMethod', ns)
        expect(canon_method['Algorithm']).to eq('http://www.w3.org/TR/2001/REC-xml-c14n-20010315')

        sig_method = doc.at_xpath('//ds:SignatureMethod', ns)
        expect(sig_method['Algorithm']).to eq('http://www.w3.org/2000/09/xmldsig#rsa-sha1')

        digest_method = doc.at_xpath('//ds:DigestMethod', ns)
        expect(digest_method['Algorithm']).to eq('http://www.w3.org/2000/09/xmldsig#sha1')
      end
    end

    it 'inclui DigestValue preenchido' do
      doc = Nokogiri::XML(xml_assinado)
      digest = doc.at_xpath('//ds:DigestValue', 'ds' => 'http://www.w3.org/2000/09/xmldsig#')

      expect(digest&.text).not_to be_empty
    end

    it 'inclui SignatureValue preenchido' do
      doc = Nokogiri::XML(xml_assinado)
      sig_value = doc.at_xpath('//ds:SignatureValue', 'ds' => 'http://www.w3.org/2000/09/xmldsig#')

      expect(sig_value&.text).not_to be_empty
    end

    it 'inclui o certificado em X509Certificate' do
      doc       = Nokogiri::XML(xml_assinado)
      x509_node = doc.at_xpath('//ds:X509Certificate', 'ds' => 'http://www.w3.org/2000/09/xmldsig#')
      cert_der  = Base64.decode64(x509_node.text)
      cert      = OpenSSL::X509::Certificate.new(cert_der)

      expect(cert.subject.to_s).to include('Teste NFCom')
    end

    it 'referencia o Id correto de infNFCom' do
      doc = Nokogiri::XML(xml_assinado)
      ref = doc.at_xpath('//ds:Reference', 'ds' => 'http://www.w3.org/2000/09/xmldsig#')

      expect(ref['URI']).to eq('#NFCom26220512345678000100620010000000011234567890')
    end

    it 'a assinatura pode ser verificada com a chave pública do certificado' do
      doc        = Nokogiri::XML(xml_assinado)
      ns         = { 'ds' => 'http://www.w3.org/2000/09/xmldsig#' }

      sig_value = Base64.decode64(doc.at_xpath('//ds:SignatureValue', ns).text)
      signed_info = doc.at_xpath('//ds:SignedInfo', ns)
      canonicalized = signed_info.canonicalize(Nokogiri::XML::XML_C14N_1_0)

      expect(
        certificado.public_key.verify(OpenSSL::Digest.new('SHA1'), sig_value, canonicalized)
      ).to be true
    end

    context 'com XML sem infNFCom' do
      let(:xml_invalido) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <NFCom xmlns="http://www.portalfiscal.inf.br/nfcom">
            <outroElemento/>
          </NFCom>
        XML
      end

      it 'levanta XmlError' do
        expect { assinador.assinar(xml_invalido) }
          .to raise_error(Nfcom::Errors::XmlError, /infNFCom element not found/)
      end
    end

    context 'com XML sem elemento NFCom raiz' do
      let(:xml_sem_raiz) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <OutroDocumento xmlns="http://www.portalfiscal.inf.br/nfcom">
            <infNFCom versao="1.00" Id="NFCom123">
              <ide/>
            </infNFCom>
          </OutroDocumento>
        XML
      end

      it 'levanta XmlError' do
        expect { assinador.assinar(xml_sem_raiz) }
          .to raise_error(Nfcom::Errors::XmlError, /NFCom element not found/)
      end
    end
  end
end
