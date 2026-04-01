# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Nfcom::Client do
  subject(:client) { described_class.new(configuration) }

  include_context 'com configuração padrão'

  describe '#initialize' do
    it 'lança ConfigurationError quando configuration é nil' do
      allow(Nfcom).to receive(:configuration).and_return(nil)

      expect { described_class.new(nil) }.to raise_error(Nfcom::Errors::ConfigurationError)
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

      allow(Nfcom::Validators::XmlValidator)
        .to receive(:new)
        .and_return(double(validar: true))

      allow(Nfcom::Utils::XmlAuthorized)
        .to receive(:build_nfcom_proc)
        .and_return('<nfcomProc />')
    end

    context 'quando autorização é bem-sucedida' do
      it 'retorna resultado e atualiza a nota' do
        ws     = double(enviar: double)
        parser = double(parse: resultado_autorizado)

        allow(Nfcom::Webservices::Autorizacao).to receive(:new).and_return(ws)
        allow(Nfcom::Parsers::Autorizacao).to receive(:new).and_return(parser)

        result = client.autorizar(nota)

        aggregate_failures do
          expect(result[:autorizada]).to be true
          expect(nota).to have_received(:gerar_chave_acesso)
          expect(nota).to have_received(:protocolo=).with('123456789')
          expect(nota).to have_received(:data_autorizacao=)
          expect(nota).to have_received(:xml_autorizado=)
        end
      end
    end

    context 'quando nota é inválida' do
      before { allow(nota).to receive_messages(valida?: false, erros: ['Erro qualquer']) }

      it 'lança ValidationError' do
        expect { client.autorizar(nota) }.to raise_error(
          Nfcom::Errors::ValidationError, /Erro qualquer/
        )
      end
    end

    context 'quando SEFAZ rejeita a nota' do
      it 'lança NotaRejeitada' do
        ws     = double(enviar: double)
        parser = double

        allow(Nfcom::Webservices::Autorizacao).to receive(:new).and_return(ws)
        allow(Nfcom::Parsers::Autorizacao).to receive(:new).and_return(parser)
        allow(parser).to receive(:parse)
          .and_raise(Nfcom::Errors::NotaRejeitada.new('539', 'Duplicidade'))

        expect { client.autorizar(nota) }.to raise_error(Nfcom::Errors::NotaRejeitada)
      end
    end

    context 'quando SEFAZ está indisponível' do
      it 'tenta novamente e lança SefazIndisponivel' do
        ws = double
        allow(ws).to receive(:enviar).and_raise(Nfcom::Errors::SefazIndisponivel)
        allow(Nfcom::Webservices::Autorizacao).to receive(:new).and_return(ws)

        expect { client.autorizar(nota) }.to raise_error(Nfcom::Errors::SefazIndisponivel)

        expect(ws).to have_received(:enviar).at_least(:twice)
      end
    end
  end

  describe '#consultar_nota' do
    it 'delega ao parser de consulta' do
      ws       = double(consultar: double)
      parser   = double(parse: { situacao: 'Autorizada' })

      allow(Nfcom::Webservices::Consulta).to receive(:new).and_return(ws)
      allow(Nfcom::Parsers::Consulta).to receive(:new).and_return(parser)

      result = client.consultar_nota(chave: '26260107159053000107620010000031981083465102')

      expect(result[:situacao]).to eq('Autorizada')
    end
  end

  describe '#status_servico' do
    it 'retorna status parseado' do
      ws     = double(verificar: double)
      parser = double(parse: { online: true })

      allow(Nfcom::Webservices::Status).to receive(:new).and_return(ws)
      allow(Nfcom::Parsers::Status).to receive(:new).and_return(parser)

      expect(client.status_servico[:online]).to be true
    end
  end

  describe '#inutilizar' do
    it 'lança ValidationError para justificativa curta' do
      expect do
        client.inutilizar(
          serie: 1,
          numero_inicial: 1,
          numero_final: 2,
          justificativa: 'curta'
        )
      end.to raise_error(Nfcom::Errors::ValidationError)
    end

    it 'delega ao parser de inutilização' do
      ws     = double(inutilizar: double)
      parser = double(parse: { inutilizada: true, protocolo: '123' })

      allow(Nfcom::Webservices::Inutilizacao).to receive(:new).and_return(ws)
      allow(Nfcom::Parsers::Inutilizacao).to receive(:new).and_return(parser)

      result = client.inutilizar(
        serie: 1,
        numero_inicial: 1,
        numero_final: 5,
        justificativa: 'Justificativa com pelo menos quinze caracteres'
      )

      expect(result[:inutilizada]).to be true
    end
  end
end
