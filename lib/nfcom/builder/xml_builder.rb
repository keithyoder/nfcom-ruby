# frozen_string_literal: true

require 'nokogiri'

module Nfcom
  module Builder
    # Construtor de XML para NFCom (Nota Fiscal de Comunicação)
    #
    # Esta classe é responsável por gerar o XML completo da NFCom
    # seguindo o layout 1.00 do schema oficial da SEFAZ.
    class XmlBuilder
      include Utils::Helpers

      attr_reader :nota, :configuration

      VERSAO_LAYOUT = '1.00'
      NAMESPACE = 'http://www.portalfiscal.inf.br/nfcom'
      MODELO_NFCOM = 62

      # Indicadores de IE do destinatário
      INDIEDEST_CONTRIBUINTE = 1
      INDIEDEST_ISENTO = 2
      INDIEDEST_NAO_CONTRIBUINTE = 9

      def initialize(nota, configuration)
        @nota = nota
        @configuration = configuration
      end

      # Gera o XML completo da NFCom
      # @return [String] XML formatado em UTF-8
      def gerar
        builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          xml.NFCom(xmlns: NAMESPACE) do
            xml.infNFCom(versao: VERSAO_LAYOUT, Id: "NFCom#{nota.chave_acesso}") do
              gerar_ide(xml)
              gerar_emit(xml)
              gerar_dest(xml)
              gerar_assinante(xml) if nota.assinante
              # gSub iria aqui (substituição)
              # gCofat iria aqui (cofaturamento)
              gerar_detalhes(xml)
              gerar_total(xml)
              # gFidelidade iria aqui (programa de fidelidade)
              gerar_fatura(xml) if nota.fatura
              # gFatCentral iria aqui (faturamento centralizado)
              # autXML iria aqui (autorizados para download)
              gerar_info_adicional(xml) if nota.informacoes_adicionais
              # gRespTec iria aqui (responsável técnico)
            end

            gerar_info_suplementar(xml)
          end
        end

        builder.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)
      end

      private

      # Gera o grupo de identificação da NFCom (tag ide)
      def gerar_ide(xml)
        xml.ide do
          xml.cUF configuration.codigo_uf
          xml.tpAmb configuration.ambiente_codigo
          xml.mod MODELO_NFCOM
          xml.serie nota.serie
          xml.nNF nota.numero
          xml.cNF nota.codigo_verificacao
          xml.cDV nota.chave_acesso[-1].to_i
          xml.dhEmi formatar_data_hora(nota.data_emissao)
          xml.tpEmis nota.tipo_emissao_codigo
          xml.nSiteAutoriz 0 # Zero para autorizador com único site
          xml.cMunFG nota.emitente.endereco.codigo_municipio
          xml.finNFCom nota.finalidade_codigo
          xml.tpFat nota.tipo_faturamento || 0 # 0=Normal, 1=Centralizado, 2=Cofaturamento
          xml.verProc 'Nfcom-Ruby-1.0'

          # Campos de contingência (se aplicável)
          if nota.tipo_emissao == :contingencia
            xml.dhCont formatar_data_hora(nota.data_contingencia) if nota.data_contingencia
            xml.xJust limitar_texto(nota.justificativa_contingencia, 256) if nota.justificativa_contingencia
          end
        end
      end

      # Gera o grupo de dados do emitente (tag emit)
      def gerar_emit(xml)
        xml.emit do
          xml.CNPJ apenas_numeros(nota.emitente.cnpj)
          xml.IE apenas_numeros(nota.emitente.inscricao_estadual)
          # IEUFDest - IE virtual na UF destino (opcional para partilha)
          xml.CRT nota.emitente.regime_tributario_codigo || 3 # 1=Simples, 2=Simples excesso, 3=Normal
          xml.xNome limitar_texto(nota.emitente.razao_social, 60)
          xml.xFant limitar_texto(nota.emitente.nome_fantasia, 60) if nota.emitente.nome_fantasia
          gerar_endereco(xml, nota.emitente.endereco, 'emit')
        end
      end

      # Gera o grupo de dados do destinatário (tag dest)
      def gerar_dest(xml)
        xml.dest do
          xml.xNome limitar_texto(nota.destinatario.razao_social, 60)

          cpf  = apenas_numeros(nota.destinatario.cpf)
          cnpj = apenas_numeros(nota.destinatario.cnpj)
          ie   = apenas_numeros(nota.destinatario.inscricao_estadual)

          # CPF ou CNPJ (mutuamente exclusivo)
          if cnpj.present?
            xml.CNPJ cnpj
          else
            xml.CPF cpf
          end

          if cnpj.present? && ie.present?
            # PJ com IE → Contribuinte
            xml.indIEDest INDIEDEST_CONTRIBUINTE
            xml.IE ie
          else
            # PF ou PJ sem IE → Não contribuinte
            xml.indIEDest INDIEDEST_NAO_CONTRIBUINTE
          end

          gerar_endereco(xml, nota.destinatario.endereco, 'dest')
        end
      end

      # Gera o grupo de dados do assinante (tag assinante)
      def gerar_assinante(xml)
        assinante = nota.assinante
        return unless assinante

        xml.assinante do
          # Código único do assinante (1-30 caracteres)
          xml.iCodAssinante limitar_texto(assinante.codigo, 30)

          # Tipo: 1=Comercial, 2=Industrial, 3=Residencial, 4=Rural, 5=Público, 6=Telecom,
          # 7=Diplomático, 8=Religioso, 99=Outros
          xml.tpAssinante assinante.tipo

          # Tipo serviço: 1=Telefonia, 2=Dados, 3=TV, 4=Internet, 5=Multimídia, 6=Outros, 7=Vários
          xml.tpServUtil assinante.tipo_servico

          # Dados do contrato (opcional)
          xml.nContrato limitar_texto(assinante.numero_contrato, 20) if assinante.numero_contrato
          xml.dContratoIni formatar_data(assinante.data_inicio_contrato) if assinante.data_inicio_contrato
          xml.dContratoFim formatar_data(assinante.data_fim_contrato) if assinante.data_fim_contrato

          # Terminal principal (condicional - se informar um, deve informar ambos)
          if assinante.terminal_principal && assinante.uf_terminal_principal
            xml.NroTermPrinc apenas_numeros(assinante.terminal_principal)
            xml.cUFPrinc assinante.uf_terminal_principal
          end

          # Terminais adicionais (0-n ocorrências)
          assinante.terminais_adicionais&.each do |terminal|
            xml.NroTermAdic apenas_numeros(terminal[:numero])
            xml.cUFAdic terminal[:uf]
          end
        end
      end

      # Gera o grupo de faturamento (tag gFat)
      # Contém apenas informações de controle de cobrança, NÃO valores
      def gerar_fatura(xml)
        xml.gFat do
          # Competência no formato AAAAMM (ex: 202601)
          xml.CompetFat nota.fatura.competencia

          # Data de vencimento no formato AAAA-MM-DD
          xml.dVencFat nota.fatura.data_vencimento

          # Período de uso do serviço (ambos ou nenhum)
          if nota.fatura.periodo_uso_inicio && nota.fatura.periodo_uso_fim
            xml.dPerUsoIni formatar_data(nota.fatura.periodo_uso_inicio)
            xml.dPerUsoFim formatar_data(nota.fatura.periodo_uso_fim)
          end

          # Linha digitável do código de barras (obrigatório)
          xml.codBarras nota.fatura.codigo_barras

          # Débito automático (opcional - se informar um, deve informar todos)
          if nota.fatura.codigo_debito_automatico
            xml.codDebAuto nota.fatura.codigo_debito_automatico
            xml.codBanco nota.fatura.codigo_banco
            xml.codAgencia nota.fatura.codigo_agencia
          end

          # enderCorresp - Endereço de correspondência (opcional)
          # gPIX - Informações do PIX (opcional)
        end
      end

      # Gera o endereço do emitente ou destinatário
      # @param xml [Nokogiri::XML::Builder] Builder do XML
      # @param endereco [Endereco] Objeto com dados do endereço
      # @param tipo [String] 'emit' ou 'dest'
      def gerar_endereco(xml, endereco, tipo)
        tag_name = tipo == 'emit' ? 'enderEmit' : 'enderDest'

        xml.send(tag_name) do
          xml.xLgr limitar_texto(endereco.logradouro, 60)
          xml.nro limitar_texto(endereco.numero, 60)
          xml.xCpl limitar_texto(endereco.complemento, 60) if endereco.complemento
          xml.xBairro limitar_texto(endereco.bairro, 60)
          xml.cMun endereco.codigo_municipio
          xml.xMun limitar_texto(endereco.municipio, 60)
          xml.CEP apenas_numeros(endereco.cep)
          xml.UF endereco.uf

          # País apenas para destinatário
          if tipo == 'dest'
            xml.cPais endereco.codigo_pais || 1058 # 1058 = Brasil (tabela BACEN)
            xml.xPais endereco.pais || 'Brasil'
          end

          xml.fone apenas_numeros(endereco.telefone) if endereco.telefone
        end
      end

      # Gera os itens/serviços da NFCom (tag det)
      def gerar_detalhes(xml)
        nota.itens.each do |item|
          xml.det(nItem: item.numero_item) do
            gerar_produto(xml, item)
            gerar_impostos_item(xml, item)
          end
        end
      end

      # Gera os dados do produto/serviço (tag prod)
      def gerar_produto(xml, item)
        xml.prod do
          xml.cProd item.codigo_servico
          xml.xProd limitar_texto(item.descricao, 120)
          xml.cClass item.classe_consumo # Código de classificação do item (tabela ANATEL)
          xml.CFOP item.cfop
          xml.uMed item.unidade # 1=Minuto, 2=MB, 3=GB, 4=UN
          xml.qFaturada formatar_decimal(item.quantidade, 4)

          # vItem = valor unitário, vProd = valor total do item
          xml.vItem formatar_decimal(item.valor_unitario)
          xml.vProd formatar_decimal(item.valor_total)

          # Valores opcionais
          xml.vDesc formatar_decimal(item.valor_desconto) if item.valor_desconto&.positive?
          xml.vOutro formatar_decimal(item.valor_outras_despesas) if item.valor_outras_despesas&.positive?
        end
      end

      # Gera os impostos do item (tag imposto)
      def gerar_impostos_item(xml, _item)
        xml.imposto do
          # ICMS00 - Tributação normal do ICMS
          # Para ISPs normalmente BC=0 (serviço isento ou não tributado)
          xml.ICMS00 do
            xml.CST '00' # 00 = Tributação normal
            xml.vBC '0.00' # Base de cálculo (0.00 para isentos)
            xml.pICMS '0.00' # Alíquota do ICMS
            xml.vICMS '0.00' # Valor do ICMS
          end

          # PIS - Programa de Integração Social (se aplicável)
          # xml.PIS do
          #   xml.CST '01' # 01=Tributável com alíquota básica
          #   xml.vBC formatar_decimal(item.valor_total)
          #   xml.pPIS '0.65' # Alíquota padrão 0.65%
          #   xml.vPIS formatar_decimal(item.valor_total * 0.0065)
          # end

          # COFINS - Contribuição para Financiamento da Seguridade Social (se aplicável)
          # xml.COFINS do
          #   xml.CST '01' # 01=Tributável com alíquota básica
          #   xml.vBC formatar_decimal(item.valor_total)
          #   xml.pCOFINS '3.00' # Alíquota padrão 3%
          #   xml.vCOFINS formatar_decimal(item.valor_total * 0.03)
          # end

          # FUST - Fundo de Universalização dos Serviços de Telecomunicações (se aplicável)
          # FUNTTEL - Fundo para o Desenvolvimento Tecnológico (se aplicável)
        end
      end

      # Gera os totalizadores da NFCom (tag total)
      def gerar_total(xml)
        xml.total do
          # Valor total dos produtos/serviços
          xml.vProd formatar_decimal(nota.total.valor_servicos)

          # Totais de ICMS
          xml.ICMSTot do
            xml.vBC formatar_decimal(nota.total.icms_base_calculo)
            xml.vICMS formatar_decimal(nota.total.icms_valor)
            xml.vICMSDeson formatar_decimal(nota.total.icms_desonerado || 0)
            xml.vFCP formatar_decimal(nota.total.fcp_valor || 0) # Fundo de Combate à Pobreza
          end

          # Tributos federais
          xml.vCOFINS formatar_decimal(nota.total.cofins_valor)
          xml.vPIS formatar_decimal(nota.total.pis_valor)
          xml.vFUNTTEL formatar_decimal(nota.total.funttel_valor || 0)
          xml.vFUST formatar_decimal(nota.total.fust_valor || 0)

          # Retenções na fonte
          xml.vRetTribTot do
            xml.vRetPIS formatar_decimal(nota.total.pis_retido || 0)
            xml.vRetCofins formatar_decimal(nota.total.cofins_retido || 0)
            xml.vRetCSLL formatar_decimal(nota.total.csll_retido || 0)
            xml.vIRRF formatar_decimal(nota.total.irrf_retido || 0)
          end

          # Descontos e acréscimos
          xml.vDesc formatar_decimal(nota.total.valor_desconto)
          xml.vOutro formatar_decimal(nota.total.valor_outras_despesas)

          # Valor total da NFCom (deve ser o último campo)
          xml.vNF formatar_decimal(nota.total.valor_total)
        end
      end

      # Gera informações adicionais (tag infAdic)
      def gerar_info_adicional(xml)
        return unless nota.informacoes_adicionais&.any?

        xml.infAdic do
          nota.informacoes_adicionais.each do |texto|
            xml.infCpl texto
          end
        end
      end

      # Gera informações suplementares (tag infNFComSupl)
      # Contém o QR Code para consulta da NFCom
      def gerar_info_suplementar(xml)
        xml.infNFComSupl do
          xml.qrCodNFCom gerar_qrcode
        end
      end

      # Gera a URL do QR Code para consulta da NFCom
      # @return [String] URL completa do QR Code
      def gerar_qrcode
        base_url = 'https://dfe-portal.svrs.rs.gov.br/nfcom/qrcode'

        # Formato: URL?chNFCom=CHAVE&tpAmb=AMBIENTE
        "#{base_url}?chNFCom=#{nota.chave_acesso}&tpAmb=#{configuration.ambiente_codigo}"
      end
    end
  end
end
