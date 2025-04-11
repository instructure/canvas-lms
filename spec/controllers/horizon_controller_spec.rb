# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require "json"

describe HorizonController do
  describe "GET canvas_career_validation" do
    it "should success when course has no errors" do
      course_factory(active_all: true)
      @course.announcements.create!(title: "Announcement 1", message: "Message 1")
      @course.assignments.create!(name: "Assignment 1", points_possible: 10, submission_types: "online_text_entry", workflow_state: "unpublished")

      account_admin_user
      user_session(@admin)

      get "validate_course", params: { course_id: @course.id }

      json = json_parse(response.body)
      expect(json).to eq({ "errors" => {} })
    end

    it "unauthorized for user" do
      course_with_student_logged_in(active_all: true)

      get "validate_course", format: :json, params: { course_id: @course.id }
      expect(response).to have_http_status(:forbidden)
    end

    it "unauthorized for teacher" do
      course_with_teacher_logged_in(active_all: true)

      get "validate_course", format: :json, params: { course_id: @course.id }
      expect(response).to have_http_status(:forbidden)
    end

    it "returns error when course has discussions" do
      course_factory(active_all: true)
      @course.discussion_topics.create!(title: "Discussion 1")

      account_admin_user
      user_session(@admin)

      get "validate_course", format: :json, params: { course_id: @course.id }

      json = json_parse(response.body)
      expect(json["errors"]).to have_key("discussions")
    end

    it "returns error when course has groups" do
      course_factory(active_all: true)
      group = @course.groups.create!(name: "Group 1")

      account_admin_user
      user_session(@admin)

      get "validate_course", format: :json, params: { course_id: @course.id }

      json = json_parse(response.body)
      expect(json["errors"]).to have_key("groups")
      expect(json["errors"]["groups"].first).to include(
        "id" => group.id,
        "name" => "Group 1"
      )
    end

    it "returns error when course has classic quizzes" do
      course_factory(active_all: true)
      quiz = @course.quizzes.create!(title: "Quiz 1")

      account_admin_user
      user_session(@admin)

      get "validate_course", format: :json, params: { course_id: @course.id }

      json = json_parse(response.body)
      expect(json["errors"]).to have_key("quizzes")
      expect(json["errors"]["quizzes"].first).to include(
        "id" => quiz.id,
        "name" => "Quiz 1"
      )
    end

    it "returns error when course has outcomes associated" do
      course_factory(active_all: true)
      outcome = @course.learning_outcomes.create!(title: "Outcome 1")

      account_admin_user
      user_session(@admin)

      get "validate_course", format: :json, params: { course_id: @course.id }

      json = json_parse(response.body)
      expect(json["errors"]).to have_key("outcomes")
      expect(json["errors"]["outcomes"].first).to include(
        "id" => outcome.id,
        "name" => "Outcome 1"
      )
    end

    it "returns error when course has collaborations tools added" do
      course_factory(active_all: true)
      collab = @course.collaborations.create!(title: "Collaboration 1")

      account_admin_user
      user_session(@admin)

      get "validate_course", format: :json, params: { course_id: @course.id }

      json = json_parse(response.body)
      expect(json["errors"]).to have_key("collaborations")
      expect(json["errors"]["collaborations"].first).to include(
        "id" => collab.id,
        "name" => "Collaboration 1"
      )
    end

    it "returns errors when multiple items have errors" do
      course_factory(active_all: true)
      @course.discussion_topics.create!(title: "Discussion 1")
      @course.quizzes.create!(title: "Problem Quiz")

      account_admin_user
      user_session(@admin)

      get "validate_course", format: :json, params: { course_id: @course.id }

      json = json_parse(response.body)
      expect(json["errors"].keys).to include("discussions", "quizzes")
    end

    it "returns some errors when course has mixed learning objects" do
      course_factory(active_all: true)
      @course.discussion_topics.create!(title: "Discussion 1")
      @course.announcements.create!(title: "Announcement 1", message: "Message 1")
      a1 = @course.assignments.create!(name: "Assignment 1", points_possible: 10, submission_types: "online_text_entry", workflow_state: "unpublished")
      a2 = @course.assignments.create!(name: "Assignment 2", points_possible: 20)
      a3 = @course.assignments.create!(name: "Assignment 3", points_possible: 30, peer_reviews: true)

      account_admin_user
      user_session(@admin)
      rubric = @course.rubrics.create! { |r| r.user = @admin }
      rubric_association_params = ActiveSupport::HashWithIndifferentAccess.new({
                                                                                 hide_score_total: "0",
                                                                                 purpose: "grading",
                                                                                 skip_updating_points_possible: false,
                                                                                 update_if_existing: true,
                                                                                 use_for_grading: "1",
                                                                                 association_object: a3
                                                                               })
      rubric_assoc = RubricAssociation.generate(@admin, rubric, @course, rubric_association_params)
      a2.update!(peer_reviews: true)
      a2.save!
      a3.rubric_association = rubric_assoc
      a3.save!

      get "validate_course", params: { course_id: @course.id }
      json = json_parse(response.body)

      expect(json["errors"]["assignments"].any? { |a| a["name"] == a1.name }).to be_falsey
      expect(json["errors"]["assignments"].any? { |a| a["name"] == a2.name }).to be_truthy
      expect(json["errors"]["assignments"].any? { |a| a["name"] == a3.name }).to be_truthy
    end
  end

  describe "POST canvas_career_conversion" do
    it "converts course to Horizon" do
      course_factory(active_all: true)
      @course.account.enable_feature!(:horizon_course_setting)
      @course.discussion_topics.create!(title: "Discussion 1")
      @course.announcements.create!(title: "Announcement 1", message: "Message 1")
      @course.assignments.create!(name: "Assignment 1", points_possible: 10, submission_types: "online_text_entry", workflow_state: "unpublished")
      a2 = @course.assignments.create!(name: "Assignment 2", points_possible: 20, workflow_state: "unpublished")
      a3 = @course.assignments.create!(name: "Assignment 3", points_possible: 30, submission_types: "online_text_entry", workflow_state: "unpublished")
      @course.assignments.create!(name: "Assignment 4", points_possible: 20, workflow_state: "unpublished")
      @course.assignments.create!(name: "Assignment 5", points_possible: 20, workflow_state: "unpublished")
      @course.groups.create!(name: "Group 1")
      @course.groups.create!(name: "Group 2")
      @course.groups.create!(name: "Group 3")
      @course.learning_outcomes.create!(title: "Outcome 1")
      @course.collaborations.create!(title: "Collaboration 1")

      account_admin_user
      user_session(@admin)
      rubric = @course.rubrics.create! { |r| r.user = @admin }
      rubric_association_params = ActiveSupport::HashWithIndifferentAccess.new({
                                                                                 hide_score_total: "0",
                                                                                 purpose: "grading",
                                                                                 skip_updating_points_possible: false,
                                                                                 update_if_existing: true,
                                                                                 use_for_grading: "1",
                                                                                 association_object: a3
                                                                               })
      rubric_assoc = RubricAssociation.generate(@admin, rubric, @course, rubric_association_params)
      a2.update!(peer_reviews: true)
      a2.save!
      a3.rubric_association = rubric_assoc
      a3.save!

      get "validate_course", params: { course_id: @course.id }

      json = JSON.parse(response.body, { symbolize_names: true })

      # not calling the endpoint directly because it's delayed
      Courses::HorizonService.convert_course_to_horizon(context: @course, errors: json[:errors])

      @course.reload
      expect(@course.discussion_topics.only_discussion_topics.count).to eq(0)
      expect(@course.assignments.all? { |a| a.submission_types == "online_text_entry" && !a.peer_reviews && !a.active_rubric_association? }).to be_truthy
      expect(@course.groups.count).to eq(3)
      expect(@course.groups.active.count).to eq(0)
      expect(@course.horizon_course?).to be_truthy
    end

    it "converts instantly if course has only compatible learning objects" do
      course_factory(active_all: true)

      account_admin_user
      user_session(@admin)

      @course.account.enable_feature!(:horizon_course_setting)
      @course.assignments.create!(name: "Assignment 1", points_possible: 10, submission_types: "online_text_entry", workflow_state: "unpublished")

      post "convert_course", params: { course_id: @course.id }, format: :json

      json = JSON.parse(response.body, { symbolize_names: true })
      @course.reload
      expect(json[:success]).to be_truthy
      expect(@course.horizon_course?).to be_truthy
    end

    it "unpublishes already published assignments" do
      course_factory(active_all: true)
      module1 = @course.context_modules.create!(name: "Module 1")
      module2 = @course.context_modules.create!(name: "Module 2", workflow_state: "unpublished")

      account_admin_user
      user_session(@admin)

      @course.account.enable_feature!(:horizon_course_setting)
      a1 = assignment_model(name: "Assignment 1", points_possible: 10, submission_types: "online_text_entry", course: @course, workflow_state: "published")
      a2 = assignment_model(name: "Assignment 2", points_possible: 10, submission_types: "online_text_entry", course: @course, workflow_state: "published")
      a3 = assignment_model(name: "Assignment 3", points_possible: 10, submission_types: "online_text_entry", course: @course, workflow_state: "published")
      a4 = assignment_model(name: "Assignment 3", points_possible: 10, submission_types: "online_text_entry", course: @course, workflow_state: "published")
      a1.context_module_tags.create!(context_module: module1, context: a1.course, tag_type: "context_module", workflow_state: "active")
      a2.context_module_tags.create!(context_module: module2, context: a2.course, tag_type: "context_module", workflow_state: "active")
      a3.context_module_tags.create!(context_module: module1, context: a2.course, tag_type: "learning_outcome", workflow_state: "active")

      get "validate_course", params: { course_id: @course.id }

      json = JSON.parse(response.body, { symbolize_names: true })

      Courses::HorizonService.convert_course_to_horizon(context: @course, errors: json[:errors])
      @course.reload
      expect(a1.reload.workflow_state).to eq("published")
      expect(a2.reload.workflow_state).to eq("unpublished")
      expect(a3.reload.workflow_state).to eq("unpublished")
      expect(a4.reload.workflow_state).to eq("unpublished")
      expect(@course.horizon_course?).to be_truthy
    end
  end

  describe "POST canvas_career_reversion" do
    it "reverts course to normal" do
      course_factory(active_all: true)

      account_admin_user
      user_session(@admin)

      @course.account.enable_feature!(:horizon_course_setting)
      @course.update!(horizon_course: true)

      expect(@course.horizon_course?).to be_truthy

      post "revert_course", params: { course_id: @course.id }, format: :json

      @course.reload
      expect(@course.horizon_course?).to be_falsey
    end
  end
end
