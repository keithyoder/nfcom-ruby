# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2025-12-30

### Added
- Estrutura inicial da gem
- Configuração básica via `Nfcom.configure`
- Modelos: Nota, Emitente, Destinatario, Item, Total, Endereco
- Builder de XML conforme layout NF-COM 1.00
- Assinatura digital com certificado A1/A3
- Validação de CNPJ, CPF e CEP
- Webservices SOAP para:
  - Autorização de notas
  - Consulta de notas
  - Status do serviço
  - Inutilização de numeração
- Parser de respostas da SEFAZ
- Validador de XML
- Validador de regras de negócio
- Geração de chave de acesso
- Geração de URL para QR Code
- Retry automático em caso de falhas
- Tratamento de erros específicos
- Helper utilities
- Gerenciador de certificado digital
- Suporte a ambiente de homologação e produção
- Suporte inicial para PE (Pernambuco)
- Documentação completa
- Exemplos de uso
- Testes RSpec (estrutura)

### Notes
- Versão inicial (MVP)
- Suporte apenas para Pernambuco no momento
- Validação XSD será implementada em versão futura
- Contingência (FS-DA) será implementada em versão futura
- Cancelamento será implementado em versão futura

## [0.1.1] - 2026-01-15

### Added
- Gerador de DANFE-COM em PDF via Prawn (`Nfcom::DanfeCom`)
  - Layout completo: cabeçalho, emitente, destinatário, itens, totais, fatura
  - Exibição do período de uso do serviço (`dPerUsoIni` / `dPerUsoFim`)
  - Banner do Simples Nacional quando `CRT = 1`
  - Suporte a logotipo (PNG e SVG via prawn-svg)
  - Formatação de código de barras e exibição de QR Code
  - Layout dinâmico adaptável ao conteúdo
- Gerador de código de barras (`Nfcom::Models::Fatura::CodigoDeBarras`)
- Modelo `Formato44` para representação da linha digitável

## [0.1.2] - 2026-03-31

### Added
- Suporte a notas de substituição (`finalidade: :substituicao`)
  - Atributos `chave_nfcom_substituida` e `motivo_substituicao` no modelo `Nota`
  - Geração do grupo `gSub` no XML (`chNFCom` + `motSub`) conforme schema NFCom v1.00
  - Validação de presença e formato da chave substituída (44 dígitos) e do motivo (D26)
  - Todos os 5 motivos de substituição suportados: erro de preço, erro cadastral, decisão judicial, erro de tributação e descontinuidade do serviço

## [0.1.3] - 2026-05-18

### Changed
- Refatoração do parser de respostas: `ResponseParser` substituído por hierarquia `Base` + subclasses `Autorizacao`, `Status`, `Consulta`, `Inutilizacao`, cada uma com método `#parse`
- `client.rb` atualizado para usar as novas classes de parser
- Correção do `SOAPAction` em `webservices/status.rb` (`nfcomStatusServicoNF`)
- Correção do `montar_envelope` em `webservices/base.rb`: prefixo `soap:` (era `soap12:`), body envolvido com `nfcomDadosMsg`, processado via `XmlCleaner`
- Correção de `consulta.rb`: wrapper `nfcomDadosMsg` e campo `xServ` ausente adicionados
- DANFE-COM: desabilitadas requisições web do prawn-svg (`enable_web_requests: false`) em ambos os call sites de `pdf.svg`
- CI expandido para Ruby 3.2, 3.3 e 3.4; RuboCop executado apenas no Ruby 3.4

### Tests
- Adicionados shared contexts para certificado mockado e configuração padrão
- Adicionadas specs de parser para as quatro subclasses
- Adicionadas specs de webservice para `status` e `consulta`
- Specs de `autorizacao` e `signature` atualizadas para usar shared contexts
- `client_spec` atualizado para usar os novos nomes de classes de parser
- Adicionadas specs de modelo para `Emitente` e `Destinatario`
- Adicionada spec do builder `DanfeCom` com XML de fixture sintético
- Removido `response_parser_spec.rb`