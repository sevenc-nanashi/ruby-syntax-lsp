# frozen_string_literal: true

require "optparse"
require_relative "core"
require_relative "version"

class RubySyntaxLsp
  def self.cli
    options = {
      log_level: :info,
    }
    opts = OptionParser.new("Usage: ruby_syntax_lsp [options]")

    opts.on("--log LEVEL", "Set log level (debug, info, warn, error, fatal)") do |v|
      options[:log_level] = level.to_sym
    end

    opts.on("--verbose", "Set log level to debug") do
      options[:log_level] = :debug
    end

    opts.version = RubySyntaxLsp::VERSION

    opts.parse!

    reader = LSP::Transport::Stdio::Reader.new
    writer = LSP::Transport::Stdio::Writer.new

    RubySyntaxLsp.new(writer, reader, options[:log_level]).start
  end
end
