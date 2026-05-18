# frozen_string_literal: true

module Nfcom
  module Parsers
    class Autorizacao < Base
      def parse
        ret = find('//nfcom:retNFCom')
        raise Errors::NotaRejeitada.new('000', 'Resposta inválida') unless ret

        c_stat   = xpath(ret, './/nfcom:cStat')
        x_motivo = xpath(ret, './/nfcom:xMotivo')

        raise Errors::NotaRejeitada.new(c_stat, x_motivo) unless c_stat == '100'

        prot = ret.at_xpath('.//nfcom:protNFCom', nfcom_namespaces)

        {
          autorizada: true,
          protocolo: xpath(prot, './/nfcom:nProt'),
          chave: xpath(prot, './/nfcom:chNFCom'),
          data_autorizacao: xpath(prot, './/nfcom:dhRecbto'),
          xml: prot&.to_xml,
          mensagem: x_motivo
        }
      end
    end
  end
end
