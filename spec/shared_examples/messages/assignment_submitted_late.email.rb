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

shared_examples_for "assignment submitted late email" do
  it "subject includes student name" do
    expect(message.subject).to eq "Late assignment: Tom has submitted late for Assignment#1"
  end

  it "renders a link to the student's submission details page" do
    expect(message.url).to eq course_assignment_submission_url(course, assignment, student.id)
  end

  context "assignment is anonymous and muted" do
    before(:each) { assignment.update!(anonymous_grading: true) }

    it "subject does not include student name" do
      expect(message.subject).to eq "Late anonymous assignment: A student has submitted late for Assignment#1"
    end

    it "renders a link to speedgrader for that student" do
      speed_grader_url = speed_grader_course_gradebook_url(course, assignment_id: assignment.id)
      speed_grader_url += "\#{\"anonymous_id\":\"#{submission.anonymous_id}\"}"
      expect(message.url).to eq speed_grader_url
    end
  end

  context "assignment is anonymous and unmuted" do
    before(:each) do
      assignment.update!(anonymous_grading: true)
      assignment.unmute!
    end

    it "subject includes student name" do
      expect(message.subject).to eq "Late assignment: Tom has submitted late for Assignment#1"
    end

    it "renders a link to the student's submission details page" do
      expect(message.url).to eq course_assignment_submission_url(course, assignment, student.id)
    end
  end
end
