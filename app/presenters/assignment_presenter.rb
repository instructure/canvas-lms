#
# Copyright (C) 2018 - present Instructure, Inc.
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

class AssignmentPresenter
  def initialize(assignment)
    @assignment = assignment
    @context = @assignment&.context
  end

  def can_view_speed_grader_link?(user)
    return false unless @context&.allows_speed_grader?
    return true if !@assignment.moderated_grading && @context.grants_any_right?(user, :manage_grades, :view_all_grades)
    return true if @context.concluded? && @context.grants_right?(user, :read_as_admin)
    @assignment.can_be_moderated_grader?(user)
  end
end
