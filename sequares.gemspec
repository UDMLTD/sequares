# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "sequares/version"

Gem::Specification.new do |spec|
  spec.name          = "sequares"
  spec.version       = Sequares::VERSION
  spec.authors       = ["Kyle Welsby"]
  spec.email         = ["kyle@mekyle.com"]

  spec.summary       = "CQRS with Event Sourcing"
  spec.description   = "Command-Query Responsibility Segregation (CQRS) with Event Sourcing"
  spec.homepage      = "https://github.com/kylewelsby/sequares"
  spec.license       = "MIT"

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "ulid", "0.0.3"
  spec.add_dependency "redis"
  spec.add_dependency "activesupport"

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "timecop"
end
