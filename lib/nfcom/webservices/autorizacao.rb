# frozen_string_literal: true

module Nfcom
  module Webservices
    # Serviço de autorização de NFCom
    #
    # Responsável por enviar NFCom para autorização na SEFAZ,
    # incluindo compressão GZIP, envio via SOAP 1.2 e processamento
    # da resposta.
    class Autorizacao < Base
      # Envia NFCom assinada para autorização
      #
      # @param xml_assinado [String] XML da NFCom já assinado
      # @return [Hash] Hash com resultado da autorização
      # @raise [Errors::ConfigurationError] Se URL não configurada
      # @raise [Errors::SefazError] Se houver erro na comunicação
      def enviar(xml_assinado)
        url = configuration.webservice_url(:recepcao)
        unless url
          raise Errors::ConfigurationError,
                "URL de recepção não configurada para #{configuration.estado}"
        end

        # Limpar e comprimir XML
        xml_limpo = Utils::XmlCleaner.clean(xml_assinado)
        xml_comprimido = Utils::Compressor.gzip_base64(xml_limpo)

        configuration.logger&.debug('XML Limpo e Comprimido') if configuration.log_level == :debug

        # Construir envelope SOAP
        soap_request = build_soap_envelope(xml_comprimido)

        # Enviar para SEFAZ
        action = 'http://www.portalfiscal.inf.br/nfcom/wsdl/NFComRecepcao/nfcomRecepcao'
        response = post_soap_with_compression(url: url, action: action, xml: soap_request)

        # Processar resposta
        parse_response(response)
      rescue StandardError => e
        configuration.logger&.error("Erro ao enviar NFCom: #{e.message}")
        raise
      end

      private

      # Constrói envelope SOAP 1.2 para NFCom
      #
      # IMPORTANTE: O namespace vai NO nfcomDadosMsg, NÃO no envelope!
      # E o nfcomDadosMsg vai DIRETO no Body, sem wrapper!
      def build_soap_envelope(xml_comprimido)
        require 'nokogiri'

        builder = Nokogiri::XML::Builder.new do |xml|
          xml['soap'].Envelope('xmlns:soap' => 'http://www.w3.org/2003/05/soap-envelope') do
            xml['soap'].Body do
              # IMPORTANTE: Namespace vai AQUI e sem wrapper!
              xml.nfcomDadosMsg(
                xml_comprimido,
                'xmlns' => 'http://www.portalfiscal.inf.br/nfcom/wsdl/NFComRecepcao'
              )
            end
          end
        end

        # Gerar XML sem formatação (save_with: 0 = sem pretty print)
        builder.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)
      end

      # Envia requisição SOAP (override de Base para adicionar certificado)
      def post_soap_with_compression(url:, action:, xml:)
        http, uri = build_http_client(url)
        request = build_soap_request(uri, action, xml)

        log_request(request)

        response = http.request(request)

        log_response(response)
        validate_http_response!(response)

        Nokogiri::XML(response.body)
      rescue Net::OpenTimeout, Net::ReadTimeout, ::Timeout::Error # rubocop:disable Lint/ShadowedException
        raise Errors::TimeoutError, 'Timeout na comunicação com SEFAZ'
      rescue OpenSSL::SSL::SSLError => e
        raise Errors::SefazError, "Erro SSL: #{e.message}"
      end

      def parse_response(soap_response)
        ret_doc = decompress_response(soap_response)

        log_decompressed_xml(ret_doc)

        extract_nfcom_result(ret_doc)
      end

      def build_http_client(url)
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)

        http.use_ssl = (uri.scheme == 'https')
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http.open_timeout = configuration.timeout
        http.read_timeout = configuration.timeout

        configure_certificate(http)

        [http, uri]
      end

      def configure_certificate(http)
        cert_pem = certificate.to_pem
        http.cert = OpenSSL::X509::Certificate.new(cert_pem[:cert])
        http.key = OpenSSL::PKey::RSA.new(cert_pem[:key])
      end

      def build_soap_request(uri, action, xml)
        request = Net::HTTP::Post.new(uri.path.empty? ? '/' : uri.path)
        request['Content-Type'] =
          "application/soap+xml;charset=UTF-8;action=\"#{action}\""
        request.body = xml
        request
      end

      def validate_http_response!(response)
        return if response.is_a?(Net::HTTPSuccess)

        raise Errors::SefazError,
              "Erro HTTP #{response.code}: #{response.message}"
      end

      def log_request(request)
        return unless configuration.log_level == :debug

        configuration.logger&.debug("SOAP Request:\n#{request.body}")
      end

      def log_response(response)
        return unless configuration.log_level == :debug

        body = response.body.force_encoding('UTF-8')
        configuration.logger&.debug("SOAP Response (raw):\n#{body}")
      end

      def decompress_response(soap_response)
        doc = Utils::ResponseDecompressor.extract_and_decompress(soap_response)
        doc.remove_namespaces!
        doc
      end

      def extract_nfcom_result(doc)
        ret = doc.at_xpath('//retNFCom')
        return log_missing_ret_nfcom(doc) unless ret

        build_result(ret)
      end

      def build_result(ret)
        result = {
          c_stat: ret.at_xpath('.//cStat')&.text,
          x_motivo: ret.at_xpath('.//xMotivo')&.text
        }

        if (prot = ret.at_xpath('.//protNFCom'))
          result[:prot_nfcom] = extract_protocol(prot)
        end

        log_extracted_result(result)
        result
      end

      def extract_protocol(prot)
        {
          n_prot: prot.at_xpath('.//nProt')&.text,
          ch_nfcom: prot.at_xpath('.//chNFCom')&.text,
          dh_rec_bto: prot.at_xpath('.//dhRecbto')&.text,
          xml: prot.to_xml
        }
      end

      def log_missing_ret_nfcom(doc)
        configuration.logger&.warn(
          "Resposta não contém retNFCom. XML: #{doc.to_xml}"
        )
        {}
      end

      def log_decompressed_xml(doc)
        return unless configuration.log_level == :debug

        configuration.logger&.debug("XML da Resposta:\n#{doc.to_xml}")
      end

      def log_extracted_result(result)
        return unless configuration.log_level == :debug

        configuration.logger&.debug("Resultado extraído: #{result.inspect}")
      end
    end
  end
end
