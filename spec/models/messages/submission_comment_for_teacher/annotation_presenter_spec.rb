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

describe Messages::SubmissionCommentForTeacher::AnnotationPresenter do
  let_once(:course) { course_model(name: "MATH-101") }
  let_once(:teacher) { course_with_teacher(course:, active_all: true).user }
  let_once(:submitter) { course_with_user("StudentEnrollment", course:, name: "Adam Jones", active_all: true).user }
  let(:assignment) { course.assignments.create!(name: "Introductions", due_at: 1.day.ago) }
  let(:submission) { assignment.submit_homework(submitter) }
  let(:message) { Message.new(context: submission, user: teacher) }
  let(:data) { { author_name: "bill smith" } }
  let(:presenter) { Messages::SubmissionCommentForTeacher::AnnotationPresenter.new(message, data:) }

  it "uses author from provided data" do
    expect(presenter.body).to eq("bill smith just made a new annotation on the submission for Adam Jones for Introductions")
  end
end
