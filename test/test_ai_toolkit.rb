# frozen_string_literal: true

require "test_helper"

class TestAiToolkit < Minitest::Test
  class EchoTool < AiToolkit::Tool
    self.input_schema = {}

    # @return [String]
    def name
      "echo"
    end

    # @return [String]
    def description
      "Echo input"
    end

    # @param params [Hash]
    # @return [String]
    def perform(params)
      "echo: #{params[:msg]}"
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
                                                  tool_uses: [{ name: "echo", input: { msg: "world" } }] },
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

  class CaptureProvider
    attr_reader :last_messages

    def initialize(tool_name)
      @tool_name = tool_name
      @calls = 0
    end

    def call(messages:, system_prompt: nil, tools: nil) # rubocop:disable Lint/UnusedMethodArgument
      @calls += 1
      @last_messages = messages
      if @calls == 1
        { stop_reason: "tool_use", tool_uses: [{ name: @tool_name, input: {} }] }
      else
        { stop_reason: "end_turn", messages: [{ role: "assistant", content: "done" }] }
      end
    end
  end

  class SafeErrorTool < AiToolkit::Tool
    self.input_schema = {}

    def name
      "safe"
    end

    def description
      "safe"
    end

    def perform(_params)
      raise AiToolkit::SafeToolError, "bad input"
    end
  end

  class UnsafeErrorTool < AiToolkit::Tool
    self.input_schema = {}

    def name
      "unsafe"
    end

    def description
      "unsafe"
    end

    def perform(_params)
      raise "boom"
    end
  end

  def test_safe_tool_error_message
    provider = CaptureProvider.new("safe")
    client = AiToolkit::Client.new(provider)

    client.request(auto: true) do |c|
      c.message :user, "start"
      c.tool SafeErrorTool.new
    end

    assert_equal "bad input", provider.last_messages.last[:content]
  end

  def test_unsafe_tool_error_message
    provider = CaptureProvider.new("unsafe")
    client = AiToolkit::Client.new(provider)

    client.request(auto: true) do |c|
      c.message :user, "start"
      c.tool UnsafeErrorTool.new
    end

    assert_equal AiToolkit::Tool::INTERNAL_ERROR_MESSAGE, provider.last_messages.last[:content]
  end
end
