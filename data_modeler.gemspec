# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'data_modeler/version'

Gem::Specification.new do |spec|
  spec.name          = "data_modeler"
  spec.version       = DataModeler::VERSION
  spec.authors       = ["Giuseppe Cuccu"]
  spec.email         = ["giuseppe.cuccu@gmail.com"]

  spec.summary       = %q{Model your data with machine learning}
  spec.description   = %q{Using machine learning, create generative models based on your data alone. Applications span from imputation to prediction. This build specifically leverages time series. Further work on data preparation will be released as a separate project.}
  spec.homepage      = "https://github.com/giuse/data_modeler"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Debug
  spec.add_development_dependency 'pry', '~> 0.10'
  spec.add_development_dependency 'pry-nav', '~> 0.2'
  spec.add_development_dependency 'pry-stack_explorer', '~> 0.4'
  spec.add_development_dependency 'pry-rescue', '~> 1.4'

  # Test
  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
