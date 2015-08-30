
# Copyright (C) 2015 Instructure, Inc.
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
# Outstanding Quiz Submissions Manager
#
# API for accessing quiz submissions which we term "outstanding" in that they are
# unsubmitted, started, and overdue.
#
# These submissions can be found by #find_by_quiz, at the
# API level, and graded internally by #grade_by_course
# or at the API by #grade_by_ids
#
module Quizzes
  class ScopedToUser < ScopeFilter
    def scope
      concat_scope { @relation.available unless can?(:manage_assignments) }
      concat_scope do
        if context.feature_enabled?(:differentiated_assignments)
          DifferentiableAssignment.scope_filter(@relation, user, context)
        end
      end
    end
  end
end
