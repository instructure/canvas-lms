# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

class OverrideListPresenter
  attr_reader :assignment, :user

  include TextHelper

  def initialize(assignment = nil, user = nil)
    @user = user
    if assignment.present?
      @assignment = AssignmentOverrideApplicator.assignment_overridden_for(assignment, user)
    end
  end

  def lock_at(due_date)
    formatted_date_string(:lock_at, due_date)
  end

  def unlock_at(due_date)
    formatted_date_string(:unlock_at, due_date)
  end

  def due_at(due_date)
    formatted_date_string(:due_at, due_date)
  end

  def due_for(due_date)
    if adhoc_current_override_count_hash.key?(due_date[:id])
      return AssignmentOverride.title_from_student_count(adhoc_current_override_count_hash[due_date[:id]])
    elsif due_date[:title]
      return due_date[:title]
    end

    multiple_due_dates? ? I18n.t("overrides.everyone_else", "Everyone else") : I18n.t("overrides.everyone", "Everyone")
  end

  def formatted_due_for(formatted_override, other_due_dates_exist: false)
    everyone = false
    section_count = 0
    group_count = 0
    student_count = 0
    mastery_paths = false

    formatted_override[:options].each do |option|
      everyone = true if option == "everyone"
      section_count += 1 if /\Asection-\d+\z/.match?(option)
      group_count += 1 if /\Agroup-\d+\z/.match?(option)
      student_count += 1 if /\Astudent-\d+\z/.match?(option)
      mastery_paths = true if option == "mastery_paths"
    end

    have_multiple_due_dates = other_due_dates_exist || section_count > 0 || group_count > 0 || student_count > 0 || mastery_paths
    result = []
    if everyone
      result << (have_multiple_due_dates ? I18n.t("overrides.everyone_else", "Everyone else") : I18n.t("overrides.everyone", "Everyone"))
    end

    if section_count > 0
      result << I18n.t(:section_count, { one: "%{count} Section", other: "%{count} Sections" }, count: section_count)
    end

    if group_count > 0
      result << I18n.t(:group_count, { one: "%{count} Group", other: "%{count} Groups" }, count: group_count)
    end

    if student_count > 0
      result << I18n.t(:student_count, { one: "%{count} Student", other: "%{count} Students" }, count: student_count)
    end

    if mastery_paths
      result << I18n.t("overrides.mastery_paths", "Mastery Paths")
    end

    result.join(", ")
  end

  def formatted_date_string(date_field, date_hash = {})
    date = date_hash[date_field]
    if date.present? && CanvasTime.is_fancy_midnight?(date_hash[date_field]) &&
       date_field == :due_at
      date_string(date, :no_words)
    else
      date.present? ? datetime_string(date) : "-"
    end
  end

  def adhoc_current_override_count_hash
    return @adhoc_current_override_count_hash if defined?(@adhoc_current_override_count_hash)

    @adhoc_current_override_count_hash = if assignment
                                           current_users = assignment.context.enrollments.current_and_invited.select(:user_id).distinct
                                           assignment.assignment_override_students.where(user_id: current_users).group(:assignment_override_id).size
                                         else
                                           {}
                                         end
  end

  # Public: Determine if multiple due dates are visible to user.
  #
  # Returns a boolean
  def multiple_due_dates?
    !!assignment.try(:has_active_overrides?)
  end

  # Public: Return all due dates visible to user, filtering out assignment info
  #   if it isn't needed (e.g. if all sections have overrides).
  #
  # Returns an array of due date hashes.
  def visible_due_dates
    return [] unless assignment

    assignment.dates_hash_visible_to(user).each do |due_date|
      due_date[:raw] = due_date.dup
      due_date[:lock_at] = lock_at due_date
      due_date[:unlock_at] = unlock_at due_date
      due_date[:due_at] = due_at due_date
      due_date[:due_for] = due_for due_date
    end
  end

  def grouped_and_sorted_by_visible_due_dates
    return [] unless assignment

    # Only supports classic quizzes and normal assignments
    type_is_allowed = assignment.is_a?(Assignment) ? assignment.submission_types != "discussion_topic" : assignment.is_a?(Quizzes::Quiz)
    if type_is_allowed
      overrides = assignment.formatted_dates_hash_visible_to(user, assignment.context)
      overrides = assignment.merge_overrides_by_date(overrides)
      other_due_dates_exist = overrides.length > 1
      overrides.sort_by! { |card| [card[:due_at].nil? ? 1 : 0, card[:due_at]] }

      overrides.map do |due_date|
        result = {}
        result[:raw] = due_date.dup
        result[:lock_at] = lock_at due_date
        result[:unlock_at] = unlock_at due_date
        result[:due_at] = due_at due_date
        result[:due_for] = formatted_due_for(due_date, other_due_dates_exist:)
        result
      end
    else
      visible_due_dates
    end
  end
end
