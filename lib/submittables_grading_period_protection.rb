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

module SubmittablesGradingPeriodProtection
  def constrained_by_grading_periods?
    grading_periods? && !current_user_is_context_admin?
  end

  def grading_periods_allow_submittable_create?(submittable, submittable_params, flash_message: false)
    apply_grading_params(submittable, submittable_params)
    return true unless submittable.graded?
    return true unless constrained_by_grading_periods?
    return true if submittable_params[:only_visible_to_overrides]

    submittable.due_at = submittable_params[:due_at]
    return true unless GradingPeriodHelper.date_in_closed_grading_period?(submittable.due_at, context_grading_periods)

    apply_error(submittable, :due_at, ERROR_MESSAGES[:set_due_at_in_closed], flash_message)
    false
  end

  def grading_periods_allow_submittable_update?(submittable, submittable_params, flash_message: false)
    return true unless submittable.graded?

    if submittable_params.key?(:only_visible_to_overrides)
      submittable.only_visible_to_overrides =
        submittable_params[:only_visible_to_overrides]
    end
    submittable.due_at = submittable_params[:due_at] if submittable_params.key?(:due_at)
    return true unless submittable.only_visible_to_overrides_changed? || due_at_changed?(submittable)
    return true unless constrained_by_grading_periods?

    in_closed_grading_period = date_in_closed_grading_period?(submittable.due_at_was)

    if in_closed_grading_period && !submittable.only_visible_to_overrides_was
      if due_at_changed?(submittable)
        apply_error(submittable, :due_at, ERROR_MESSAGES[:change_due_at_in_closed], flash_message)
      else
        message = ERROR_MESSAGES[:change_only_visible_to_overrides]
        apply_error(submittable, :only_visible_to_overrides, message, flash_message)
      end
      return false
    end

    return true if submittable.only_visible_to_overrides && submittable.only_visible_to_overrides_was
    return true unless date_in_closed_grading_period?(submittable.due_at)

    apply_error(submittable, :due_at, ERROR_MESSAGES[:change_due_at_to_closed], flash_message)
    false
  end

  def grading_periods_allow_assignment_overrides_batch_create?(submittable, overrides, flash_message: false)
    return true unless constrained_by_grading_periods?
    return true unless overrides.any? { |override| date_in_closed_grading_period?(override[:due_at]) }

    apply_error(submittable, :due_at, ERROR_MESSAGES[:set_override_due_at_in_closed], flash_message)
    false
  end

  def grading_periods_allow_assignment_overrides_batch_update?(submittable, prepared_batch, flash_message: false)
    return true unless constrained_by_grading_periods?

    can_create_overrides?(submittable, prepared_batch[:overrides_to_create], flash_message:) &&
      can_update_overrides?(submittable, prepared_batch[:overrides_to_update], flash_message:) &&
      can_delete_overrides?(submittable, prepared_batch[:overrides_to_delete], flash_message:)
  end

  def grading_periods_allow_assignment_override_update?(override)
    return true unless constrained_by_grading_periods?
    return true unless override.changed?

    if date_in_closed_grading_period?(override.due_at_was)
      apply_error(override, :due_at, ERROR_MESSAGES[:change_override_due_at_in_closed], false)
      return false
    end

    if date_in_closed_grading_period?(override.due_at)
      apply_error(override, :due_at, ERROR_MESSAGES[:change_override_due_at_to_closed], false)
      return false
    end

    true
  end

  def date_in_closed_grading_period?(date)
    GradingPeriodHelper.date_in_closed_grading_period?(date, context_grading_periods)
  end

  private

  def due_at_changed?(submittable)
    submittable.due_at_was.to_i != submittable.due_at.to_i
  end

  def apply_grading_params(submittable, submittable_params)
    case submittable
    when Quizzes::Quiz
      submittable.quiz_type = submittable_params[:quiz_type]
    when Assignment
      submittable.submission_types = submittable_params[:submission_types]
    end
  end

  def can_create_overrides?(submittable, overrides, flash_message: false)
    # Known Issue: This method explicitly does not handle the case where
    # creating an override would cause a student to assume a due date in an
    # open grading period when previously in a closed grading period.
    return true unless overrides.any? { |override| date_in_closed_grading_period?(override.due_at) }

    apply_error(submittable, :due_at, ERROR_MESSAGES[:set_override_due_at_in_closed], flash_message)
    false
  end

  def can_update_overrides?(submittable, overrides, flash_message: false)
    changed_overrides = overrides.reject { |override| override.due_at_was.to_i == override.due_at.to_i }
    return true if changed_overrides.empty?

    if changed_overrides.any? { |override| date_in_closed_grading_period?(override.due_at_was) }
      apply_error(submittable, :due_at, ERROR_MESSAGES[:change_override_due_at_in_closed], flash_message)
      return false
    end

    return true unless changed_overrides.any? { |override| date_in_closed_grading_period?(override.due_at) }

    apply_error(submittable, :due_at, ERROR_MESSAGES[:change_override_due_at_to_closed], flash_message)
    false
  end

  def can_delete_overrides?(submittable, overrides, flash_message: false)
    # Known Issue: This method explicitly does not handle the case where
    # deleting an override would cause a student to assume a due date in a
    # closed grading period when previously in an open grading period.
    return true unless overrides.any? { |override| date_in_closed_grading_period?(override.due_at) }

    apply_error(submittable, :due_at, ERROR_MESSAGES[:delete_override_in_closed], flash_message)
    false
  end

  def current_user_is_context_admin?
    if @current_user_is_context_admin.nil?
      @current_user_is_context_admin = @context.account_membership_allows(@current_user)
    end
    @current_user_is_context_admin
  end

  def context_grading_periods
    @context_grading_periods ||= GradingPeriod.for(@context)
  end

  def apply_error(submittable, attribute, message, flash_message)
    submittable.errors.add(attribute, message)
    flash[:error] = message if flash_message
  end

  ERROR_MESSAGES = {
    set_due_at_in_closed: I18n.t("Cannot set the due date to a date within a closed grading period"),
    change_due_at_in_closed: I18n.t("Cannot change the due date when due in a closed grading period"),
    change_due_at_to_closed: I18n.t("Cannot change the due date to a date within a closed grading period"),
    set_override_due_at_in_closed: I18n.t("Cannot set override due date to a date within a closed grading period"),
    change_override_due_at_in_closed: I18n.t("Cannot change the due date of an override in a closed grading period"),
    change_override_due_at_to_closed: I18n.t("Cannot change an override due date to a date within a closed grading period"),
    delete_override_in_closed: I18n.t("Cannot delete an override with a due date within a closed grading period"),
    change_only_visible_to_overrides: I18n.t("Cannot set only visible to overrides when due in a closed grading period")
  }.freeze
end
