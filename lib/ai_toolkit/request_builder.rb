# frozen_string_literal: true

module AiToolkit
  # Collects messages, system prompts and tools for a request
  class RequestBuilder
    attr_reader :messages, :tools, :tool_objects

    # Create a new request builder
    # @return [void]
    def initialize
      @system_prompt = nil
      @messages = []
      @tools = []
      @tool_objects = {}
    end

    # Set or get the system prompt
    # @param prompt [String, nil]
    #   the prompt to set
    # @return [String, nil]
    def system_prompt(prompt = nil)
      @system_prompt = prompt if prompt
      @system_prompt
    end

    # Add a chat message
    # @param role [Symbol, String]
    # @param content [String]
    def message(role, content)
      @messages << { role: role.to_s, content: content }
    end

    # Register a tool for the request
    #
    # For Claude built-in server side tools, pass the tool name (String or
    # Symbol) along with optional configuration options. For client side tools,
    # provide an object that responds to `#name`, `#description` and
    # `#perform`.
    #
    # @param name_or_obj [String, Symbol, Object]
    #   tool name or object
    # @param schema [Hash, nil]
    #   JSON schema for client side tool input. Ignored for server side tools.
    # @param opts [Hash]
    #   additional options for Claude built-in tools (e.g. `max_uses`)
    # @return [void]
    def tool(name_or_obj, schema = nil, **opts)
      if name_or_obj.is_a?(Symbol) || name_or_obj.is_a?(String)
        spec = { name: name_or_obj.to_s }
        spec[:input_schema] = schema if schema
        spec.merge!(opts) unless opts.empty?
        @tools << spec
      else
        @tool_objects[name_or_obj.name.to_s] = name_or_obj
        @tools << name_or_obj.tool_spec if name_or_obj.respond_to?(:tool_spec)
      end
    end
  end
end
