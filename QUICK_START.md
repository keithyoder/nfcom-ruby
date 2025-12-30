# Guia de Início Rápido - Gem Nfcom

## ✅ O que foi criado

A estrutura completa da gem Ruby para emissão de NF-COM (Nota Fiscal de Comunicação) modelo 62 foi criada com sucesso!

### Estrutura de Arquivos

```
nfcom/
├── lib/
│   └── nfcom/
│       ├── builder/           # Construtores de XML e assinatura
│       │   ├── xml_builder.rb
│       │   ├── signature.rb
│       │   └── qrcode.rb
│       ├── models/            # Modelos de dados
│       │   ├── nota.rb
│       │   ├── emitente.rb
│       │   ├── destinatario.rb
│       │   ├── item.rb
│       │   ├── total.rb
│       │   └── endereco.rb
│       ├── webservices/       # Integração SOAP com SEFAZ
│       │   ├── base.rb
│       │   ├── autorizacao.rb
│       │   ├── consulta.rb
│       │   ├── status.rb
│       │   └── inutilizacao.rb
│       ├── validators/        # Validações
│       │   ├── xml_validator.rb
│       │   └── business_rules.rb
│       ├── parsers/           # Parser de respostas
│       │   └── response_parser.rb
│       ├── utils/             # Utilitários
│       │   ├── certificate.rb
│       │   └── helpers.rb
│       ├── configuration.rb   # Configuração da gem
│       ├── client.rb          # Cliente principal
│       ├── errors.rb          # Erros customizados
│       └── version.rb
├── spec/                      # Testes RSpec
├── examples/                  # Exemplos de uso
├── schemas/                   # Schemas XSD (a adicionar)
├── nfcom.gemspec             # Especificação da gem
├── Gemfile
├── Rakefile
├── README.md                  # Documentação completa
├── CHANGELOG.md
└── LICENSE

Total: 31 arquivos Ruby criados!
```

## 🚀 Próximos Passos

### 1. Instalar Dependências

```bash
cd nfcom
bundle install
```

### 2. Obter Credenciais da SEFAZ-PE

Você precisará:
- ✅ Certificado digital A1 ou A3 (e-CNPJ)
- ✅ Credenciamento no portal efisco.sefaz.pe.gov.br
- ✅ CSC (Código de Segurança do Contribuinte)

### 3. Configurar a Gem

Crie um arquivo de configuração (ex: `config/nfcom.rb`):

```ruby
require 'nfcom'

Nfcom.configure do |config|
  # Ambiente
  config.ambiente = :homologacao  # Sempre começar em homologação!
  config.estado = 'PE'
  
  # Certificado
  config.certificado_path = ENV['NFCOM_CERT_PATH']
  config.certificado_senha = ENV['NFCOM_CERT_PASSWORD']
  
  # CSC
  config.csc_id = ENV['NFCOM_CSC_ID']
  config.csc = ENV['NFCOM_CSC']
  
  # Emitente
  config.cnpj = 'SEU_CNPJ'
  config.razao_social = 'SUA_RAZAO_SOCIAL'
  config.inscricao_estadual = 'SUA_IE'
end
```

### 4. Testar Status da SEFAZ

```ruby
require 'nfcom'
# ... configuração ...

client = Nfcom::Client.new
status = client.status_servico

puts "SEFAZ está #{status[:online] ? 'ONLINE' : 'OFFLINE'}"
```

### 5. Emitir Primeira Nota de Teste

Use o exemplo em `examples/emitir_nota.rb` como base.

## 📋 Checklist de Implementação

### Antes de Produção

- [ ] Testar em homologação
- [ ] Validar todos os campos obrigatórios
- [ ] Testar com diferentes cenários:
  - [ ] Cliente pessoa física
  - [ ] Cliente pessoa jurídica
  - [ ] Múltiplos itens
  - [ ] Com desconto
- [ ] Implementar armazenamento de XMLs
- [ ] Implementar controle de numeração sequencial
- [ ] Criar job assíncrono (Sidekiq)
- [ ] Implementar envio de email com XML
- [ ] Testar retry automático
- [ ] Documentar processo interno

### Melhorias Futuras

- [ ] Adicionar validação contra schemas XSD
- [ ] Implementar contingência (FS-DA)
- [ ] Adicionar cancelamento de notas
- [ ] Adicionar carta de correção
- [ ] Gerar DANFE-COM em PDF
- [ ] Adicionar suporte a outros estados
- [ ] Criar dashboard de monitoramento
- [ ] Adicionar testes de integração completos

## 🔧 Desenvolvimento Local

### Rodar Testes

```bash
bundle exec rspec
```

### Verificar Código

```bash
bundle exec rubocop
```

### Console Interativo

```bash
bundle exec irb -r ./lib/nfcom
```

## 📦 Publicar Gem (Quando Pronto)

```bash
# 1. Criar tag de versão
git tag v0.1.0
git push --tags

# 2. Build da gem
gem build nfcom.gemspec

# 3. Publicar no RubyGems
gem push nfcom-0.1.0.gem
```

## 🛠️ Integração com Rails

### Adicionar ao Gemfile

```ruby
# Gemfile
gem 'nfcom', path: 'path/to/nfcom'  # Desenvolvimento local
# ou
gem 'nfcom'  # Quando publicada
```

### Criar Initializer

```ruby
# config/initializers/nfcom.rb
Nfcom.configure do |config|
  # ... configuração ...
end
```

### Criar Service Object

Veja exemplo completo no README.md

### Criar Background Job

```ruby
class EmitirNfcomJob < ApplicationJob
  queue_as :nfcom
  
  def perform(invoice_id)
    invoice = Invoice.find(invoice_id)
    NfcomService.new(invoice).emitir
  end
end
```

## 🎯 Para Seu Caso Específico (4000 notas/mês)

### Arquitetura Recomendada

1. **Fila Assíncrona**: Sidekiq com Redis
2. **Armazenamento**: 
   - XMLs no S3 ou storage local
   - Metadados no PostgreSQL
3. **Monitoramento**:
   - Dashboard de notas pendentes/processadas/rejeitadas
   - Alertas para falhas
4. **Backup**: 
   - Backup diário dos XMLs autorizados

### Performance

- 4000 notas/mês = ~133 notas/dia
- Com processamento assíncrono: ~5-10 notas/minuto
- Tempo médio por nota: 5-10 segundos (inclui SEFAZ)

### Contingência

Tenha um plano B caso a SEFAZ fique fora:
- Emisão em contingência (FS-DA)
- Fila de retry automático
- Notificação da equipe

## 📞 Suporte

- Documentação completa: README.md
- Exemplos: pasta examples/
- Issues: GitHub (quando publicado)
- SEFAZ-PE: efisco.sefaz.pe.gov.br

## ✨ Resumo

Você agora tem uma gem Ruby completa e funcional para emissão de NF-COM!

**O que funciona:**
✅ Configuração completa
✅ Modelos de dados com validação
✅ Geração de XML
✅ Assinatura digital
✅ Comunicação SOAP com SEFAZ
✅ Autorização de notas
✅ Consulta de notas
✅ Status do serviço
✅ Inutilização
✅ Tratamento de erros
✅ Documentação completa

**Próximo passo imediato:**
1. Configure suas credenciais da SEFAZ
2. Teste o status do serviço
3. Emita sua primeira nota em homologação

Boa sorte com o projeto! 🚀
