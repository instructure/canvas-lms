# frozen_string_literal: true

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

class Submission::UploadPresenter
  include Rails.application.routes.url_helpers
  include ApplicationHelper

  def initialize(course, assignment)
    @course = course
    @assignment = assignment
  end

  def self.for(course, assignment)
    if assignment.anonymize_students?
      Submission::AnonymousUploadPresenter.new(course, assignment)
    else
      new(course, assignment)
    end
  end

  def file_download_href(comment, file)
    context_url(
      @course,
      :context_assignment_submission_url,
      @assignment.id,
      comment.dig(:submission, :user_id),
      download: file[:id],
      comment_id: comment[:id]
    )
  end

  def progress
    @progress ||= @assignment.submission_reupload_progress
  end

  def submission_href(comment)
    context_url(@course, :context_assignment_submission_url, @assignment.id, comment.dig(:submission, :user_id))
  end

  def student_name(comment)
    comment[:submission][:user_name]
  end
end
