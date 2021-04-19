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

class AddPartialIndexToScores < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def up
    duplicate_enrollment_ids = Score.
      group(:enrollment_id, :grading_period_id).
      having('count(*) > 1').
      select(:enrollment_id)
    saved_scores = Score.where(enrollment_id: duplicate_enrollment_ids, grading_period_id: nil).
      order(:enrollment_id, :workflow_state, :created_at).
      select('DISTINCT ON (enrollment_id) id')
    Score.where(enrollment_id: duplicate_enrollment_ids, grading_period_id: nil).
      where.not(id: saved_scores).delete_all

    add_index :scores, :enrollment_id, unique: true, where: 'grading_period_id is null', algorithm: :concurrently
  end

  def down
    remove_index :scores, :enrollment_id
  end
end
