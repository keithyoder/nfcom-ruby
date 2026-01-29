# frozen_string_literal: true

require 'spec_helper'
require 'nfcom/models/nota'
require 'nfcom/configuration'

RSpec.describe Nfcom::Client do
  subject(:client) { described_class.new(configuration) }

  let(:configuration) do
    instance_double(
      Nfcom::Configuration,
      certificado_path: '/tmp/cert.pfx',
      cnpj: '12345678000199',
      inscricao_estadual: '123456789',
      estado: 'PE',
      max_tentativas: 2,
      tempo_espera_retry: 0
    )
  end

  describe '#initialize' do
    it 'raises when configuration is nil' do
      allow(Nfcom).to receive(:configuration).and_return(nil)

      expect do
        described_class.new(nil)
      end.to raise_error(Nfcom::Errors::ConfigurationError)
    end
  end

  describe '#autorizar' do
    let(:nota) do
      instance_double(
        Nfcom::Models::Nota,
        valida?: true,
        erros: [],
        gerar_chave_acesso: true
      ).tap do |n|
        allow(n).to receive(:protocolo=)
        allow(n).to receive(:data_autorizacao=)
        allow(n).to receive(:xml_autorizado=)
      end
    end

    let(:xml_assinado) { '<xml>assinado</xml>' }

    let(:resultado_autorizado) do
      {
        autorizada: true,
        protocolo: '123456789',
        data_autorizacao: '2026-01-16T08:45:59-03:00',
        xml: '<protNFCom />'
      }
    end

    before do
      allow(Nfcom::Builder::XmlBuilder)
        .to receive(:new)
        .and_return(double(gerar: '<xml/>'))

      allow(Nfcom::Builder::Signature)
        .to receive(:new)
        .and_return(double(assinar: xml_assinado))
    end

    context 'when authorization succeeds' do
      it 'returns parsed result and updates nota' do
        ws = double(enviar: double)
        parser = double(parse_autorizacao: resultado_autorizado)

        allow(Nfcom::Webservices::Autorizacao)
          .to receive(:new)
          .and_return(ws)

        allow(Nfcom::Parsers::ResponseParser)
          .to receive(:new)
          .and_return(parser)

        allow(Nfcom::Utils::XmlAuthorized)
          .to receive(:build_nfcom_proc)
          .and_return('<nfcomProc />')

        result = client.autorizar(nota)

        expect(result[:autorizada]).to be(true)
        expect(nota).to have_received(:gerar_chave_acesso)
        expect(nota).to have_received(:protocolo=).with('123456789')
        expect(nota).to have_received(:data_autorizacao=)
        expect(nota).to have_received(:xml_autorizado=)
      end
    end

    context 'when nota is invalid' do
      before do
        allow(nota).to receive_messages(valida?: false, erros: ['Erro qualquer'])
      end

      it 'raises ValidationError' do
        expect do
          client.autorizar(nota)
        end.to raise_error(Nfcom::Errors::ValidationError, /Erro qualquer/)
      end
    end

    context 'when SEFAZ rejects the nota' do
      it 'raises NotaRejeitada' do
        ws = double(enviar: double)
        parser = double

        allow(Nfcom::Webservices::Autorizacao)
          .to receive(:new)
          .and_return(ws)

        allow(Nfcom::Parsers::ResponseParser)
          .to receive(:new)
          .and_return(parser)

        allow(parser)
          .to receive(:parse_autorizacao)
          .and_raise(Nfcom::Errors::NotaRejeitada.new('539', 'Duplicidade'))

        expect do
          client.autorizar(nota)
        end.to raise_error(Nfcom::Errors::NotaRejeitada)
      end
    end

    context 'when SEFAZ is unavailable' do
      it 'retries and then raises' do
        ws = double
        allow(ws).to receive(:enviar)
          .and_raise(Nfcom::Errors::SefazIndisponivel)

        allow(Nfcom::Webservices::Autorizacao)
          .to receive(:new)
          .and_return(ws)

        expect do
          client.autorizar(nota)
        end.to raise_error(Nfcom::Errors::SefazIndisponivel)

        expect(ws).to have_received(:enviar).at_least(:twice)
      end
    end
  end

  describe '#consultar_nota' do
    it 'delegates to ResponseParser' do
      ws = double
      response = double
      parser = double(parse_consulta: { situacao: 'Autorizada' })

      allow(Nfcom::Webservices::Consulta)
        .to receive(:new)
        .and_return(ws)

      allow(ws).to receive(:consultar).and_return(response)

      allow(Nfcom::Parsers::ResponseParser)
        .to receive(:new)
        .and_return(parser)

      result = client.consultar_nota(chave: '123')

      expect(result[:situacao]).to eq('Autorizada')
    end
  end

  describe '#status_servico' do
    it 'returns parsed status' do
      ws = double
      response = double
      parser = double(parse_status: { online: true })

      allow(Nfcom::Webservices::Status)
        .to receive(:new)
        .and_return(ws)

      allow(ws).to receive(:verificar).and_return(response)

      allow(Nfcom::Parsers::ResponseParser)
        .to receive(:new)
        .and_return(parser)

      result = client.status_servico

      expect(result[:online]).to be(true)
    end
  end

  describe '#inutilizar' do
    it 'raises validation error for short justification' do
      expect do
        client.inutilizar(
          serie: 1,
          numero_inicial: 1,
          numero_final: 2,
          justificativa: 'curta'
        )
      end.to raise_error(Nfcom::Errors::ValidationError)
    end
  end
end
