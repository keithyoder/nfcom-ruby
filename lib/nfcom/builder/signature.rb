# frozen_string_literal: true

require 'openssl'
require 'base64'
require 'nokogiri'

module Nfcom
  module Builder
    class Signature
      attr_reader :configuration

      def initialize(configuration)
        @configuration = configuration
        @certificate = Utils::Certificate.new(
          configuration.certificado_path,
          configuration.certificado_senha
        )
      end

      def assinar(xml)
        doc = Nokogiri::XML(xml)
        
        # Encontra o nó infNFCom que precisa ser assinado
        inf_nfcom = doc.at_xpath('//xmlns:infNFCom', 'xmlns' => 'http://www.portalfiscal.inf.br/nfcom')
        raise Errors::XmlError, "Elemento infNFCom não encontrado no XML" unless inf_nfcom

        # Canonicaliza o elemento
        canon_inf = inf_nfcom.canonicalize(Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0)
        
        # Calcula o digest (SHA1)
        digest = OpenSSL::Digest::SHA1.digest(canon_inf)
        digest_base64 = Base64.strict_encode64(digest)
        
        # Cria SignedInfo
        signed_info = criar_signed_info(inf_nfcom['Id'], digest_base64)
        
        # Canonicaliza SignedInfo
        canon_signed_info = Nokogiri::XML(signed_info).root.canonicalize(Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0)
        
        # Assina com a chave privada
        signature_value = @certificate.key.sign(OpenSSL::Digest::SHA1.new, canon_signed_info)
        signature_value_base64 = Base64.strict_encode64(signature_value)
        
        # Adiciona a assinatura ao XML
        adicionar_assinatura(doc, signed_info, signature_value_base64)
        
        doc.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)
      end

      private

      def criar_signed_info(reference_uri, digest_value)
        <<~XML
          <SignedInfo xmlns="http://www.w3.org/2000/09/xmldsig#">
            <CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315"/>
            <SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"/>
            <Reference URI="##{reference_uri}">
              <Transforms>
                <Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>
                <Transform Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315"/>
              </Transforms>
              <DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/>
              <DigestValue>#{digest_value}</DigestValue>
            </Reference>
          </SignedInfo>
        XML
      end

      def adicionar_assinatura(doc, signed_info_xml, signature_value)
        nfcom = doc.at_xpath('//xmlns:NFCom', 'xmlns' => 'http://www.portalfiscal.inf.br/nfcom')
        
        # Cria elemento Signature
        signature = Nokogiri::XML::Node.new('Signature', doc)
        signature.add_namespace(nil, 'http://www.w3.org/2000/09/xmldsig#')
        
        # Adiciona SignedInfo
        signed_info_node = Nokogiri::XML.fragment(signed_info_xml)
        signature.add_child(signed_info_node)
        
        # Adiciona SignatureValue
        sig_value = Nokogiri::XML::Node.new('SignatureValue', doc)
        sig_value.content = signature_value
        signature.add_child(sig_value)
        
        # Adiciona KeyInfo
        key_info = criar_key_info(doc)
        signature.add_child(key_info)
        
        # Adiciona Signature ao documento
        nfcom.add_child(signature)
      end

      def criar_key_info(doc)
        key_info = Nokogiri::XML::Node.new('KeyInfo', doc)
        
        x509_data = Nokogiri::XML::Node.new('X509Data', doc)
        x509_cert = Nokogiri::XML::Node.new('X509Certificate', doc)
        
        # Remove headers do certificado
        cert_base64 = @certificate.cert.to_pem
          .gsub('-----BEGIN CERTIFICATE-----', '')
          .gsub('-----END CERTIFICATE-----', '')
          .gsub("\n", '')
        
        x509_cert.content = cert_base64
        x509_data.add_child(x509_cert)
        key_info.add_child(x509_data)
        
        key_info
      end
    end
  end
end
