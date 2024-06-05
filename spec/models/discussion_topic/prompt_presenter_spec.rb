# frozen_string_literal: true

# Copyright (C) 2024 - present Instructure, Inc.
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

describe DiscussionTopic::PromptPresenter do
  before do
    course_model
    @instructor_1 = @user

    @topic = @course.discussion_topics.create!(
      title: "Discussion Topic Title",
      message: "Discussion Topic Message",
      user: @instructor_1
    )

    @student_1 = user_model
    @student_2 = user_model
    @topic.course.enroll_user(@student_1, "StudentEnrollment", enrollment_state: "active")
    @topic.course.enroll_user(@student_2, "StudentEnrollment", enrollment_state: "active")

    @topic.discussion_entries.create!(user: @student_1, message: "I liked the course.")
    entry_2 = @topic.discussion_entries.create!(user: @student_2, message: "I felt the course was too hard.")
    @topic.discussion_entries.create!(user: @instructor_1, message: "I'm sorry to hear that. Could you please provide more details?", parent_entry: entry_2)

    @presenter = described_class.new(@topic)
  end

  describe "#initialize" do
    it "initializes with a discussion topic" do
      expect(@presenter.instance_variable_get(:@topic)).to eq(@topic)
    end
  end

  describe "#dynamic_content_for_summary" do
    it "generates correct discussion summary" do
      expected_output = <<~TEXT
        DISCUSSION BY instructor_1 WITH TITLE:
        '''
        #{@topic.title}
        '''

        DISCUSSION MESSAGE:
        '''
        #{@topic.message}
        '''

        DISCUSSION ENTRY BY student_1 ON THREAD LEVEL 1:
        '''
        I liked the course.
        '''

        DISCUSSION ENTRY BY student_2 ON THREAD LEVEL 2:
        '''
        I felt the course was too hard.
        '''

        DISCUSSION ENTRY BY instructor_1 ON THREAD LEVEL 2.1:
        '''
        I'm sorry to hear that. Could you please provide more details?
        '''
      TEXT

      expect(@presenter.dynamic_content_for_summary.strip).to eq(expected_output.strip)
    end
  end
end
