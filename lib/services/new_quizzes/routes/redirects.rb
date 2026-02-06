# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
#

module Services
  class NewQuizzes
    module Routes
      # Centralized redirect path generation for New Quizzes.
      # Use this to find all places where New Quizzes redirects occur.
      #
      # Examples:
      #   Services::NewQuizzes::Routes::Redirects.assignment_build(context: @context, assignment: @assignment)
      #   Services::NewQuizzes::Routes::Redirects.item_bank_launch(context: @context, tool: @tool)
      class Redirects
        class << self
          include Rails.application.routes.url_helpers

          # Generate item bank launch path for New Quizzes
          # @param context [Course, Account] The context (course or account)
          # @param tool [ContextExternalTool] The external tool
          # @return [String] The path to the item banks page
          def item_bank_launch(context:, tool:)
            if context.is_a?(Course)
              course_new_quizzes_banks_path(context, tool)
            elsif context.is_a?(Account)
              account_new_quizzes_banks_path(context, tool)
            else
              raise ArgumentError, "Context must be a Course or Account"
            end
          end

          # Generate assignment launch path (main entry point)
          # This renders the app shell and lets React Router handle navigation
          # @param context [Course] The course context
          # @param assignment [Assignment] The assignment
          # @param params [Hash] Additional query parameters to forward (e.g., module_item_id, return_url)
          # @return [String] The path to launch the assignment
          def assignment_launch(context:, assignment:, **params)
            course_assignment_new_quizzes_launch_path(context, assignment, params)
          end
        end
      end
    end
  end
end
