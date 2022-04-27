# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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
#
class WikiPages::ScopedToUser < ScopeFilter
  def scope
    # published API parameter notwithstanding, hide unpublished items if the user doesn't have permission to see them
    concat_scope { @relation.published unless can?(:view_unpublished_items) }
    concat_scope do
      wiki_context = context.is_a?(Wiki) ? context.context : context
      if wiki_context.is_a?(Course) && wiki_context.conditional_release?
        return DifferentiableAssignment.scope_filter(@relation, user, wiki_context)
      end

      @relation
    end
  end
end
