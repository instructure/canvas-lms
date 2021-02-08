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

class BackfillWorkflowStateOnProficienciesAndRatings < ActiveRecord::Migration[5.2]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    DataFixup::BackfillNulls.run(OutcomeProficiency, :workflow_state, default_value: 'active')
    change_column_null(:outcome_proficiencies, :workflow_state, false)
    DataFixup::BackfillNulls.run(OutcomeProficiencyRating, :workflow_state, default_value: 'active')
    change_column_null(:outcome_proficiency_ratings, :workflow_state, false)
  end

  def down
    change_column_null(:outcome_proficiencies, :workflow_state, true)
    change_column_null(:outcome_proficiency_ratings, :workflow_state, true)
  end
end
