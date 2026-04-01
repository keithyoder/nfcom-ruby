# frozen_string_literal: true

module Nfcom
  module Parsers
    class Inutilizacao < Base
      def parse
        ret = find('//nfcom:retInutNFCom')
        raise Errors::SefazError, 'Resposta de inutilização inválida' unless ret

        inf = ret.at_xpath('.//nfcom:infInut', nfcom_namespaces)
        codigo = xpath(inf, './/nfcom:cStat')
        motivo = xpath(inf, './/nfcom:xMotivo')

        {
          inutilizada: codigo.to_s == '102',
          codigo: codigo,
          motivo: motivo,
          protocolo: xpath(inf, './/nfcom:nProt')
        }
      end
    end
  end
end
