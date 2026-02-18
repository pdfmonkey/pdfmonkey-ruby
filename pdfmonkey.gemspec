# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pdfmonkey/version'

Gem::Specification.new do |spec|
  spec.name          = 'pdfmonkey'
  spec.version       = Pdfmonkey::VERSION
  spec.authors       = ['Simon Courtois']
  spec.email         = ['scourtois_github@cubyx.fr']

  spec.summary       = 'Connect to the PDFMonkey API'
  spec.description   = 'Generate awesome PDF with web technologies at pdfmonkey.io'
  spec.homepage      = 'https://github.com/pdfmonkeyio/pdfmonkey-ruby'
  spec.license       = 'MIT'

  spec.metadata = {
    'changelog_uri' => 'https://github.com/pdfmonkeyio/pdfmonkey-ruby/blob/master/CHANGELOG.md',
    'source_code_uri' => 'https://github.com/pdfmonkeyio/pdfmonkey-ruby',
    'rubygems_mfa_required' => 'true'
  }

  spec.required_ruby_version = '>= 3.2'

  spec.files         = Dir['lib/**/*', 'LICENSE.txt', 'README.md', 'CHANGELOG.md']
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.2'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.8'
  spec.add_development_dependency 'rubocop', '~> 1.68'
end
