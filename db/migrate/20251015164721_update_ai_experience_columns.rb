# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

class UpdateAiExperienceColumns < ActiveRecord::Migration[7.2]
  tag :predeploy

  def up
    change_table :ai_experiences, bulk: true do |t|
      # Rename scenario column to pedagogical_guidance and make it required
      t.rename :scenario, :pedagogical_guidance
      t.change_null :pedagogical_guidance, false

      # Make learning_objective required
      t.change_null :learning_objective, false

      # Remove required constraint from facts column
      t.change_null :facts, true
    end
  end
end
