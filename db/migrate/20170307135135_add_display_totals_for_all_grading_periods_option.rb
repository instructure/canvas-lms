# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

class AddDisplayTotalsForAllGradingPeriodsOption < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def up
    add_column :grading_period_groups, :display_totals_for_all_grading_periods, :boolean
    change_column_default :grading_period_groups, :display_totals_for_all_grading_periods, false

    Account.where(id: GradingPeriodGroup.select(:account_id)).find_each do |account|
      DataFixup::BackfillNulls.run(
        GradingPeriodGroup.where(account_id: account.id),
        [:display_totals_for_all_grading_periods],
        default_value: account.feature_enabled?(:all_grading_periods_totals)
      )
    end
    Course.where(id: GradingPeriodGroup.select(:course_id)).find_each do |course|
      DataFixup::BackfillNulls.run(
        GradingPeriodGroup.where(course_id: course.id),
        [:display_totals_for_all_grading_periods],
        default_value: course.feature_enabled?(:all_grading_periods_totals)
      )
    end

    change_column_null :grading_period_groups, :display_totals_for_all_grading_periods, false
  end

  def down
    remove_column :grading_period_groups, :display_totals_for_all_grading_periods
  end
end
