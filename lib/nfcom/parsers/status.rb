# frozen_string_literal: true

module Nfcom
  module Parsers
    class Status < Base
      def parse
        ret = find('//nfcom:retConsStatServNFCom')
        raise Errors::SefazError, 'Resposta de status inválida' unless ret

        codigo = xpath(ret, './/nfcom:cStat')
        motivo = xpath(ret, './/nfcom:xMotivo')

        {
          online: codigo.to_s == '107',
          codigo: codigo,
          motivo: motivo,
          tempo_medio: xpath(ret, './/nfcom:tMed'),
          data_hora: xpath(ret, './/nfcom:dhRecbto')
        }
      end
    end
  end
end
