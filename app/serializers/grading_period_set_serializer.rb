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

class GradingPeriodSetSerializer < Canvas::APISerializer
  include PermissionsSerializer
  root :grading_period_set

  attributes :id,
             :title,
             :weighted,
             :display_totals_for_all_grading_periods,
             :account_id,
             :course_id,
             :grading_periods,
             :permissions,
             :created_at

  def grading_periods
    @grading_periods ||= object.grading_periods.active.map do |period|
      GradingPeriodSerializer.new(period, controller: @controller, scope: @scope, root: false)
    end
  end

  def serializable_object(...)
    stringify!(super)
  end
end
