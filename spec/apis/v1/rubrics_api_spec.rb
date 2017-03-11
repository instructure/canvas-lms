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

  def rubrics_api_call(context, params={}, type='course')
    api_call(
      :get, "/api/v1/#{type}s/#{context.id}/rubrics", {
        controller: 'rubrics_api',
        action: 'index',
        format: 'json',
        "#{type}_id": context.id.to_s
      }.merge(params)
    )
  end

  def rubric_api_call(context, params={}, type='course')
    api_call(
      :get, "/api/v1/#{type}s/#{context.id}/rubrics/#{@rubric.id}", {
        controller: 'rubrics_api',
        action: 'show',
        id: @rubric.id.to_s,
        format: 'json',
        "#{type}_id": context.id.to_s
      }.merge(params)
    )
  end

  def raw_rubric_call(context, params={}, type='course')
    raw_api_call(
      :get, "/api/v1/#{type}s/#{context.id}/rubrics/#{@rubric.id}", {
        controller: 'rubrics_api',
        action: 'show',
        format: 'json',
        id: @rubric.id.to_s,
        "#{type}_id": context.id.to_s
      }.merge(params)
    )
  end

  def paginate_call(context, type)
    @user = account_admin_user
    7.times { create_rubric(context) }
    json = rubrics_api_call(context, {:per_page => '3'}, type)

    expect(json.length).to eq 3
    links = response.headers['Link'].split(",")
    expect(links.all?{ |l| l =~ /api\/v1\/#{type}s\/#{context.id}\/rubrics/ }).to be_truthy
    expect(links.find{ |l| l.match(/rel="next"/)}).to match /page=2/
    expect(links.find{ |l| l.match(/rel="first"/)}).to match /page=1/
    expect(links.find{ |l| l.match(/rel="last"/)}).to match /page=3/

    # get the last page
    json = rubrics_api_call(context, {:per_page => '3', :page => '3'}, type)

    expect(json.length).to eq 2
    links = response.headers['Link'].split(",")
    expect(links.all?{ |l| l =~ /api\/v1\/#{type}s\/#{context.id}\/rubrics/ }).to be_truthy
    expect(links.find{ |l| l.match(/rel="prev"/)}).to match /page=2/
    expect(links.find{ |l| l.match(/rel="first"/)}).to match /page=1/
    expect(links.find{ |l| l.match(/rel="last"/)}).to match /page=3/
  end

  describe "in a course" do
    describe "index action" do
      before :once do
        course_with_teacher active_all: true
        create_rubric(@course)
      end

      it "returns an array of all rubrics in a course" do
        create_rubric(@course)
        response = rubrics_api_call(@course)
        expect(response[0].keys.sort).to eq ALLOWED_RUBRIC_FIELDS.sort
        expect(response.length).to eq 2
      end

      it "requires the user to have permission to manage rubrics" do
        @user = @student
        raw_rubric_call(@course)

        assert_status(401)
      end

      it "should paginate" do
        paginate_call(@course, 'course')
      end
    end

    describe "show action" do
      before :once do
        course_with_teacher active_all: true
        create_rubric(@course)
      end

      it "returns a rubric" do
        response = rubric_api_call(@course)
        expect(response.keys.sort).to eq ALLOWED_RUBRIC_FIELDS.sort
      end

      it "requires the user to have permission to manage rubrics" do
        @user = @student
        raw_rubric_call(@course)

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

        it "does not return rubric assessments by default" do
          response = rubric_api_call(@course)
          expect(response).not_to have_key "assessments"
        end

        it "returns rubric assessments when passed 'assessments'" do
          response = rubric_api_call(@course, {include: "assessments"})
          expect(response).to have_key "assessments"
          expect(response["assessments"].length).to eq 2
        end

        it "returns any rubric assessments used for grading when passed 'graded_assessments'" do
          response = rubric_api_call(@course, {include: "graded_assessments"})
          expect(response["assessments"][0]["assessment_type"]).to eq "grading"
          expect(response["assessments"].length).to eq 1
        end

        it "returns any peer review assessments when passed 'peer_assessments'" do
          response = rubric_api_call(@course, {include: "peer_assessments"})
          expect(response["assessments"][0]["assessment_type"]).to eq "peer_review"
          expect(response["assessments"].length).to eq 1
        end

        it "returns an error if passed an invalid argument" do
          raw_rubric_call(@course, {include: "cheez"})

          expect(response).not_to be_success
          json = JSON.parse response.body
          expect(json["errors"]["include"].first["message"]).to eq "invalid assessment type requested. Must be one of the following: assessments, graded_assessments, peer_assessments"
        end

        context "style argument" do
          it "returns all data when passed 'full'" do
            response = rubric_api_call(@course, {include: "assessments", style: "full"})
            expect(response["assessments"][0]).to have_key 'data'
          end

          it "returns only comments when passed 'comments_only'" do
            response = rubric_api_call(@course, {include: "assessments", style: "comments_only"})
            expect(response["assessments"][0]).to have_key 'comments'
          end

          it "returns an error if passed an invalid argument" do
            raw_rubric_call(@course, {include: "assessments", style: "BigMcLargeHuge"})

            expect(response).not_to be_success
            json = JSON.parse response.body
            expect(json["errors"]["style"].first["message"]).to eq "invalid style requested. Must be one of the following: full, comments_only"
          end

          it "returns an error if passed a style parameter without assessments" do
            raw_rubric_call(@course, {style: "full"})

            expect(response).not_to be_success
            json = JSON.parse response.body
            expect(json["errors"]["style"].first["message"]).to eq "invalid parameters. Style parameter passed without requesting assessments"
          end
        end
      end
    end
  end

  describe "in an account" do
    describe "index action" do
      before :once do
        @user = account_admin_user
        create_rubric(@account)
      end

      it "requires the user to have permission to manage rubrics" do
        @user = @student
        raw_rubric_call(@account, {}, 'account')

        assert_status(401)
      end

      it "should paginate" do
        paginate_call(@account, 'account')
      end

      it "returns an array of all rubrics in an account" do
        create_rubric(@account)
        response = rubrics_api_call(@account, {}, 'account')
        expect(response[0].keys.sort).to eq ALLOWED_RUBRIC_FIELDS.sort
        expect(response.length).to eq 2
      end
    end

    describe "show action" do
      before :once do
        @user = account_admin_user
        create_rubric(@account)
      end

      it "returns a rubric" do
        response = rubric_api_call(@account, {}, 'account')
        expect(response.keys.sort).to eq ALLOWED_RUBRIC_FIELDS.sort
      end

      it "requires the user to have permission to manage rubrics" do
        @user = @student
        raw_rubric_call(@account, {}, 'account')

        assert_status(401)
      end

      context "include parameter" do
        before :once do
          course_with_student(user: @user, active_all: true)
          course_with_teacher active_all: true
          create_rubric(@account)
          ['grading', 'peer_review'].each.with_index do |type, index|
            create_rubric_assessment({type: type, comments: "comment #{index}"})
          end
          @user = account_admin_user
        end

        it "does not return rubric assessments by default" do
          response = rubric_api_call(@account, {}, 'account')
          expect(response).not_to have_key "assessments"
        end

        it "returns rubric assessments when passed 'assessments'" do
          response = rubric_api_call(@account, {include: "assessments"}, 'account')
          expect(response).to have_key "assessments"
          expect(response["assessments"].length).to eq 2
        end

        it "returns any rubric assessments used for grading when passed 'graded_assessments'" do
          response = rubric_api_call(@account, {include: "graded_assessments"}, 'account')
          expect(response["assessments"][0]["assessment_type"]).to eq "grading"
          expect(response["assessments"].length).to eq 1
        end

        it "returns any peer review assessments when passed 'peer_assessments'" do
          response = rubric_api_call(@account, {include: "peer_assessments"}, 'account')
          expect(response["assessments"][0]["assessment_type"]).to eq "peer_review"
          expect(response["assessments"].length).to eq 1
        end

        it "returns an error if passed an invalid argument" do
          raw_rubric_call(@account, {include: "cheez"}, 'account')

          expect(response).not_to be_success
          json = JSON.parse response.body
          expect(json["errors"]["include"].first["message"]).to eq "invalid assessment type requested. Must be one of the following: assessments, graded_assessments, peer_assessments"
        end

        context "style argument" do
          before :once do
            @user = account_admin_user
          end

          it "returns all data when passed 'full'" do
            response = rubric_api_call(@account, {include: "assessments", style: "full"}, 'account')
            expect(response["assessments"][0]).to have_key 'data'
          end

          it "returns only comments when passed 'comments_only'" do
            response = rubric_api_call(@account, {include: "assessments", style: "comments_only"}, 'account')
            expect(response["assessments"][0]).to have_key 'comments'
          end

          it "returns an error if passed an invalid argument" do
            raw_rubric_call(@account, {include: "assessments", style: "BigMcLargeHuge"}, 'account')

            expect(response).not_to be_success
            json = JSON.parse response.body
            expect(json["errors"]["style"].first["message"]).to eq "invalid style requested. Must be one of the following: full, comments_only"
          end

          it "returns an error if passed a style parameter without assessments" do
            raw_rubric_call(@account, {style: "full"}, 'account')

            expect(response).not_to be_success
            json = JSON.parse response.body
            expect(json["errors"]["style"].first["message"]).to eq "invalid parameters. Style parameter passed without requesting assessments"
          end
        end
      end
    end
  end
end
