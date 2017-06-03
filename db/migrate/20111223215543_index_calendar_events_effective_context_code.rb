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

class IndexCalendarEventsEffectiveContextCode < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    if connection.adapter_name == 'PostgreSQL'
      connection.execute("CREATE INDEX index_calendar_events_on_effective_context_code ON #{CalendarEvent.quoted_table_name}(effective_context_code) WHERE effective_context_code IS NOT NULL")
    else
      add_index :calendar_events, [:effective_context_code]
    end
  end

  def self.down
    remove_index :calendar_events, [:effective_context_code]
  end
end
