# frozen_string_literal: true

# config/initializers/nfcom.rb
# Configuração da gem Nfcom para emissão de NF-COM

require 'nfcom'

Nfcom.configure do |config|
  # ============================================
  # AMBIENTE
  # ============================================
  # Sempre começar em homologação!
  # Mude para :producao apenas após testar tudo
  config.ambiente = Rails.env.production? ? :producao : :homologacao
  config.estado = 'PE'

  # ============================================
  # CERTIFICADO DIGITAL (OBRIGATÓRIO)
  # ============================================
  # Use variáveis de ambiente para não commitar senhas
  config.certificado_path = ENV['NFCOM_CERTIFICADO_PATH'] ||
                            Rails.root.join('config', 'certificados', 'certificado.pfx').to_s
  config.certificado_senha = ENV.fetch('NFCOM_CERTIFICADO_SENHA', nil)

  # ============================================
  # DADOS DO EMITENTE (OBRIGATÓRIO)
  # ============================================
  config.cnpj = ENV.fetch('NFCOM_CNPJ', nil)
  config.razao_social = ENV.fetch('NFCOM_RAZAO_SOCIAL', nil)
  config.inscricao_estadual = ENV.fetch('NFCOM_INSCRICAO_ESTADUAL', nil)
  config.regime_tributario = ENV.fetch('NFCOM_REGIME_TRIBUTARIO', 1).to_i
  # 1 = Simples Nacional
  # 2 = Simples Nacional - Excesso de sublimite de receita bruta
  # 3 = Regime Normal

  # ============================================
  # CONFIGURAÇÕES OPCIONAIS
  # ============================================
  config.serie_padrao = ENV.fetch('NFCOM_SERIE_PADRAO', 1).to_i
  config.timeout = 30
  config.max_tentativas = 3

  # Logging
  config.log_level = Rails.env.production? ? :info : :debug
  config.logger = Rails.logger
end

# ============================================
# VALIDAÇÃO DA CONFIGURAÇÃO
# ============================================
# Valida se as configurações obrigatórias estão presentes
Rails.application.config.after_initialize do
  config = Nfcom.configuration

  erros = []
  erros << 'NFCOM_CERTIFICADO_PATH não configurado' if config.certificado_path.nil?
  erros << 'NFCOM_CERTIFICADO_SENHA não configurado' if config.certificado_senha.nil?
  erros << 'NFCOM_CNPJ não configurado' if config.cnpj.nil?
  erros << 'NFCOM_RAZAO_SOCIAL não configurado' if config.razao_social.nil?
  erros << 'NFCOM_INSCRICAO_ESTADUAL não configurado' if config.inscricao_estadual.nil?

  if erros.any? && Rails.env.production?
    Rails.logger.error 'NFCOM: Configuração incompleta!'
    erros.each { |erro| Rails.logger.error "  - #{erro}" }
    raise 'NFCOM não está configurado corretamente. Verifique as variáveis de ambiente.'
  elsif erros.any?
    Rails.logger.warn "NFCOM: Configuração incompleta (#{Rails.env}):"
    erros.each { |erro| Rails.logger.warn "  - #{erro}" }
  else
    Rails.logger.info "NFCOM: Configurado com sucesso! (#{config.ambiente} - #{config.estado})"
  end
end
