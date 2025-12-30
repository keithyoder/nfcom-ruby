# frozen_string_literal: true

module Nfcom
  module Parsers
    class ResponseParser
      attr_reader :response

      def initialize(response)
        @response = response
      end

      def parse_autorizacao
        # Códigos de status da SEFAZ
        codigo = response.dig(:ret_env_nfcom, :c_stat)
        motivo = response.dig(:ret_env_nfcom, :x_motivo)

        case codigo.to_s
        when '100' # Autorizada
          {
            autorizada: true,
            codigo: codigo,
            motivo: motivo,
            protocolo: response.dig(:ret_env_nfcom, :prot_nfcom, :n_prot),
            chave: response.dig(:ret_env_nfcom, :prot_nfcom, :ch_nfcom),
            data_autorizacao: response.dig(:ret_env_nfcom, :prot_nfcom, :dh_rec_bto),
            xml: response.dig(:ret_env_nfcom, :prot_nfcom, :xml)
          }
        when '110' # Denegada
          raise Errors::NotaDenegada, "Nota denegada [#{codigo}]: #{motivo}"
        else # Rejeitada
          raise Errors::NotaRejeitada.new(codigo, motivo)
        end
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
