# frozen_string_literal: true

require 'logger'

module Nfcom
  class Configuration
    AMBIENTES = {
      homologacao: 2,
      producao: 1
    }.freeze

    ESTADOS = {
      'AC' => '12', 'AL' => '27', 'AP' => '16', 'AM' => '13',
      'BA' => '29', 'CE' => '23', 'DF' => '53', 'ES' => '32',
      'GO' => '52', 'MA' => '21', 'MT' => '51', 'MS' => '50',
      'MG' => '31', 'PA' => '15', 'PB' => '25', 'PR' => '41',
      'PE' => '26', 'PI' => '22', 'RJ' => '33', 'RN' => '24',
      'RS' => '43', 'RO' => '11', 'RR' => '14', 'SC' => '42',
      'SP' => '35', 'SE' => '28', 'TO' => '17'
    }.freeze

    # Configurações básicas
    attr_accessor :ambiente, :estado, :timeout

    # Certificado digital
    attr_accessor :certificado_path, :certificado_senha

    # Dados do emitente
    attr_accessor :cnpj, :razao_social, :inscricao_estadual, :regime_tributario

    # Configurações de série e numeração
    attr_accessor :serie_padrao, :numero_inicial

    # Logging
    attr_accessor :logger
    attr_reader :log_level

    # Retry
    attr_accessor :max_tentativas, :tempo_espera_retry

    def initialize
      @ambiente = :homologacao
      @estado = 'PE'
      @timeout = 30
      @serie_padrao = 1
      @numero_inicial = 1
      @max_tentativas = 3
      @tempo_espera_retry = 2
      @log_level = :info
      @logger = Logger.new($stdout)
      @logger.level = Logger::INFO
    end

    def ambiente_codigo
      AMBIENTES[ambiente]
    end

    def codigo_uf
      ESTADOS[estado]
    end

    def homologacao?
      ambiente == :homologacao
    end

    def producao?
      ambiente == :producao
    end

    def desabilitar_logs
      @logger = Logger.new(IO::NULL)
    end

    def habilitar_logs(output = $stdout)
      @logger = Logger.new(output)
      atualizar_log_level
    end

    # Setter para log_level (atualiza também o logger)
    def log_level=(level)
      @log_level = level
      atualizar_log_level
    end

    def webservice_url(servico)
      base_url = if homologacao?
                   webservices_homologacao[estado.to_sym]
                 else
                   webservices_producao[estado.to_sym]
                 end

      return nil unless base_url

      base_url[servico]
    end

    private

    def atualizar_log_level
      return unless @logger

      @logger.level = case @log_level
                      when :debug then Logger::DEBUG
                      when :info then Logger::INFO
                      when :warn then Logger::WARN
                      when :error then Logger::ERROR
                      when :fatal then Logger::FATAL
                      else Logger::INFO # rubocop:disable Lint/DuplicateBranch
                      end
    end

    def webservices_homologacao
      {
        PE: {
          recepcao: 'https://nfcom-homologacao.svrs.rs.gov.br/WS/NFComRecepcao/NFComRecepcao.asmx',
          consulta: 'https://nfcom-homologacao.svrs.rs.gov.br/WS/NFComConsulta/NFComConsulta.asmx',
          status: 'https://nfcom-homologacao.svrs.rs.gov.br/WS/NFComStatusServico/NFComStatusServico.asmx',
          evento: 'https://nfcom-homologacao.svrs.rs.gov.br/WS/NFComRecepcaoEvento/NFComRecepcaoEvento.asmx'
        }
      }
    end

    def webservices_producao
      {
        PE: {
          recepcao: 'https://nfcom.svrs.rs.gov.br/WS/NFComRecepcao/NFComRecepcao.asmx',
          consulta: 'https://nfcom.svrs.rs.gov.br/WS/NFComConsulta/NFComConsulta.asmx',
          status: 'https://nfcom.svrs.rs.gov.br/WS/NFComStatusServico/NFComStatusServico.asmx',
          evento: 'https://nfcom.svrs.rs.gov.br/WS/NFComRecepcaoEvento/NFComRecepcaoEvento.asmx'
        }
      }
    end
  end
end
