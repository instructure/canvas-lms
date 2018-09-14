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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe PeerReviewsApiController, type: :request do

  def rubric_association_params_for_assignment(assign)
    HashWithIndifferentAccess.new({
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
      assessment_type: 'peer_review',
      assessor: assessor_submission.user,
      rubric: @rubric,
      user: submission.user,
      rubric_association: rubric_assoc
    })
    AssessmentRequest.create!(
      rubric_assessment: rubric_assessment,
      user: submission.user,
      asset: submission,
      assessor_asset: assessor_submission,
      assessor: assessor_submission.user)
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
      @resource_params = { controller: 'peer_reviews_api', action: 'destroy', format: 'json', course_id: @course.id,
                           assignment_id: @assignment1.id, submission_id: @submission.id, section_id: @cs.id }
    end

    def delete_peer_review(current_user, resource_path, resource_params)
      student3 = student_in_course(active_all: true).user
      assessment_request = @assignment.assign_peer_review(student3, @student1)
      @user = current_user
      json = api_call(:delete, resource_path, resource_params, {user_id: student3.id})
      expect(AssessmentRequest.where(id: assessment_request.id).count).to eq(0)
      expect(json).to eq({"assessor_id"=>assessment_request.assessor_id,
                          "asset_id"=>assessment_request.asset_id,
                          "asset_type"=>"Submission",
                          "id"=>assessment_request.id,
                          "user_id"=>assessment_request.user_id,
                          "workflow_state"=>"assigned"})
    end

    context 'with admin context' do

      before :once do
        account_admin_user()
      end

      it 'should delete peer review' do
        delete_peer_review(@admin, @resource_path, @resource_params)
      end

      it 'should delete peer review for course section' do
        delete_peer_review(@admin, @section_resource_path, @resource_params)
      end

      it 'should render bad request' do
        student3 = student_in_course(active_all: true).user
        @user = @admin
        api_call(:delete, @resource_path, @resource_params, { user_id: student3.id },
                 {}, {:expected_status => 400})
      end

    end

    context 'with teacher context' do

      it 'should delete peer review' do
        delete_peer_review(@teacher, @resource_path, @resource_params)
      end

    end

    context 'with student context' do

      it "returns 401 unauthorized access" do
        student3 = student_in_course(active_all: true).user
        api_call(:delete, @resource_path, @resource_params, { user_id: student3.id },
                 {}, {:expected_status => 401})
      end

    end

  end

  describe "Post 'create'" do

    before :once do
      @resource_path = "/api/v1/courses/#{@course.id}/assignments/#{@assignment1.id}/submissions/#{@submission.id}/peer_reviews"
      @section_resource_path = "/api/v1/sections/#{@cs.id}/assignments/#{@assignment1.id}/submissions/#{@submission.id}/peer_reviews"
      @resource_params = { controller: 'peer_reviews_api', action: 'create', format: 'json', course_id: @course.id,
                           assignment_id: @assignment1.id, submission_id: @submission.id, section_id: @cs.id }
    end

    def create_peer_review(current_user, resource_path, resource_params)
      student3 = student_in_course(active_all: true).user
      @user = current_user
      json = api_call(:post, resource_path, resource_params, {user_id: student3.id})
      requests = AssessmentRequest.for_assessor(student3.id)
      expect(requests.count).to eq(1)
      expect(json).to eq({"assessor_id"=>student3.id, "asset_id"=>@submission.id, "asset_type"=>"Submission", "id"=>requests.first.id, "user_id"=>@student1.id, "workflow_state"=>"assigned"})
    end

    context 'with admin_context' do

      before :once do
        account_admin_user()
      end

      it 'should create peer review' do
        create_peer_review(@admin, @resource_path, @resource_params)
      end

      it 'should create peer review for course section' do
        create_peer_review(@admin, @section_resource_path, @resource_params)
      end

      it 'should not create peer review where the reviewer and student are same' do
        api_call(:post, @resource_path, @resource_params, {user_id: @student1.id}, {}, {:expected_status => 400})
      end

    end

    context 'with teacher context' do

      it 'should create peer review' do
        create_peer_review(@teacher, @resource_path, @resource_params)
      end

    end

    context 'with student context' do

      it "returns 401 unauthorized access" do
        student3 = student_in_course(active_all: true).user
        api_call(:post, @resource_path, @resource_params, { user_id: student3.id },
                 {}, {:expected_status => 401})
      end

    end

  end

  describe "Get 'index'" do

    before :once do
      @resource_path = "/api/v1/courses/#{@course.id}/assignments/#{@assignment1.id}/peer_reviews"
      @section_resource_path = "/api/v1/sections/#{@cs.id}/assignments/#{@assignment1.id}/peer_reviews"
      @submission_resource_path = "/api/v1/courses/#{@course.id}/assignments/#{@assignment1.id}/submissions/#{@submission.id}/peer_reviews"
      @submission_section_resource_path = "/api/v1/sections/#{@cs.id}/assignments/#{@assignment1.id}/submissions/#{@submission.id}/peer_reviews"
      @resource_params = { controller: 'peer_reviews_api', action: 'index', format: 'json', course_id: @course.id,
                           assignment_id: @assignment1.id, section_id: @cs.id }
      @submission_resource_params = { controller: 'peer_reviews_api', action: 'index', format: 'json',
                                      course_id: @course.id, assignment_id: @assignment1.id,
                                      submission_id: @submission.id, section_id: @cs.id }

      @assessment_with_user = {"assessor" => {"id"=>@student2.id,
                                              "display_name"=>"User",
                                              "avatar_image_url"=>"http://www.example.com/images/messages/avatar-50.png",
                                              "html_url"=>"http://www.example.com/courses/#{@course.id}/users/#{@student2.id}"},
                               "assessor_id"=>@student2.id,
                               "asset_id"=>@submission.id,
                               "asset_type"=>"Submission",
                               "id"=>@assessment_request.id,
                               "user" => {"id"=>@student1.id,
                                          "display_name"=>"User",
                                          "avatar_image_url"=>"http://www.example.com/images/messages/avatar-50.png",
                                          "html_url"=>"http://www.example.com/courses/#{@course.id}/users/#{@student1.id}"},
                               "user_id"=>@student1.id,
                               "workflow_state"=>@assessment_request.workflow_state}
    end

    def list_peer_review(current_user, resource_path, resource_params)
      @user = current_user
      json = api_call(:get, resource_path, resource_params)
      expect(json.count).to eq(1)
      expect(json[0]).to eq({"assessor_id"=>@student2.id,
                             "asset_id"=>@submission.id,
                             "asset_type"=>"Submission",
                             "id"=>@assessment_request.id,
                             "user_id"=>@student1.id,
                             "workflow_state"=>@assessment_request.workflow_state})

    end

    def assessment_with_comments(comment)
      {
        "assessor_id" => @student2.id,
        "asset_id" => @submission.id,
        "asset_type" => "Submission",
        "id" => @assessment_request.id,
        "submission_comments" => [
          {
            "author_id" => @student2.id,
            "author_name" => @student2.name,
            "comment" => comment.comment,
            "created_at" => comment.created_at.as_json,
            "edited_at" => nil,
            "id" => comment.id,
            "author" => {
              "id" => @student2.id,
              "display_name" => @student2.name,
              "avatar_image_url" => "http://www.example.com/images/messages/avatar-50.png",
              "html_url" => "http://www.example.com/courses/#{@course.id}/users/#{@student2.id}"
            }
          }
        ],
        "user_id" => @student1.id,
        "workflow_state" => @assessment_request.workflow_state
      }
    end

    context 'with admin_context' do

      before :once do
        account_admin_user()
      end

      it 'should return all peer reviews' do
        list_peer_review(@admin, @resource_path, @resource_params)
      end

      it 'should return all peer reviews in a section' do
        list_peer_review(@admin, @section_resource_path, @resource_params)
      end

      it 'should return all peer reviews when anonymous peer reviews enabled' do
        @assignment1.update_attribute(:anonymous_peer_reviews, true)
        list_peer_review(@admin, @resource_path, @resource_params)
      end

      it 'should include user information' do
        json = api_call(:get, @resource_path, @resource_params, { :include => %w(user) })
        expect(json.count).to eq(1)
        expect(json[0]).to eq(@assessment_with_user)
      end

      it 'should include submission comments' do
        @comment = @submission.add_comment(:author => @student2, :comment => "student2 comment")
        json = api_call(:get, @resource_path, @resource_params, { :include => %w(submission_comments) })
        expect(json.count).to eq(1)
        expect(json[0]).to eq(assessment_with_comments(@comment))
      end

      it 'should return peer reviews for a specific submission' do
        submission2 = @assignment1.find_or_create_submission(@student2)
        assessment_request(submission2, @teacher, @submission)
        list_peer_review(@admin, @submission_resource_path, @submission_resource_params)
      end

      it 'should return peer reviews for a specific submission in a section' do
        submission2 = @assignment1.find_or_create_submission(@student2)
        assessment_request(submission2, @teacher, @submission)
        list_peer_review(@admin, @submission_section_resource_path, @submission_resource_params)
      end

    end

    context 'with teacher_context' do

      it 'should return all peer reviews' do
        list_peer_review(@teacher, @resource_path, @resource_params)
      end

      it 'should return all peer reviews when anonymous peer reviews enabled' do
        @assignment1.update_attribute(:anonymous_peer_reviews, true)
        list_peer_review(@teacher, @resource_path, @resource_params)
      end

      it 'should include user information' do
        @user = @teacher
        json = api_call(:get, @resource_path, @resource_params, { :include => %w(user) })
        expect(json.count).to eq(1)
        expect(json[0]).to eq(@assessment_with_user)
      end

      it 'should include submission comments' do
        @user = @teacher
        @comment = @submission.add_comment(:author => @student2, :comment => "student2 comment")
        json = api_call(:get, @resource_path, @resource_params, { :include => %w(submission_comments) })
        expect(json.count).to eq(1)
        expect(json[0]).to eq(assessment_with_comments(@comment))
      end

      it 'should return peer reviews for a specific submission' do
        submission2 = @assignment1.find_or_create_submission(@student2)
        assessment_request(submission2, @teacher, @submission)
        list_peer_review(@teacher, @submission_resource_path, @submission_resource_params)
      end


    end

    context 'with student_context' do

      it 'should return peer reviews for user' do
        list_peer_review(@student1, @resource_path, @resource_params)
      end

      it 'should not return assessor if anonymous peer reviews enabled' do
        @user = @student1
        @assignment1.update_attribute(:anonymous_peer_reviews, true)
        json = api_call(:get, @resource_path, @resource_params)
        expect(json.count).to eq(1)
        expect(json[0]).to eq({"asset_id"=>@submission.id,
                               "asset_type"=>"Submission",
                               "id"=>@assessment_request.id,
                               "user_id"=>@student1.id,
                               "workflow_state"=>@assessment_request.workflow_state})

      end

      it 'should not return peer reviews for assessor' do
        @user = @student2
        json = api_call(:get, @resource_path, @resource_params)
        expect(json.count).to eq(0)
      end

      it 'should include user information' do
        @assignment1.update_attribute(:anonymous_peer_reviews, false)
        @user = @student1
        json = api_call(:get, @resource_path, @resource_params, { :include => %w(user) })
        expect(json.count).to eq(1)
        expect(json[0]).to eq(@assessment_with_user)
      end

      it 'should not include assessor information when peer reviews are enabled' do
        @assignment1.update_attribute(:anonymous_peer_reviews, true)
        @user = @student1
        json = api_call(:get, @resource_path, @resource_params, { :include => %w(user) })
        expect(json.count).to eq(1)
        expect(json[0]).to eq({"asset_id"=>@submission.id,
                               "asset_type"=>"Submission",
                               "id"=>@assessment_request.id,
                               "user" => {"id"=>@student1.id,
                                          "display_name"=>"User",
                                          "avatar_image_url"=>"http://www.example.com/images/messages/avatar-50.png",
                                          "html_url"=>"http://www.example.com/courses/#{@course.id}/users/#{@student1.id}"},
                               "user_id"=>@student1.id,
                               "workflow_state"=>@assessment_request.workflow_state})
      end

      it 'should include submission comments' do
        @assignment1.update_attribute(:anonymous_peer_reviews, false)
        @comment = @submission.add_comment(:author => @student2, :comment => "student2 comment")
        @user = @student1
        json = api_call(:get, @resource_path, @resource_params, { :include => %w(submission_comments) })
        expect(json.count).to eq(1)
        expect(json[0]).to eq(assessment_with_comments(@comment))
      end


      it 'should not include submission comments user information when anonymous peer reviews' do
        @course.root_account.tap{|a| a.enable_service(:avatars)}.save!
        @assignment1.update_attribute(:anonymous_peer_reviews, true)
        @comment = @submission.add_comment(:author => @student2, :comment => "review comment")
        @user = @student1
        json = api_call(:get, @resource_path, @resource_params, { :include => %w(submission_comments) })
        expect(json.count).to eq(1)
        expect(json[0]).to eq(
          {
            "asset_id"=>@submission.id,
            "asset_type"=>"Submission",
            "id"=>@assessment_request.id,
            "submission_comments" => [
              {
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
            "user_id"=>@student1.id,
            "workflow_state"=>@assessment_request.workflow_state
          }
        )
      end

      it 'should return peer reviews for a specific submission' do
        @user = @student1
        submission2 = @assignment1.find_or_create_submission(@student2)
        assessment_request(submission2, @teacher, @submission)
        json = api_call(:get, @submission_resource_path, @submission_resource_params)
        expect(json.count).to eq(1)
        expect(json[0]).to eq({"assessor_id"=>@student2.id,
                               "asset_id"=>@submission.id,
                               "asset_type"=>"Submission",
                               "id"=>@assessment_request.id,
                               "user_id"=>@student1.id,
                               "workflow_state"=>@assessment_request.workflow_state})
      end

      it 'should return no peer reviews for invalid submission' do
        @assignment2 = assignment_model(course: @course)
        @submission_resource_path = "/api/v1/courses/#{@course.id}/assignments/#{@assignment2.id}/submissions/#{@submission.id}/peer_reviews"
        @submission_resource_params = { controller: 'peer_reviews_api', action: 'index', format: 'json',
                                        course_id: @course.id, assignment_id: @assignment2.id,
                                        submission_id: @submission.id, section_id: @cs.id }
        json = api_call(:get, @submission_resource_path, @submission_resource_params)
        expect(json.count).to eq(0)
      end

    end
  end
end
