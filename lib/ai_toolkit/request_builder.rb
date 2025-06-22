# frozen_string_literal: true

module AiToolkit
  # Collects messages, system prompts and tools for a request
  class RequestBuilder
    attr_reader :messages, :tools, :tool_objects

    def initialize
      @system_prompt = nil
      @messages = []
      @tools = []
      @tool_objects = {}
    end

    def system_prompt(prompt = nil)
      @system_prompt = prompt if prompt
      @system_prompt
    end

    def message(role, content)
      @messages << { role: role.to_s, content: content }
    end

    def tool(name_or_obj, schema = nil)
      if name_or_obj.is_a?(Symbol) || name_or_obj.is_a?(String)
        @tools << { name: name_or_obj.to_s, input_schema: schema }
      else
        @tool_objects[name_or_obj.name.to_s] = name_or_obj
        @tools << name_or_obj.tool_spec if name_or_obj.respond_to?(:tool_spec)
      end
    end
  end
end
