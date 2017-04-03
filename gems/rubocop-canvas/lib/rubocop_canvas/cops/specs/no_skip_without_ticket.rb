require "jira_ref_parser"

module RuboCop
  module Cop
    module Specs
      class NoSkipWithoutTicket < Cop
        MSG = "Reference a ticket if skipping."\
              " Example: skip('time bomb on saturdays CNVS-123456').".freeze

        METHOD = :skip

        def on_send(node)
          _receiver, method_name, *args = *node
          return unless method_name == METHOD
          first_arg = args.to_a.first
          return unless first_arg
          reason = first_arg.children.first
          return if refs_ticket?(reason)
          add_offense node, :expression, MSG, :warning
        end

        def refs_ticket?(reason)
          reason =~ /#{JiraRefParser::IssueIdRegex}/
        end
      end
    end
  end
end
