# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

require_relative "../helpers/assignments_common"

describe "quizzes assignments" do
  include_context "in-process server selenium tests"
  include AssignmentsCommon

  before do
    @domain_root_account = Account.default
    course_with_teacher_logged_in
    provision_quizzes_next @course
    @course.root_account.enable_feature!(:quizzes_next)
    @course.enable_feature!(:quizzes_next)
    @tool = @course.context_external_tools.create!(
      name: "Quizzes.Next",
      consumer_key: "test123",
      shared_secret: "test123",
      tool_id: "Quizzes 2",
      url: "http://example.com/launch"
    )
  end

  context "created on the index page" do
    it "redirects to the quiz", priority: "2" do
      ag = @course.assignment_groups.create!(name: "Quiz group")
      get "/courses/#{@course.id}/assignments"
      build_assignment_with_type("Quiz", assignment_group_id: ag.id, name: "New Quiz", submit: true)
      refresh_page
      expect_new_page_load { f("#assignment_group_#{ag.id}_assignments .ig-title").click }
      expect(driver.current_url).to match %r{/courses/\d+/quizzes/\d+}
    end
  end

  context "created with 'more options'" do
    it "redirects to the quiz new page and maintain parameters", priority: "2" do
      ag = @course.assignment_groups.create!(name: "Quiz group")
      get "/courses/#{@course.id}/assignments"
      expect_new_page_load { build_assignment_with_type("Quiz", assignment_group_id: ag.id, name: "Testy!", more_options: true) }
      expect(f('input[name="quiz[title]"]')).to have_value "Testy!"
    end

    it "redirects to the assignments new page (new quizzes) and maintains parameters if classic quizzes are disabled" do
      @course.enable_feature!(:new_quizzes_by_default)
      ag = @course.assignment_groups.create!(name: "Quiz group")
      get "/courses/#{@course.id}/assignments"
      expect_new_page_load { build_assignment_with_type("Quiz", assignment_group_id: ag.id, name: "Testy!", more_options: true) }
      expect(f('input[name="name"]')).to have_value "Testy!"
      expect(driver.current_url).to match(%r{/courses/\d+/assignments/new\?quiz_lti})
    end
  end

  context "edited from the index page" do
    it "updates quiz when updated", priority: "1" do
      assign = @course.assignments.create!(name: "Testy!", submission_types: "online_quiz")
      get "/courses/#{@course.id}/assignments"
      edit_assignment(assign.id, name: "Retest!", submit: true)
      expect(Quizzes::Quiz.where(assignment_id: assign).first.title).to eq "Retest!"
    end
  end

  context "edited with 'more options'" do
    it "redirects to the quiz edit page and maintain parameters", priority: "2" do
      assign = @course.assignments.create!(name: "Testy!", submission_types: "online_quiz")
      get "/courses/#{@course.id}/assignments"
      expect_new_page_load { edit_assignment(assign.id, name: "Retest!", more_options: true) }
      expect(f('input[name="quiz[title]"]')).to have_value "Retest!"
    end

    it "redirects to the assignment edit page (new quizzes) and maintains parameters if classic quizzes are disabled" do
      @course.enable_feature!(:new_quizzes_by_default)
      assign = @course.assignments.create!(name: "Testy!")
      assign.quiz_lti!
      assign.save!
      get "/courses/#{@course.id}/assignments"
      expect_new_page_load { edit_assignment(assign.id, name: "Retest!", more_options: true) }
      expect(f('input[name="name"]')).to have_value "Retest!"
    end
  end
end
