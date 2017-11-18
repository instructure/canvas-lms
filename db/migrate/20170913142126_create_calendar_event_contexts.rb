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
#
class CreateCalendarEventContexts < ActiveRecord::Migration[5.0]
  tag :predeploy

  def change
    create_table :calendar_event_contexts do |t|
      t.integer :calendar_event_id, limit: 8, null: false

      t.integer :context_id, limit: 8, null: false
      t.string :context_type, null: false

      t.string :workflow_state, null: false, default: 'active'

      t.timestamps
    end

    add_foreign_key :calendar_event_contexts, :calendar_events
    add_index :calendar_event_contexts, %i{calendar_event_id context_id context_type}, name: 'calendar_event_context_uniq_idx', unique: true
  end
end
