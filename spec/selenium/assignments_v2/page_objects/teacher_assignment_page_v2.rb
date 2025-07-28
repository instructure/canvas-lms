# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class TeacherViewPageV2
  class << self
    include SeleniumDependencies

    # Selectors
    def details_tab
      fj("div[role='tab']:contains('Details')")
    end

    def assignment_type
      f("#AssignmentType")
    end

    # Methods & Actions
    def visit(course, assignment)
      course.account.enable_feature!(:assignment_enhancements_teacher_view)
      get "/courses/#{course.id}/assignments/#{assignment.id}"
      wait_for(method: nil, timeout: 1) do
        assignment_type
      end
    end

    def assignment_title(title)
      fj("h1:contains(#{title})")
    end

    def publish_button
      f("button[data-testid='assignment-publish-menu']")
    end

    def publish_status(workflow_state)
      fj("button:contains(#{workflow_state.capitalize})")
    end

    def status_pill
      f("span[data-testid='assignment-status-pill']")
    end

    def edit_button
      f("a[data-testid='edit-button']")
    end

    def assign_to_button
      f("button[data-testid='assign-to-button']")
    end

    def speedgrader_button
      f("a[data-testid='speedgrader-button']")
    end

    def assign_to_tray
      f("div[data-testid='item-assign-to-card']")
    end

    def options_button
      f("button[data-testid='assignment-options-button']")
    end

    def peer_reviews_option
      f("a[data-testid='peer-review-option']")
    end

    def send_to_option
      f("button[data-testid='send-to-option']")
    end

    def send_to_modal
      f("span[data-testid='send-to-modal']")
    end

    def copy_to_option
      f("button[data-testid='copy-to-option']")
    end

    def copy_to_tray
      f("span[data-testid='copy-to-tray']")
    end

    def download_submissions_option
      f("button[data-testid='download-submissions-option']")
    end

    def download_submissions_button
      f("a[data-testid='download_button']")
    end
  end
end
