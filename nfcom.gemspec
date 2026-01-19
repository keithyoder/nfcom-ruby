# frozen_string_literal: true

require_relative 'lib/nfcom/version'

Gem::Specification.new do |spec|
  spec.name = 'nfcom'
  spec.version = Nfcom::VERSION
  spec.authors = ['Keith Yoder']
  spec.email = ['keith.yoder@gmail.com']

  spec.summary = 'Biblioteca Ruby para emissão de NF-COM (Nota Fiscal de Comunicação) modelo 62'
  spec.description = 'Gem para integração com SEFAZ para emissão de NF-COM, incluindo geração ' \
                     'de XML, assinatura digital, envio e consulta de notas fiscais ' \
                     'de serviços de comunicação e telecomunicação'
  spec.homepage = 'https://github.com/keithyoder/nfcom'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/keithyoder/nfcom-ruby'
  spec.metadata['changelog_uri'] = 'https://github.com/keithyoder/nfcom-ruby/blob/main/CHANGELOG.md'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'nokogiri', '>= 1.18.3', '< 2.0'
  spec.add_dependency 'openssl', '>= 3.0', '< 5.0'
  spec.add_dependency 'prawn', '>= 2.4', '< 3.0'
  spec.add_dependency 'prawn-qrcode', '>= 0.3', '< 1.0'
  spec.add_dependency 'prawn-svg', '>= 0.32', '< 1.0'
  spec.add_dependency 'rqrcode', '>= 2.0', '< 4.0'
end
