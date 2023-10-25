# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

class GradingStatusesPage
  class << self
    include SeleniumDependencies

    def visit(account_id)
      get "/accounts/#{account_id}/grading_settings"
    end

    def grading_statuses_tab
      f("#tab-gradingStatusTab")
    end

    def standard_statuses
      ff("#standard-status")
    end

    def standard_status_edit_buttons
      ff('[data-testid="color-picker-edit-button"]')
    end

    def color_picker_option(hexcode)
      f("[data-testid='color-picker-#{hexcode}']")
    end

    def color_picker_edit_button
      f('[data-testid="color-picker-edit-button"]')
    end

    def color_input
      f('[data-testid="color-picker-input"]')
    end

    def custom_statuses
      ff("#custom-status")
    end

    def new_custom_status_buttons
      ff('[data-testid="new-custom-status"]')
    end

    def save_status_button
      f('[data-testid="save-status-button"]')
    end

    def custom_status_name_input
      f('[data-testid="custom-status-name-input"]')
    end

    def existing_custom_statuses
      ff("#saved-custom-status")
    end

    def delete_custom_status_buttons
      ff('[data-testid="delete-custom-status-button"]')
    end

    def confirm_delete_button
      f('[data-testid="confirm-button"]')
    end
  end
end
