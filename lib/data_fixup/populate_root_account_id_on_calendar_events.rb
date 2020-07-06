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

module DataFixup::PopulateRootAccountIdOnCalendarEvents
  def self.run(min, max)
    # CalendarEvents with context of Course, Group, or CourseSection are handled
    # by PopulateRootAccountIdOnModels.
    # events with context of AppointmentGroup and User are special cases and
    # are handled here.

    # effective_context is populated in one of two ways:
    # 1. as part of an appointment group, which will either be a Course or CourseSection
    # 2. from a parent event, not part of an appointment group. This will be the parent
    #    event's context, which will be one of Course/CourseSection/Group.
    effective_context_types = [
      Course,
      CourseSection,
      Group
    ]

    effective_context_types.each do |model|
      qtn = model.quoted_table_name # to appease the linter on line 41
      CalendarEvent.find_ids_in_ranges(start_at: min, end_at: max) do |batch_min, batch_max|
        CalendarEvent.where(id: batch_min..batch_max, context_type: ["AppointmentGroup", "User"]).
          where("effective_context_code like ?", "#{model.table_name.singularize}%").
          # pull id from effective context code that looks like `course_1` or `course_section_1`
          joins("INNER JOIN #{qtn} ON #{qtn}.id = cast(reverse(split_part(reverse(calendar_events.effective_context_code), '_', 1)) as integer)").
          update_all("root_account_id=#{qtn}.root_account_id")
      end
    end
  end
end