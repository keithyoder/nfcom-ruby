# Nfcom Ruby

[![CI](https://github.com/keithyoder/nfcom-ruby/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/keithyoder/nfcom-ruby/actions/workflows/ci.yml)
[![RuboCop](https://github.com/keithyoder/nfcom-ruby/actions/workflows/rubocop.yml/badge.svg?branch=main)](https://github.com/keithyoder/nfcom-ruby/actions/workflows/rubocop.yml)
[![Security](https://github.com/keithyoder/nfcom-ruby/actions/workflows/security.yml/badge.svg?branch=main)](https://github.com/keithyoder/nfcom-ruby/actions/workflows/security.yml)
[![Gem Version](https://badge.fury.io/rb/nfcom.svg)](https://badge.fury.io/rb/nfcom)
Biblioteca Ruby para emissão de NF-COM (Nota Fiscal de Comunicação) modelo 62, desenvolvida especialmente para provedores de internet e empresas de telecomunicação.

## Características

- ✅ Emissão de NF-COM modelo 62
- ✅ Assinatura digital com certificado A1/A3
- ✅ Integração com SEFAZ via webservices SOAP
- ✅ Validação de XML e regras de negócio
- ✅ Suporte a ambiente de homologação e produção
- ✅ Retry automático em caso de falhas
- ✅ Geração de QR Code para consulta
- ✅ Consulta de notas autorizadas
- ✅ Verificação de status da SEFAZ
- ✅ Inutilização de numeração

## Instalação

Adicione ao seu Gemfile:

```ruby
gem 'nfcom'
```

Ou instale diretamente:

```bash
gem install nfcom
```

## Configuração

```ruby
require 'nfcom'

Nfcom.configure do |config|
  # Ambiente
  config.ambiente = :homologacao  # ou :producao
  config.estado = 'PE'
  
  # Certificado digital
  config.certificado_path = '/path/to/certificado.pfx'
  config.certificado_senha = 'senha_do_certificado'
    
  # Dados do emitente
  config.cnpj = '12345678000100'
  config.razao_social = 'Minha Empresa LTDA'
  config.inscricao_estadual = '0123456789'
  config.regime_tributario = 1  # 1=Simples Nacional, 3=Normal
  
  # Configurações opcionais
  config.serie_padrao = 1
  config.timeout = 30
  config.max_tentativas = 3
  config.log_level = :info
end
```

## Uso Básico

### Emitir uma Nota

```ruby
# 1. Criar a nota
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
  
  # Destinatário (cliente)
  n.destinatario = Nfcom::Models::Destinatario.new(
    cpf: '12345678900',
    razao_social: 'Cliente Pessoa Física',
    tipo_assinante: :residencial,
    email: 'cliente@email.com',
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
  
  # Adicionar serviço (item)
  n.add_item(
    codigo_servico: '0303',      # Internet
    descricao: 'Plano Fibra 100MB',
    classe_consumo: '0303',
    cfop: '5307',                # Prestação de serviço de comunicação
    unidade: 'UN',
    quantidade: 1,
    valor_unitario: 99.90
  )
end

# 2. Enviar para SEFAZ
client = Nfcom::Client.new
resultado = client.autorizar(nota)

if resultado[:autorizada]
  puts "✓ Nota autorizada!"
  puts "Chave: #{resultado[:chave]}"
  puts "Protocolo: #{resultado[:protocolo]}"
  
  # Salvar XML autorizado
  File.write("nota_#{nota.numero}.xml", resultado[:xml])
else
  puts "✗ Erro: #{resultado[:motivo]}"
end
```

### Consultando uma Nota

```ruby
client = Nfcom::Client.new

resultado = client.consultar_nota(
  chave: '26220512345678000100620010000000011234567890'
)

puts "Situação: #{resultado[:situacao]}"
puts "Protocolo: #{resultado[:protocolo]}"
```

### Verificando Status da SEFAZ

```ruby
client = Nfcom::Client.new
status = client.status_servico

if status[:online]
  puts "✓ SEFAZ online"
  puts "Tempo médio de resposta: #{status[:tempo_medio]}ms"
else
  puts "✗ SEFAZ offline: #{status[:motivo]}"
end
```

### Inutilizando Numeração

```ruby
client = Nfcom::Client.new

resultado = client.inutilizar(
  serie: 1,
  numero_inicial: 10,
  numero_final: 15,
  justificativa: 'Inutilização de numeração por erro no sistema'
)

if resultado[:inutilizada]
  puts "✓ Numeração inutilizada"
  puts "Protocolo: #{resultado[:protocolo]}"
end
```

## Integração com Rails

### Service Object

```ruby
# app/services/nfcom_service.rb
class NfcomService
  def initialize(invoice)
    @invoice = invoice
  end
  
  def emitir
    nota = build_nota
    client = Nfcom::Client.new
    
    resultado = client.autorizar(nota)
    
    if resultado[:autorizada]
      @invoice.update!(
        nfcom_chave: resultado[:chave],
        nfcom_numero: resultado[:numero],
        nfcom_xml: resultado[:xml],
        nfcom_protocolo: resultado[:protocolo],
        nfcom_emitida_em: Time.current
      )
      
      # Enviar email
      NfcomMailer.enviar_nota(@invoice).deliver_later
      
      true
    else
      raise Nfcom::Errors::NotaRejeitada.new(
        resultado[:codigo],
        resultado[:motivo]
      )
    end
  end
  
  private
  
  def build_nota
    Nfcom::Models::Nota.new do |n|
      n.serie = 1
      n.numero = proximo_numero
      n.emitente = build_emitente
      n.destinatario = build_destinatario
      
      @invoice.items.each do |item|
        n.add_item(
          codigo_servico: '0303',
          descricao: item.description,
          classe_consumo: '0303',
          cfop: '5307',
          valor_unitario: item.amount
        )
      end
    end
  end
  
  def proximo_numero
    # Lógica para obter próximo número sequencial
  end
end
```

### Background Job

```ruby
# app/jobs/emitir_nfcom_job.rb
class EmitirNfcomJob < ApplicationJob
  queue_as :nfcom
  
  def perform(invoice_id)
    invoice = Invoice.find(invoice_id)
    NfcomService.new(invoice).emitir
  rescue Nfcom::Errors::NotaRejeitada => e
    invoice.update!(
      nfcom_erro: e.message,
      nfcom_codigo_erro: e.codigo
    )
    raise e
  end
end

# Uso
EmitirNfcomJob.perform_later(invoice.id)
```

## Tratamento de Erros

```ruby
begin
  client.autorizar(nota)
rescue Nfcom::Errors::ValidationError => e
  puts "Erro de validação: #{e.message}"
rescue Nfcom::Errors::NotaRejeitada => e
  puts "Nota rejeitada [#{e.codigo}]: #{e.motivo}"
rescue Nfcom::Errors::SefazIndisponivel => e
  puts "SEFAZ temporariamente indisponível"
  # Tentar novamente mais tarde
rescue Nfcom::Errors::CertificateError => e
  puts "Erro no certificado: #{e.message}"
rescue Nfcom::Errors::TimeoutError => e
  puts "Timeout na comunicação"
end
```

## Códigos de Serviço

Para provedores de internet:

- `0303` - Serviço de Internet
- `0304` - TV por Assinatura
- `0305` - Telefonia

## CFOPs Comuns

- `5307` - Prestação de serviço de comunicação (dentro do estado)
- `6307` - Prestação de serviço de comunicação (fora do estado)

## Ambiente de Homologação

Durante o desenvolvimento, sempre use o ambiente de homologação:

```ruby
Nfcom.configure do |config|
  config.ambiente = :homologacao
  # ... outras configurações
end
```

**Importante:** Use CNPJs de teste no ambiente de homologação. Consulte a documentação da SEFAZ para a lista de CNPJs válidos para testes.

## Desenvolvimento

```bash
# Instalar dependências
bundle install

# Rodar testes
bundle exec rspec

# Rodar linter
bundle exec rubocop
```

## Contribuindo

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/nova-funcionalidade`)
3. Commit suas mudanças (`git commit -am 'Adiciona nova funcionalidade'`)
4. Push para a branch (`git push origin feature/nova-funcionalidade`)
5. Crie um Pull Request

## Licença

MIT License - veja [LICENSE](LICENSE) para detalhes.

## Suporte

- GitHub Issues: https://github.com/keithyoder/nfcom/issues
- Documentação SEFAZ: http://www.nfcom.fazenda.gov.br/

## Roadmap

- [ ] Suporte a mais estados
- [ ] Contingência (FS-DA)
- [ ] Cancelamento de notas
- [ ] Carta de correção
- [ ] Geração de DANFE-COM (PDF)
- [ ] Validação contra schemas XSD
- [ ] Cache de consultas
- [ ] Webhook para eventos

## Autores

- Keith Yoder - Desenvolvedor inicial

## Agradecimentos

Gem desenvolvida para facilitar a emissão de NF-COM por provedores de internet brasileiros.
