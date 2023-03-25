# frozen_string_literal: true

require "language_server-protocol"
require "logger"

LSP = LanguageServer::Protocol

class RubySyntaxLsp
  def initialize(writer, reader, level)
    @writer = writer
    @reader = reader
    @logger = Logger.new(STDERR, level: level)
  end

  def start
    @logger.info "Started Ruby Syntax LSP server..."
    @reader.read do |request|
      break if request[:method] == "shutdown"
      method_name = ("request_" + request[:method].gsub(/[A-Z]/) { |m| "_#{m.downcase}" }.gsub("/", "_")).to_sym
      if respond_to?(method_name)
        @logger.debug "Received supported method: #{method_name}"
        begin
          send(method_name, request[:id], request[:params])
        rescue => e
          @logger.error "Error: #{e.full_message}"
          @writer.write(
            code: -32603,
            message: e.message,
          )
        end
      elsif request[:method].start_with?("$/")
        @logger.debug "Received unsupported method: #{request[:method]}"
      else
        @writer.write(
          code: -32601,
          message: "Method not implemented: #{request[:method]}",
        )
      end
    end
  end

  def request_initialize(id, params)
    @writer.write(
      id: id,
      result: LSP::Interface::InitializeResult.new(
        capabilities: LSP::Interface::ServerCapabilities.new(
          text_document_sync: LSP::Interface::TextDocumentSyncOptions.new(
            change: LSP::Constant::TextDocumentSyncKind::FULL,
          ),
        ),
      ),
    )
  end

  def request_initialized(id, params)
    # none
  end

  def request_text_document_did_change(id, params)
    @writer.write(
      method: "textDocument/publishDiagnostics",
      params: {
        uri: params[:textDocument][:uri],
        diagnostics: params[:contentChanges].filter_map do |change|
          text = change[:text]
          begin
            RubyVM::InstructionSequence.compile(text)
          rescue SyntaxError => e
            @logger.info("SyntaxError detected:\n#{e.message}")
            lines = text.lines
            e.message.split(/^<compiled>:(?=\d+: )/m)[1..].map do |error|
              @logger.info("Parsing this error message:\n#{error}")
              lineno_s, message = error.split(": ", 2)
              lineno = lineno_s.strip.to_i
              @logger.info("Line number: #{lineno}")
              range = if message.lines.length > 1 # Message has `^`
                  pos_start = message.lines[2].delete_prefix("...").index("^")
                  if message.lines[1].start_with?("...")
                    pos_start += lines[lineno - 1].index(message.lines[1].delete_prefix("...").delete_suffix("..."))
                  end
                  pos_end = pos_start + message.lines[2].count("~") + 1

                  @logger.info("line: #{lineno}, position: #{pos_start}-#{pos_end}")
                  LSP::Interface::Range.new(
                    start: LSP::Interface::Position.new(line: lineno - 1, character: pos_start),
                    end: LSP::Interface::Position.new(line: lineno - 1, character: pos_end),
                  )
                else
                  @logger.info("line: #{lineno}, no position")
                  LSP::Interface::Range.new(
                    start: LSP::Interface::Position.new(line: lineno - 1, character: 0),
                    end: LSP::Interface::Position.new(line: lineno - 1, character: lines[lineno - 1].length - 1),
                  )
                end
              LSP::Interface::Diagnostic.new(
                range: range,
                severity: LSP::Constant::DiagnosticSeverity::ERROR,
                message: message.lines[0].strip.sub(/^syntax error, /, ""),
                source: "Ruby Syntax LSP",
              )
            end
          else
            @logger.info("No SyntaxError")
            nil
          end
        end.flatten,
      },
    )
  end
end
