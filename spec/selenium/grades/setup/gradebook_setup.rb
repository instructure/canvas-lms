# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

module GradebookSetup
  include Factories

  def backend_group_helper
    Factories::GradingPeriodGroupHelper.new
  end

  def backend_period_helper
    Factories::GradingPeriodHelper.new
  end

  def create_grading_periods(term_name, now = Time.zone.now)
    set1 = backend_group_helper.create_for_account_with_term(Account.default, term_name, "Set 1")
    @gp_closed = backend_period_helper.create_for_group(set1, closed_attributes(now))
    @gp_ended = backend_period_helper.create_for_group(set1, ended_attributes(now))
    @gp_current = backend_period_helper.create_for_group(set1, current_attributes(now))
  end

  def add_teacher_and_student
    course_factory(active_all: true)
    student_in_course
  end

  def associate_course_to_term(term_name)
    @course.enrollment_term = Account.default.enrollment_terms.find_by(name: term_name)
    @course.save!
    @course.reload
  end

  def closed_attributes(now = Time.zone.now)
    {
      title: "GP Closed",
      start_date: 3.weeks.ago(now),
      end_date: 2.weeks.ago(now),
      close_date: 2.weeks.ago(now)
    }
  end

  def ended_attributes(now = Time.zone.now)
    {
      title: "GP Ended",
      start_date: 2.weeks.ago(now),
      end_date: 2.days.ago(now),
      close_date: 2.days.from_now
    }
  end

  def current_attributes(now = Time.zone.now)
    {
      title: "GP Current",
      start_date: 1.day.ago(now),
      end_date: 2.weeks.from_now,
      close_date: 2.weeks.from_now
    }
  end

  def update_display_preferences(concluded, inactive)
    update_course_preferences(@teacher, {
                                "show_concluded_enrollments" => concluded.to_s,
                                "show_inactive_enrollments" => inactive.to_s
                              })
  end

  def update_course_preferences(user, preferences)
    user.set_preference(:gradebook_settings, @course.global_id, preferences)
  end

  def display_concluded_enrollments
    update_display_preferences(true, false)
  end

  def display_inactive_enrollments
    update_display_preferences(false, true)
  end

  def show_grading_periods_filter(user)
    set_filter_visibility(user, "gradingPeriods", true)
  end

  def show_sections_filter(user)
    set_filter_visibility(user, "sections", true)
  end

  def show_modules_filter(user)
    set_filter_visibility(user, "modules", true)
  end

  def show_student_groups_filter(user)
    set_filter_visibility(user, "studentGroups", true)
  end

  def set_filter_visibility(user, filter, visible)
    filters = user.get_preference(:gradebook_settings, @course.global_id)&.dig(:selected_view_options_filters) || []
    if visible && !filters.include?(filter)
      filters << filter
    elsif !visible && filters.include?(filter)
      filters.delete(filter)
    end
    update_course_preferences(user, selected_view_options_filters: filters)
  end
end
