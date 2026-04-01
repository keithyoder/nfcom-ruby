# frozen_string_literal: true

module Nfcom
  module Parsers
    class Consulta < Base
      def parse
        ret = find('//nfcom:retConsSitNFCom')
        raise Errors::SefazError, 'Resposta de consulta inválida' unless ret

        codigo = xpath(ret, './/nfcom:cStat')
        motivo = xpath(ret, './/nfcom:xMotivo')

        {
          codigo: codigo,
          motivo: motivo,
          situacao: interpretar_situacao(codigo),
          protocolo: xpath(ret, './/nfcom:protNFCom/nfcom:infProt/nfcom:nProt'),
          data_autorizacao: xpath(ret, './/nfcom:protNFCom/nfcom:infProt/nfcom:dhRecbto')
        }
      end

      private

      def interpretar_situacao(codigo)
        case codigo.to_s
        when '100', '150' then 'Autorizada'
        when '110', '301', '302' then 'Denegada'
        when '101', '151', '155' then 'Cancelada'
        else 'Desconhecida'
        end
      end
    end
  end
end
