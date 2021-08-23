# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

class GradingPeriodGradeSummaryPresenter < GradeSummaryPresenter
  attr_reader :grading_period_id

  def initialize(context, current_user, id_param, assignment_order: :due_at, grading_period_id:)
    super(context, current_user, id_param, assignment_order: assignment_order)
    @grading_period_id = grading_period_id
  end

  def assignments_visible_to_student
    grading_period = GradingPeriod.for(@context).where(id: grading_period_id).first
    grading_period.assignments_for_student(@context, super, student)
  end

  def groups
    @groups ||= begin
      assignments.uniq(&:assignment_group_id).map(&:assignment_group)
    end
  end
end
