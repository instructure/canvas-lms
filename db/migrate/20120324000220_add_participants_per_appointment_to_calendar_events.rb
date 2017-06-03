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

class AddParticipantsPerAppointmentToCalendarEvents < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    change_table :calendar_events do |t|
      t.integer :participants_per_appointment
      t.boolean :override_participants_per_appointment
    end
  end

  def self.down
    change_table :calendar_events do |t|
      t.remove :participants_per_appointment
      t.remove :override_participants_per_appointment
    end
  end
end
