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

require "spec_helper"
require_relative "../../../messages/messages_helper"

describe "submission_comment_for_teacher" do
  let_once(:course) { course_model(name: "MATH-101") }
  let_once(:assignment) { course.assignments.create!(name: "Introductions", due_at: 1.day.ago) }
  let_once(:teacher) { course_with_teacher(course:, active_all: true).user }

  let_once(:submitter) do
    course_with_user("StudentEnrollment", course:, name: "Adam Jones", active_all: true).user
  end
  let_once(:commenter) do
    course_with_user("StudentEnrollment", course:, name: "Betty Ford", active_all: true).user
  end
  let_once(:submission) { assignment.submit_homework(submitter) }

  let_once(:asset) { submission.add_comment(author: commenter, comment: "Looks good!") }
  let_once(:notification_name) { "Submission Comment For Teacher" }

  include_examples "a message"
end
