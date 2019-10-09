#
# Copyright (C) 2019 - present Instructure, Inc.
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

require_relative '../../common'

class StudentAssignmentPageV2
  class << self
    include SeleniumDependencies

    def visit(course, assignment)
      get "/courses/#{course.id}/assignments/#{assignment.id}/"
    end

    def assignment_locked_image
      f("img[alt='Assignment Locked']")
    end

    def lock_icon
      f("svg[name='IconLock']")
    end

    def checkmark_icon
      f('svg[name="IconCheckMark"]')
    end

    def assignment_title(title)
      fj("h2 span:contains(#{title})")
    end

    def details_toggle
      f("button[data-test-id='assignments-2-assignment-toggle-details']")
    end

    def assignment_group_link
      f("a[data-testid='assignmentgroup-link']")
    end

    def due_date_css(due_at)
      "time:contains('#{due_at}')"
    end

    def points_possible_css(points_possible)
      "span:contains('#{points_possible}')"
    end

    def content_tablist
      f("div[data-testid='assignment-2-student-content-tabs']")
    end

    def comment_container
      f("div[data-testid='comments-container']")
    end

    def send_comment_button
      fj('button:contains("Send Comment")')
    end

    def comments_tab
      fj('[role="tab"]:contains("Comments")')
    end

    def comment_text_area
      f('textarea')
    end

    def record_upload_button
      f("button[data-testid='media-modal-launch-button']")
    end

    def media_modal
      f("span[aria-label='Upload Media']")
    end

    def leave_a_comment(comment)
      replace_content(comment_text_area, comment)
      send_comment_button.click
    end
  end
end
