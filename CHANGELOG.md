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

[Unreleased]: https://github.com/keithyoder/nfcom/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/keithyoder/nfcom/releases/tag/v0.1.0
