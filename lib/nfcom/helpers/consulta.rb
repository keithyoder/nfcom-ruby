# frozen_string_literal: true

module Nfcom
  module Helpers
    module Consulta
      # Returns the URL to confirm an already-authorized NFCom
      #
      # @param chave [String] Chave de acesso da NFCom (44 chars)
      # @param ambiente [Symbol] :homologacao or :producao (optional, defaults to current config)
      # @return [String] URL to confirm the nota
      def self.url(chave:, ambiente: Nfcom.configuration.ambiente)
        raise ArgumentError, 'Chave de acesso inválida' unless chave&.length == 44

        tp_amb = (ambiente == :producao ? 1 : 2)
        "https://dfe-portal.svrs.rs.gov.br/nfcom/qrcode?chNFCom=#{chave}&tpAmb=#{tp_amb}"
      end

      # Optional: parse the chave from a full XML string
      #
      # @param xml [String] NFCom XML (as stored in :xml_autorizado)
      # @return [String] chave de acesso
      def self.chave_from_xml(xml)
        doc = Nokogiri::XML(xml)
        doc.at_xpath('//NFCom/infNFCom/@Id')&.value&.sub(/^NFCom/, '')
      end
    end
  end
end
