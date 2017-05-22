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

class CreateAppointmentGroupSubContexts < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :appointment_group_sub_contexts do |t|
      t.references :appointment_group, :limit => 8
      t.integer :sub_context_id, :limit => 8
      t.string :sub_context_type
      t.string :sub_context_code
      t.timestamps null: true
    end

    add_index :appointment_group_sub_contexts, :id

    AppointmentGroup.all.each do |ag|
      next unless ag.sub_context_id
      sc = ag.appointment_group_sub_contexts.build
      sc.sub_context_id   = ag.sub_context_id
      sc.sub_context_type = ag.sub_context_type
      sc.sub_context_code = ag.sub_context_code
      sc.save!
    end
  end

  def self.down
    drop_table :appointment_group_sub_contexts
  end
end
