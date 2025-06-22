# frozen_string_literal: true

module AiToolkit
  # Structured response returned from the provider
  class Response
    attr_reader :stop_reason, :messages, :tool_uses

    # @param data [Hash]
    #   raw response data
    def initialize(data)
      @stop_reason = data[:stop_reason]
      @messages = data[:messages] || []
      @tool_uses = data[:tool_uses] || []
    end
  end
end
