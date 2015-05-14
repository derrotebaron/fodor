Gem::Specification.new do |s|
  s.name          = 'fodor'
  s.version       = '1.0.0'
  s.summary       = 'Flag Optimization using Discrete Optimization in Ruby'
  s.description   = 'FODOR is intended to optimize the compile-flags of program using discrete optimization. It is specifically tailored to be used in the libgeodecomp project.'
  s.authors       = ["Johannes Knödtel"]
  s.email         = 'johannes.knoedtel@fau.de'
  s.require_paths = "lib"
  s.files         = Dir.glob("lib/**/*") + ["man/man1/fodor"]
  s.license       = "Boost Software License Version 1.0"
  s.add_runtime_dependency "log4r", [">= 1.1.10"]
  s.add_runtime_dependency "mail", [">= 2.6.0"]
  s.add_development_dependency "md2man", "~> 4.0"
  s.executables = ["fodor"]
end
