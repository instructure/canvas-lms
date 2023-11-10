# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
class CoursePaceDueDatesCalculator
  attr_reader :course_pace

  def initialize(course_pace)
    @course_pace = course_pace
  end

  def get_due_dates(items, enrollment = nil, start_date: nil)
    due_dates = {}
    # Ensure UTC for calculations against the database values
    enrollment_start_date = enrollment&.start_at || [enrollment&.effective_start_at, enrollment&.created_at].compact.max
    start_date = start_date || enrollment_start_date&.utc&.to_date || course_pace.start_date.to_date
    # We have to make sure we start counting on a day that is enabled
    unless CoursePacesDateHelpers.day_is_enabled?(start_date, course_pace.exclude_weekends, blackout_dates)
      start_date = CoursePacesDateHelpers.first_enabled_day(start_date, course_pace.exclude_weekends, blackout_dates)
    end

    items.each do |item|
      due_date = CoursePacesDateHelpers.add_days(
        start_date,
        item.duration,
        course_pace.exclude_weekends,
        blackout_dates
      )

      # If the course pace hasn't been committed yet we need to group the items from their module_item_id or we will
      # end up grouping them by nil and losing the data for each item as it gets overwritten by the next item.
      key = course_pace.persisted? ? item.id : item.module_item_id
      due_dates[key] = due_date.to_date
      start_date = due_date # The next item's start date is this item's due date
    end

    due_dates
  end

  def blackout_dates
    @blackout_dates ||= course_pace.course.blackout_dates + calendar_event_blackout_dates
  end

  private

  def calendar_event_blackout_dates
    account_codes =
      Account.multi_account_chain_ids([course_pace.course.account.id]).map { |id| "account_#{id}" }
    context_codes = account_codes.append("course_#{course_pace.course.id}")
    CalendarEvent.with_blackout_date.active.for_context_codes(context_codes)
  end
end
