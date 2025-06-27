# frozen_string_literal: true

require_relative "result_item"

module AiToolkit
  module Results
    # Represents a tool response sent back to the LLM.
    class ToolResponse < ResultItem
      attr_reader :tool_use_id, :content

      # @param tool_use_id [String]
      # @param content [String]
      def initialize(tool_use_id:, content:)
        super()
        @tool_use_id = tool_use_id
        @content = content
      end
    end
  end
end
