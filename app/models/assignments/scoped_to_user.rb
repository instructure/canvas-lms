#
# Copyright (C) 2011 - 2015 Instructure, Inc.
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
module Assignments
  class ScopedToUser < ScopeFilter
    def scope
      concat_scope { context.active_assignments }
      concat_scope do
        unless can?(:manage_assignments) || can?(:read_as_admin)
          @relation.published
        end
      end
      concat_scope do
        if context.feature_enabled?(:differentiated_assignments)
          DifferentiableAssignment.scope_filter(@relation, user, context)
        end
      end
    end
  end
end
