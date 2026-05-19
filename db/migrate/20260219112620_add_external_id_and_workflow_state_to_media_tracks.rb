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

class AddExternalIdAndWorkflowStateToMediaTracks < ActiveRecord::Migration[8.0]
  tag :predeploy

  def change
    change_table :media_tracks, bulk: true do |t|
      t.string :external_id, limit: 255
      t.string :workflow_state, null: false, default: "ready", limit: 255
      t.check_constraint "workflow_state IN ('ready', 'failed', 'processing')", name: "chk_workflow_state_enum"
    end
  end
end
