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

module GraphQLHelpers::AnonymousGrading
  def anonymous_grading_scoped_context(submission)
    # Only set the permission if it hasn't been calculated yet for this submission
    # This prevents redundant permission checks and loader calls
    if context[:hide_the_user_for_anonymous_grading].nil?

      # Use graphql-batch to load the assignment for this submission
      # This batches multiple assignment loads together to prevent N+1 queries
      hide_user_value_promise = load_association(:assignment).then do
        # Calculate whether the user should be hidden for anonymous grading
        # Returns true if the user SHOULD be hidden (negation of can_read_submission_user_name?)
        !submission.can_read_submission_user_name?(
          context[:current_user],
          context[:session]
        )
      end

      # Store the promise in scoped context for this specific submission
      # The promise will be automatically resolved by graphql-batch before field resolution
      # Other parts of the subgraph can access this value via context[:hide_the_user_for_anonymous_grading]
      context.scoped_set!(:hide_the_user_for_anonymous_grading, hide_user_value_promise)
    end
  end

  def unless_hiding_user_for_anonymous_grading
    return yield unless Account.site_admin.feature_enabled?(:graphql_honor_anonymous_grading)

    permission_value = context[:hide_the_user_for_anonymous_grading]

    # If it's a promise, wait for it to resolve, otherwise use the value directly
    if permission_value.respond_to?(:then)
      permission_value.then { |hide_user_value| yield unless hide_user_value }
    else
      yield unless permission_value
    end
  end
end
