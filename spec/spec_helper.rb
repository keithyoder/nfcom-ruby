# frozen_string_literal: true

require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
end

require 'nfcom'
require 'webmock/rspec'
require 'vcr'

# Carregar todos os arquivos de suporte
Dir[File.join(__dir__, 'support', '**', '*.rb')].sort.each { |f| require f }

RSpec.configure do |config|
  # Habilitar flags como --only-failures e --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Desabilitar exposição global de métodos do RSpec
  config.disable_monkey_patching!

  # Configurar sintaxe de expectativas
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Usar cores na saída
  config.color = true

  # Formato de documentação para arquivo único
  config.default_formatter = 'doc' if config.files_to_run.one?

  # Executar specs em ordem aleatória
  config.order = :random

  # Seed para reproduzir falhas
  Kernel.srand config.seed

  # Configurar Nfcom antes de todos os testes
  config.before(:suite) do
    Nfcom.configure do |c|
      c.ambiente = :homologacao
      c.estado = 'PE'
      c.timeout = 30
      c.serie_padrao = 1
      c.numero_inicial = 1

      # Desabilitar logs durante testes (a menos que DEBUG=true)
      c.desabilitar_logs unless ENV['DEBUG']
    end
  end

  # Resetar configuração antes de cada teste
  config.before do
    Nfcom.reset_configuration!
  end

  # Limpar mocks do WebMock após cada teste
  config.after do
    WebMock.reset!
  end
end

# Configuração do VCR para gravar interações HTTP
VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Permitir conexões localhost (útil para desenvolvimento)
  config.allow_http_connections_when_no_cassette = false

  # Filtrar dados sensíveis das gravações
  config.filter_sensitive_data('<CERTIFICADO>') do |interaction|
    # Ocultar dados de certificado das gravações
    interaction.request.headers['Authorization']&.first
  end

  config.filter_sensitive_data('<CSC>') do
    ENV['NFCOM_CSC'] || 'fake_csc'
  end

  config.filter_sensitive_data('<CNPJ>') do
    ENV['NFCOM_CNPJ'] || '12345678000195'
  end

  # Filtrar corpo da requisição se contiver certificado
  config.before_record do |interaction|
    # Remover certificados codificados em base64 das gravações
    if interaction.request.body&.include?('X509Certificate')
      interaction.request.body = interaction.request.body.gsub(
        %r{<X509Certificate>.*?</X509Certificate>}m,
        '<X509Certificate>FILTERED</X509Certificate>'
      )
    end

    # Remover chaves privadas das gravações
    interaction.response.body = 'FILTERED_CERTIFICATE_DATA' if interaction.response.body&.include?('-----BEGIN')
  end

  # Nomear cassetes automaticamente baseado no exemplo
  config.default_cassette_options = {
    record: :new_episodes,
    match_requests_on: %i[method uri body]
  }
end
