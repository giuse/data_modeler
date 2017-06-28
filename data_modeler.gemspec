# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'data_modeler/version'

Gem::Specification.new do |spec|
  spec.name          = "data_modeler"
  spec.version       = DataModeler::VERSION
  spec.authors       = ["Giuseppe Cuccu"]
  spec.email         = ["giuseppe.cuccu@gmail.com"]

  spec.summary       = %{Model your data with machine learning}
  spec.description   = %{Using machine learning, create generative models based on your data alone. Applications span from prediction to imputation and compression. This build specifically leverages time series. NOTE: Since version 1.0.0 we're production-ready! :)}
  spec.homepage      = "https://github.com/giuse/data_modeler"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(/^exe\//, &File.method(:basename))
  spec.require_paths = ["lib"]

  # Models
  # TODO: learn to keep them independent from the gem (plug-ins)
  spec.add_dependency 'ruby-fann', '~>1.2'

  # Debug
  spec.add_development_dependency 'pry', '~> 0.10'
  spec.add_development_dependency 'pry-nav', '~> 0.2'
  spec.add_development_dependency 'pry-stack_explorer', '~> 0.4'
  spec.add_development_dependency 'pry-rescue', '~> 1.4'

  # Test
  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.6'
  spec.add_development_dependency 'rspec-retry', '~> 0.5.4' # testing nondeterministic models
end
