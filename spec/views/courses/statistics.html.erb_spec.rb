# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require_relative "../views_helper"

describe "courses/statistics" do
  before do
    course_with_teacher(active_all: true)
    assign(:range_start, Date.parse("Jan 1 2000"))
    assign(:range_end, 3.days.from_now)
  end

  let(:doc) { Nokogiri::HTML5(response.body) }

  it "only lists active quiz objects, questions, and submissions" do
    quiz_with_submission
    @quiz.destroy
    quiz_with_submission

    view_context(@course, @user)
    render

    expect(doc.at_css(".quiz_count").text).to eq "1"
    expect(doc.at_css(".quiz_question_count").text).to eq "1"
    expect(doc.at_css(".quiz_submission_count").text).to eq "1"
  end

  context "student annotation assignments" do
    before do
      @attachment = attachment_model(context: @course)
      @assignment = @course.assignments.create!(
        name: "annotated",
        submission_types: "student_annotation",
        annotatable_attachment: @attachment
      )
    end

    it "includes counts for student annotation assignments" do
      view_context(@course, @user)
      render
      expect(doc.at_css("#student-annotation-assignment-count").text).to eq "1"
    end

    it "includes counts for student annotation submissions" do
      student = student_in_course(course: @course, active_all: true).user
      @assignment.submit_homework(
        student,
        submission_type: "student_annotation",
        annotatable_attachment_id: @attachment.id
      )

      view_context(@course, @user)
      render
      expect(doc.at_css("#student-annotation-submission-count").text).to eq "1"
    end
  end
end
