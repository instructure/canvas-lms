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

require_relative "../../common"

module AssignmentPostingPolicyTray
  extend SeleniumDependencies

  def self.tray_container
    f('[role=dialog][aria-label="Assignment Posting Policy"]')
  end

  def self.post_policy_radio_button(policy_type)
    # policy_type should be "Automatically" or "Manually"
    fj("#AssignmentPostingPolicyTray__RadioInputGroup label:contains('#{policy_type}')")
  end

  def self.manually_radio_input
    f('[data-testid="assignment-posting-policy-manual-radio"]')
  end

  def self.automatically_radio_input
    f('[data-testid="assignment-posting-policy-automatic-radio"]')
  end

  def self.save_button
    f('[data-testid="assignment-posting-policy-save-button"]')
  end

  def self.cancel_button
    f('[data-testid="assignment-posting-policy-cancel-button"]')
  end

  # Scheduled Release elements
  def self.scheduled_release_policy_section
    f('[data-testid="scheduled-release-policy"]')
  end

  def self.schedule_release_checkbox
    fj('label:contains("Schedule Release Dates")')
  end

  def self.schedule_release_checkbox_input
    # Find the actual input element for checking state
    f('[data-testid="scheduled-release-checkbox"]')
  end

  def self.shared_schedule_radio
    fj('label:contains("Grades & Comments Together")')
  end

  def self.shared_schedule_radio_input
    # Find the actual input element for checking state
    f('[data-testid="shared-scheduled-post"]')
  end

  def self.separate_schedule_radio
    fj('label:contains("Separate Schedules")')
  end

  def self.separate_schedule_radio_input
    # Find the actual input element for checking state
    f('[data-testid="separate-scheduled-post"]')
  end

  def self.shared_datetime_input
    f('[data-testid="shared-scheduled-post-datetime"]')
  end

  def self.grades_datetime_input
    f('[data-testid="separate-scheduled-post-datetime-grade"]')
  end

  def self.comments_datetime_input
    f('[data-testid="separate-scheduled-post-datetime-comment"]')
  end

  # Actions
  def self.select_manually_post
    post_policy_radio_button("Manually").click
  end

  def self.select_automatically_post
    post_policy_radio_button("Automatically").click
  end

  def self.enable_scheduled_release
    schedule_release_checkbox.click unless schedule_release_checkbox.selected?
  end

  def self.select_shared_schedule
    shared_schedule_radio.click
  end

  def self.select_separate_schedule
    separate_schedule_radio.click
  end

  def self.set_shared_schedule(date:, time:)
    # DateTimeInput has separate date and time fields - find by label text using .//text() for nested content
    date_label = shared_datetime_input.find_element(:xpath, ".//label[contains(., 'Release Date')]")
    date_input_id = date_label.attribute("for")
    date_input = driver.find_element(:id, date_input_id)

    time_label = shared_datetime_input.find_element(:xpath, ".//label[contains(., 'Time')]")
    time_input_id = time_label.attribute("for")
    time_input = driver.find_element(:id, time_input_id)

    date_input.clear
    date_input.send_keys(date)
    time_input.clear
    time_input.send_keys(time)
    time_input.send_keys(:tab)
  end

  def self.set_grades_schedule(date:, time:)
    # DateTimeInput has separate date and time fields - find by label text using .//text() for nested content
    date_label = grades_datetime_input.find_element(:xpath, ".//label[contains(., 'Grades Release Date')]")
    date_input_id = date_label.attribute("for")
    date_input = driver.find_element(:id, date_input_id)

    time_label = grades_datetime_input.find_element(:xpath, ".//label[contains(., 'Time')]")
    time_input_id = time_label.attribute("for")
    time_input = driver.find_element(:id, time_input_id)

    # Clear using select all + delete to ensure full clear
    date_input.click
    date_input.send_keys([:control, "a"], :delete)
    date_input.send_keys(date)

    time_input.click
    time_input.send_keys([:control, "a"], :delete)
    time_input.send_keys(time)
    time_input.send_keys(:tab)
  end

  def self.set_comments_schedule(date:, time:)
    # DateTimeInput has separate date and time fields - find by label text using .//text() for nested content
    date_label = comments_datetime_input.find_element(:xpath, ".//label[contains(., 'Comments Release Date')]")
    date_input_id = date_label.attribute("for")
    date_input = driver.find_element(:id, date_input_id)

    time_label = comments_datetime_input.find_element(:xpath, ".//label[contains(., 'Time')]")
    time_input_id = time_label.attribute("for")
    time_input = driver.find_element(:id, time_input_id)

    # Clear using select all + delete to ensure full clear
    date_input.click
    date_input.send_keys([:control, "a"], :delete)
    date_input.send_keys(date)

    time_input.click
    time_input.send_keys([:control, "a"], :delete)
    time_input.send_keys(time)
    time_input.send_keys(:tab)
  end

  def self.click_save
    save_button.click
    wait_for_ajaximations
  end

  def self.click_cancel
    cancel_button.click
  end
end
