# frozen_string_literal: true

module AiToolkit
  module Results
    # Represents a message with an unknown type. Stores the raw JSON text
    # so it can be inspected by callers.
    class UnknownResult < ResultItem
      attr_reader :json

      # @param json [String]
      def initialize(json:)
        super()
        @json = json
      end
    end
  end
end
