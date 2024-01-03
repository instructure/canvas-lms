# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

class AddBooleanFieldsToCustomGradeStatuses < ActiveRecord::Migration[7.0]
  tag :predeploy

  def change
    change_table :custom_grade_statuses, bulk: true do |t|
      t.column :applies_to_submissions, :boolean, default: true, null: false
      t.column :applies_to_final_grade, :boolean, default: true, null: false
      t.column :allow_final_grade_value, :boolean, default: true, null: false
    end
  end
end
