# frozen_string_literal: true

module Nfcom
  module Parsers
    class Base
      attr_reader :document

      def initialize(http_response)
        @document = Nokogiri::XML(http_response)
      end

      private

      def nfcom_namespaces
        {
          'soap' => 'http://www.w3.org/2003/05/soap-envelope',
          'nfcom' => 'http://www.portalfiscal.inf.br/nfcom'
        }
      end

      def xpath(node, path)
        node.at_xpath(path, nfcom_namespaces)&.text
      end

      def find(path)
        document.at_xpath(path, nfcom_namespaces)
      end
    end
  end
end
