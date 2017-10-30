#
# Copyright (C) 2017 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

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
          add_offense node, message: MSG, severity: :warning
        end

        def refs_ticket?(reason)
          reason =~ /#{JiraRefParser::IssueIdRegex}/
        end
      end
    end
  end
end
