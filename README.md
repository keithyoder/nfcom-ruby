# Nfcom Ruby

[![CI](https://github.com/keithyoder/nfcom-ruby/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/keithyoder/nfcom-ruby/actions/workflows/ci.yml)
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
  config.regime_tributario = :simples_nacional
  
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
  
  # Fatura
  n.fatura = Nfcom::Models::Fatura.new(
    competencia: '202601',                    # AAAAMM
    data_vencimento: '2026-02-15',            # YYYY-MM-DD
    codigo_barras: '23793381286000000099901234567890123456789012',
    valor_fatura: 99.90
  )
  
  # Adicionar serviço (item)
  n.add_item(
    codigo_servico: '0303',                   # Internet
    descricao: 'Plano Fibra 100MB',
    classe_consumo: :nao_medido_internet,     # Usar símbolo do enum
    cfop: '5307',                             # Prestação de serviço de comunicação
    unidade: :un,                             # Usar símbolo
    quantidade: 1,
    valor_unitario: 99.90
  )
end

# 2. Enviar para SEFAZ
client = Nfcom::Client.new
resultado = client.autorizar(nota)

if resultado[:autorizada]
  puts "✓ Nota autorizada!"
  puts "Chave: #{nota.chave_acesso}"
  puts "Protocolo: #{nota.protocolo}"
  puts "Data: #{nota.data_autorizacao}"
  
  # Salvar XML autorizado completo (nfcomProc)
  # Este XML contém a NFCom assinada + protocolo de autorização
  xml_completo = nota.xml_autorizado
  File.write("nfcom_#{nota.numero}_#{nota.protocolo}.xml", xml_completo)
  
  # Ou salvar com formatação bonita
  doc = Nokogiri::XML(xml_completo)
  File.write("nfcom_#{nota.numero}.xml", doc.to_xml(indent: 2))
  
  puts "✓ XML salvo com sucesso"
else
  puts "✗ Erro na autorização"
  puts "Código: #{resultado[:codigo]}"
  puts "Motivo: #{resultado[:motivo]}"
end
```

### O que é armazenado após autorização

Após a autorização bem-sucedida, o objeto `nota` é atualizado com:

```ruby
nota.chave_acesso        # "26260107159053000107620010000081661049503004"
nota.protocolo           # "3262600000362421"
nota.data_autorizacao    # "2026-01-16T06:29:46-03:00"
nota.xml_autorizado      # XML completo (nfcomProc)
```

O `nota.xml_autorizado` contém o documento completo no formato `nfcomProc`:
- A NFCom original assinada (`<NFCom>` com `<Signature>`)
- O protocolo de autorização da SEFAZ (`<protNFCom>`)

Este é o XML legalmente válido que deve ser armazenado e fornecido ao cliente.

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

## Ambiente de Homologação

Durante o desenvolvimento, sempre use o ambiente de homologação:

```ruby
Nfcom.configure do |config|
  config.ambiente = :homologacao
  # ... outras configurações
end
```

## Desenvolvimento

```bash
# Instalar dependências
bundle install

# Rodar testes
bundle exec rspec

# Rodar linter
bundle exec rubocop

# Console interativo
bundle exec irb -r ./lib/nfcom
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

- GitHub Issues: https://github.com/keithyoder/nfcom-ruby/issues
- Documentação SEFAZ: http://www.nfcom.fazenda.gov.br/
- Manual NFCom: [Portal da Nota Fiscal](http://www.nfcom.fazenda.gov.br/)

## Roadmap

- [x] Emissão de NFCom
- [x] Assinatura digital
- [x] Integração SEFAZ
- [x] Consulta de notas
- [x] Validações completas
- [ ] Geração de DANFE-COM (PDF)
- [ ] Suporte a mais estados (atualmente PE)
- [ ] Contingência (FS-DA)
- [ ] Cancelamento de notas
- [ ] Carta de correção
- [ ] Validação contra schemas XSD
- [ ] Cache de consultas
- [ ] Webhook para eventos

## Autores

- Keith Yoder - Desenvolvedor inicial