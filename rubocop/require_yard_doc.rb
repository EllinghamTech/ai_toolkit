# frozen_string_literal: true

module RuboCop
  module Cop
    module YARD
      # Cop that enforces presence of YARD documentation for all methods.
      class RequireDocumentation < Base
        MSG = "Missing YARD documentation for method."

        # @param node [RuboCop::AST::DefNode]
        #   method definition node
        def on_def(node)
          check_documentation(node)
        end

        # @param node [RuboCop::AST::DefsNode]
        #   singleton method definition node
        def on_defs(node)
          check_documentation(node)
        end

        private

        # Check if documentation exists for the given node.
        # @param node [RuboCop::AST::Node]
        #   method definition node
        def check_documentation(node)
          doc_lines = gather_comments(node)
          return if doc_lines.any? { |l| l.match?(/@\w+/) }

          add_offense(node)
        end

        # Gather comment lines above a node.
        # @param node [RuboCop::AST::Node]
        #   method definition node
        # @return [Array<String>] comment lines
        def gather_comments(node)
          lines = processed_source.lines
          idx = node.first_line - 2
          comments = []
          while idx >= 0 && lines[idx].lstrip.start_with?("#")
            comments.unshift(lines[idx])
            idx -= 1
          end
          comments
        end
      end
    end
  end
end
