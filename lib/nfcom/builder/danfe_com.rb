# frozen_string_literal: true

require 'date'
require 'prawn'
require 'prawn/measurement_extensions'
require 'prawn/table'
require 'prawn-svg'

module Nfcom
  module Builder
    class DanfeCom
      include Utils::Helpers

      Prawn::Fonts::AFM.hide_m17n_warning = true

      attr_reader :xml_doc, :ns, :logo_path

      def initialize(xml_autorizado, logo_path: nil)
        raise Errors::XmlError, 'XML não pode ser vazio' if xml_autorizado.nil? || xml_autorizado.strip.empty?

        @logo_path = logo_path
        @xml_doc = Nokogiri::XML(xml_autorizado)
        @ns = 'http://www.portalfiscal.inf.br/nfcom'

        raise Errors::XmlError, 'XML inválido: não contém elemento NFCom' unless xml_doc.at_xpath('//xmlns:NFCom',
                                                                                                  'xmlns' => ns)
      rescue Nokogiri::XML::SyntaxError => e
        raise Errors::XmlError, "Erro ao fazer parse do XML: #{e.message}"
      end

      # ----------------------------
      # MAIN PUBLIC METHODS
      # ----------------------------
      def gerar
        Prawn::Document.new(page_size: 'A4', margin: [5.mm] * 4) do |pdf|
          setup_fonts(pdf)
          gerar_conteudo(pdf)
        end.render
      end

      def gerar_arquivo(filepath)
        File.write(filepath, gerar)
      end

      # ----------------------------
      # PRIVATE METHODS
      # ----------------------------
      private

      def setup_fonts(pdf)
        pdf.font 'Helvetica'
      end

      # rubocop:disable Metrics/AbcSize
      def gerar_conteudo(pdf)
        ide       = xml_doc.at_xpath('//xmlns:ide', 'xmlns' => ns)
        emit      = xml_doc.at_xpath('//xmlns:emit', 'xmlns' => ns)
        dest      = xml_doc.at_xpath('//xmlns:dest', 'xmlns' => ns)
        total     = xml_doc.at_xpath('//xmlns:total', 'xmlns' => ns)
        itens     = xml_doc.xpath('//xmlns:det', 'xmlns' => ns)
        gfat      = xml_doc.at_xpath('//xmlns:gFat', 'xmlns' => ns)
        assinante = xml_doc.at_xpath('//xmlns:assinante', 'xmlns' => ns)
        prot      = xml_doc.at_xpath('//xmlns:protNFCom', 'xmlns' => ns)
        inf_adic  = xml_doc.at_xpath('//xmlns:infAdic', 'xmlns' => ns)

        y_pos = pdf.cursor
        y_pos = gerar_cabecalho(pdf, y_pos)
        y_pos = gerar_info_emitente_documento(pdf, emit, ide, y_pos)
        y_pos = gerar_chave_protocolo(pdf, prot, y_pos)
        y_pos = gerar_destinatario(pdf, dest, y_pos)
        y_pos = gerar_assinante(pdf, assinante, y_pos) if assinante
        y_pos = gerar_faturamento(pdf, gfat, y_pos) if gfat
        y_pos = gerar_itens(pdf, itens, y_pos)
        gerar_totais(pdf, total, y_pos)
        gerar_info_adicional(pdf, inf_adic) if inf_adic
        gerar_rodape(pdf, ide, prot)
      end
      # rubocop:enable Metrics/AbcSize

      # ----------------------------
      # HEADER / LOGO
      # ----------------------------
      # rubocop:disable Metrics/AbcSize
      def gerar_cabecalho(pdf, y_pos)
        if logo_path && File.exist?(logo_path)
          begin
            if logo_path.to_s.downcase.end_with?('.svg')
              renderizar_logo_svg(pdf, y_pos)
            else
              pdf.image logo_path.to_s, at: [0, y_pos - 2.mm], fit: [40.mm, 18.mm]
            end
          rescue StandardError => e
            warn "Logo ignorado: #{e.message}"
          end
        end

        title_x = logo_path && File.exist?(logo_path) ? 45.mm : 0
        title_w = logo_path && File.exist?(logo_path) ? 155.mm : 200.mm

        pdf.text_box 'DANFE-COM', at: [title_x, y_pos - 5.mm], size: 18, style: :bold, align: :center, width: title_w
        pdf.text_box 'Documento Auxiliar da Nota Fiscal de Comunicação',
                     at: [title_x, y_pos - 12.mm], size: 10, align: :center, width: title_w

        y_pos - 22.mm
      end
      # rubocop:enable Metrics/AbcSize

      def renderizar_logo_svg(pdf, y_pos)
        raise 'prawn-svg não instalado' unless defined?(Prawn::Svg)

        pdf.svg File.read(logo_path.to_s), at: [0, y_pos - 2.mm], width: 40.mm, height: 18.mm
      end

      # ----------------------------
      # EMITENTE / DESTINATARIO
      # ----------------------------
      # rubocop:disable Metrics/AbcSize
      def gerar_info_emitente_documento(pdf, emit, ide, y_pos)
        pdf.stroke_rectangle [0, y_pos], 200.mm, 30.mm
        emit_info = extrair_emitente(emit)
        pdf.text_box 'EMITENTE', at: [2.mm, y_pos - 2.mm], size: 10, style: :bold
        pdf.text_box emit_info[:nome], at: [2.mm, y_pos - 6.mm], size: 10, style: :bold
        pdf.text_box "CNPJ: #{formatar_cnpj(emit_info[:cnpj])}", at: [2.mm, y_pos - 11.mm], size: 10
        pdf.text_box "IE: #{emit_info[:ie]}", at: [2.mm, y_pos - 16.mm], size: 10
        pdf.text_box montar_endereco_linha(emit_info), at: [2.mm, y_pos - 21.mm], size: 10, width: 120.mm
        pdf.text_box "#{emit_info[:municipio]}/#{emit_info[:uf]} - CEP: #{formatar_cep(emit_info[:cep])}",
                     at: [2.mm, y_pos - 26.mm], size: 10

        pdf.stroke_vertical_line y_pos, y_pos - 30.mm, at: 130.mm

        numero = ide.at_xpath('xmlns:nNF', 'xmlns' => ns)&.text
        serie  = ide.at_xpath('xmlns:serie', 'xmlns' => ns)&.text
        dh_em  = ide.at_xpath('xmlns:dhEmi', 'xmlns' => ns)&.text
        fin_nf = ide.at_xpath('xmlns:finNFCom', 'xmlns' => ns)&.text

        pdf.text_box 'NÚMERO', at: [132.mm, y_pos - 2.mm], size: 10, style: :bold
        pdf.text_box numero.to_s.rjust(6, '0'), at: [132.mm, y_pos - 7.mm], size: 14, style: :bold
        pdf.text_box 'SÉRIE', at: [155.mm, y_pos - 2.mm], size: 10, style: :bold
        pdf.text_box serie, at: [155.mm, y_pos - 7.mm], size: 14, style: :bold
        pdf.text_box 'DATA DE EMISSÃO', at: [132.mm, y_pos - 14.mm], size: 10, style: :bold
        pdf.text_box formatar_data_hora_xml(dh_em), at: [132.mm, y_pos - 19.mm], size: 10
        pdf.text_box tipo_documento(fin_nf), at: [132.mm, y_pos - 25.mm], size: 10, style: :bold

        y_pos - 33.mm
      end
      # rubocop:enable Metrics/AbcSize

      # rubocop:disable Metrics/AbcSize
      def gerar_destinatario(pdf, dest, y_pos)
        pdf.stroke_rectangle [0, y_pos], 200.mm, 28.mm
        dest_info = extrair_destinatario(dest)

        pdf.text_box 'DESTINATÁRIO / TOMADOR DO SERVIÇO', at: [2.mm, y_pos - 2.mm], size: 10, style: :bold
        pdf.text_box dest_info[:nome], at: [2.mm, y_pos - 7.mm], size: 12, style: :bold

        doc_label = dest_info[:cnpj] ? 'CNPJ' : 'CPF'
        doc_val   = dest_info[:cnpj] || dest_info[:cpf]
        pdf.text_box "#{doc_label}: #{formatar_cnpj_cpf(doc_val)}", at: [2.mm, y_pos - 13.mm], size: 10

        ie_text = case dest_info[:ind_ie_dest]
                  when '1' then dest_info[:ie]
                  when '2' then 'ISENTO'
                  else 'NÃO CONTRIBUINTE'
                  end
        pdf.text_box "IE: #{ie_text}", at: [70.mm, y_pos - 13.mm], size: 10

        pdf.text_box montar_endereco_linha(dest_info), at: [2.mm, y_pos - 18.mm], size: 10, width: 195.mm

        cidade_cep = "#{dest_info[:bairro]} - #{dest_info[:municipio]}/#{dest_info[:uf]} - " \
                     "CEP: #{formatar_cep(dest_info[:cep])}"
        pdf.text_box cidade_cep, at: [2.mm, y_pos - 23.mm], size: 10

        y_pos - 32.mm
      end
      # rubocop:enable Metrics/AbcSize

      # ----------------------------
      # QR CODE
      # ----------------------------
      def gerar_chave_protocolo(pdf, prot, y_pos)
        pdf.stroke_rectangle [0, y_pos], 200.mm, 30.mm

        chave = extrair_chave_acesso(prot)
        renderizar_qrcode(pdf, chave, y_pos)
        renderizar_info_chave(pdf, chave, y_pos)
        renderizar_info_protocolo(pdf, prot, y_pos)
        renderizar_texto_consulta(pdf, y_pos)

        y_pos - 33.mm
      end

      def extrair_chave_acesso(prot)
        # Try to get chave from protocol (inside infProt)
        chave = prot&.at_xpath('xmlns:infProt/xmlns:chNFCom', 'xmlns' => ns)&.text
        # Fallback to extracting from infNFCom Id attribute
        chave ||= xml_doc.at_xpath('//xmlns:infNFCom', 'xmlns' => ns)&.[]('Id')&.gsub('NFCom', '')
        chave
      end

      def renderizar_qrcode(pdf, chave, y_pos)
        return unless chave

        # Use Qrcode builder to generate SVG
        ambiente_symbol = tipo_ambiente == 1 ? :producao : :homologacao
        qr_builder = Nfcom::Builder::Qrcode.new(chave, ambiente_symbol)
        qr_svg = qr_builder.gerar_qrcode_svg

        # Render SVG (prawn-svg converts string to SVG)
        pdf.svg qr_svg, at: [2.mm, y_pos - 2.mm], width: 26.mm, height: 26.mm
      rescue StandardError => e
        warn "QR Code error: #{e.message}"
        pdf.stroke_rectangle [2.mm, y_pos - 2.mm], 22.mm, 22.mm
        pdf.text_box 'QR', at: [6.mm, y_pos - 9.mm], size: 10, style: :bold
      end

      def renderizar_info_chave(pdf, chave, y_pos)
        pdf.text_box 'CHAVE DE ACESSO', at: [30.mm, y_pos - 2.mm], size: 10, style: :bold
        pdf.text_box formatar_chave_acesso(chave), at: [30.mm, y_pos - 7.mm], size: 10, width: 165.mm
      end

      def renderizar_info_protocolo(pdf, prot, y_pos)
        # Protocol data is nested inside infProt
        protocolo = prot&.at_xpath('xmlns:infProt/xmlns:nProt', 'xmlns' => ns)&.text
        dh_recbto = prot&.at_xpath('xmlns:infProt/xmlns:dhRecbto', 'xmlns' => ns)&.text

        return unless protocolo

        pdf.text_box 'PROTOCOLO DE AUTORIZAÇÃO', at: [30.mm, y_pos - 13.mm], size: 10, style: :bold
        pdf.text_box "#{protocolo} - #{formatar_data_hora_xml(dh_recbto)}", at: [30.mm, y_pos - 18.mm], size: 10
      end

      def renderizar_texto_consulta(pdf, y_pos)
        texto = 'Consulte a autenticidade deste documento através do QR Code ou da ' \
                'chave de acesso no site da SEFAZ'
        pdf.text_box texto, at: [30.mm, y_pos - 24.mm], size: 8
      end

      # ----------------------------
      # EXTRACTION METHODS
      # ----------------------------
      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def extrair_emitente(emit)
        return {} unless emit

        {
          cnpj: emit.at_xpath('xmlns:CNPJ', 'xmlns' => ns)&.text,
          nome: emit.at_xpath('xmlns:xNome', 'xmlns' => ns)&.text,
          ie: emit.at_xpath('xmlns:IE', 'xmlns' => ns)&.text,
          logradouro: emit.at_xpath('xmlns:enderEmit/xmlns:xLgr', 'xmlns' => ns)&.text,
          numero: emit.at_xpath('xmlns:enderEmit/xmlns:nro', 'xmlns' => ns)&.text,
          complemento: emit.at_xpath('xmlns:enderEmit/xmlns:xCpl', 'xmlns' => ns)&.text,
          bairro: emit.at_xpath('xmlns:enderEmit/xmlns:xBairro', 'xmlns' => ns)&.text,
          municipio: emit.at_xpath('xmlns:enderEmit/xmlns:xMun', 'xmlns' => ns)&.text,
          uf: emit.at_xpath('xmlns:enderEmit/xmlns:UF', 'xmlns' => ns)&.text,
          cep: emit.at_xpath('xmlns:enderEmit/xmlns:CEP', 'xmlns' => ns)&.text
        }
      end

      def extrair_destinatario(dest)
        return {} unless dest

        {
          nome: dest.at_xpath('xmlns:xNome', 'xmlns' => ns)&.text,
          cnpj: dest.at_xpath('xmlns:CNPJ', 'xmlns' => ns)&.text,
          cpf: dest.at_xpath('xmlns:CPF', 'xmlns' => ns)&.text,
          ie: dest.at_xpath('xmlns:IE', 'xmlns' => ns)&.text,
          ind_ie_dest: dest.at_xpath('xmlns:indIEDest', 'xmlns' => ns)&.text,
          logradouro: dest.at_xpath('xmlns:enderDest/xmlns:xLgr', 'xmlns' => ns)&.text,
          numero: dest.at_xpath('xmlns:enderDest/xmlns:nro', 'xmlns' => ns)&.text,
          complemento: dest.at_xpath('xmlns:enderDest/xmlns:xCpl', 'xmlns' => ns)&.text,
          bairro: dest.at_xpath('xmlns:enderDest/xmlns:xBairro', 'xmlns' => ns)&.text,
          municipio: dest.at_xpath('xmlns:enderDest/xmlns:xMun', 'xmlns' => ns)&.text,
          uf: dest.at_xpath('xmlns:enderDest/xmlns:UF', 'xmlns' => ns)&.text,
          cep: dest.at_xpath('xmlns:enderDest/xmlns:CEP', 'xmlns' => ns)&.text
        }
      end
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      # ----------------------------
      # HELPER METHODS
      # ----------------------------
      def montar_endereco_linha(info)
        return '' unless info

        line = "#{info[:logradouro]}, #{info[:numero]}"
        line += " - #{info[:complemento]}" if info[:complemento] && !info[:complemento].to_s.strip.empty?
        line += " - #{info[:bairro]}" if info[:bairro] && !info[:bairro].to_s.strip.empty?
        line
      end

      def formatar_cnpj(cnpj)
        return '' unless cnpj

        cnpj.gsub!(/\D/, '')
        return cnpj unless cnpj.length == 14

        "#{cnpj[0..1]}.#{cnpj[2..4]}.#{cnpj[5..7]}/#{cnpj[8..11]}-#{cnpj[12..13]}"
      end

      def formatar_cpf(cpf)
        return '' unless cpf

        cpf.gsub!(/\D/, '')
        return cpf unless cpf.length == 11

        "#{cpf[0..2]}.#{cpf[3..5]}.#{cpf[6..8]}-#{cpf[9..10]}"
      end

      def formatar_cnpj_cpf(value)
        return '' unless value

        value.length == 14 ? formatar_cnpj(value) : formatar_cpf(value)
      end

      def apenas_numeros(str)
        str.to_s.gsub(/\D/, '')
      end

      def formatar_cep(cep)
        return '' unless cep

        cep.gsub!(/\D/, '')
        return cep unless cep.length == 8

        "#{cep[0..1]}.#{cep[2..4]}-#{cep[5..7]}"
      end

      def tipo_documento(fin_nfcom)
        case fin_nfcom
        when '0' then 'NFCom Normal'
        when '3' then 'NFCom de Substituição'
        when '4' then 'NFCom de Ajuste'
        else 'NFCom'
        end
      end

      def formatar_chave_acesso(chave)
        return '' unless chave

        chave.scan(/.{4}/).join(' ')
      end

      def tipo_ambiente
        @tipo_ambiente ||= xml_doc.at_xpath('//xmlns:ide/xmlns:tpAmb', 'xmlns' => ns)&.text&.to_i || 2
      end

      def formatar_data_hora_xml(datetime)
        return '' unless datetime

        DateTime.parse(datetime).strftime('%d/%m/%Y %H:%M:%S')
      rescue ArgumentError
        datetime
      end

      # ----------------------------
      # ASSINANTE
      # ----------------------------
      def gerar_assinante(pdf, assinante, y_pos) # rubocop:disable Metrics/AbcSize
        pdf.stroke_rectangle [0, y_pos], 200.mm, 18.mm
        pdf.text_box 'DADOS DO ASSINANTE', at: [2.mm, y_pos - 2.mm], size: 10, style: :bold

        cod = assinante.at_xpath('xmlns:iCodAssinante', 'xmlns' => ns)&.text
        tipo_serv = assinante.at_xpath('xmlns:tpServUtil', 'xmlns' => ns)&.text
        contrato = assinante.at_xpath('xmlns:nContrato', 'xmlns' => ns)&.text

        pdf.text_box "Código: #{cod}", at: [2.mm, y_pos - 7.mm], size: 10
        pdf.text_box "Tipo Serviço: #{tipo_servico_texto(tipo_serv)}", at: [50.mm, y_pos - 7.mm], size: 10
        pdf.text_box "Contrato: #{contrato}", at: [2.mm, y_pos - 12.mm], size: 10 if contrato

        y_pos - 21.mm
      end

      def tipo_servico_texto(codigo)
        tipos = {
          '1' => 'Telefonia',
          '2' => 'Comunicação de dados',
          '3' => 'TV por Assinatura',
          '4' => 'Provimento de acesso à Internet',
          '5' => 'Multimídia',
          '6' => 'Outros',
          '7' => 'Vários'
        }
        tipos[codigo] || codigo
      end

      # ----------------------------
      # FATURAMENTO
      # ----------------------------
      # rubocop:disable Metrics/AbcSize
      def gerar_faturamento(pdf, gfat, y_pos)
        pdf.stroke_rectangle [0, y_pos], 200.mm, 22.mm
        pdf.text_box 'INFORMAÇÕES DE FATURAMENTO', at: [2.mm, y_pos - 2.mm], size: 10, style: :bold

        compet = gfat.at_xpath('xmlns:CompetFat', 'xmlns' => ns)&.text
        venc = gfat.at_xpath('xmlns:dVencFat', 'xmlns' => ns)&.text
        periodo_ini = gfat.at_xpath('xmlns:dPerUsoIni', 'xmlns' => ns)&.text
        periodo_fim = gfat.at_xpath('xmlns:dPerUsoFim', 'xmlns' => ns)&.text
        cod_barras = gfat.at_xpath('xmlns:codBarras', 'xmlns' => ns)&.text

        pdf.text_box "Competência: #{formatar_competencia(compet)}", at: [2.mm, y_pos - 7.mm], size: 10
        pdf.text_box "Vencimento: #{formatar_data_simples(venc)}", at: [50.mm, y_pos - 7.mm], size: 10

        # Service period (if provided)
        if periodo_ini && periodo_fim
          periodo_texto = "#{formatar_data_simples(periodo_ini)} a #{formatar_data_simples(periodo_fim)}"
          pdf.text_box "Período de Uso: #{periodo_texto}", at: [100.mm, y_pos - 7.mm], size: 10
        end

        if cod_barras
          pdf.text_box 'Código de Barras:', at: [2.mm, y_pos - 13.mm], size: 10
          pdf.text_box formatar_codigo_barras(cod_barras), at: [2.mm, y_pos - 18.mm], size: 8
        end

        y_pos - 25.mm
      end
      # rubocop:enable Metrics/AbcSize

      def formatar_competencia(comp)
        return '' unless comp

        "#{comp[4..5]}/#{comp[0..3]}"
      end

      def formatar_data_simples(data)
        return '' unless data

        Date.parse(data).strftime('%d/%m/%Y')
      rescue ArgumentError
        data
      end

      def formatar_codigo_barras(codigo)
        return '' unless codigo

        codigo.scan(/.{5}/).join(' ')
      end

      # ----------------------------
      # ITENS
      # ----------------------------
      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def gerar_itens(pdf, itens, y_pos)
        y_pos -= 5.mm
        pdf.move_cursor_to(y_pos)

        pdf.text 'DISCRIMINAÇÃO DOS SERVIÇOS', size: 10, style: :bold
        pdf.move_down 4.mm

        table_data = [['Item', 'Código', 'Descrição', 'Classe', 'CFOP', 'Unid', 'Qtd', 'Vl Unit', 'Vl Total']]

        itens.each do |item|
          prod = item.at_xpath('xmlns:prod', 'xmlns' => ns)
          table_data << [
            item['nItem'],
            prod.at_xpath('xmlns:cProd', 'xmlns' => ns)&.text,
            prod.at_xpath('xmlns:xProd', 'xmlns' => ns)&.text,
            prod.at_xpath('xmlns:cClass', 'xmlns' => ns)&.text,
            prod.at_xpath('xmlns:CFOP', 'xmlns' => ns)&.text,
            unidade_texto(prod.at_xpath('xmlns:uMed', 'xmlns' => ns)&.text),
            formatar_numero(prod.at_xpath('xmlns:qFaturada', 'xmlns' => ns)&.text, 2),
            formatar_moeda(prod.at_xpath('xmlns:vItem', 'xmlns' => ns)&.text),
            formatar_moeda(prod.at_xpath('xmlns:vProd', 'xmlns' => ns)&.text)
          ]
        end

        pdf.table(table_data, header: true, width: 200.mm,
                              cell_style: { size: 9, padding: [3, 4], border_width: 0.5 }) do |t|
          t.row(0).font_style = :bold
          t.row(0).background_color = 'EEEEEE'
          t.columns(6..8).align = :right
        end

        pdf.cursor
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      def unidade_texto(codigo)
        { '1' => 'Min', '2' => 'MB', '3' => 'GB', '4' => 'UN' }[codigo] || codigo
      end

      def formatar_numero(valor, decimais = 2)
        return '0,00' unless valor

        format("%.#{decimais}f", valor.to_f).gsub('.', ',')
      end

      def formatar_moeda(valor)
        return 'R$ 0,00' unless valor

        "R$ #{format('%.2f', valor.to_f).gsub('.', ',')}"
      end

      # ----------------------------
      # TOTAIS
      # ----------------------------
      # rubocop:disable Metrics/AbcSize
      def gerar_totais(pdf, total, y_pos)
        pdf.move_cursor_to(y_pos)
        pdf.move_down 3.mm

        icms_tot = total.at_xpath('xmlns:ICMSTot', 'xmlns' => ns)

        totals_data = [
          ['Base Cálculo ICMS', formatar_moeda(icms_tot&.at_xpath('xmlns:vBC', 'xmlns' => ns)&.text)],
          ['Valor ICMS', formatar_moeda(icms_tot&.at_xpath('xmlns:vICMS', 'xmlns' => ns)&.text)],
          ['Valor PIS', formatar_moeda(total.at_xpath('xmlns:vPIS', 'xmlns' => ns)&.text)],
          ['Valor COFINS', formatar_moeda(total.at_xpath('xmlns:vCOFINS', 'xmlns' => ns)&.text)],
          ['Desconto', formatar_moeda(total.at_xpath('xmlns:vDesc', 'xmlns' => ns)&.text)],
          ['Outras Despesas', formatar_moeda(total.at_xpath('xmlns:vOutro', 'xmlns' => ns)&.text)],
          ['VALOR TOTAL', formatar_moeda(total.at_xpath('xmlns:vNF', 'xmlns' => ns)&.text)]
        ]

        pdf.float do
          pdf.table(totals_data, position: :right, width: 75.mm,
                                 cell_style: { size: 10, padding: [3, 5], border_width: 0.5 },
                                 column_widths: { 0 => 37.mm, 1 => 38.mm }) do |t|
            t.column(1).align = :right
            t.row(-1).font_style = :bold
            t.row(-1).background_color = 'EEEEEE'
            t.row(-1).size = 11
          end
        end

        pdf.move_down 40.mm
        pdf.cursor
      end
      # rubocop:enable Metrics/AbcSize

      # ----------------------------
      # INFORMAÇÕES ADICIONAIS
      # ----------------------------
      def gerar_info_adicional(pdf, inf_adic)
        inf_cpl = inf_adic.xpath('xmlns:infCpl', 'xmlns' => ns)
        return unless inf_cpl.any?

        pdf.move_down 3.mm
        pdf.text 'INFORMAÇÕES COMPLEMENTARES', size: 10, style: :bold
        pdf.move_down 2.mm

        inf_cpl.each do |node|
          text = node.text.to_s.strip
          next if text.empty?

          pdf.text text, size: 9
          pdf.move_down 2.mm
        end
      end

      # ----------------------------
      # RODAPÉ
      # ----------------------------
      def gerar_rodape(pdf, ide, prot)
        pdf.move_down 5.mm

        c_stat = prot&.at_xpath('xmlns:cStat', 'xmlns' => ns)&.text
        if c_stat == '100'
          pdf.fill_color '006400'
          pdf.text 'NOTA FISCAL AUTORIZADA', size: 11, style: :bold, align: :center
          pdf.fill_color '000000'
        elsif c_stat
          pdf.fill_color 'FF0000'
          pdf.text "STATUS: #{c_stat}", size: 11, style: :bold, align: :center
          pdf.fill_color '000000'
        end

        tp_amb = ide.at_xpath('xmlns:tpAmb', 'xmlns' => ns)&.text
        return unless tp_amb == '2'

        pdf.move_down 3.mm
        pdf.fill_color 'FF0000'
        pdf.text 'DOCUMENTO EMITIDO EM AMBIENTE DE HOMOLOGAÇÃO - SEM VALOR FISCAL',
                 size: 10, style: :bold, align: :center
        pdf.fill_color '000000'
      end
    end
  end
end
