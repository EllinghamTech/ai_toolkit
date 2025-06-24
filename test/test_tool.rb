# frozen_string_literal: true

require "test_helper"

class TestTool < Minitest::Test
  class BasicTool < AiToolkit::Tool
    input_schema({ type: "object" })

    # @return [String]
    def name
      "basic"
    end

    # @return [String]
    def description
      "basic desc"
    end

    # @param _params [Hash]
    # @return [String]
    def perform(_params)
      "done"
    end
  end

  class ErrorTool < BasicTool
    # @param _params [Hash]
    # @return [void]
    def perform(_params)
      raise "fail"
    end
  end

  class SafeErrorTool < BasicTool
    # @param _params [Hash]
    # @return [void]
    def perform(_params)
      raise AiToolkit::SafeToolError, "bad"
    end
  end

  # @return [void]
  def test_tool_spec
    spec = BasicTool.new.tool_spec
    assert_equal "basic", spec[:name]
    assert_equal "basic desc", spec[:description]
    assert_equal({ type: "object" }, spec[:input_schema])
  end

  # @return [void]
  def test_error_handling
    result = ErrorTool.new.call({})
    assert_equal "There was an internal error with this call tool due to a code exception", result
  end

  # @return [void]
  def test_safe_error_handling
    result = SafeErrorTool.new.call({})
    assert_equal "bad", result
  end

  # @return [void]
  def test_invalid_schema
    assert_raises(ArgumentError) do
      Class.new(AiToolkit::Tool) do
        input_schema "not a hash"
      end
    end
  end
end
