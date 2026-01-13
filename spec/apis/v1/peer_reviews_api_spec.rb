# frozen_string_literal: true

#
# Copyright (C) 2015 Instructure, Inc.
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

require_relative "../api_spec_helper"

describe PeerReviewsApiController, type: :request do
  def rubric_association_params_for_assignment(assign)
    ActiveSupport::HashWithIndifferentAccess.new({
                                                   hide_score_total: "0",
                                                   purpose: "grading",
                                                   skip_updating_points_possible: false,
                                                   update_if_existing: true,
                                                   use_for_grading: "1",
                                                   association_object: assign
                                                 })
  end

  def assessment_request(submission, teacher, assessor_submission)
    ra_params = rubric_association_params_for_assignment(submission.assignment)
    rubric_assoc = RubricAssociation.generate(teacher, @rubric, @course, ra_params)
    rubric_assessment = RubricAssessment.create!({
                                                   artifact: submission,
                                                   assessment_type: "peer_review",
                                                   assessor: assessor_submission.user,
                                                   rubric: @rubric,
                                                   user: submission.user,
                                                   rubric_association: rubric_assoc
                                                 })
    AssessmentRequest.create!(
      rubric_assessment:,
      user: submission.user,
      asset: submission,
      assessor_asset: assessor_submission,
      assessor: assessor_submission.user
    )
  end

  before :once do
    course_with_teacher(active_all: true)
    @cs = @course.course_sections.create!
    @student1 = student_in_course(active_all: true).user
    @student2 = student_in_course(active_all: true).user
    @assignment1 = assignment_model(course: @course)
    @submission = @assignment1.find_or_create_submission(@student1)
    @assessor_submission = @assignment1.find_or_create_submission(@student2)
    @rubric = @course.rubrics.create! { |r| r.user = @teacher }
    @assessment_request = assessment_request(@submission, @teacher, @assessor_submission)
  end

  describe "Delete 'delete'" do
    before :once do
      @resource_path = "/api/v1/courses/#{@course.id}/assignments/#{@assignment1.id}/submissions/#{@submission.id}/peer_reviews"
      @section_resource_path = "/api/v1/sections/#{@cs.id}/assignments/#{@assignment1.id}/submissions/#{@submission.id}/peer_reviews"
      @resource_params = { controller: "peer_reviews_api",
                           action: "destroy",
                           format: "json",
                           course_id: @course.id,
                           assignment_id: @assignment1.id,
                           submission_id: @submission.id,
                           section_id: @cs.id }
    end

    def delete_peer_review(current_user, resource_path, resource_params)
      student3 = student_in_course(active_all: true).user
      assessment_request = @assignment.assign_peer_review(student3, @student1)
      @user = current_user
      json = api_call(:delete, resource_path, resource_params, { user_id: student3.id })
      expect(AssessmentRequest.where(id: assessment_request.id).count).to eq(0)
      expect(json).to eq({ "assessor_id" => assessment_request.assessor_id,
                           "asset_id" => assessment_request.asset_id,
                           "asset_type" => "Submission",
                           "id" => assessment_request.id,
                           "user_id" => assessment_request.user_id,
                           "workflow_state" => "assigned" })
    end

    context "with admin context" do
      before :once do
        account_admin_user
      end

      it "deletes peer review" do
        delete_peer_review(@admin, @resource_path, @resource_params)
      end

      it "deletes peer review for course section" do
        delete_peer_review(@admin, @section_resource_path, @resource_params)
      end

      it "renders bad request" do
        student3 = student_in_course(active_all: true).user
        @user = @admin
        api_call(:delete,
                 @resource_path,
                 @resource_params,
                 { user_id: student3.id },
                 {},
                 { expected_status: 400 })
      end
    end

    context "with teacher context" do
      it "deletes peer review" do
        delete_peer_review(@teacher, @resource_path, @resource_params)
      end
    end

    context "with student context" do
      it "returns 403 forbidden access" do
        student3 = student_in_course(active_all: true).user
        api_call(:delete,
                 @resource_path,
                 @resource_params,
                 { user_id: student3.id },
                 {},
                 { expected_status: 403 })
      end
    end
  end

  describe "Post 'create'" do
    before :once do
      @resource_path = "/api/v1/courses/#{@course.id}/assignments/#{@assignment1.id}/submissions/#{@submission.id}/peer_reviews"
      @section_resource_path = "/api/v1/sections/#{@cs.id}/assignments/#{@assignment1.id}/submissions/#{@submission.id}/peer_reviews"
      @resource_params = { controller: "peer_reviews_api",
                           action: "create",
                           format: "json",
                           course_id: @course.id,
                           assignment_id: @assignment1.id,
                           submission_id: @submission.id,
                           section_id: @cs.id }
    end

    def create_peer_review(current_user, resource_path, resource_params)
      student3 = student_in_course(active_all: true).user
      @user = current_user
      json = api_call(:post, resource_path, resource_params, { user_id: student3.id })
      requests = AssessmentRequest.for_assessor(student3.id)
      expect(requests.count).to eq(1)
      expect(json).to eq({ "assessor_id" => student3.id, "asset_id" => @submission.id, "asset_type" => "Submission", "id" => requests.first.id, "user_id" => @student1.id, "workflow_state" => "assigned" })
    end

    context "with admin_context" do
      before :once do
        account_admin_user
      end

      it "creates peer review" do
        create_peer_review(@admin, @resource_path, @resource_params)
      end

      it "creates peer review for course section" do
        create_peer_review(@admin, @section_resource_path, @resource_params)
      end

      it "does not create peer review where the reviewer and student are same" do
        api_call(:post, @resource_path, @resource_params, { user_id: @student1.id }, {}, { expected_status: 400 })
      end
    end

    context "with teacher context" do
      it "creates peer review" do
        create_peer_review(@teacher, @resource_path, @resource_params)
      end
    end

    context "with student context" do
      it "returns 403 forbidden access" do
        student3 = student_in_course(active_all: true).user
        api_call(:post,
                 @resource_path,
                 @resource_params,
                 { user_id: student3.id },
                 {},
                 { expected_status: 403 })
      end
    end
  end

  describe "Get 'index'" do
    before :once do
      @resource_path = "/api/v1/courses/#{@course.id}/assignments/#{@assignment1.id}/peer_reviews"
      @section_resource_path = "/api/v1/sections/#{@cs.id}/assignments/#{@assignment1.id}/peer_reviews"
      @submission_resource_path = "/api/v1/courses/#{@course.id}/assignments/#{@assignment1.id}/submissions/#{@submission.id}/peer_reviews"
      @submission_section_resource_path = "/api/v1/sections/#{@cs.id}/assignments/#{@assignment1.id}/submissions/#{@submission.id}/peer_reviews"
      @resource_params = { controller: "peer_reviews_api",
                           action: "index",
                           format: "json",
                           course_id: @course.id,
                           assignment_id: @assignment1.id,
                           section_id: @cs.id }
      @submission_resource_params = { controller: "peer_reviews_api",
                                      action: "index",
                                      format: "json",
                                      course_id: @course.id,
                                      assignment_id: @assignment1.id,
                                      submission_id: @submission.id,
                                      section_id: @cs.id }

      @assessment_with_user = { "assessor" => { "id" => @student2.id,
                                                "anonymous_id" => @student2.id.to_s(36),
                                                "display_name" => "User",
                                                "avatar_image_url" => "http://www.example.com/images/messages/avatar-50.png",
                                                "pronouns" => nil,
                                                "html_url" => "http://www.example.com/courses/#{@course.id}/users/#{@student2.id}" },
                                "assessor_id" => @student2.id,
                                "asset_id" => @submission.id,
                                "asset_type" => "Submission",
                                "id" => @assessment_request.id,
                                "user" => { "id" => @student1.id,
                                            "anonymous_id" => @student1.id.to_s(36),
                                            "display_name" => "User",
                                            "avatar_image_url" => "http://www.example.com/images/messages/avatar-50.png",
                                            "pronouns" => nil,
                                            "html_url" => "http://www.example.com/courses/#{@course.id}/users/#{@student1.id}" },
                                "user_id" => @student1.id,
                                "workflow_state" => @assessment_request.workflow_state }
    end

    def list_peer_review(current_user, resource_path, resource_params)
      @user = current_user
      json = api_call(:get, resource_path, resource_params)
      expect(json.count).to eq(1)
      expect(json[0]).to eq({ "assessor_id" => @student2.id,
                              "asset_id" => @submission.id,
                              "asset_type" => "Submission",
                              "id" => @assessment_request.id,
                              "user_id" => @student1.id,
                              "workflow_state" => @assessment_request.workflow_state })
    end

    def assessment_with_comments(comment)
      {
        "assessor_id" => @student2.id,
        "asset_id" => @submission.id,
        "asset_type" => "Submission",
        "id" => @assessment_request.id,
        "submission_comments" => [
          {
            "attempt" => nil,
            "author_id" => @student2.id,
            "author_name" => @student2.name,
            "comment" => comment.comment,
            "created_at" => comment.created_at.as_json,
            "edited_at" => nil,
            "id" => comment.id,
            "author" => {
              "id" => @student2.id,
              "anonymous_id" => @student2.id.to_s(36),
              "display_name" => @student2.name,
              "pronouns" => nil,
              "avatar_image_url" => "http://www.example.com/images/messages/avatar-50.png",
              "html_url" => "http://www.example.com/courses/#{@course.id}/users/#{@student2.id}"
            }
          }
        ],
        "user_id" => @student1.id,
        "workflow_state" => @assessment_request.workflow_state
      }
    end

    context "with admin_context" do
      before :once do
        account_admin_user
      end

      it "returns all peer reviews" do
        list_peer_review(@admin, @resource_path, @resource_params)
      end

      it "returns all peer reviews in a section" do
        list_peer_review(@admin, @section_resource_path, @resource_params)
      end

      it "returns all peer reviews when anonymous peer reviews enabled" do
        @assignment1.update_attribute(:anonymous_peer_reviews, true)
        list_peer_review(@admin, @resource_path, @resource_params)
      end

      it "includes user information" do
        json = api_call(:get, @resource_path, @resource_params, { include: %w[user] })
        expect(json.count).to eq(1)
        expect(json[0]).to eq(@assessment_with_user)
      end

      it "includes submission comments" do
        @comment = @submission.add_comment(author: @student2, comment: "student2 comment")
        json = api_call(:get, @resource_path, @resource_params, { include: %w[submission_comments] })
        expect(json.count).to eq(1)
        expect(json[0]).to eq(assessment_with_comments(@comment))
      end

      it "returns peer reviews for a specific submission" do
        submission2 = @assignment1.find_or_create_submission(@student2)
        assessment_request(submission2, @teacher, @submission)
        list_peer_review(@admin, @submission_resource_path, @submission_resource_params)
      end

      it "returns peer reviews for a specific submission in a section" do
        submission2 = @assignment1.find_or_create_submission(@student2)
        assessment_request(submission2, @teacher, @submission)
        list_peer_review(@admin, @submission_section_resource_path, @submission_resource_params)
      end
    end

    context "with teacher_context" do
      it "returns all peer reviews" do
        list_peer_review(@teacher, @resource_path, @resource_params)
      end

      it "returns all peer reviews when anonymous peer reviews enabled" do
        @assignment1.update_attribute(:anonymous_peer_reviews, true)
        list_peer_review(@teacher, @resource_path, @resource_params)
      end

      it "includes user information" do
        @user = @teacher
        json = api_call(:get, @resource_path, @resource_params, { include: %w[user] })
        expect(json.count).to eq(1)
        expect(json[0]).to eq(@assessment_with_user)
      end

      it "includes submission comments" do
        @user = @teacher
        @comment = @submission.add_comment(author: @student2, comment: "student2 comment")
        json = api_call(:get, @resource_path, @resource_params, { include: %w[submission_comments] })
        expect(json.count).to eq(1)
        expect(json[0]).to eq(assessment_with_comments(@comment))
      end

      it "returns peer reviews for a specific submission" do
        submission2 = @assignment1.find_or_create_submission(@student2)
        assessment_request(submission2, @teacher, @submission)
        list_peer_review(@teacher, @submission_resource_path, @submission_resource_params)
      end
    end

    context "with student_context" do
      it "returns peer reviews for user" do
        list_peer_review(@student1, @resource_path, @resource_params)
      end

      it "does not return assessor if anonymous peer reviews enabled" do
        @user = @student1
        @assignment1.update_attribute(:anonymous_peer_reviews, true)
        json = api_call(:get, @resource_path, @resource_params)
        expect(json.count).to eq(1)
        expect(json[0]).to eq({ "asset_id" => @submission.id,
                                "asset_type" => "Submission",
                                "id" => @assessment_request.id,
                                "user_id" => @student1.id,
                                "workflow_state" => @assessment_request.workflow_state })
      end

      it "does not return peer reviews for assessor" do
        @user = @student2
        json = api_call(:get, @resource_path, @resource_params)
        expect(json.count).to eq(0)
      end

      it "includes user information" do
        @assignment1.update_attribute(:anonymous_peer_reviews, false)
        @user = @student1
        json = api_call(:get, @resource_path, @resource_params, { include: %w[user] })
        expect(json.count).to eq(1)
        expect(json[0]).to eq(@assessment_with_user)
      end

      it "does not include assessor information when peer reviews are enabled" do
        @assignment1.update_attribute(:anonymous_peer_reviews, true)
        @user = @student1
        json = api_call(:get, @resource_path, @resource_params, { include: %w[user] })
        expect(json.count).to eq(1)
        expect(json[0]).to eq({ "asset_id" => @submission.id,
                                "asset_type" => "Submission",
                                "id" => @assessment_request.id,
                                "user" => { "id" => @student1.id,
                                            "anonymous_id" => @student1.id.to_s(36),
                                            "display_name" => "User",
                                            "pronouns" => nil,
                                            "avatar_image_url" => "http://www.example.com/images/messages/avatar-50.png",
                                            "html_url" => "http://www.example.com/courses/#{@course.id}/users/#{@student1.id}" },
                                "user_id" => @student1.id,
                                "workflow_state" => @assessment_request.workflow_state })
      end

      it "includes submission comments" do
        @assignment1.update_attribute(:anonymous_peer_reviews, false)
        @comment = @submission.add_comment(author: @student2, comment: "student2 comment")
        @user = @student1
        json = api_call(:get, @resource_path, @resource_params, { include: %w[submission_comments] })
        expect(json.count).to eq(1)
        expect(json[0]).to eq(assessment_with_comments(@comment))
      end

      it "does not include submission comments user information when anonymous peer reviews" do
        @course.root_account.tap { |a| a.enable_service(:avatars) }.save!
        @assignment1.update_attribute(:anonymous_peer_reviews, true)
        @comment = @submission.add_comment(author: @student2, comment: "review comment")
        @user = @student1
        json = api_call(:get, @resource_path, @resource_params, { include: %w[submission_comments] })
        expect(json.count).to eq(1)
        expect(json[0]).to eq(
          {
            "asset_id" => @submission.id,
            "asset_type" => "Submission",
            "id" => @assessment_request.id,
            "submission_comments" => [
              {
                "attempt" => nil,
                "author_id" => nil,
                "author_name" => "Anonymous User",
                "avatar_path" => User.default_avatar_fallback,
                "comment" => "review comment",
                "created_at" => @comment.created_at.as_json,
                "edited_at" => nil,
                "id" => @comment.id,
                "author" => {}
              }
            ],
            "user_id" => @student1.id,
            "workflow_state" => @assessment_request.workflow_state
          }
        )
      end

      it "returns peer reviews for a specific submission" do
        @user = @student1
        submission2 = @assignment1.find_or_create_submission(@student2)
        assessment_request(submission2, @teacher, @submission)
        json = api_call(:get, @submission_resource_path, @submission_resource_params)
        expect(json.count).to eq(1)
        expect(json[0]).to eq({ "assessor_id" => @student2.id,
                                "asset_id" => @submission.id,
                                "asset_type" => "Submission",
                                "id" => @assessment_request.id,
                                "user_id" => @student1.id,
                                "workflow_state" => @assessment_request.workflow_state })
      end

      it "returns no peer reviews for invalid submission" do
        @assignment2 = assignment_model(course: @course)
        @submission_resource_path = "/api/v1/courses/#{@course.id}/assignments/#{@assignment2.id}/submissions/#{@submission.id}/peer_reviews"
        @submission_resource_params = { controller: "peer_reviews_api",
                                        action: "index",
                                        format: "json",
                                        course_id: @course.id,
                                        assignment_id: @assignment2.id,
                                        submission_id: @submission.id,
                                        section_id: @cs.id }
        json = api_call(:get, @submission_resource_path, @submission_resource_params)
        expect(json.count).to eq(0)
      end
    end
  end

  describe "Post 'allocate'" do
    before :once do
      # Enable feature flag for allocation endpoint
      @course.enable_feature!(:peer_review_allocation_and_grading)

      @assignment2 = @course.assignments.create!(
        title: "Peer Review Assignment",
        peer_reviews: true,
        peer_review_count: 2,
        automatic_peer_reviews: false
      )
      @resource_path = "/api/v1/courses/#{@course.id}/assignments/#{@assignment2.id}/allocate"
      @resource_params = {
        controller: "peer_reviews_api",
        action: "allocate",
        format: "json",
        course_id: @course.id,
        assignment_id: @assignment2.id
      }
    end

    context "with student context" do
      it "allocates multiple peer reviews successfully" do
        student3 = student_in_course(active_all: true).user
        @user = @student1
        @assignment2.submit_homework(@student1, body: "My submission")
        @assignment2.submit_homework(@student2, body: "Student2 submission")
        @assignment2.submit_homework(student3, body: "Student3 submission")

        json = api_call(:post, @resource_path, @resource_params)

        expect(json).to be_an(Array)
        expect(json.size).to eq(2)
        expect(json.all? { |ar| ar["assessor_id"] == @student1.id }).to be true
        expect(json.pluck("user_id")).to match_array([@student2.id, student3.id])
        expect(json.all? { |ar| ar["workflow_state"] == "assigned" }).to be true
      end

      it "returns error when feature flag is not enabled" do
        @course.disable_feature!(:peer_review_allocation_and_grading)
        @user = @student1
        @assignment2.submit_homework(@student1, body: "My submission")
        @assignment2.submit_homework(@student2, body: "Student2 submission")

        json = api_call(:post,
                        @resource_path,
                        @resource_params,
                        {},
                        {},
                        { expected_status: 403 })
        expect(json["errors"]["base"]).to include("feature is not enabled")

        # Re-enable for other tests
        @course.enable_feature!(:peer_review_allocation_and_grading)
      end

      it "returns error when assignment does not have peer reviews enabled" do
        @assignment3 = @course.assignments.create!(title: "No Peer Reviews")
        @resource_path = "/api/v1/courses/#{@course.id}/assignments/#{@assignment3.id}/allocate"
        @resource_params[:assignment_id] = @assignment3.id

        @user = @student1
        @assignment3.submit_homework(@student1, body: "My submission")

        api_call(:post,
                 @resource_path,
                 @resource_params,
                 {},
                 {},
                 { expected_status: 403 })
      end

      it "returns error when student has not submitted" do
        @user = @student1
        @assignment2.submit_homework(@student2, body: "Student2 submission")

        json = api_call(:post,
                        @resource_path,
                        @resource_params,
                        {},
                        {},
                        { expected_status: 403 })
        expect(json["errors"]["base"]).to include("must submit")
      end

      it "returns error when assignment is locked" do
        @user = @student1
        @assignment2.update!(lock_at: 1.day.ago)
        @assignment2.submit_homework(@student1, body: "My submission")

        json = api_call(:post,
                        @resource_path,
                        @resource_params,
                        {},
                        {},
                        { expected_status: 403 })
        expect(json["errors"]["base"]).to include("no longer available")
      end

      it "returns error when assignment has not unlocked" do
        @user = @student1
        @assignment2.update!(unlock_at: 1.day.from_now)
        @assignment2.submit_homework(@student1, body: "My submission")

        json = api_call(:post,
                        @resource_path,
                        @resource_params,
                        {},
                        {},
                        { expected_status: 403 })
        expect(json["errors"]["base"]).to include("locked until")
      end

      it "returns existing ongoing reviews and allocates additional to meet required count" do
        @assignment2.submit_homework(@student1, body: "My submission")
        student3 = student_in_course(active_all: true).user
        student4 = student_in_course(active_all: true).user
        @assignment2.submit_homework(student3, body: "Student3 submission")
        @assignment2.submit_homework(student4, body: "Student4 submission")

        # Create an ongoing review
        existing_request = @assignment2.assign_peer_review(@student1, student3)

        # Set @user AFTER creating student3 to avoid it being overwritten
        @user = @student1

        json = api_call(:post, @resource_path, @resource_params)

        expect(json).to be_an(Array)
        expect(json.size).to eq(2)
        expect(json.pluck("id")).to include(existing_request.id)
        expect(json.pluck("user_id")).to match_array([student3.id, student4.id])
      end

      it "returns error when peer review count limit reached" do
        @assignment2.update!(peer_review_count: 1)
        @assignment2.submit_homework(@student1, body: "My submission")
        student3 = student_in_course(active_all: true).user
        @assignment2.submit_homework(student3, body: "Student3 submission")

        # Create and complete a review
        request = @assignment2.assign_peer_review(@student1, student3)
        request.update!(workflow_state: "completed")

        # Set @user AFTER creating student3
        @user = @student1

        json = api_call(:post,
                        @resource_path,
                        @resource_params,
                        {},
                        {},
                        { expected_status: 403 })
        expect(json["errors"]["base"]).to include("assigned all required")
      end

      it "returns error when no submissions available" do
        @user = @student1
        @assignment2.submit_homework(@student1, body: "My submission")

        json = api_call(:post,
                        @resource_path,
                        @resource_params,
                        {},
                        {},
                        { expected_status: 400 })
        expect(json["errors"]["base"]).to include("no peer reviews available")
      end

      it "prioritizes unreviewed submissions" do
        @assignment2.submit_homework(@student1, body: "My submission")
        @assignment2.submit_homework(@student2, body: "Student2 submission")

        student3 = student_in_course(active_all: true).user
        student4 = student_in_course(active_all: true).user

        # Student3 submits first
        submission3 = @assignment2.submit_homework(student3, body: "Student3 submission")
        submission3.update!(submitted_at: 2.days.ago)

        # Student4 submits later
        submission4 = @assignment2.submit_homework(student4, body: "Student4 submission")
        submission4.update!(submitted_at: 1.day.ago)

        # Student2 reviews student3 (older submission)
        @assignment2.assign_peer_review(@student2, student3)

        # Set @user AFTER creating additional students
        @user = @student1

        # Student1 should get student4 (unreviewed) first, then student2
        json = api_call(:post, @resource_path, @resource_params)
        expect(json).to be_an(Array)
        expect(json.size).to eq(2)
        expect(json.pluck("user_id")).to include(student4.id, @student2.id)
      end

      it "prioritizes older submissions when all have been reviewed" do
        @assignment2.submit_homework(@student1, body: "My submission")

        student3 = student_in_course(active_all: true).user
        student4 = student_in_course(active_all: true).user

        # Create submissions with different times
        submission3 = @assignment2.submit_homework(student3, body: "Student3 submission")
        submission3.update!(submitted_at: 3.days.ago)

        submission4 = @assignment2.submit_homework(student4, body: "Student4 submission")
        submission4.update!(submitted_at: 2.days.ago)

        # All have been reviewed by someone else (student2 doesn't need to submit to be a reviewer)
        @assignment2.assign_peer_review(@student2, student3)
        @assignment2.assign_peer_review(@student2, student4)

        # Set @user AFTER creating additional students
        @user = @student1

        # Should allocate oldest submissions first (student3, then student4)
        json = api_call(:post, @resource_path, @resource_params)
        expect(json).to be_an(Array)
        expect(json.size).to eq(2)
        expect(json.pluck("user_id")).to eq([student3.id, student4.id])
      end

      it "excludes student's own submission" do
        student3 = student_in_course(active_all: true).user
        @user = @student1
        @assignment2.submit_homework(@student1, body: "My submission")
        @assignment2.submit_homework(@student2, body: "Student2 submission")
        @assignment2.submit_homework(student3, body: "Student3 submission")

        json = api_call(:post, @resource_path, @resource_params)

        expect(json).to be_an(Array)
        expect(json.size).to eq(2)
        expect(json.pluck("user_id")).to match_array([@student2.id, student3.id])
        expect(json.none? { |ar| ar["user_id"] == @student1.id }).to be true
      end

      it "handles anonymous peer reviews" do
        student3 = student_in_course(active_all: true).user
        @assignment2.update!(anonymous_peer_reviews: true)
        @user = @student1
        @assignment2.submit_homework(@student1, body: "My submission")
        @assignment2.submit_homework(@student2, body: "Student2 submission")
        @assignment2.submit_homework(student3, body: "Student3 submission")

        json = api_call(:post, @resource_path, @resource_params)

        expect(json).to be_an(Array)
        expect(json.size).to eq(2)
        expect(json.all? { |ar| ar["assessor_id"].nil? }).to be true # Should be hidden for students
        expect(json.pluck("user_id")).to match_array([@student2.id, student3.id])
      end

      context "with assignment overrides" do
        it "allows access when student has adhoc override" do
          @assignment2.update!(only_visible_to_overrides: true)
          @assignment2.submit_homework(@student1, body: "My submission")
          @assignment2.submit_homework(@student2, body: "Student2 submission")
          student3 = student_in_course(active_all: true).user
          @assignment2.submit_homework(student3, body: "Student3 submission")

          # Create adhoc override for student1, student2, and student3 so all can see assignment
          create_adhoc_override_for_assignment(@assignment2, [@student1, @student2, student3])

          @user = @student1

          json = api_call(:post, @resource_path, @resource_params)

          # Verify allocation succeeded
          expect(json).to be_an(Array)
          expect(json.size).to eq(2)
          expect(json.all? { |ar| ar["id"].present? }).to be true
          expect(json.pluck("user_id")).to match_array([@student2.id, student3.id])
          expect(json.all? { |ar| ar["workflow_state"] == "assigned" }).to be true
        end

        it "returns 403 when student has no override and only_visible_to_overrides is true" do
          @assignment2.update!(only_visible_to_overrides: true)
          @assignment2.submit_homework(@student1, body: "My submission")

          # Create override for student2 only
          create_adhoc_override_for_assignment(@assignment2, @student2)

          @user = @student1

          api_call(:post,
                   @resource_path,
                   @resource_params,
                   {},
                   {},
                   { expected_status: 403 })
        end

        it "allows access when student is in section with override" do
          section2 = @course.course_sections.create!(name: "Section 2")
          @student1.enrollments.first.update!(course_section: section2)
          @student2.enrollments.first.update!(course_section: section2)
          student3 = student_in_course(active_all: true).user
          student3.enrollments.first.update!(course_section: section2)

          @assignment2.update!(only_visible_to_overrides: true)
          @assignment2.submit_homework(@student1, body: "My submission")
          @assignment2.submit_homework(@student2, body: "Student2 submission")
          @assignment2.submit_homework(student3, body: "Student3 submission")

          # Create section override for section2 (all students are in it)
          create_section_override_for_assignment(@assignment2, course_section: section2)

          @user = @student1

          json = api_call(:post, @resource_path, @resource_params)

          # Verify allocation succeeded
          expect(json).to be_an(Array)
          expect(json.size).to eq(2)
          expect(json.all? { |ar| ar["id"].present? }).to be true
          expect(json.all? { |ar| ar["workflow_state"] == "assigned" }).to be true
        end

        it "returns 403 when student is not in section with override" do
          section2 = @course.course_sections.create!(name: "Section 2")
          @student2.enrollments.first.update!(course_section: section2)

          @assignment2.update!(only_visible_to_overrides: true)
          @assignment2.submit_homework(@student1, body: "My submission")

          # Create section override for section2 only (student1 is in default section)
          create_section_override_for_assignment(@assignment2, course_section: section2)

          @user = @student1

          api_call(:post,
                   @resource_path,
                   @resource_params,
                   {},
                   {},
                   { expected_status: 403 })
        end

        it "allows access when student is in group with override" do
          group_category = @course.group_categories.create!(name: "Project Groups")
          group1 = @course.groups.create!(name: "Group 1", group_category:)
          group2 = @course.groups.create!(name: "Group 2", group_category:)
          group3 = @course.groups.create!(name: "Group 3", group_category:)
          student3 = student_in_course(active_all: true).user
          group1.add_user(@student1, "accepted")
          group2.add_user(@student2, "accepted")
          group3.add_user(student3, "accepted")

          @assignment2.update!(only_visible_to_overrides: true, grade_group_students_individually: false)
          @assignment2.group_category = group_category
          @assignment2.save!

          @assignment2.submit_homework(@student1, body: "My submission")
          @assignment2.submit_homework(@student2, body: "Student2 submission")
          @assignment2.submit_homework(student3, body: "Student3 submission")

          # Create group overrides for all groups
          create_group_override_for_assignment(@assignment2, group: group1)
          create_group_override_for_assignment(@assignment2, group: group2)
          create_group_override_for_assignment(@assignment2, group: group3)

          @user = @student1

          json = api_call(:post, @resource_path, @resource_params)

          # Verify allocation succeeded
          expect(json).to be_an(Array)
          expect(json.size).to eq(2)
          expect(json.all? { |ar| ar["id"].present? }).to be true
          expect(json.all? { |ar| ar["workflow_state"] == "assigned" }).to be true
        end
      end
    end

    context "with teacher context" do
      it "returns 403 forbidden for teachers" do
        @user = @teacher
        api_call(:post,
                 @resource_path,
                 @resource_params,
                 {},
                 {},
                 { expected_status: 403 })
      end
    end
  end

  describe "Post 'create' with peer_review_sub_assignment linking" do
    before :once do
      @assignment_with_peer_reviews = assignment_model(course: @course, peer_reviews: true)
      @submission_for_pr = @assignment_with_peer_reviews.find_or_create_submission(@student1)
      @reviewer = student_in_course(active_all: true, course: @course).user
      @resource_path = "/api/v1/courses/#{@course.id}/assignments/#{@assignment_with_peer_reviews.id}/submissions/#{@submission_for_pr.id}/peer_reviews"
      @resource_params = { controller: "peer_reviews_api",
                           action: "create",
                           format: "json",
                           course_id: @course.id,
                           assignment_id: @assignment_with_peer_reviews.id,
                           submission_id: @submission_for_pr.id }
    end

    context "when all conditions are met" do
      before :once do
        @course.enable_feature!(:peer_review_allocation_and_grading)
        @peer_review_sub_assignment = PeerReviewSubAssignment.create!(
          title: "Test Peer Review",
          context: @course,
          parent_assignment: @assignment_with_peer_reviews
        )
      end

      it "creates peer review linked to peer_review_sub_assignment" do
        @user = @teacher
        json = api_call(:post, @resource_path, @resource_params, { user_id: @reviewer.id })

        created_request = AssessmentRequest.find(json["id"])
        expect(created_request.peer_review_sub_assignment_id).to eq(@peer_review_sub_assignment.id)
        expect(created_request.peer_review_sub_assignment).to eq(@peer_review_sub_assignment)
      end

      it "returns successfully when all conditions are met" do
        @user = @teacher
        json = api_call(:post, @resource_path, @resource_params, { user_id: @reviewer.id })

        expect(json["workflow_state"]).to eq("assigned")
        expect(json["assessor_id"]).to eq(@reviewer.id)
        expect(json["user_id"]).to eq(@student1.id)
      end
    end

    context "when peer_review_allocation_and_grading feature flag is disabled" do
      before :once do
        @peer_review_sub_assignment = PeerReviewSubAssignment.create!(
          title: "Test Peer Review",
          context: @course,
          parent_assignment: @assignment_with_peer_reviews
        )
      end

      it "creates peer review without linking when feature flag is disabled" do
        @user = @teacher
        json = api_call(:post, @resource_path, @resource_params, { user_id: @reviewer.id })

        expect(json["workflow_state"]).to eq("assigned")
        expect(json["id"]).to be_present

        created_request = AssessmentRequest.find(json["id"])
        expect(created_request.peer_review_sub_assignment_id).to be_nil
      end
    end

    context "when parent assignment does not have peer_reviews enabled" do
      before :once do
        @assignment_with_peer_reviews.update!(peer_reviews: false)
        @course.enable_feature!(:peer_review_allocation_and_grading)
        @peer_review_sub_assignment = PeerReviewSubAssignment.create!(
          title: "Test Peer Review",
          context: @course,
          parent_assignment: @assignment_with_peer_reviews
        )
      end

      it "creates peer review without linking when peer_reviews is false" do
        @user = @teacher
        json = api_call(:post, @resource_path, @resource_params, { user_id: @reviewer.id })

        created_request = AssessmentRequest.find(json["id"])
        expect(created_request.peer_review_sub_assignment_id).to be_nil
      end
    end

    context "when peer_review_sub_assignment does not exist" do
      before :once do
        @course.enable_feature!(:peer_review_allocation_and_grading)
      end

      it "creates peer review without linking when sub-assignment does not exist (graceful degradation)" do
        @user = @teacher
        json = api_call(:post, @resource_path, @resource_params, { user_id: @reviewer.id })

        created_request = AssessmentRequest.find(json["id"])
        expect(created_request).to be_persisted
        expect(created_request.peer_review_sub_assignment_id).to be_nil
      end

      it "does not fail when sub-assignment does not exist" do
        @user = @teacher

        expect do
          api_call(:post, @resource_path, @resource_params, { user_id: @reviewer.id })
        end.not_to raise_error
      end
    end

    context "with multiple conditions" do
      it "does not link when only feature flag is enabled but other conditions are not met" do
        @course.enable_feature!(:peer_review_allocation_and_grading)
        @assignment_with_peer_reviews.update!(peer_reviews: false)

        @user = @teacher
        json = api_call(:post, @resource_path, @resource_params, { user_id: @reviewer.id })

        created_request = AssessmentRequest.find(json["id"])
        expect(created_request.peer_review_sub_assignment_id).to be_nil
      end
    end
  end
end
