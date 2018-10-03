#
# Copyright (C) 2018 - present Instructure, Inc.
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

describe "assignment_submitted_late.email" do
  include Rails.application.routes.url_helpers

  def default_url_options
    { host: 'localhost' }
  end

  let(:course) { Course.create!(name: "Inst101") }
  let(:student) { course_with_user("StudentEnrollment", course: course, name: "Tom", active_all: true).user }
  let(:assignment) { course.assignments.create!(name: "Assignment#1", due_at: 1.day.ago) }
  let(:submission) { assignment.submit_homework(student) }
  let(:message) { generate_message(:assignment_submitted_late, :email, submission, {}) }

  include_examples "assignment submitted late email"

  it "body includes the student name" do
    expect(
      message.body
    ).to include(
      "Tom has just turned in a late submission for Assignment#1 in the course Inst101"
    )
  end

  it "body does not include the student name if assignment is anonymous and muted" do
    assignment.update!(anonymous_grading: true)
    expect(
      message.body
    ).to include(
      "A student has just turned in a late submission for Assignment#1 in the course Inst101"
    )
  end

  it "body includes the student name if assignment is anonymous and unmuted" do
    assignment.update!(anonymous_grading: true)
    assignment.unmute!
    expect(
      message.body
    ).to include(
      "Tom has just turned in a late submission for Assignment#1 in the course Inst101"
    )
  end
end
