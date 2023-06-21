# frozen_string_literal: true

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
#

module Messages::SubmissionCommentForTeacher
  class Presenter
    def initialize(message, data: {})
      @message = message
      @data = data
    end

    def link
      return @link if defined?(@link)

      @link = if anonymous?
                message.speed_grader_course_gradebook_url(course.id, assignment_id: assignment.id, anonymous_id: submission.anonymous_id)
              else
                message.course_assignment_submission_url(course.id, assignment, submission.user_id)
              end
    end

    def comment_text
      submission_comment.comment
    end

    def anonymous?
      assignment.anonymize_students?
    end

    delegate :attachments, :media_comment?, to: :submission_comment

    protected

    attr_reader :message

    def assignment
      submission.assignment
    end

    def course
      assignment.context
    end

    def submission
      submission_comment.submission
    end

    def submission_comment
      message.context
    end

    def anonymous_author_id
      if submission_comment.author == submission.user
        submission.anonymous_id
      else
        return @author_submission&.anonymous_id if defined?(@author_submission)

        @author_submission = Submission.find_by(assignment:, user: submission_comment.author)
        @author_submission&.anonymous_id
      end
    end
  end
end
