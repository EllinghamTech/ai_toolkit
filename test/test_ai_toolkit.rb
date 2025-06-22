# frozen_string_literal: true

require "test_helper"

class TestAiToolkit < Minitest::Test
  class EchoTool
    def name
      "echo"
    end

    def call(input)
      "echo: #{input}"
    end

    def tool_spec
      { name: name, input_schema: {} }
    end
  end

  # rubocop:disable Metrics/MethodLength
  def test_request_returns_response
    provider = AiToolkit::Providers::Fake.new([
                                                { stop_reason: "end_turn",
                                                  messages: [{ role: "assistant", content: "hi" }] }
                                              ])
    client = AiToolkit::Client.new(provider)

    resp = client.request do |c|
      c.system_prompt "Hello"
      c.message :user, "hi"
      c.tool :echo, {}
    end

    assert_equal "end_turn", resp.stop_reason
    assert_equal "hi", resp.messages.first[:content]
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def test_auto_tool_loop
    provider = AiToolkit::Providers::Fake.new([
                                                { stop_reason: "tool_use",
                                                  tool_uses: [{ name: "echo", input: "world" }] },
                                                { stop_reason: "end_turn",
                                                  messages: [{ role: "assistant", content: "done" }] }
                                              ])
    client = AiToolkit::Client.new(provider)

    resp = client.request(auto: true) do |c|
      c.message :user, "start"
      c.tool EchoTool.new
    end

    assert_equal "end_turn", resp.stop_reason
    assert_equal "done", resp.messages.first[:content]
  end
  # rubocop:enable Metrics/MethodLength
end
