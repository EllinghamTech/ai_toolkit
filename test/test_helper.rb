# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "ai_toolkit"
require "ai_toolkit/providers/fake"
require "ai_toolkit/providers/claude"
require "ai_toolkit/providers/bedrock"

require "minitest/autorun"
