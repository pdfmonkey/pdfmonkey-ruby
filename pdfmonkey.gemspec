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

  spec.files         = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.17'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.8'
  spec.add_development_dependency 'rubocop', '~> 0.60.0'
  spec.add_development_dependency 'simplecov', '~> 0.16.1'
end
