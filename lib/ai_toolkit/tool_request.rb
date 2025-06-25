# frozen_string_literal: true

require_relative "result_item"

module AiToolkit
  # Represents a tool request from the LLM.
  class ToolRequest < ResultItem
    attr_reader :id, :name, :input

    # @param id [String]
    # @param name [String]
    # @param input [Object]
    def initialize(id:, name:, input:)
      super()
      @id = id
      @name = name
      @input = input
    end
  end
end
