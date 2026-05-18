# frozen_string_literal: true

# Contexto compartilhado para webservices que precisam de um certificado válido.
#
# Faz stub do carregamento do certificado para evitar dependência de arquivo .pfx
# real nos specs. Gera um par de chaves e certificado autoassinado em memória.
#
# @example
#   RSpec.describe Nfcom::Webservices::Status do
#     include_context 'com certificado mockado'
#   end

RSpec.shared_context 'com certificado mockado' do
  let(:chave_privada) { OpenSSL::PKey::RSA.new(2048) }

  let(:certificado_x509) do
    cert = OpenSSL::X509::Certificate.new
    cert.version    = 2
    cert.serial     = 1
    cert.subject    = OpenSSL::X509::Name.parse('/CN=00000000000191')
    cert.issuer     = cert.subject
    cert.public_key = chave_privada.public_key
    cert.not_before = Time.now - 3600
    cert.not_after  = Time.now + (365 * 24 * 3600)
    cert.sign(chave_privada, OpenSSL::Digest.new('SHA256'))
    cert
  end

  let(:certificado_mock) do
    instance_double(Nfcom::Utils::Certificate).tap do |mock|
      allow(mock).to receive_messages(to_pem: {
                                        cert: certificado_x509.to_pem,
                                        key: chave_privada.to_pem
                                      }, cert: certificado_x509, key: chave_privada)
    end
  end

  before do
    allow(Nfcom::Utils::Certificate).to receive(:new).and_return(certificado_mock)
  end
end

RSpec.shared_context 'com configuração padrão' do
  let(:configuration) do
    Nfcom::Configuration.new.tap do |c|
      c.ambiente           = :producao
      c.estado             = 'PE'
      c.cnpj               = '00000000000191'
      c.inscricao_estadual = '000000000'
      c.max_tentativas     = 2
      c.tempo_espera_retry = 0
      c.certificado_path   = 'qualquer.pfx'
      c.certificado_senha  = 'qualquer'
      c.desabilitar_logs
    end
  end
end
