# frozen_string_literal: true

require 'spec_helper'

NFCOM_NS = 'http://www.portalfiscal.inf.br/nfcom'

RSpec.describe Nfcom::Builder::XmlBuilder do
  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------
  def el(doc, xpath)
    doc.at_xpath(xpath, 'n' => NFCOM_NS)
  end

  def els(doc, xpath)
    doc.xpath(xpath, 'n' => NFCOM_NS)
  end

  # ---------------------------------------------------------------------------
  # Shared fixtures
  # ---------------------------------------------------------------------------
  let(:configuration) do
    Nfcom.configure do |c|
      c.estado   = 'PE'
      c.ambiente = :homologacao
    end
    Nfcom.configuration
  end

  let(:emitente) do
    e = Nfcom::Models::Emitente.new(
      cnpj: '12345678000195',
      razao_social: 'Provedor Teste LTDA',
      inscricao_estadual: '123456789',
      regime_tributario: :simples_nacional
    )
    e.endereco = Nfcom::Models::Endereco.new(
      logradouro: 'Rua Teste',
      numero: '123',
      bairro: 'Centro',
      municipio: 'Recife',
      uf: 'PE',
      cep: '50000000',
      codigo_municipio: '2611606'
    )
    e
  end

  let(:destinatario) do
    d = Nfcom::Models::Destinatario.new(
      cpf: '12345678909',
      razao_social: 'Cliente Teste'
    )
    d.endereco = Nfcom::Models::Endereco.new(
      logradouro: 'Av Cliente',
      numero: '456',
      bairro: 'Boa Vista',
      municipio: 'Recife',
      uf: 'PE',
      cep: '51000000',
      codigo_municipio: '2611606'
    )
    d
  end

  let(:fatura) do
    Nfcom::Models::Fatura.new(
      competencia: '202601',
      data_vencimento: Date.new(2026, 1, 30),
      valor_fatura: 99.90,
      codigo_barras: '83620000000999000000000000000000000000000000'
    )
  end

  let(:classe_consumo_valida) { Nfcom::Models::Item::CLASSES_CONSUMO.values.first }

  let(:nota) do
    n = Nfcom::Models::Nota.new(serie: 1, numero: 42)
    n.emitente            = emitente
    n.destinatario        = destinatario
    n.fatura              = fatura
    n.chave_acesso        = '26260112345678000195620010000000421234567890'
    n.codigo_verificacao  = '1234567'
    n.add_item(
      codigo_servico: '0303',
      descricao: 'Plano Fibra 100MB',
      classe_consumo: classe_consumo_valida,
      cfop: '5307',
      unidade: :un,
      quantidade: 1.0,
      valor_unitario: 99.90
    )
    n
  end

  let(:xml_string) { described_class.new(nota, configuration).gerar }
  let(:doc)        { Nokogiri::XML(xml_string) }

  # ---------------------------------------------------------------------------

  describe '#gerar' do
    it 'retorna uma string XML válida' do
      expect(xml_string).to be_a(String)
      expect(doc.errors).to be_empty
    end

    it 'tem o namespace correto no elemento raiz' do
      expect(doc.root.namespace.href).to eq(NFCOM_NS)
    end

    it 'inclui infNFCom com versao e Id corretos' do
      inf = el(doc, '//n:infNFCom')

      aggregate_failures do
        expect(inf['versao']).to eq('1.00')
        expect(inf['Id']).to eq("NFCom#{nota.chave_acesso}")
      end
    end
  end

  # ---------------------------------------------------------------------------

  describe 'grupo ide' do
    it 'contém os campos obrigatórios corretos' do
      aggregate_failures do
        expect(el(doc, '//n:ide/n:cUF').text).to eq('26')
        expect(el(doc, '//n:ide/n:tpAmb').text).to eq('2')
        expect(el(doc, '//n:ide/n:mod').text).to eq('62')
        expect(el(doc, '//n:ide/n:serie').text).to eq('1')
        expect(el(doc, '//n:ide/n:nNF').text).to eq('42')
        expect(el(doc, '//n:ide/n:finNFCom').text).to eq('0')
        expect(el(doc, '//n:ide/n:tpFat').text).to eq('0')
        expect(el(doc, '//n:ide/n:verProc').text).to eq('Nfcom-Ruby-1.0')
      end
    end

    context 'dado finalidade :substituicao' do
      before { nota.finalidade = :substituicao }

      it 'emite finNFCom = 3' do
        expect(el(doc, '//n:ide/n:finNFCom').text).to eq('3')
      end
    end
  end

  # ---------------------------------------------------------------------------

  describe 'grupo emit' do
    it 'contém CNPJ, IE e xNome do emitente' do
      aggregate_failures do
        expect(el(doc, '//n:emit/n:CNPJ').text).to eq('12345678000195')
        expect(el(doc, '//n:emit/n:IE').text).to eq('123456789')
        expect(el(doc, '//n:emit/n:xNome').text).to eq('Provedor Teste LTDA')
      end
    end

    it 'contém o endereço do emitente' do
      aggregate_failures do
        expect(el(doc, '//n:emit/n:enderEmit/n:xLgr').text).to eq('Rua Teste')
        expect(el(doc, '//n:emit/n:enderEmit/n:UF').text).to eq('PE')
        expect(el(doc, '//n:emit/n:enderEmit/n:CEP').text).to eq('50000000')
      end
    end

    context 'quando emitente tem nome fantasia' do
      before { emitente.nome_fantasia = 'Tessi Telecom' }

      it 'inclui xFant' do
        expect(el(doc, '//n:emit/n:xFant').text).to eq('Tessi Telecom')
      end
    end

    context 'quando emitente não tem nome fantasia' do
      it 'não inclui xFant' do
        expect(el(doc, '//n:emit/n:xFant')).to be_nil
      end
    end
  end

  # ---------------------------------------------------------------------------

  describe 'grupo dest' do
    context 'dado destinatário pessoa física' do
      it 'usa CPF e indIEDest = 9' do
        aggregate_failures do
          expect(el(doc, '//n:dest/n:CPF').text).to eq('12345678909')
          expect(el(doc, '//n:dest/n:CNPJ')).to be_nil
          expect(el(doc, '//n:dest/n:indIEDest').text).to eq('9')
        end
      end
    end

    context 'dado destinatário pessoa jurídica sem IE' do
      before do
        dest = Nfcom::Models::Destinatario.new(cnpj: '98765432000100', razao_social: 'Empresa LTDA')
        dest.endereco = destinatario.endereco
        nota.destinatario = dest
      end

      it 'usa CNPJ e indIEDest = 9' do
        aggregate_failures do
          expect(el(doc, '//n:dest/n:CNPJ').text).to eq('98765432000100')
          expect(el(doc, '//n:dest/n:CPF')).to be_nil
          expect(el(doc, '//n:dest/n:indIEDest').text).to eq('9')
        end
      end
    end

    context 'dado destinatário pessoa jurídica com IE' do
      before do
        dest = Nfcom::Models::Destinatario.new(
          cnpj: '98765432000100',
          razao_social: 'Empresa Contrib LTDA',
          inscricao_estadual: '987654321'
        )
        dest.endereco = destinatario.endereco
        nota.destinatario = dest
      end

      it 'usa CNPJ, IE e indIEDest = 1' do
        aggregate_failures do
          expect(el(doc, '//n:dest/n:CNPJ').text).to eq('98765432000100')
          expect(el(doc, '//n:dest/n:IE').text).to eq('987654321')
          expect(el(doc, '//n:dest/n:indIEDest').text).to eq('1')
        end
      end
    end

    it 'contém o endereço do destinatário com cPais e xPais' do
      aggregate_failures do
        expect(el(doc, '//n:dest/n:enderDest/n:xLgr').text).to eq('Av Cliente')
        expect(el(doc, '//n:dest/n:enderDest/n:UF').text).to eq('PE')
        expect(el(doc, '//n:dest/n:enderDest/n:cPais').text).to eq('1058')
        expect(el(doc, '//n:dest/n:enderDest/n:xPais').text).to eq('Brasil')
      end
    end
  end

  # ---------------------------------------------------------------------------

  describe 'grupo assinante' do
    context 'quando nota não tem assinante' do
      it 'não inclui o elemento assinante' do
        expect(el(doc, '//n:assinante')).to be_nil
      end
    end

    context 'quando nota tem assinante' do
      before do
        nota.assinante = Nfcom::Models::Assinante.new(
          codigo: '42',
          tipo: Nfcom::Models::Assinante::TIPO_RESIDENCIAL,
          tipo_servico: Nfcom::Models::Assinante::SERVICO_INTERNET,
          numero_contrato: '999'
        )
      end

      it 'inclui iCodAssinante, tpAssinante e nContrato' do
        aggregate_failures do
          expect(el(doc, '//n:assinante/n:iCodAssinante').text).to eq('42')
          expect(el(doc, '//n:assinante/n:tpAssinante').text).to eq(
            Nfcom::Models::Assinante::TIPO_RESIDENCIAL.to_s
          )
          expect(el(doc, '//n:assinante/n:nContrato').text).to eq('999')
        end
      end
    end
  end

  # ---------------------------------------------------------------------------

  describe 'grupo gSub (substituição)' do
    let(:chave_original) { '26260107159053000107620010000031981083465102' }

    context 'quando finalidade é :normal' do
      it 'não inclui gSub' do
        expect(el(doc, '//n:gSub')).to be_nil
      end
    end

    context 'quando finalidade é :substituicao com chave e motivo' do
      before do
        nota.finalidade              = :substituicao
        nota.chave_nfcom_substituida = chave_original
        nota.motivo_substituicao     = '01'
      end

      it 'inclui gSub com chNFCom e motSub' do
        aggregate_failures do
          expect(el(doc, '//n:gSub/n:chNFCom').text).to eq(chave_original)
          expect(el(doc, '//n:gSub/n:motSub').text).to eq('01')
        end
      end

      it 'posiciona gSub antes de det' do
        nomes = el(doc, '//n:infNFCom').children.select(&:element?).map(&:name)

        expect(nomes.index('gSub')).to be < nomes.index('det')
      end
    end

    context 'quando chave_nfcom_substituida é nil' do
      before do
        nota.finalidade          = :substituicao
        nota.motivo_substituicao = '01'
      end

      it 'não inclui gSub (guard do método)' do
        expect(el(doc, '//n:gSub')).to be_nil
      end
    end

    it 'formata motSub com dois dígitos quando motivo é inteiro' do
      nota.finalidade              = :substituicao
      nota.chave_nfcom_substituida = chave_original
      nota.motivo_substituicao     = 1

      expect(el(doc, '//n:gSub/n:motSub').text).to eq('01')
    end
  end

  # ---------------------------------------------------------------------------

  describe 'grupo det (itens)' do
    it 'gera um det por item' do
      expect(els(doc, '//n:det').size).to eq(1)
    end

    it 'numera os itens sequencialmente pelo atributo nItem' do
      nota.add_item(
        codigo_servico: '0304',
        descricao: 'Segundo Serviço',
        classe_consumo: classe_consumo_valida,
        cfop: '5307',
        unidade: :un,
        quantidade: 1.0,
        valor_unitario: 10.00
      )

      expect(els(doc, '//n:det').map { |d| d['nItem'].to_i }).to eq([1, 2])
    end

    it 'inclui prod com os campos obrigatórios' do
      aggregate_failures do
        expect(el(doc, '//n:det/n:prod/n:cProd').text).to eq('0303')
        expect(el(doc, '//n:det/n:prod/n:xProd').text).to eq('Plano Fibra 100MB')
        expect(el(doc, '//n:det/n:prod/n:CFOP').text).to eq('5307')
        expect(el(doc, '//n:det/n:prod/n:vProd').text).to eq('99.90')
      end
    end

    it 'inclui ICMS00 no imposto' do
      aggregate_failures do
        expect(el(doc, '//n:det/n:imposto/n:ICMS00/n:CST').text).to eq('00')
        expect(el(doc, '//n:det/n:imposto/n:ICMS00/n:vBC').text).to eq('0.00')
        expect(el(doc, '//n:det/n:imposto/n:ICMS00/n:vICMS').text).to eq('0.00')
      end
    end

    context 'quando item tem desconto' do
      before do
        nota.itens.first.valor_desconto = 10.00
        nota.recalcular_totais
      end

      it 'inclui vDesc no prod' do
        expect(el(doc, '//n:det/n:prod/n:vDesc')).not_to be_nil
      end
    end
  end

  # ---------------------------------------------------------------------------

  describe 'grupo total' do
    it 'contém vProd e vNF' do
      aggregate_failures do
        expect(el(doc, '//n:total/n:vProd').text).to eq('99.90')
        expect(el(doc, '//n:total/n:vNF').text).to eq('99.90')
      end
    end

    it 'contém ICMSTot com zeros para Simples Nacional' do
      aggregate_failures do
        expect(el(doc, '//n:total/n:ICMSTot/n:vBC').text).to eq('0.00')
        expect(el(doc, '//n:total/n:ICMSTot/n:vICMS').text).to eq('0.00')
      end
    end
  end

  # ---------------------------------------------------------------------------

  describe 'grupo gFat' do
    it 'contém CompetFat, dVencFat e codBarras' do
      aggregate_failures do
        expect(el(doc, '//n:gFat/n:CompetFat').text).to eq('202601')
        expect(el(doc, '//n:gFat/n:dVencFat').text).to eq('2026-01-30')
        expect(el(doc, '//n:gFat/n:codBarras')).not_to be_nil
      end
    end

    context 'quando fatura tem período de uso' do
      before do
        nota.fatura.periodo_uso_inicio = Date.new(2025, 12, 31)
        nota.fatura.periodo_uso_fim    = Date.new(2026, 1, 30)
      end

      it 'inclui dPerUsoIni e dPerUsoFim' do
        aggregate_failures do
          expect(el(doc, '//n:gFat/n:dPerUsoIni').text).to eq('2025-12-31')
          expect(el(doc, '//n:gFat/n:dPerUsoFim').text).to eq('2026-01-30')
        end
      end
    end

    context 'quando fatura não tem período de uso' do
      it 'não inclui dPerUsoIni nem dPerUsoFim' do
        aggregate_failures do
          expect(el(doc, '//n:gFat/n:dPerUsoIni')).to be_nil
          expect(el(doc, '//n:gFat/n:dPerUsoFim')).to be_nil
        end
      end
    end
  end

  # ---------------------------------------------------------------------------

  describe 'grupo infAdic' do
    context 'quando nota não tem informacoes_adicionais' do
      it 'não inclui infAdic' do
        expect(el(doc, '//n:infAdic')).to be_nil
      end
    end

    context 'quando nota tem informacoes_adicionais' do
      before { nota.informacoes_adicionais = "Simples Nacional\nSem crédito IPI" }

      it 'inclui um infCpl por linha' do
        cpls = els(doc, '//n:infAdic/n:infCpl')

        aggregate_failures do
          expect(cpls.size).to eq(2)
          expect(cpls[0].text).to eq('Simples Nacional')
          expect(cpls[1].text).to eq('Sem crédito IPI')
        end
      end
    end
  end

  # ---------------------------------------------------------------------------

  describe 'grupo infNFComSupl' do
    it 'inclui qrCodNFCom com a chave de acesso e ambiente correto' do
      qr = el(doc, '//n:infNFComSupl/n:qrCodNFCom')

      aggregate_failures do
        expect(qr.text).to include(nota.chave_acesso)
        expect(qr.text).to include('tpAmb=2')
      end
    end
  end

  # ---------------------------------------------------------------------------

  describe 'ordem dos elementos em infNFCom' do
    it 'respeita a sequência: ide, emit, dest, det, total, gFat' do
      nomes = el(doc, '//n:infNFCom').children.select(&:element?).map(&:name)

      %w[ide emit dest det total gFat].each_cons(2) do |anterior, posterior|
        expect(nomes.index(anterior)).to be < nomes.index(posterior),
                                         "Esperava #{anterior} antes de #{posterior}, mas got #{nomes}"
      end
    end

    context 'dado nota com substituição e assinante' do
      before do
        nota.assinante = Nfcom::Models::Assinante.new(
          codigo: '1',
          tipo: Nfcom::Models::Assinante::TIPO_RESIDENCIAL,
          tipo_servico: Nfcom::Models::Assinante::SERVICO_INTERNET
        )
        nota.finalidade              = :substituicao
        nota.chave_nfcom_substituida = '26260107159053000107620010000031981083465102'
        nota.motivo_substituicao     = '01'
      end

      it 'posiciona assinante antes de gSub e gSub antes de det' do
        nomes = el(doc, '//n:infNFCom').children.select(&:element?).map(&:name)

        aggregate_failures do
          expect(nomes.index('assinante')).to be < nomes.index('gSub')
          expect(nomes.index('gSub')).to be < nomes.index('det')
        end
      end
    end
  end
end
