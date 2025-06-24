# frozen_string_literal: true

require 'json'

module AiToolkit
  # Error type raised by tools when the message can be shown to the model
  class SafeToolError < StandardError; end

  # Base class for implementing tools
  class Tool
    # Generic message returned when an unsafe tool raises an exception
    INTERNAL_ERROR_MESSAGE = 'There was an internal error with this call tool due to a code exception'

    class << self
      # Input schema for the tool
      # @return [Hash]
      def input_schema
        @input_schema || {}
      end

      # Set the input schema for the tool
      # @param schema [Hash]
      # @return [void]
      def input_schema=(schema)
        validate_schema!(schema)
        @input_schema = schema
      end

      private

      # Validate the provided schema
      # @param schema [Hash]
      # @raise [ArgumentError] if schema is invalid
      def validate_schema!(schema)
        raise ArgumentError, 'Schema must be a Hash' unless schema.is_a?(Hash)

        JSON.generate(schema)
        true
      rescue JSON::GeneratorError => e
        raise ArgumentError, "Invalid JSON schema: #{e.message}"
      end
    end

    # Tool name
    # @return [String]
    def name
      raise NotImplementedError
    end

    # Tool description
    # @return [String]
    def description
      raise NotImplementedError
    end

    # Input schema for this instance
    # @return [Hash]
    def input_schema
      self.class.input_schema
    end

    # Perform the tool action
    # @param params [Hash]
    # @return [String]
    def perform(params) # rubocop:disable Lint/UnusedMethodArgument
      raise NotImplementedError
    end

    # Wrapper for building the tool spec used by the provider
    # @return [Hash]
    def tool_spec
      { name: name, description: description, input_schema: input_schema }
    end

    # Call the tool
    # @param params [Hash]
    # @return [String]
    def call(params)
      perform(params)
    end
  end
end

