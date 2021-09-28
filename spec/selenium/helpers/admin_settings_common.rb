# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require_relative '../common'

module AdminSettingsCommon
  SIS_SYNC_ID = "#account_settings_sis_syncing_value".freeze
  SIS_IMPORT_ID = "#account_allow_sis_import".freeze
  DUE_DATE_REQUIRED_CHECKBOX_ID = "#account_settings_sis_require_assignment_due_date_value".freeze
  NAME_LENGTH_ID = "#account_settings_sis_assignment_name_length_value".freeze
  NAME_LENGTH_VALUE_ID = "#account_settings_sis_assignment_name_length_input_value".freeze
  DEFAULT_SIS = "#account_settings_sis_default_grade_export_value".freeze

  def turn_on_sis_settings(account)
    account.set_feature_flag! 'post_grades', 'on'
    account.set_feature_flag! :new_sis_integrations, 'on'
    account.allow_sis_import = true
    account.settings[:sis_syncing] = {:value=>true, :locked=>false}
    account.settings[:sis_default_grade_export] = {:value=>true}
    account.save!
  end

  def turn_on_sis_sync
    set_checkbox_via_label(SIS_SYNC_ID, true)
  end

  def turn_on_default
    set_checkbox_via_label(DEFAULT_SIS, true)
  end

  def turn_off_sis_sync
    set_checkbox_via_label(SIS_SYNC_ID, false)
  end

  def turn_on_sis_import
    set_checkbox_via_label(SIS_IMPORT_ID, true)
  end

  def turn_off_sis_import
    set_checkbox_via_label(SIS_IMPORT_ID, false)
  end

  def turn_on_due_date_req
    set_checkbox_via_label(DUE_DATE_REQUIRED_CHECKBOX_ID, true)
  end

  def turn_off_due_date_req
    set_checkbox_via_label(DUE_DATE_REQUIRED_CHECKBOX_ID, false)
  end

  def turn_on_name_length
    set_checkbox_via_label(NAME_LENGTH_ID, true)
  end

  def turn_off_name_length
    set_checkbox_via_label(NAME_LENGTH_ID, false)
  end

  def name_length_sis(length=255)
    label_val = NAME_LENGTH_VALUE_ID[1..-1]
    label = f("label[for=\"#{label_val}\"]")
    set_value(label, length)
    f("#account_settings button[type=submit]").click
  end

  def set_checkbox_via_label(id, checked)
    # Use this method for checkboxes that are hidden by their label (ic-Checkbox)
    checkbox = f(id)
    label = f("label[for=\"#{id[1..-1]}\"]")
    label.click if is_checked(checkbox) != checked
    f("#account_settings button[type=submit]").click
  end
end
