# frozen_string_literal: true

module Nfcom
  module Utils
    class XmlAuthorized
      NFCOM_NAMESPACE = 'http://www.portalfiscal.inf.br/nfcom'

      def self.build_nfcom_proc(xml_assinado:, xml_protocolo:)
        nfcom_doc = Nokogiri::XML(xml_assinado, &:strict)
        prot_doc  = Nokogiri::XML(xml_protocolo, &:strict)

        nfcom_node = nfcom_doc.at_xpath('/*[local-name()="NFCom"]')
        prot_node  = prot_doc.at_xpath('/*[local-name()="protNFCom"]')

        raise Errors::XmlError, 'NFCom não encontrada no XML assinado' unless nfcom_node
        raise Errors::XmlError, 'protNFCom não encontrada no XML de protocolo' unless prot_node

        builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          xml.nfcomProc(xmlns: NFCOM_NAMESPACE, versao: '1.00') do
            xml << nfcom_node.to_xml
            xml << prot_node.to_xml
          end
        end

        builder.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)
      end
    end
  end
end
