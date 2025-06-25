# frozen_string_literal: true

module AiToolkit
  # Structured response returned from the provider
  class Response
    attr_reader :stop_reason, :messages, :tool_uses, :results

    # @param data [Hash]
    #   raw response data
    # @param results [Array<ResultItem>]
    #   ordered list of results from all requests
    def initialize(data, results: [])
      @stop_reason = data[:stop_reason]
      @messages = data[:messages] || []
      @tool_uses = data[:tool_uses] || []
      @results = results
    end

    # Base class for all result items
    class ResultItem; end

    # Represents a tool request from the LLM
    class ToolRequest < ResultItem
      attr_reader :id, :name, :input

      # @param id [String]
      # @param name [String]
      # @param input [Object]
      def initialize(id:, name:, input:)
        @id = id
        @name = name
        @input = input
      end
    end

    # Represents a tool response sent back to the LLM
    class ToolResponse < ResultItem
      attr_reader :tool_use_id, :content

      # @param tool_use_id [String]
      # @param content [String]
      def initialize(tool_use_id:, content:)
        @tool_use_id = tool_use_id
        @content = content
      end
    end

    # Represents a normal message from the LLM
    class MessageResult < ResultItem
      attr_reader :role, :content

      # @param role [String]
      # @param content [String]
      def initialize(role:, content:)
        @role = role
        @content = content
      end
    end
  end
end
