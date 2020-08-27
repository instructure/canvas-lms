#
# Copyright (C) 2020 - present Instructure, Inc.
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
#

class Submission::AnonymousUploadPresenter < Submission::UploadPresenter
  def initialize(course, assignment)
    @course = course
    @assignment = assignment
  end

  def file_download_href(comment, file)
    context_url(
      @course,
      :course_assignment_anonymous_submission_url,
      @assignment,
      anonymous_id(comment),
      download: file[:id],
      comment_id: comment[:id]
    )
  end

  def submission_href(comment)
    context_url(
      @course,
      :speed_grader_context_gradebook_url,
      assignment_id: @assignment,
      anonymous_id: anonymous_id(comment)
    )
  end

  def student_name(_comment)
    I18n.t("Anonymous Student")
  end

  private

  def anonymous_id(comment)
    # We didn't used to store 'anonymous_id' on "submissions_reupload" Progress objects (in which
    # case it won't be available on the comment hash here), so if it's not available we'll fetch
    # it from the submission object.
    comment.dig(:submission, :anonymous_id) || student_ids_to_anonymous_ids[comment.dig(:submission, :user_id)]
  end

  def student_ids_to_anonymous_ids
    @student_ids_to_anonymous_ids ||= @assignment.all_submissions.pluck(:user_id, :anonymous_id).to_h
  end
end
