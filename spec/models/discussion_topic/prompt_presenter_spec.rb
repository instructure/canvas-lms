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

  describe "#content_for_summary" do
    it "generates correct discussion summary" do
      expected_output = <<~TEXT
        <discussion>
          <topic user="instructor_1">
            <title>
        Discussion Topic Title    </title>
            <message>
        Discussion Topic Message    </message>
          </topic>
          <entries>
        <entry user="student_1" index="1">
        I liked the course.</entry>
        <entry user="student_2" index="2">
        I felt the course was too hard.</entry>
        <entry user="instructor_1" index="2.1">
        I'm sorry to hear that. Could you please provide more details?</entry>
          </entries>
        </discussion>
      TEXT

      expect(@presenter.content_for_summary.strip).to eq(expected_output.strip)
    end

    describe ".focus_for_summary" do
      it "generates focus XML with user input" do
        user_input = "specific focus"
        expected_output = <<~XML
          <focus>specific focus</focus>
        XML

        result = DiscussionTopic::PromptPresenter.focus_for_summary(user_input:)
        expect(result.strip).to eq(expected_output.strip)
      end

      it "generates focus XML with default focus" do
        expected_output = <<~XML
          <focus>general summary</focus>
        XML

        result = DiscussionTopic::PromptPresenter.focus_for_summary(user_input: nil)
        expect(result.strip).to eq(expected_output.strip)
      end
    end

    describe ".raw_summary_for_refinement" do
      it "generates raw summary XML" do
        raw_summary = "This is the raw summary."
        expected_output = <<~XML
          <raw_summary>This is the raw summary.</raw_summary>
        XML

        result = DiscussionTopic::PromptPresenter.raw_summary_for_refinement(raw_summary:)
        expect(result.strip).to eq(expected_output.strip)
      end
    end
  end
end
