# frozen_string_literal: true

# rubocop:disable YARD/RequireDocumentation

require "test_helper"

class TestRealProviders < Minitest::Test
  class EchoTool < AiToolkit::Tool
    input_schema(
      {
        type: "object",
        properties: { text: { type: "string" } },
        required: ["text"]
      }
    )

    # @return [String]
    def name
      "echo"
    end

    # @return [String]
    def description
      "Echoes the provided text back"
    end

    # @param params [Hash]
    # @return [String]
    def perform(params)
      params[:text]
    end
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def test_claude_provider
    puts "Claude"
    skip "CLAUDE_API_KEY not set" unless ENV["CLAUDE_API_KEY"]

    provider = AiToolkit::Providers::Claude.new(
      api_key: ENV.fetch("CLAUDE_API_KEY", nil),
      model: ENV.fetch("CLAUDE_MODEL", nil)
    )
    client = AiToolkit::Client.new(provider)

    tool = EchoTool.new

    resp = client.request(auto: true) do |c|
      c.system_prompt "You can use the 'echo' tool to repeat any text back to the user."
      c.message :user, "Hello"
      c.message :assistant, "Yes, how can I help you?"
      c.tool tool
      c.message :user, "Use the echo tool to repeat the word 'testing'."
    end

    refute_empty resp.messages

    # To prove to the testing user
    puts resp.messages.to_json
    puts resp.to_json
  end

  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def test_bedrock_provider
    puts "Bedrock"
    skip "BEDROCK_MODEL_ID not set" unless ENV["BEDROCK_MODEL_ID"]

    provider = AiToolkit::Providers::Bedrock.new(
      model_id: ENV.fetch("BEDROCK_MODEL_ID", nil)
    )
    client = AiToolkit::Client.new(provider)

    tool = EchoTool.new

    resp = client.request(auto: true) do |c|
      c.system_prompt "You can use the 'echo' tool to repeat any text back to the user."
      c.message :user, "Hello"
      c.message :assistant, "Yes, how can I help you?"
      c.tool tool
      c.message :user, "Use the echo tool to repeat the word 'testing'."
    end

    refute_empty resp.messages

    # To prove to the testing user
    puts resp.messages.to_json
    puts resp.to_json
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def test_claude_web_search
    puts "Claude web_search"
    skip "CLAUDE_API_KEY not set" unless ENV["CLAUDE_API_KEY"]

    provider = AiToolkit::Providers::Claude.new(
      api_key: ENV.fetch("CLAUDE_API_KEY", nil),
      model: ENV.fetch("CLAUDE_MODEL", nil)
    )
    client = AiToolkit::Client.new(provider)

    resp = client.request do |c|
      c.system_prompt "You can use the web_search tool to find information."
      c.tool :web_search, nil, type: "web_search_20250305"
      c.message :user, "Search the web for Ruby programming language."
    end

    refute_empty resp.messages

    # To prove to the testing user
    puts resp.messages.to_json
    puts resp.to_json
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
end
# rubocop:enable YARD/RequireDocumentation
