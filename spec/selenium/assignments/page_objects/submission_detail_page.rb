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

class SubmissionDetails
  class << self
    include SeleniumDependencies

    # element locators

    def comment_text_by_id(comment_id)
      f("#submission_comment_#{comment_id} span").text
    end

    def comment_list_div
      f('.comment_list')
    end

    def comments
      f('.comment_list .comment .comment')
    end

    def view_feedback_link
      f("div .file-upload-submission-attachment a").attribute('text')
    end

    def add_comment_text_area
      f('.ic-Input.grading_comment')
    end

    def comment_save_button
      fj('button:contains("Save")')
    end


    # page actions

    def submit_comment(text)
      replace_content(add_comment_text_area, text)
      comment_save_button.click
      wait_for_ajaximations
    end

    def visit_as_student(course_id, assignment_id, student_id)
      get "/courses/#{course_id}/assignments/#{assignment_id}/submissions/#{student_id}"
    end
  end
end
