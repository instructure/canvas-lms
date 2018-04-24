#
# Copyright (C) 2017 - present Instructure, Inc.
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

module AssignmentUtil
  def self.due_date_required?(assignment)
    assignment.post_to_sis.present? && due_date_required_for_account?(assignment.context)
  end

  def self.in_date_range?(date, start_date, end_date)
    # due dates are considered equal if they're the same up to the minute
    date = Assignment.due_date_compare_value date
    start_date = Assignment.due_date_compare_value start_date
    end_date = Assignment.due_date_compare_value end_date
    date >= start_date && date <= end_date
  end

  def self.due_date_ok?(assignment)
    !due_date_required?(assignment) ||
    assignment.due_at.present? ||
    assignment.grading_type == 'not_graded'
  end

  def self.assignment_name_length_required?(assignment)
    assignment.post_to_sis.present? && name_length_required_for_account?(assignment.context)
  end

  def self.assignment_max_name_length(context)
    account = Context.get_account(context)
    account.try(:sis_assignment_name_length_input).try(:[], :value).to_i
  end

  def self.post_to_sis_friendly_name(context)
    account = Context.get_account(context)
    account.try(:root_account).try(:settings).try(:[], :sis_name) || "SIS"
  end

  def self.name_length_required_for_account?(context)
    account = Context.get_account(context)
    account.try(:sis_syncing).try(:[], :value) &&
    account.try(:sis_assignment_name_length).try(:[], :value) &&
    sis_integration_settings_enabled?(context)
  end

  def self.due_date_required_for_account?(context)
    account = Context.get_account(context)
    account.try(:sis_syncing).try(:[], :value).present? &&
    account.try(:sis_require_assignment_due_date).try(:[], :value) &&
    sis_integration_settings_enabled?(context)
  end

  def self.sis_integration_settings_enabled?(context)
    account = Context.get_account(context)
    account.try(:feature_enabled?, 'new_sis_integrations').present?
  end
end
