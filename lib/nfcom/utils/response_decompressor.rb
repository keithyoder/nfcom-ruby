# frozen_string_literal: true

require 'nokogiri'

module Nfcom
  module Utils
    # Descompressor de respostas da SEFAZ
    #
    # Processa respostas SOAP da SEFAZ, extraindo e descompactando
    # o XML de resposta quando necessário.
    class ResponseDecompressor
      # Extrai e descompacta resposta da SEFAZ
      #
      # @param soap_response [Nokogiri::XML::Document] Documento SOAP da resposta
      # @return [Nokogiri::XML::Document] Documento XML descompactado
      # @raise [Errors::SefazError] Se houver erro na resposta ou faltar nfcomResultMsg
      def self.extract_and_decompress(soap_response)
        doc = soap_response.dup
        doc.remove_namespaces!

        # Verificar se tem Fault
        if (fault = doc.at_xpath('//Fault'))
          error_msg = fault.at_xpath('.//Text')&.text || 'Erro desconhecido'
          raise Errors::SefazError, "Erro SOAP: #{error_msg}"
        end

        # Extrair nfcomResultMsg
        result_msg_node = doc.at_xpath('//nfcomResultMsg')
        raise Errors::SefazError, 'Resposta SOAP não contém nfcomResultMsg' unless result_msg_node

        # Verificar se tem retNFCom direto (resposta não comprimida - geralmente erros)
        ret_nfcom_direto = result_msg_node.at_xpath('.//retNFCom')

        xml_descomprimido = if ret_nfcom_direto
                              # Resposta NÃO está comprimida (erro de processamento)
                              result_msg_node.to_xml
                            else
                              # Resposta está comprimida (normal)
                              base64_comprimido = result_msg_node.text.strip
                              Compressor.ungzip_base64(base64_comprimido)
                            end

        Nokogiri::XML(xml_descomprimido)
      end
    end
  end
end
