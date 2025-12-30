# frozen_string_literal: true

module Nfcom
  module Validators
    class XmlValidator
      SCHEMA_PATH = File.join(__dir__, '../../schemas/nfcom_v1.00.xsd')

      def validar(xml)
        # TODO: Implementar validação contra XSD
        # Por enquanto, apenas valida se é XML válido
        doc = Nokogiri::XML(xml)

        if doc.errors.any?
          erros = doc.errors.map(&:message).join(', ')
          raise Errors::ValidationError, "XML inválido: #{erros}"
        end

        # TODO: Validar contra schema XSD quando disponível
        # xsd = Nokogiri::XML::Schema(File.read(SCHEMA_PATH))
        # erros = xsd.validate(doc)
        # raise Errors::ValidationError, erros.map(&:message).join(', ') if erros.any?

        true
      rescue Nokogiri::XML::SyntaxError => e
        raise Errors::XmlError, "Erro de sintaxe no XML: #{e.message}"
      end
    end
  end
end
