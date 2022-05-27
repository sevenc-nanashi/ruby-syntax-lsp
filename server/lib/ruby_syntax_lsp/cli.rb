# frozen_string_literal: true

require "optparse"
require_relative "core"
require_relative "version"

class RubySyntaxLsp
  def self.cli
    options = {
      transport: :stdio,
      port: nil,
      unix_socket: nil,
      log_level: :info,
    }
    opts = OptionParser.new("Usage: ruby_syntax_lsp [options]")
    opts.on("--stdio", "Use stdio transport") do
      options[:transport] = :stdio
    end

    opts.on("--tcp PORT", "Use tcp transport") do |port|
      options[:transport] = :tcp
      options[:port] = port.to_i
    end

    opts.on("--unix SOCKET", "Use unix transport") do |socket|
      options[:transport] = :unix
      options[:unix_socket] = socket
    end

    opts.on("--log LEVEL", "Log level") do |level|
      options[:log_level] = level.to_sym
    end

    opts.version = RubySyntaxLsp::VERSION

    opts.parse!

    case options[:transport]
    when :tcp
      require "socket"
      socket = TCPServer.new(options[:port])
      reader = LSP::Transport::Io::Reader.new(socket)
      writer = LSP::Transport::Io::Writer.new(socket)
    when :unix
      require "socket"
      socket = UNIXServer.new(options[:unix_socket])
      reader = LSP::Transport::Io::Reader.new(socket)
      writer = LSP::Transport::Io::Writer.new(socket)
    when :stdio
      reader = LSP::Transport::Stdio::Reader.new
      writer = LSP::Transport::Stdio::Writer.new
    else
      raise "Unknown transport: #{options[:transport]}"
    end

    RubySyntaxLsp.new(writer, reader, options[:log_level]).start
  end
end
