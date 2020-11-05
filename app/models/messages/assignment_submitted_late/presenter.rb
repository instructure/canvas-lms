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

module Messages::AssignmentSubmittedLate
  class Presenter
    def initialize(message)
      @message = message
    end

    def link
      if anonymous?
        message.speed_grader_course_gradebook_url(course.id, assignment_id: assignment.id, anonymous_id: submission.anonymous_id)
      else
        message.course_assignment_submission_url(course.id, assignment, submission.user_id)
      end
    end

    protected

    attr_reader :message

    def assignment
      submission.assignment
    end

    def anonymous?
      assignment.anonymize_students?
    end

    def course
      assignment.context
    end

    def submission
      message.context
    end
  end
end
