# frozen_string_literal: true

require_relative "nfcom/version"
require_relative "nfcom/configuration"
require_relative "nfcom/client"
require_relative "nfcom/errors"

# Models
require_relative "nfcom/models/nota"
require_relative "nfcom/models/emitente"
require_relative "nfcom/models/destinatario"
require_relative "nfcom/models/item"
require_relative "nfcom/models/total"
require_relative "nfcom/models/endereco"

# Builders
require_relative "nfcom/builder/xml_builder"
require_relative "nfcom/builder/signature"
require_relative "nfcom/builder/qrcode"

# Webservices
require_relative "nfcom/webservices/base"
require_relative "nfcom/webservices/autorizacao"
require_relative "nfcom/webservices/consulta"
require_relative "nfcom/webservices/status"
require_relative "nfcom/webservices/inutilizacao"

# Validators
require_relative "nfcom/validators/xml_validator"
require_relative "nfcom/validators/business_rules"

# Parsers
require_relative "nfcom/parsers/response_parser"

# Utils
require_relative "nfcom/utils/certificate"
require_relative "nfcom/utils/helpers"

module Nfcom
  class Error < StandardError; end

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?
  end

  def self.reset_configuration!
    self.configuration = Configuration.new
  end
end
