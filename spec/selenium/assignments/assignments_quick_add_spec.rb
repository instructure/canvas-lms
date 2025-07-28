# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative "../common"
require_relative "../helpers/files_common"
require_relative "../helpers/submissions_common"
require_relative "../helpers/assignments_common"

describe "assignments" do
  include_context "in-process server selenium tests"
  include FilesCommon
  include AssignmentsCommon
  include SubmissionsCommon

  before do
    course_with_teacher_logged_in

    @assignment_name = "pink panther"
    @assignment_points = "3"
    @assignment_date = "2015-07-31"
  end

  context "quick add" do
    def fill_out_quick_add_modal(type)
      get "/courses/#{@course.id}/assignments"

      build_assignment_with_type(type, name: "pink panther", points: "3", due_at: "2015-07-31")
    end

    it "opens quick add modal", priority: "1" do
      get "/courses/#{@course.id}/assignments"

      f(".add_assignment").click

      expect(f("[data-testid='modal-title']")).to include_text("Create Assignment")
    end

    it "creating basic assignment defaults to 'online_text_entry' submission type", priority: "1" do
      get "/courses/#{@course.id}/assignments"

      build_assignment_with_type("Assignment", name: "pink panther", points: "3", due_at: "2015-07-31", submit: true)

      a = Assignment.last
      expect(a.submission_types).to eq("online_text_entry")
    end

    context "more options button" do
      it "works for assignments and transfer values", priority: "1" do
        fill_out_quick_add_modal("Assignment")
        f("[data-testid='more-options-button']").click

        expect(f("#edit_assignment_header")).to be
        expect(f("#assignment_name").attribute(:value)).to include(@assignment_name)
        expect(f("#assignment_points_possible").attribute(:value)).to include(@assignment_points)
      end

      it "works for discussions and transfer values", priority: "1" do
        fill_out_quick_add_modal("Discussion")
        f("[data-testid='more-options-button']").click

        expect(f(".discussion-edit-header")).to be
        expect(f("#discussion-title").attribute(:value)).to include(@assignment_name)
        expect(f("#discussion_topic_assignment_points_possible").attribute(:value)).to include(@assignment_points)
      end

      it "works for quizzes and transfer values", priority: "1" do
        fill_out_quick_add_modal("Quiz")
        f("[data-testid='more-options-button']").click

        expect(f("#quiz_edit_wrapper")).to be
        expect(f("#quiz_title").attribute(:value)).to include(@assignment_name)
      end
    end
  end

  context "quick edit" do
    before do
      @title = "zoidberg"
    end

    it "works with an assignment", priority: "1" do
      @course.assignments.create!(title: "test assignment", name: @title, workflow_state: "published")
      get "/courses/#{@course.id}/assignments"
      click_cog_to_edit

      expect(f("[data-testid='assignment-name-input']").attribute(:value)).to include(@title)
    end

    it "works with a quiz", priority: "1" do
      @course.assignments.create(title: @title, submission_types: "online_quiz", workflow_state: "published")
      get "/courses/#{@course.id}/assignments"
      click_cog_to_edit

      expect(f("[data-testid='assignment-name-input']").attribute(:value)).to include(@title)
    end

    it "works with a graded discussion", priority: "1" do
      @course.assignments.create!(name: @title, submission_types: "discussion_topic")
      get "/courses/#{@course.id}/assignments"
      click_cog_to_edit
      expect(f("[data-testid='assignment-name-input']").attribute(:value)).to include(@title)
    end

    context "more options button" do
      it "redirects to quiz edit page", priority: "1" do
        quiz = @course.quizzes.create
        quiz.publish!

        get "/courses/#{@course.id}/assignments"
        click_cog_to_edit

        f("[data-testid='more-options-button']").click

        expect(driver.current_url).to include("/quizzes/#{quiz.id}/edit")
      end
    end
  end
end
