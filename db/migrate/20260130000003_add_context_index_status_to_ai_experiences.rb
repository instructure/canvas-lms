# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

class AddContextIndexStatusToAiExperiences < ActiveRecord::Migration[8.0]
  tag :predeploy

  def change
    add_column :ai_experiences, :context_index_status, :string, null: false, default: "not_started", limit: 255
    add_check_constraint :ai_experiences,
                         "context_index_status IN ('not_started', 'in_progress', 'completed', 'failed')",
                         name: "ai_experiences_context_index_status_check",
                         validate: false
    validate_constraint :ai_experiences, "ai_experiences_context_index_status_check"
  end
end
