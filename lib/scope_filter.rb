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
class ScopeFilter
  def initialize(context, user, relation=nil)
    @context = context
    @user = user
    @relation = relation
  end
  attr_reader :context, :user

  # Implement in subclasses.
  def scope
    @relation
  end

  private
  def can?(*permissions)
    permissions.all? do |permission|
      context.grants_right?(user, permission)
    end
  end

  # Facilitates conditionally chaining scopes.
  # Use within subclassed implementations of #scope.
  # i.e.:
  #
  # def scope
  #   concat_scope { context.active_assignments }
  #   concat_scope { @relation.published unless can_view_unpublished_assignments? }
  #   concat_scope do
  #     if context.feature_enabled?(:differentiated_assignments)
  #       DifferentiableAssignment.scope_filter(@relation, user, context)
  #     end
  #   end
  # end

  def concat_scope
    @relation = yield || @relation
  end
end
