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

class CreateLatePolicies < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    create_table :late_policies do |t|
      t.belongs_to :course, foreign_key: true, limit: 8, index: true, null: false

      t.boolean :missing_submission_deduction_enabled, null: false, default: false
      t.decimal :missing_submission_deduction, precision: 5, scale: 2, null: false, default: 0

      t.boolean :late_submission_deduction_enabled, null: false, default: false
      t.decimal :late_submission_deduction, precision: 5, scale: 2, null: false, default: 0
      t.string :late_submission_interval, limit: 16, null: false, default: 'day'

      t.boolean :late_submission_minimum_percent_enabled, null: false, default: false
      t.decimal :late_submission_minimum_percent, precision: 5, scale: 2, null: false, default: 0

      t.timestamps null: false
    end
  end
end
