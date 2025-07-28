# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

require_relative "../../views_helper"

describe "quizzes/quizzes/_quiz_edit" do
  before do
    course_with_student
    view_context
    assign(:quiz, @course.quizzes.create!)
    assign(:js_env, { quiz_max_combination_count: 200 })
  end

  it "renders" do
    render partial: "quizzes/quizzes/quiz_edit"
    expect(response).not_to be_nil
  end

  it "includes conditional content if configured" do
    allow(ConditionalRelease::Service).to receive(:enabled_in_context?).and_return(true)
    render partial: "quizzes/quizzes/quiz_edit"
    expect(response.body).to match(/conditional_release/)
  end

  it "does not include conditional content if not configured" do
    allow(ConditionalRelease::Service).to receive(:enabled_in_context?).and_return(false)
    render partial: "quizzes/quizzes/quiz_edit"
    expect(response.body).not_to match(/conditional_release/)
  end

  it "includes quiz details" do
    render partial: "quizzes/quizzes/quiz_edit"
    expect(response.body).to match(/options_tab/)
  end

  it "includes quiz questions" do
    render partial: "quizzes/quizzes/quiz_edit"
    expect(response.body).to match(/questions_tab/)
  end

  it "warns about existing submission data" do
    assign(:has_student_submissions, true)
    render partial: "quizzes/quizzes/quiz_edit"
    expect(response.body).to match(/student_submissions_warning/)
  end

  it "does not warn if no existing data" do
    assign(:has_student_submissions, false)
    render partial: "quizzes/quizzes/quiz_edit"
    expect(response.body).not_to match(/student_submissions_warning/)
  end

  context "with suppress_assignment feature" do
    context "on" do
      before do
        root_account = @course.root_account
        root_account.settings[:suppress_assignments] = true
        root_account.save
      end

      it "shows grading visibility option" do
        render partial: "quizzes/quizzes/quiz_edit_details"
        expect(response.body).to include("Grading Visibility")
        expect(response.body).to include("Hide from gradebook view and student grades view")
      end

      it "renders grading visibility checkbox as checked when suppress_assignment is true" do
        quiz = @course.quizzes.create!
        assignment = @course.assignments.create!(title: "Test Assignment", suppress_assignment: true)
        quiz.update!(assignment_id: assignment.id)
        assign(:quiz, quiz)
        render partial: "quizzes/quizzes/quiz_edit_details"
        doc = Nokogiri::HTML.fragment(response.body)
        checkbox = doc.at_css("input[type='checkbox'][name='quiz[suppress_assignment]']")
        expect(checkbox).not_to be_nil
        expect(checkbox["checked"]).to eq("checked")
      end

      it "renders checkbox as unchecked when suppress_assignment is false" do
        quiz = @course.quizzes.create!
        assignment = @course.assignments.create!(title: "Test Assignment", suppress_assignment: false)
        quiz.update!(assignment_id: assignment.id)
        assign(:quiz, quiz)
        render partial: "quizzes/quizzes/quiz_edit_details"
        doc = Nokogiri::HTML.fragment(response.body)
        checkbox = doc.at_css("input[type='checkbox'][name='quiz[suppress_assignment]']")
        expect(checkbox).not_to be_nil
        expect(checkbox["checked"]).to be_nil
      end
    end

    context "off" do
      before do
        root_account = @course.root_account
        root_account.settings[:suppress_assignment] = false
        root_account.save
      end

      it "does not show grading visibility option" do
        render partial: "quizzes/quizzes/quiz_edit_details"
        expect(response.body).not_to include("Grading Visibility")
        expect(response.body).not_to include("Hide from gradebook view and student grades view")
      end
    end
  end
end
