# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Nfcom::Builder::DanfeCom do
  subject(:danfe) { described_class.new(xml_autorizado) }

  let(:xml_autorizado) { xml_nfcom_sintetico }

  # XML sintético — sem dados reais de produção
  let(:xml_nfcom_sintetico) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <nfcomProc xmlns="http://www.portalfiscal.inf.br/nfcom" versao="1.00">
        <NFCom>
          <infNFCom versao="1.00" Id="NFCom26260000000001910062001000000000100000000001">
            <ide>
              <cUF>26</cUF>
              <tpAmb>1</tpAmb>
              <mod>62</mod>
              <serie>1</serie>
              <nNF>1</nNF>
              <cNF>0000001</cNF>
              <cDV>0</cDV>
              <dhEmi>2026-01-01T10:00:00-03:00</dhEmi>
              <tpEmis>1</tpEmis>
              <nSiteAutoriz>0</nSiteAutoriz>
              <cMunFG>2611606</cMunFG>
              <finNFCom>0</finNFCom>
              <tpFat>0</tpFat>
              <verProc>Nfcom-Ruby-Test</verProc>
            </ide>
            <emit>
              <CNPJ>00000000000191</CNPJ>
              <IE>000000000</IE>
              <CRT>1</CRT>
              <xNome>Provedor Teste LTDA</xNome>
              <xFant>Provedor Teste</xFant>
              <enderEmit>
                <xLgr>Rua Teste</xLgr>
                <nro>1</nro>
                <xBairro>Centro</xBairro>
                <cMun>2611606</cMun>
                <xMun>Recife</xMun>
                <CEP>50000000</CEP>
                <UF>PE</UF>
              </enderEmit>
            </emit>
            <dest>
              <xNome>Cliente Teste</xNome>
              <CPF>52998224725</CPF>
              <indIEDest>9</indIEDest>
              <enderDest>
                <xLgr>Rua do Cliente</xLgr>
                <nro>100</nro>
                <xBairro>Bairro Teste</xBairro>
                <cMun>2611606</cMun>
                <xMun>Recife</xMun>
                <CEP>50100000</CEP>
                <UF>PE</UF>
                <cPais>1058</cPais>
                <xPais>Brasil</xPais>
              </enderDest>
            </dest>
            <assinante>
              <iCodAssinante>1000</iCodAssinante>
              <tpAssinante>3</tpAssinante>
              <tpServUtil>4</tpServUtil>
              <nContrato>9999</nContrato>
              <dContratoIni>2020-01-01</dContratoIni>
            </assinante>
            <det nItem="1">
              <prod>
                <cProd>0303</cProd>
                <xProd>Internet 100Mbps</xProd>
                <cClass>0100401</cClass>
                <CFOP>5307</CFOP>
                <uMed>4</uMed>
                <qFaturada>1.0000</qFaturada>
                <vItem>99.90</vItem>
                <vProd>99.90</vProd>
              </prod>
              <imposto>
                <ICMS00>
                  <CST>00</CST>
                  <vBC>0.00</vBC>
                  <pICMS>0.00</pICMS>
                  <vICMS>0.00</vICMS>
                </ICMS00>
              </imposto>
            </det>
            <total>
              <vProd>99.90</vProd>
              <ICMSTot>
                <vBC>0.00</vBC>
                <vICMS>0.00</vICMS>
                <vICMSDeson>0.00</vICMSDeson>
                <vFCP>0.00</vFCP>
              </ICMSTot>
              <vCOFINS>0.00</vCOFINS>
              <vPIS>0.00</vPIS>
              <vFUNTTEL>0.00</vFUNTTEL>
              <vFUST>0.00</vFUST>
              <vRetTribTot>
                <vRetPIS>0.00</vRetPIS>
                <vRetCofins>0.00</vRetCofins>
                <vRetCSLL>0.00</vRetCSLL>
                <vIRRF>0.00</vIRRF>
              </vRetTribTot>
              <vDesc>0.00</vDesc>
              <vOutro>0.00</vOutro>
              <vNF>99.90</vNF>
            </total>
            <gFat>
              <CompetFat>202601</CompetFat>
              <dVencFat>2026-01-30</dVencFat>
              <dPerUsoIni>2025-12-31</dPerUsoIni>
              <dPerUsoFim>2026-01-30</dPerUsoFim>
              <codBarras>36497000000000059900000100039537600000179159</codBarras>
            </gFat>
            <infAdic>
              <infCpl>Documento emitido por ME ou EPP optante pelo Simples Nacional.</infCpl>
            </infAdic>
          </infNFCom>
        </NFCom>
        <protNFCom versao="1.00">
          <infProt Id="NFCom0000000000000001">
            <tpAmb>1</tpAmb>
            <verAplic>RS20260105081314</verAplic>
            <chNFCom>26260000000001910062001000000000100000000001</chNFCom>
            <dhRecbto>2026-01-01T10:00:00-03:00</dhRecbto>
            <nProt>0000000000000001</nProt>
            <digVal>AAAAAAAAAAAAAAAAAAAAAAAAAAAA=</digVal>
            <cStat>100</cStat>
            <xMotivo>Autorizado o uso da NFCom</xMotivo>
          </infProt>
        </protNFCom>
      </nfcomProc>
    XML
  end

  let(:xml_homologacao) do
    xml_nfcom_sintetico.gsub('<tpAmb>1</tpAmb>', '<tpAmb>2</tpAmb>')
  end

  describe '#initialize' do
    it 'inicializa com XML válido' do
      expect(danfe).to be_a(described_class)
    end

    it 'lança XmlError para XML vazio' do
      expect { described_class.new('') }.to raise_error(Nfcom::Errors::XmlError, /vazio/)
    end

    it 'lança XmlError para XML nil' do
      expect { described_class.new(nil) }.to raise_error(Nfcom::Errors::XmlError, /vazio/)
    end

    it 'lança XmlError para XML sem elemento NFCom' do
      expect { described_class.new('<outro/>') }.to raise_error(
        Nfcom::Errors::XmlError, /não contém elemento NFCom/
      )
    end
  end

  describe '#gerar' do
    it 'retorna bytes de PDF' do
      pdf = danfe.gerar
      expect(pdf[0..3]).to eq('%PDF')
    end

    it 'retorna uma String' do
      expect(danfe.gerar).to be_a(String)
    end
  end

  describe 'métodos privados de formatação' do
    describe '#formatar_competencia' do
      it 'formata AAAAMM para MM/AAAA' do
        expect(danfe.send(:formatar_competencia, '202601')).to eq('01/2026')
      end

      it 'retorna string vazia para nil' do
        expect(danfe.send(:formatar_competencia, nil)).to eq('')
      end
    end

    describe '#formatar_chave_acesso' do
      it 'agrupa em blocos de 4 separados por espaço' do
        chave = '12345678901234567890123456789012345678901234'
        resultado = danfe.send(:formatar_chave_acesso, chave)
        expect(resultado.split(' ').length).to eq(11)
      end

      it 'retorna string vazia para nil' do
        expect(danfe.send(:formatar_chave_acesso, nil)).to eq('')
      end
    end

    describe '#tipo_documento' do
      it 'retorna NFCom Normal para finNFCom 0' do
        expect(danfe.send(:tipo_documento, '0')).to eq('NFCom Normal')
      end

      it 'retorna NFCom de Substituição para finNFCom 3' do
        expect(danfe.send(:tipo_documento, '3')).to eq('NFCom de Substituição')
      end

      it 'retorna NFCom de Ajuste para finNFCom 4' do
        expect(danfe.send(:tipo_documento, '4')).to eq('NFCom de Ajuste')
      end

      it 'retorna NFCom para código desconhecido' do
        expect(danfe.send(:tipo_documento, '9')).to eq('NFCom')
      end
    end

    describe '#tipo_ambiente' do
      it 'retorna 1 para produção' do
        expect(danfe.send(:tipo_ambiente)).to eq(1)
      end

      it 'retorna 2 para homologação' do
        danfe_homol = described_class.new(xml_homologacao)
        expect(danfe_homol.send(:tipo_ambiente)).to eq(2)
      end
    end

    describe '#formatar_data_hora_xml' do
      it 'formata datetime ISO para DD/MM/AAAA HH:MM:SS' do
        expect(danfe.send(:formatar_data_hora_xml, '2026-01-29T22:18:31-03:00'))
          .to eq('29/01/2026 22:18:31')
      end

      it 'retorna string vazia para nil' do
        expect(danfe.send(:formatar_data_hora_xml, nil)).to eq('')
      end

      it 'retorna o valor original para formato inválido' do
        expect(danfe.send(:formatar_data_hora_xml, 'invalido')).to eq('invalido')
      end
    end

    describe '#montar_endereco_linha' do
      it 'monta linha com logradouro e número' do
        info = { logradouro: 'Rua Teste', numero: '123', complemento: nil, bairro: 'Centro' }
        expect(danfe.send(:montar_endereco_linha, info)).to eq('Rua Teste, 123 - Centro')
      end

      it 'inclui complemento quando presente' do
        info = { logradouro: 'Rua Teste', numero: '123', complemento: 'Apto 1', bairro: 'Centro' }
        expect(danfe.send(:montar_endereco_linha, info)).to eq('Rua Teste, 123 - Apto 1 - Centro')
      end

      it 'retorna string vazia para nil' do
        expect(danfe.send(:montar_endereco_linha, nil)).to eq('')
      end
    end

    describe '#tipo_servico_texto' do
      it 'retorna descrição para código 4 (internet)' do
        expect(danfe.send(:tipo_servico_texto, '4')).to eq('Provimento de acesso à Internet')
      end

      it 'retorna o próprio código para código desconhecido' do
        expect(danfe.send(:tipo_servico_texto, '99')).to eq('99')
      end
    end
  end
end
