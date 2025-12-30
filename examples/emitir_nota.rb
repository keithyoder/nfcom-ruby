# frozen_string_literal: true

require 'nfcom'

# Configuração
Nfcom.configure do |config|
  config.ambiente = :homologacao
  config.estado = 'PE'
  config.certificado_path = 'caminho/para/certificado.pfx'
  config.certificado_senha = 'senha'
  config.cnpj = '12345678000100'
  config.razao_social = 'Provedor Internet LTDA'
  config.inscricao_estadual = '0123456789'
end

# Criar nota
nota = Nfcom::Models::Nota.new do |n|
  n.serie = 1
  n.numero = 1

  # Emitente
  n.emitente = Nfcom::Models::Emitente.new(
    cnpj: '12345678000100',
    razao_social: 'Provedor Internet LTDA',
    nome_fantasia: 'Meu Provedor',
    inscricao_estadual: '0123456789',
    endereco: {
      logradouro: 'Rua das Flores',
      numero: '123',
      bairro: 'Centro',
      codigo_municipio: '2611606',
      municipio: 'Recife',
      uf: 'PE',
      cep: '50000-000'
    }
  )

  # Destinatário
  n.destinatario = Nfcom::Models::Destinatario.new(
    cpf: '12345678900',
    razao_social: 'Cliente Teste',
    tipo_assinante: :residencial,
    email: 'cliente@teste.com',
    endereco: {
      logradouro: 'Av. Principal',
      numero: '456',
      bairro: 'Jardins',
      codigo_municipio: '2611606',
      municipio: 'Recife',
      uf: 'PE',
      cep: '51000-000'
    }
  )

  # Adicionar item
  n.add_item(
    codigo_servico: '0303',
    descricao: 'Plano Fibra 100MB',
    classe_consumo: '0303',
    cfop: '5307',
    quantidade: 1,
    valor_unitario: 99.90
  )
end

# Validar nota
if nota.valida?
  puts '✓ Nota válida'

  # Emitir nota
  begin
    client = Nfcom::Client.new
    resultado = client.autorizar(nota)

    if resultado[:autorizada]
      puts '✓ Nota autorizada!'
      puts "  Chave: #{resultado[:chave]}"
      puts "  Protocolo: #{resultado[:protocolo]}"
      puts "  Data: #{resultado[:data_autorizacao]}"
    end
  rescue Nfcom::Errors::NotaRejeitada => e
    puts "✗ Nota rejeitada [#{e.codigo}]: #{e.motivo}"
  rescue Nfcom::Errors::SefazIndisponivel
    puts '✗ SEFAZ temporariamente indisponível'
  rescue StandardError => e
    puts "✗ Erro: #{e.message}"
  end
else
  puts '✗ Nota inválida:'
  nota.erros.each { |erro| puts "  - #{erro}" }
end
