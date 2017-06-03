#
# Copyright (C) 2012 - present Instructure, Inc.
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

class AppointmentGroups < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :appointment_groups do |t|
      t.string :title
      t.text :description
      t.string   "location_name"
      t.string   "location_address"
      t.integer :context_id, :limit => 8
      t.string :context_type
      t.string :context_code
      t.integer :sub_context_id, :limit => 8
      t.string :sub_context_type
      t.string :sub_context_code
      t.string :workflow_state
      t.datetime :created_at
      t.datetime :updated_at
      t.datetime :start_at
      t.datetime :end_at
      t.integer :participants_per_appointment
      t.integer :max_appointments_per_participant # nil means no limit
      t.integer :min_appointments_per_participant, :default => 0
    end
    add_index :appointment_groups, [:context_id]
    add_index :appointment_groups, [:context_code]

    add_column :calendar_events, :parent_calendar_event_id, :integer, :limit => 8
    add_index :calendar_events, [:parent_calendar_event_id]
    add_column :calendar_events, :effective_context_code, :string
  end

  def self.down
    drop_table :appointment_groups

    remove_column :calendar_events, :parent_calendar_event_id
    remove_column :calendar_events, :effective_context_code
  end
end
