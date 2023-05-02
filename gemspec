# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "pinecone"
  spec.version       = '1.0'
  
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.7'
end