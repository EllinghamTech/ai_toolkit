# frozen_string_literal: true

# rubocop:disable YARD/RequireDocumentation

require "test_helper"

class TestRealProviders < Minitest::Test
  def test_claude_provider
    skip "CLAUDE_API_KEY not set" unless ENV["CLAUDE_API_KEY"]

    provider = AiToolkit::Providers::Claude.new(
      api_key: ENV.fetch("CLAUDE_API_KEY", nil),
      model: ENV.fetch("CLAUDE_MODEL", nil)
    )
    client = AiToolkit::Client.new(provider)

    resp = client.request do |c|
      c.message :user, "Hello"
      c.message :assistant, "Yes, how can I help you?"
      c.message :user, "Give me a short story."
    end

    refute_empty resp.messages

    # To prove to the testing user
    puts resp.messages.to_json
    puts resp.to_json
  end

  def test_bedrock_provider
    skip "BEDROCK_MODEL_ID not set" unless ENV["BEDROCK_MODEL_ID"]

    provider = AiToolkit::Providers::Bedrock.new(
      model_id: ENV.fetch("BEDROCK_MODEL_ID", nil)
    )
    client = AiToolkit::Client.new(provider)

    resp = client.request do |c|
      c.message :user, "Hello"
      c.message :assistant, "Yes, how can I help you?"
      c.message :user, "Give me a short story."
    end

    refute_empty resp.messages

    # To prove to the testing user
    puts resp.messages.to_json
    puts resp.to_json
  end
end
# rubocop:enable YARD/RequireDocumentation
