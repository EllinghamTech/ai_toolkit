# frozen_string_literal: true

require "test_helper"

class TestAiToolkit < Minitest::Test
  class EchoTool
    # @return [String]
    def name
      "echo"
    end

    # @param input [String]
    # @return [String]
    def call(input)
      "echo: #{input}"
    end

    # @return [Hash]
    def tool_spec
      { name: name, input_schema: {} }
    end
  end

  class CaptureProvider
    attr_reader :last_args

    def initialize(response)
      @response = response
    end

    def call(**args)
      @last_args = args
      @response
    end
  end

  # rubocop:disable Metrics/MethodLength
  # Test simple request
  # @return [void]
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
  # Test auto tool loop
  # @return [void]
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

  # @return [void]
  def test_max_iterations_limit
    provider = AiToolkit::Providers::Fake.new([
                                                { stop_reason: "tool_use",
                                                  tool_uses: [{ name: "echo", input: "one" }] },
                                                { stop_reason: "tool_use",
                                                  tool_uses: [{ name: "echo", input: "two" }] },
                                                { stop_reason: "end_turn",
                                                  messages: [{ role: "assistant", content: "done" }] }
                                              ])
    client = AiToolkit::Client.new(provider)

    resp = client.request(auto: true, max_iterations: 1) do |c|
      c.message :user, "start"
      c.tool EchoTool.new
    end

    assert_equal "tool_use", resp.stop_reason
  end

  # @return [void]
  def test_passes_max_tokens
    provider = CaptureProvider.new({ stop_reason: "end_turn", messages: [] })
    client = AiToolkit::Client.new(provider)

    client.request(max_tokens: 55) do |c|
      c.message :user, "hi"
    end

    assert_equal 55, provider.last_args[:max_tokens]
  end
end
