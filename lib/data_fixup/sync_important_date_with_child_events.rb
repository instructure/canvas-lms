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

module DataFixup
  module SyncImportantDateWithChildEvents
    def self.run
      CalendarEvent
        .where(context_type: "CourseSection", workflow_state: "active", important_dates: false)
        .where(CalendarEvent.from("#{CalendarEvent.quoted_table_name} parent")
          .where("parent.id=calendar_events.parent_calendar_event_id")
          .where(parent: { important_dates: true }).arel.exists)
        .in_batches.update_all(important_dates: true)
    end
  end
end
