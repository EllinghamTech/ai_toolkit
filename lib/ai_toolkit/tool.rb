# frozen_string_literal: true

require "json"

module AiToolkit
  # Error used to indicate that a tool failure should be shown to the LLM.
  class SafeToolError < StandardError; end

  # Abstract base class for defining tools usable by the client.
  class Tool
    class << self
      # Get or set the JSON schema for tool input.
      # @param schema [Hash, nil] JSON schema defining the tool input
      # @return [Hash, nil]
      def input_schema(schema = nil)
        if schema
          validate_schema(schema)
          @input_schema = schema
        else
          @input_schema
        end
      end

      private

      # Validate that the provided schema is valid JSON.
      # @param schema [Hash]
      # @return [void]
      def validate_schema(schema)
        raise ArgumentError, "schema must be a Hash" unless schema.is_a?(Hash)

        JSON.parse(JSON.generate(schema))
      rescue JSON::ParserError, JSON::GeneratorError => e
        raise ArgumentError, "invalid JSON schema: #{e.message}"
      end
    end

    # Name of the tool.
    # @return [String]
    def name
      raise NotImplementedError, "Tool must implement #name"
    end

    # Description of the tool.
    # @return [String]
    def description
      raise NotImplementedError, "Tool must implement #description"
    end

    # Input schema for this instance.
    # @return [Hash, nil]
    def input_schema
      self.class.input_schema
    end

    # Specification hash for the request builder.
    # @return [Hash]
    def tool_spec
      { name: name, description: description, input_schema: input_schema }
    end

    # Public entry point for tool execution.
    # @param params [Hash]
    #   parameters passed by the LLM
    # @return [String]
    def call(params)
      perform(params)
    rescue SafeToolError => e
      e.message
    rescue StandardError
      "There was an internal error with this call tool due to a code exception"
    end

    # Perform the tool's work.
    # @param params [Hash]
    # @return [String]
    def perform(params)
      raise NotImplementedError, "Tool must implement #perform"
    end
  end
end
