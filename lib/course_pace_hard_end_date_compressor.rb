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

class CoursePaceHardEndDateCompressor
  # Takes a list of course pace module items, compresses them by a specified percentage, and
  # validates that they don't extend past the plan length.
  ROUNDING_BREAKPOINT = 0.75 # Determines when we round up

  # @param course_pace [CoursePace] the plan you want to compress
  # @param items [CoursePaceModuleItem[]] The module items you want to compress
  # @param enrollment [Enrollment] The enrollment you want to compress the plan for
  # @param compress_items_after [integer] an optional integer representing the position of that you want to start at when
  #   compressing items, rather than compressing them all
  # @params save [boolean] set to yes if you want the items saved after being modified.
  # @params start_date [Date] the start date of the plan. Used to calculate the number of days to the hard end date
  def self.compress(course_pace, items, enrollment: nil, compress_items_after: nil, save: false, start_date: nil)
    return if compress_items_after && compress_items_after >= items.length - 1
    return items if items.empty?

    course_pace_due_dates_calculator = CoursePaceDueDatesCalculator.new(course_pace)
    blackout_dates = course_pace_due_dates_calculator.blackout_dates
    enrollment_start_date = enrollment&.start_at || [enrollment&.effective_start_at, enrollment&.created_at].compact.max
    start_date_of_item_group = start_date || enrollment_start_date&.to_date || course_pace.start_date.to_date
    end_date = course_pace.end_date || course_pace.course.end_at&.to_date || course_pace.course.enrollment_term&.end_at&.to_date

    unless CoursePacesDateHelpers.day_is_enabled?(start_date_of_item_group, course_pace.exclude_weekends, blackout_dates)
      start_date_of_item_group = CoursePacesDateHelpers.first_enabled_day(start_date_of_item_group, course_pace.exclude_weekends, blackout_dates)
    end
    unless end_date.nil? || CoursePacesDateHelpers.day_is_enabled?(end_date, course_pace.exclude_weekends, blackout_dates)
      end_date = CoursePacesDateHelpers.previous_enabled_day(end_date, course_pace.exclude_weekends, blackout_dates)
    end

    due_dates = course_pace_due_dates_calculator.get_due_dates(items, enrollment, start_date: start_date_of_item_group)

    if compress_items_after
      starting_item = items[compress_items_after]
      # The group should start one day after the due date of the previous item
      start_date_of_item_group = CoursePacesDateHelpers.add_days(
        due_dates[starting_item.id],
        1,
        course_pace.exclude_weekends,
        blackout_dates
      )
      items = items[compress_items_after + 1..]
    end

    # This is how much time the Hard End Date plan should take up
    actual_plan_length = CoursePacesDateHelpers.days_between(
      start_date_of_item_group,
      end_date,
      course_pace.exclude_weekends,
      blackout_dates:
    )

    # If the course pace hasn't been committed yet we are grouping the items by their module_item_id since the item.id is
    # not set yet.
    key = course_pace.persisted? ? items[-1].id : items[-1].module_item_id
    final_item_due_date = due_dates[key]

    # Return if we are already within the end of the course pace
    return items if end_date.blank? || final_item_due_date < end_date

    # This is how much time we're currently using
    plan_length_with_items = CoursePacesDateHelpers.days_between(
      start_date_of_item_group,
      (start_date_of_item_group > final_item_due_date) ? start_date_of_item_group : final_item_due_date,
      course_pace.exclude_weekends,
      blackout_dates:
    )

    # This is the percentage that we should modify the plan by, so it hits our specified end date
    compression_percentage = (plan_length_with_items == 0) ? 0 : actual_plan_length / plan_length_with_items.to_f

    unrounded_durations = items.map { |ppmi| ppmi.duration * compression_percentage }
    rounded_durations = round_durations(unrounded_durations, actual_plan_length)

    items = update_item_durations(items, rounded_durations, save)

    # when compressing heavily, the final due date can end up being after the course pace hard end date
    # adjust later module items
    new_due_dates = course_pace_due_dates_calculator.get_due_dates(items, enrollment, start_date: start_date_of_item_group)
    # If the course pace hasn't been committed yet we are grouping the items by their module_item_id since the item.id is
    # not set yet.
    key = course_pace.persisted? ? items[-1].id : items[-1].module_item_id
    if new_due_dates[key] > end_date
      days_over = CoursePacesDateHelpers.days_between(
        end_date,
        new_due_dates[key],
        course_pace.exclude_weekends,
        inclusive_end: false,
        blackout_dates:
      )
      adjusted_durations = shift_durations_down(rounded_durations, days_over)
      items = update_item_durations(items, adjusted_durations, save)
    end

    items
  end

  # Takes an array of floating durations and rounds them to integers. The process used to determine how to round is as follows:
  # -  If a duration is >= 1:
  #     - If the remainder is >= the breakpoint:
  #         - Round up
  #     - If the remainder is < breakpoint:
  #         - Round down
  # - If a duration is < 0:
  #     - Create a group of linked assignments by:
  #         - Adding all the decimals of the following assignments until either:
  #             - We hit >= the breakpoint
  #             - We hit an assignment that's >= the breakpoint on its own
  #         - Assign the first assignment a duration of 1, and link all the rest of the assignments in the group
  # After doing this, we check to make sure we haven't overallocated. If we have, we start at the end of the list and remove 1 day
  # from each duration that was rounded up, until we are no longer overallocated.
  #
  # @param durations [float[]] an array of floated durations that you want rounded
  # @param plan_length [integer] the total plan length. Used to adjust as necessary if values that were rounded up cause
  #   an overallocation.
  def self.round_durations(durations, plan_length)
    # First, just round up or down based on the breakpoint
    rounded_durations = durations.map do |duration|
      next PaceDuration.new(duration, "NONE", 0) if duration == 0

      remainder = duration % 1

      if remainder >= ROUNDING_BREAKPOINT
        PaceDuration.new(duration.ceil, "UP", remainder)
      else
        PaceDuration.new(duration.floor, "DOWN", remainder)
      end
    end

    # Second, adjust assignments that were rounded down to 0 by setting the first assignment in a group (where a group is
    # a set of assignment's whose combined remainders are >= the ROUNDING_BREAKPOINT) to 1
    current_zero_range_start = nil
    current_zero_range_remainder_sum = 0

    rounded_durations.each_with_index do |duration, index|
      if duration.duration == 0
        current_zero_range_start = index if current_zero_range_start.nil?
        current_zero_range_remainder_sum += duration.remainder
        if current_zero_range_remainder_sum >= ROUNDING_BREAKPOINT
          rounded_durations[current_zero_range_start].duration = 1
          current_zero_range_start = nil
          current_zero_range_remainder_sum = 0
        end
      else
        current_zero_range_start = nil
        current_zero_range_remainder_sum = 0
      end
    end

    # Third, adjust if our plan doesn't match the expected plan length.
    # If we're below the expected plan length, round anything up that we previously rounded down.
    # If we're above the expected plan length, round anything down that we previously rounded up.
    new_plan_length = rounded_durations.sum(&:duration)

    if new_plan_length != plan_length
      rounded_durations = rounded_durations.reverse.map do |duration|
        if duration.rounded_down? && new_plan_length < plan_length
          duration.increment
          new_plan_length += 1
        elsif duration.rounded_up? && new_plan_length > plan_length
          duration.decrement
          new_plan_length -= 1
        end

        duration
      end.reverse
    end

    rounded_durations
  end

  # Iterates through array of durations, decreasing each one until either it
  # or the number of days the over the course pace end date reaches 0. This weights
  # the reduction heaviest on the last module item, then the next in reverse order,
  # and so on.
  #
  # @param durations [Duration[]] The array of Durations used to calculate the course pace item due dates
  # @param days_over [Integer] The number of days over the course pace hard end date the durations totaled
  def self.shift_durations_down(durations, days_over)
    durations.reverse.map do |duration|
      while duration.duration > 0 && days_over > 0
        duration.decrement
        days_over -= 1
      end

      duration
    end.reverse
  end

  def self.update_item_durations(items, durations, save)
    items.each_with_index do |ppmi, index|
      ppmi.duration = durations[index].duration
      ppmi.save! if save && ppmi.changed?
      ppmi
    end
    items
  end
end

PaceDuration = Struct.new(:duration, :rounding_direction, :remainder) do
  def rounded_up?
    rounding_direction == "UP"
  end

  def rounded_down?
    rounding_direction == "DOWN"
  end

  def increment
    self.duration += 1
    self.rounding_direction = "UP"
  end

  def decrement
    self.duration -= 1
    self.rounding_direction = "DOWN"
  end
end
