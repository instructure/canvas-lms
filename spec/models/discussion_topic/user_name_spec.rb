# frozen_string_literal: true

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

require "spec_helper"

describe DiscussionTopic, "#user_name" do
  before :once do
    course_with_teacher
    @course.enroll_user(@teacher, "TeacherEnrollment", enrollment_state: "active")
    @student = student_in_course(course: @course).user
  end

  it "returns nil when topic is anonymous and author is not an instructor" do
    topic = @course.discussion_topics.create!(
      title: "Anon by student",
      message: "message",
      user: @student,
      anonymous_state: "full_anonymity"
    )

    expect(topic.user_name).to be_nil
  end

  it "returns the author's name when topic is anonymous and author is an instructor" do
    topic = @course.discussion_topics.create!(
      title: "Anon by teacher",
      message: "message",
      user: @teacher,
      anonymous_state: "full_anonymity"
    )

    expect(topic.user_name).to eq(@teacher.name)
  end

  it "returns the author's name when topic is not anonymous" do
    topic = @course.discussion_topics.create!(
      title: "Not anonymous",
      message: "message",
      user: @student
    )

    expect(topic.user_name).to eq(@student.name)
  end
end
