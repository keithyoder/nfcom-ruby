# frozen_string_literal: true

require 'nokogiri'
require 'openssl'
require 'base64'

module Nfcom
  module Builder
    class Signature
      ALGORITHMS = {
        c14n: 'http://www.w3.org/TR/2001/REC-xml-c14n-20010315',
        rsa_sha1: 'http://www.w3.org/2000/09/xmldsig#rsa-sha1',
        sha1: 'http://www.w3.org/2000/09/xmldsig#sha1',
        enveloped: 'http://www.w3.org/2000/09/xmldsig#enveloped-signature'
      }.freeze

      DSIG_NS = 'http://www.w3.org/2000/09/xmldsig#'

      def initialize(configuration)
        @configuration = configuration
        @certificate = Utils::Certificate.new(
          configuration.certificado_path,
          configuration.certificado_senha
        )
      end

      def assinar(xml_string)
        # Parse XML
        doc = Nokogiri::XML(xml_string)

        # Find infNFCom element
        inf_nfcom = doc.at_xpath(
          '//nfcom:infNFCom',
          'nfcom' => 'http://www.portalfiscal.inf.br/nfcom'
        )

        raise Errors::XmlError, 'infNFCom element not found' unless inf_nfcom

        # Get reference URI
        ref_uri = "##{inf_nfcom['Id']}"

        # Calculate digest of canonicalized infNFCom
        digest_value = calculate_digest(inf_nfcom)

        # Build SignedInfo
        signed_info = build_signed_info(ref_uri, digest_value)

        # Calculate signature of canonicalized SignedInfo
        signature_value = calculate_signature(signed_info)

        # Get certificate
        cert_value = get_certificate_value

        # Build complete Signature element
        signature_xml = build_signature_xml(signed_info, signature_value, cert_value)

        # Insert Signature into NFCom
        insert_signature(doc, signature_xml)

        # Return signed XML
        doc.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)
      end

      private

      def calculate_digest(element)
        # Canonicalize using C14N 1.0
        canonicalized = element.canonicalize(Nokogiri::XML::XML_C14N_1_0)

        # Calculate SHA1 digest
        digest = OpenSSL::Digest::SHA1.digest(canonicalized)

        # Return Base64 encoded
        Base64.strict_encode64(digest)
      end

      def build_signed_info(ref_uri, digest_value)
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.SignedInfo(xmlns: DSIG_NS) do
            # Use exact algorithm URIs required by NFCom
            xml.CanonicalizationMethod(Algorithm: ALGORITHMS[:c14n])
            xml.SignatureMethod(Algorithm: ALGORITHMS[:rsa_sha1])

            xml.Reference(URI: ref_uri) do
              xml.Transforms do
                xml.Transform(Algorithm: ALGORITHMS[:enveloped])
                xml.Transform(Algorithm: ALGORITHMS[:c14n])
              end
              xml.DigestMethod(Algorithm: ALGORITHMS[:sha1])
              xml.DigestValue digest_value
            end
          end
        end

        builder.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)
      end

      def calculate_signature(signed_info_xml)
        # Parse SignedInfo
        signed_info_doc = Nokogiri::XML(signed_info_xml)

        # Canonicalize using C14N 1.0
        canonicalized = signed_info_doc.canonicalize(Nokogiri::XML::XML_C14N_1_0)

        # Sign with RSA-SHA1
        signature = @certificate.key.sign(OpenSSL::Digest.new('SHA1'), canonicalized)

        # Return Base64 encoded
        Base64.strict_encode64(signature)
      end

      def get_certificate_value
        # Get certificate as DER, then Base64 encode
        # Remove PEM headers/footers, just the certificate data
        cert_der = @certificate.cert.to_der
        Base64.strict_encode64(cert_der)
      end

      def build_signature_xml(signed_info_xml, signature_value, cert_value)
        # Parse SignedInfo to get the element
        signed_info_doc = Nokogiri::XML(signed_info_xml)
        signed_info_element = signed_info_doc.root

        builder = Nokogiri::XML::Builder.new do |xml|
          xml.Signature(xmlns: DSIG_NS) do
            # Insert SignedInfo element
            xml.parent << signed_info_element

            xml.SignatureValue signature_value

            xml.KeyInfo do
              xml.X509Data do
                xml.X509Certificate cert_value
              end
            end
          end
        end

        builder.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)
      end

      def insert_signature(doc, signature_xml)
        # Parse signature
        signature_doc = Nokogiri::XML(signature_xml)
        signature_element = signature_doc.root

        # Find NFCom root element
        nfcom_element = doc.at_xpath(
          '//nfcom:NFCom',
          'nfcom' => 'http://www.portalfiscal.inf.br/nfcom'
        )

        raise Errors::XmlError, 'NFCom element not found' unless nfcom_element

        nfcom_element.add_child(signature_element)
      end
    end
  end
end
