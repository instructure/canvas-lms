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
  include SeleniumDependencies

  def visit_as_student(courseid,assignmentid,studentid)
    get "/courses/#{courseid}/assignments/#{assignmentid}/submissions/#{studentid}"
  end

  def comment_text_by_id(comment_id)
    f("#submission_comment_#{comment_id} span").text
  end

  def comment_list_div
    f('.comment_list')
  end

  def view_feedback_link
    f("div .file-upload-submission-attachment a").attribute('text')
  end
end
