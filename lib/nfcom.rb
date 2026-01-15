# frozen_string_literal: true

require_relative 'nfcom/version'
require_relative 'nfcom/configuration'
require_relative 'nfcom/client'
require_relative 'nfcom/errors'

# Utils
require_relative 'nfcom/utils/xml_cleaner'
require_relative 'nfcom/utils/certificate'
require_relative 'nfcom/utils/compressor'
require_relative 'nfcom/utils/helpers'
require_relative 'nfcom/utils/response_decompressor'

# Models
require_relative 'nfcom/models/nota'
require_relative 'nfcom/models/emitente'
require_relative 'nfcom/models/destinatario'
require_relative 'nfcom/models/assinante'
require_relative 'nfcom/models/item'
require_relative 'nfcom/models/fatura'
require_relative 'nfcom/models/total'
require_relative 'nfcom/models/endereco'

# Builders
require_relative 'nfcom/builder/xml_builder'
require_relative 'nfcom/builder/signature'
require_relative 'nfcom/builder/qrcode'

# Webservices
require_relative 'nfcom/webservices/base'
require_relative 'nfcom/webservices/autorizacao'
require_relative 'nfcom/webservices/consulta'
require_relative 'nfcom/webservices/status'
require_relative 'nfcom/webservices/inutilizacao'

# Validators
require_relative 'nfcom/validators/xml_validator'
require_relative 'nfcom/validators/business_rules'

# Parsers
require_relative 'nfcom/parsers/response_parser'

# Gem Nfcom - Emissão de NF-COM (Nota Fiscal de Comunicação) modelo 62
#
# Esta gem fornece uma interface completa para emissão de notas fiscais
# de serviços de comunicação e telecomunicação, com integração direta
# com a SEFAZ através de webservices SOAP.
#
# @example Configuração básica
#   Nfcom.configure do |config|
#     config.ambiente = :homologacao
#     config.estado = 'PE'
#     config.certificado_path = '/path/to/certificado.pfx'
#     config.certificado_senha = 'senha'
#     config.cnpj = '12345678000100'
#     config.razao_social = 'Provedor LTDA'
#     config.inscricao_estadual = '0123456789'
#   end
#
# @example Emitir uma nota
#   nota = Nfcom::Models::Nota.new do |n|
#     n.serie = 1
#     n.numero = 1
#     n.emitente = Nfcom::Models::Emitente.new(...)
#     n.destinatario = Nfcom::Models::Destinatario.new(...)
#     n.add_item(codigo_servico: '0303', descricao: 'Internet', valor_unitario: 99.90)
#   end
#
#   client = Nfcom::Client.new
#   resultado = client.autorizar(nota)
#
# @see https://github.com/keithyoder/nfcom-ruby Documentação completa no GitHub
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
