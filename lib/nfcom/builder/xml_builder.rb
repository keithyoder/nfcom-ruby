# frozen_string_literal: true

require 'nokogiri'

module Nfcom
  module Builder
    class XmlBuilder
      include Utils::Helpers

      attr_reader :nota, :configuration

      VERSAO_LAYOUT = '1.00'
      NAMESPACE = 'http://www.portalfiscal.inf.br/nfcom'

      def initialize(nota, configuration)
        @nota = nota
        @configuration = configuration
      end

      def gerar
        builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          xml.NFCom(xmlns: NAMESPACE) do
            xml.infNFCom(versao: VERSAO_LAYOUT, Id: "NFCom#{nota.chave_acesso}") do
              gerar_ide(xml)
              gerar_emit(xml)
              gerar_dest(xml)
              gerar_detalhes(xml)
              gerar_total(xml)
              gerar_info_adicional(xml) if nota.informacoes_adicionais
            end
          end
        end

        builder.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)
      end

      private

      def gerar_ide(xml)
        xml.ide do
          xml.cUF configuration.codigo_uf
          xml.tpAmb configuration.ambiente_codigo
          xml.mod '62'
          xml.serie nota.serie
          xml.nNF nota.numero
          xml.cNF nota.codigo_verificacao
          xml.cDV nota.chave_acesso[-1]
          xml.dhEmi formatar_data_hora(nota.data_emissao)
          xml.tpEmis nota.tipo_emissao_codigo
          xml.nSiteAutoriz '0' # Site do autorizador - 0 para ambiente próprio
          xml.cMunFG nota.emitente.endereco.codigo_municipio
          xml.finNFCom nota.finalidade_codigo
          xml.tpFat '0' # 0=Normal, 1=Cortesia/Bonificação
          xml.verProc 'Nfcom-Ruby-1.0' # Identificador do software
        end
      end

      def gerar_emit(xml)
        xml.emit do
          xml.CNPJ apenas_numeros(nota.emitente.cnpj)
          xml.IE apenas_numeros(nota.emitente.inscricao_estadual)
          xml.IM apenas_numeros(nota.emitente.inscricao_municipal) if nota.emitente.inscricao_municipal
          xml.xNome limitar_texto(nota.emitente.razao_social, 60)
          xml.xFant limitar_texto(nota.emitente.nome_fantasia, 60) if nota.emitente.nome_fantasia
          
          gerar_endereco(xml, nota.emitente.endereco, 'emit')
        end
      end

      def gerar_dest(xml)
        xml.dest do
          if nota.destinatario.pessoa_juridica?
            xml.CNPJ apenas_numeros(nota.destinatario.cnpj)
          else
            xml.CPF apenas_numeros(nota.destinatario.cpf)
          end
          
          xml.xNome limitar_texto(nota.destinatario.razao_social, 60)
          
          gerar_endereco(xml, nota.destinatario.endereco, 'dest')
          
          xml.indIEDest '9' # 9=Não Contribuinte
          xml.IE apenas_numeros(nota.destinatario.inscricao_estadual) if nota.destinatario.inscricao_estadual
          xml.email nota.destinatario.email if nota.destinatario.email
        end
      end

      def gerar_endereco(xml, endereco, tipo)
        xml.enderEmit do
          xml.xLgr limitar_texto(endereco.logradouro, 60)
          xml.nro limitar_texto(endereco.numero, 60)
          xml.xCpl limitar_texto(endereco.complemento, 60) if endereco.complemento
          xml.xBairro limitar_texto(endereco.bairro, 60)
          xml.cMun endereco.codigo_municipio
          xml.xMun limitar_texto(endereco.municipio, 60)
          xml.UF endereco.uf
          xml.CEP apenas_numeros(endereco.cep)
          xml.cPais endereco.codigo_pais || '1058' # Brasil
          xml.xPais endereco.pais || 'Brasil'
          xml.fone apenas_numeros(endereco.telefone) if endereco.telefone
        end
      end

      def gerar_detalhes(xml)
        nota.itens.each do |item|
          xml.det(nItem: item.numero_item) do
            xml.prod do
              xml.cProd item.codigo_servico
              xml.xProd limitar_texto(item.descricao, 120)
              xml.cClass item.classe_consumo
              xml.CFOP item.cfop
              xml.uMed item.unidade
              xml.qFaturada formatar_decimal(item.quantidade, 4)
              xml.vProd formatar_decimal(item.valor_unitario)
              xml.vDesc formatar_decimal(item.valor_desconto) if item.valor_desconto > 0
              xml.vOutro formatar_decimal(item.valor_outras_despesas) if item.valor_outras_despesas > 0
            end

            # Impostos (simplificado - expandir conforme necessário)
            xml.imposto do
              xml.ICMS do
                xml.ICMS00 do
                  xml.CST '00'
                  xml.vBC formatar_decimal(item.valor_total)
                  xml.pICMS '0.00'
                  xml.vICMS '0.00'
                end
              end
            end
          end
        end
      end

      def gerar_total(xml)
        xml.total do
          xml.ICMSTot do
            xml.vServ formatar_decimal(nota.total.valor_servicos)
            xml.vBC formatar_decimal(nota.total.icms_base_calculo)
            xml.vICMS formatar_decimal(nota.total.icms_valor)
            xml.vPIS formatar_decimal(nota.total.pis_valor)
            xml.vCOFINS formatar_decimal(nota.total.cofins_valor)
            xml.vDesc formatar_decimal(nota.total.valor_desconto)
            xml.vOutro formatar_decimal(nota.total.valor_outras_despesas)
            xml.vNF formatar_decimal(nota.total.valor_total)
          end
        end
      end

      def gerar_info_adicional(xml)
        xml.infAdic do
          xml.infCpl limitar_texto(nota.informacoes_adicionais, 5000)
        end
      end
    end
  end
end
