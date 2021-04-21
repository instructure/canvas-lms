# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

class AddWorkflowStateToProficienciesAndRatings < ActiveRecord::Migration[5.2]
  tag :predeploy

  def up
    add_column :outcome_proficiencies, :workflow_state, :string
    change_column_default(:outcome_proficiencies, :workflow_state, 'active')

    add_column :outcome_proficiency_ratings, :workflow_state, :string
    change_column_default(:outcome_proficiency_ratings, :workflow_state, 'active')
  end

  def down
    remove_column :outcome_proficiencies, :workflow_state
    remove_column :outcome_proficiency_ratings, :workflow_state
  end
end
