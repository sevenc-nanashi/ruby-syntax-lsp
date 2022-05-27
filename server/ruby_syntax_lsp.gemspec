# frozen_string_literal: true

require_relative "lib/ruby_syntax_lsp"

Gem::Specification.new do |spec|
  spec.name = "ruby_syntax_lsp"
  spec.version = RubySyntaxLsp::VERSION
  spec.authors = ["sevenc-nanashi"]
  spec.email = ["sevenc7c@sevenc7c.com"]

  spec.summary = "A Ruby Language Server that checks syntax"
  spec.homepage = "https://github.com/sevenc-nanashi/ruby_syntax_lsp"
  spec.license = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.0.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/sevenc-nanashi/ruby_syntax_lsp"
  spec.metadata["changelog_uri"] = "https://github.com/sevenc-nanashi/ruby_syntax_lsp/blob/main/CHANGELOG.md"

  spec.files = Dir.glob("{lib,exe}/**/*")
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "language_server-protocol", "~> 3.16"

  spec.metadata["rubygems_mfa_required"] = "true"
end
