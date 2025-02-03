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
    if context[:hide_the_user_for_anonymous_grading].nil?
      context.scoped_set!(:hide_the_user_for_anonymous_grading,
                          !submission.can_read_submission_user_name?(current_user, session))
    end
  end

  def unless_hiding_user_for_anonymous_grading
    if !Account.site_admin.feature_enabled?(:graphql_honor_anonymous_grading) ||
       !context[:hide_the_user_for_anonymous_grading]
      yield
    end
  end
end
