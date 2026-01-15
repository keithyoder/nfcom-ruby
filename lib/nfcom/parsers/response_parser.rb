# frozen_string_literal: true

module Nfcom
  module Parsers
    # Interpreta as respostas XML da SEFAZ para diferentes operações
    #
    # Esta classe é responsável por processar as respostas SOAP retornadas
    # pela SEFAZ e convertê-las em hashes Ruby com informações estruturadas.
    #
    # @example Processar resposta de autorização
    #   response = webservice.autorizar(xml)
    #   parser = Nfcom::Parsers::ResponseParser.new(response)
    #   resultado = parser.parse_autorizacao
    #
    #   if resultado[:autorizada]
    #     puts "Nota autorizada!"
    #     puts "Protocolo: #{resultado[:protocolo]}"
    #     puts "Chave: #{resultado[:chave]}"
    #   end
    #
    # @example Consultar status do serviço
    #   response = webservice.status
    #   parser = Nfcom::Parsers::ResponseParser.new(response)
    #   status = parser.parse_status
    #
    #   if status[:online]
    #     puts "SEFAZ online (#{status[:tempo_medio]}ms)"
    #   else
    #     puts "SEFAZ offline: #{status[:motivo]}"
    #   end
    #
    # @example Consultar situação de uma nota
    #   response = webservice.consultar(chave)
    #   parser = Nfcom::Parsers::ResponseParser.new(response)
    #   consulta = parser.parse_consulta
    #
    #   puts "Situação: #{consulta[:situacao]}"
    #   puts "Protocolo: #{consulta[:protocolo]}"
    #
    # @example Tratar erro de autorização
    #   begin
    #     resultado = parser.parse_autorizacao
    #   rescue Nfcom::Errors::NotaRejeitada => e
    #     puts "Nota rejeitada [#{e.codigo}]: #{e.motivo}"
    #   rescue Nfcom::Errors::NotaDenegada => e
    #     puts "Nota denegada: #{e.message}"
    #   end
    #
    # Métodos de parsing:
    #
    # - parse_autorizacao - Processa resposta de autorização de nota
    #   Retorna: { autorizada, codigo, motivo, protocolo, chave, data_autorizacao, xml }
    #   Códigos: '100' = Autorizada, '110' = Denegada, outros = Rejeitada
    #
    # - parse_consulta - Processa resposta de consulta de nota
    #   Retorna: { codigo, motivo, situacao, protocolo, data_autorizacao }
    #   Situações: 'Autorizada', 'Cancelada', 'Denegada', 'Desconhecida'
    #
    # - parse_status - Processa resposta de status do serviço
    #   Retorna: { online, codigo, motivo, tempo_medio, data_hora }
    #   Código: '107' = Serviço em operação
    #
    # - parse_inutilizacao - Processa resposta de inutilização de numeração
    #   Retorna: { inutilizada, codigo, motivo, protocolo }
    #   Código: '102' = Inutilização homologada
    #
    # Códigos de status comuns da SEFAZ:
    # - 100 - Autorizado o uso da NF-COM
    # - 102 - Inutilização de número homologado
    # - 107 - Serviço em Operação
    # - 110 - Uso Denegado (irregularidade fiscal do emitente)
    # - 101 - Cancelamento de NF-COM homologado
    # - 135 - Evento registrado e vinculado a NF-COM
    #
    # Exceções lançadas:
    # - Errors::NotaRejeitada - Quando a nota é rejeitada pela SEFAZ
    # - Errors::NotaDenegada - Quando o uso da nota é denegado
    #
    # @note Este parser é usado internamente pelo Client, você normalmente
    #   não precisa instanciá-lo diretamente.
    class ResponseParser
      attr_reader :response

      def initialize(response)
        @response = response
      end

      def parse_autorizacao
        c_stat = @response[:c_stat]
        x_motivo = @response[:x_motivo]

        # Status 100 = Authorized
        raise Errors::NotaRejeitada.new(c_stat, x_motivo) unless c_stat == '100'

        {
          autorizada: true,
          protocolo: @response.dig(:prot_nfcom, :n_prot),
          chave: @response.dig(:prot_nfcom, :ch_nfcom),
          data_autorizacao: @response.dig(:prot_nfcom, :dh_rec_bto),
          xml: @response.dig(:prot_nfcom, :xml),
          mensagem: x_motivo
        }

        # Rejected or error
      end

      def parse_consulta
        codigo = response.dig(:ret_cons_sit_nfcom, :c_stat)
        motivo = response.dig(:ret_cons_sit_nfcom, :x_motivo)

        {
          codigo: codigo,
          motivo: motivo,
          situacao: interpretar_situacao(codigo),
          protocolo: response.dig(:ret_cons_sit_nfcom, :prot_nfcom, :n_prot),
          data_autorizacao: response.dig(:ret_cons_sit_nfcom, :prot_nfcom, :dh_rec_bto)
        }
      end

      def parse_status
        codigo = response.dig(:ret_cons_stat_serv, :c_stat)
        motivo = response.dig(:ret_cons_stat_serv, :x_motivo)
        tempo_medio = response.dig(:ret_cons_stat_serv, :t_med)

        {
          online: codigo.to_s == '107',
          codigo: codigo,
          motivo: motivo,
          tempo_medio: tempo_medio,
          data_hora: response.dig(:ret_cons_stat_serv, :dh_recbto)
        }
      end

      def parse_inutilizacao
        codigo = response.dig(:ret_inut_nfcom, :inf_inut, :c_stat)
        motivo = response.dig(:ret_inut_nfcom, :inf_inut, :x_motivo)

        {
          inutilizada: codigo.to_s == '102',
          codigo: codigo,
          motivo: motivo,
          protocolo: response.dig(:ret_inut_nfcom, :inf_inut, :n_prot)
        }
      end

      private

      def interpretar_situacao(codigo)
        case codigo.to_s
        when '100', '150'
          'Autorizada'
        when '110', '301', '302'
          'Denegada'
        when '101', '151', '155'
          'Cancelada'
        else
          'Desconhecida'
        end
      end
    end
  end
end
