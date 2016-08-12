#
# Copyright (C) 2016 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../sharding_spec_helper')

describe "Rubrics API", type: :request do
  include Api::V1::Rubric

  ALLOWED_RUBRIC_FIELDS = Api::V1::Rubric::API_ALLOWED_RUBRIC_OUTPUT_FIELDS[:only]

  before :once do
    @account = Account.default
  end

  def create_rubric(context, opts={})
    @rubric = Rubric.new(:context => context)
    @rubric.data = [rubric_data_hash(opts)]
    @rubric.save!
  end

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

  def create_rubric_assessment(opts={})
    assessment_type = opts[:type] || "grading"
    assignment1 = assignment_model(context: @course)
    submission = assignment1.find_or_create_submission(@student)
    ra_params = rubric_association_params_for_assignment(submission.assignment)
    rubric_assoc = RubricAssociation.generate(@teacher, @rubric, @course, ra_params)
    rubric_assessment = RubricAssessment.create!({
      artifact: submission,
      assessment_type: assessment_type,
      assessor: @teacher,
      rubric: @rubric,
      user: submission.user,
      rubric_association: rubric_assoc,
      data: [{points: 3.0, description: "hello", comments: opts[:comments]}]
    })
  end

  def rubric_data_hash(opts={})
    hash = {
      points: 3,
      description: "Criteria row",
      id: 1,
      ratings: [
        {
          points: 3,
          description: "Rockin'",
          criterion_id: 1,
          id: 2
        },
        {
          points: 0,
          description: "Lame",
          criterion_id: 2,
          id: 3
        }
      ]
    }.merge(opts)
    hash
  end

  def rubrics_api_call
    api_call(
      :get, "/api/v1/courses/#{@course.id}/rubrics",
      controller: 'rubrics_api',
      action: 'index',
      course_id: @course.id.to_s,
      format: 'json'
    )
  end

  def rubric_api_call(params={})
    api_call(
      :get, "/api/v1/courses/#{@course.id}/rubrics/#{@rubric.id}",
      controller: 'rubrics_api',
      action: 'show',
      course_id: @course.id.to_s,
      id: @rubric.id.to_s,
      format: 'json',
      include: params[:include],
      style: params[:style]
    )
  end

  def raw_rubric_call(params={})
    raw_api_call(:get, "/api/v1/courses/#{@course.id}/rubrics/#{@rubric.id}",
      { controller: 'rubrics_api',
        action: 'show',
        format: 'json',
        course_id: @course.id.to_s,
        id: @rubric.id.to_s,
        include: params[:include],
        style: params[:style]
      }
    )
  end

  describe "index action" do
    before :once do
      course_with_teacher active_all: true
      create_rubric(@course)
    end

    it "returns an array of all rubrics in an account" do
      create_rubric(@account)
      response = rubrics_api_call
      expect(response[0].keys.sort).to eq ALLOWED_RUBRIC_FIELDS.sort
      expect(response.length).to eq 1
    end

    it "returns an array of all rubrics in a course" do
      create_rubric(@course)
      response = rubrics_api_call
      expect(response[0].keys.sort).to eq ALLOWED_RUBRIC_FIELDS.sort
      expect(response.length).to eq 2
    end

    it "requires the user to have permission to manage rubrics" do
      @user = @student
      raw_rubric_call

      assert_status(401)
    end

  end

  describe "show action" do
    before :once do
      course_with_teacher active_all: true
      create_rubric(@course)
    end

    it "returns a rubric" do
      response = rubric_api_call
      expect(response.keys.sort).to eq ALLOWED_RUBRIC_FIELDS.sort
    end

    it "requires the user to have permission to manage rubrics" do
      @user = @student
      raw_rubric_call

      assert_status(401)
    end


    context "include parameter" do
      before :once do
        course_with_student(user: @user, active_all: true)
        course_with_teacher active_all: true
        create_rubric(@course)
        ['grading', 'peer_review'].each.with_index do |type, index|
          create_rubric_assessment({type: type, comments: "comment #{index}"})
        end
      end

      it "does not returns rubric assessments by default" do
        response = rubric_api_call
        expect(response).not_to have_key "assessmensdts"
      end

      it "returns rubric assessments when passed 'assessessments'" do
        response = rubric_api_call({include: "assessments"})
        expect(response).to have_key "assessments"
        expect(response["assessments"].length).to eq 2
      end

      it "returns any rubric assessments used for grading when passed 'graded_assessessments'" do
        response = rubric_api_call({include: "graded_assessments"})
        expect(response["assessments"][0]["assessment_type"]).to eq "grading"
        expect(response["assessments"].length).to eq 1
      end

      it "returns any peer review assessments when passed 'peer_assessessments'" do
        response = rubric_api_call({include: "peer_assessments"})
        expect(response["assessments"][0]["assessment_type"]).to eq "peer_review"
        expect(response["assessments"].length).to eq 1
      end

      it "returns an error if passed an invalid argument" do
        raw_rubric_call({include: "cheez"})

        expect(response).not_to be_success
        json = JSON.parse response.body
        expect(json["errors"]["include"].first["message"]).to eq "invalid assessment type requested. Must be one of the following: assessments, graded_assessments, peer_assessments"
      end

      context "style argument" do
        it "returns all data when passed 'full'" do
          response = rubric_api_call({include: "assessments", style: "full"})
          expect(response["assessments"][0]).to have_key 'data'
        end

        it "returns only comments when passed 'comments_only'" do
          response = rubric_api_call({include: "assessments", style: "comments_only"})
          expect(response["assessments"][0]).to have_key 'comments'
        end

        it "returns an error if passed an invalid argument" do
          raw_rubric_call({include: "assessments", style: "BigMcLargeHuge"})

          expect(response).not_to be_success
          json = JSON.parse response.body
          expect(json["errors"]["style"].first["message"]).to eq "invalid style requested. Must be one of the following: full, comments_only"
        end

        it "returns an error if passed a style parameter without assessments" do
          raw_rubric_call({style: "full"})

          expect(response).not_to be_success
          json = JSON.parse response.body
          expect(json["errors"]["style"].first["message"]).to eq "invalid parameters. Style parameter passed without requesting assessments"
        end
      end
    end
  end
end