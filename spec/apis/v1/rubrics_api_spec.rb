# frozen_string_literal: true

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

require_relative "../api_spec_helper"

describe "Rubrics API", type: :request do
  include Api::V1::Rubric

  let(:allowed_rubric_fields) { Api::V1::Rubric::API_ALLOWED_RUBRIC_OUTPUT_FIELDS[:only] }

  before :once do
    @account = Account.default
  end

  def create_rubric(context, opts = {})
    @rubric = Rubric.new(context:)
    @rubric.data = [rubric_data_hash(opts)]
    @rubric.save!
    @rubric.update_with_association(nil, {}, context, { association_object: context })
  end

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

  def create_rubric_assessment(opts = {})
    assessment_type = opts[:type] || "grading"
    assignment1 = assignment_model(context: @course)
    submission = assignment1.find_or_create_submission(@student)
    ra_params = rubric_association_params_for_assignment(submission.assignment)
    rubric_assoc = RubricAssociation.generate(@teacher, @rubric, @course, ra_params)
    RubricAssessment.create!({
                               artifact: submission,
                               assessment_type:,
                               assessor: @teacher,
                               rubric: @rubric,
                               user: submission.user,
                               rubric_association: rubric_assoc,
                               data: [{ points: 3.0, description: "hello", comments: opts[:comments] }]
                             })
  end

  def rubric_data_hash(opts = {})
    {
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
  end

  def rubrics_api_call(context, params = {}, type = "course")
    api_call(
      :get, "/api/v1/#{type}s/#{context.id}/rubrics", {
        controller: "rubrics_api",
        action: "index",
        format: "json",
        "#{type}_id": context.id.to_s
      }.merge(params)
    )
  end

  def rubric_api_call(context, params = {}, type = "course")
    api_call(
      :get, "/api/v1/#{type}s/#{context.id}/rubrics/#{@rubric.id}", {
        controller: "rubrics_api",
        action: "show",
        id: @rubric.id.to_s,
        format: "json",
        "#{type}_id": context.id.to_s
      }.merge(params)
    )
  end

  def create_rubric_api_call(context, params = {}, type = "course")
    api_call(
      :post, "/api/v1/#{type}s/#{context.id}/rubrics", {
        controller: "rubrics",
        action: "create",
        format: "json",
        "#{type}_id": context.id.to_s
      }.merge(params)
    )
  end

  def update_rubric_api_call(context, params = {}, type = "course")
    api_call(
      :put, "/api/v1/#{type}s/#{context.id}/rubrics/#{@rubric.id}", {
        controller: "rubrics",
        action: "update",
        id: @rubric.id.to_s,
        format: "json",
        "#{type}_id": context.id.to_s
      }.merge(params)
    )
  end

  def raw_rubric_call(context, params = {}, type = "course")
    raw_api_call(
      :get, "/api/v1/#{type}s/#{context.id}/rubrics/#{@rubric.id}", {
        controller: "rubrics_api",
        action: "show",
        format: "json",
        id: @rubric.id.to_s,
        "#{type}_id": context.id.to_s
      }.merge(params)
    )
  end

  def paginate_call(context, type)
    @user = account_admin_user
    7.times { create_rubric(context) }
    json = rubrics_api_call(context, { per_page: "3" }, type)

    expect(json.length).to eq 3
    links = response.headers["Link"].split(",")
    expect(links.all? { |l| l =~ %r{api/v1/#{type}s/#{context.id}/rubrics} }).to be_truthy
    expect(links.find { |l| l.include?('rel="next"') }).to match(/page=2/)
    expect(links.find { |l| l.include?('rel="first"') }).to match(/page=1/)
    expect(links.find { |l| l.include?('rel="last"') }).to match(/page=3/)

    # get the last page
    json = rubrics_api_call(context, { per_page: "3", page: "3" }, type)

    expect(json.length).to eq 2
    links = response.headers["Link"].split(",")
    expect(links.all? { |l| l =~ %r{api/v1/#{type}s/#{context.id}/rubrics} }).to be_truthy
    expect(links.find { |l| l.include?('rel="prev"') }).to match(/page=2/)
    expect(links.find { |l| l.include?('rel="first"') }).to match(/page=1/)
    expect(links.find { |l| l.include?('rel="last"') }).to match(/page=3/)
  end

  describe "course level rubrics" do
    describe "index action" do
      before :once do
        course_with_teacher active_all: true
        create_rubric(@course)
      end

      it "returns an array of all rubrics in a course" do
        create_rubric(@course)
        response = rubrics_api_call(@course)
        expect(response[0].keys.sort).to eq allowed_rubric_fields.sort
        expect(response.length).to eq 2
      end

      it "requires the user to have permission to manage rubrics" do
        @user = @student
        raw_rubric_call(@course)

        assert_status(401)
      end

      it "paginates" do
        paginate_call(@course, "course")
      end
    end

    describe "show action" do
      before :once do
        course_with_teacher active_all: true
        create_rubric(@course)
      end

      it "returns a rubric" do
        response = rubric_api_call(@course)
        expect(response.keys.sort).to eq allowed_rubric_fields.sort
      end

      it "returns not found status if the rubric is soft deleted" do
        @rubric.destroy!
        rubric_api_call(@course)

        assert_status(404)
      end

      it "requires the user to have permission to manage rubrics" do
        @user = @student
        raw_rubric_call(@course)

        assert_status(401)
      end

      it "returns unauthorized status if teacher is not in the course" do
        teacher_in_other_course = @teacher
        course_with_teacher(active_all: true)
        create_rubric(@course)
        @user = teacher_in_other_course
        raw_rubric_call(@course)
        assert_status(401)
      end

      it "returns not found status if rubric belongs to a course other than the one requested for" do
        # Enroll the same teacher in 2 courses.
        course1 = course_with_teacher(active_all: true).course
        course2 = course_with_teacher(active_all: true, user: @teacher).course
        create_rubric(course1)
        # @rubric has an association with course1; now request it but scoped to
        # course2.
        raw_rubric_call(course2)
        assert_status(404)
      end

      it "always return rubrics for admins" do
        course_with_teacher(active_all: true)
        create_rubric(@course)
        @user = account_admin_user
        raw_rubric_call(@course)
        assert_status(200)
      end

      context "include parameter" do
        before :once do
          course_with_student(user: @user, active_all: true)
          course_with_teacher active_all: true
          create_rubric(@course)
          RubricAssociation.generate(@teacher, @rubric, @course, association_object: @account)
          ["grading", "peer_review"].each.with_index do |type, index|
            create_rubric_assessment({ type:, comments: "comment #{index}" })
          end
        end

        it "does not return rubric assessments by default" do
          response = rubric_api_call(@course)
          expect(response).not_to have_key "assessments"
        end

        it "returns rubric assessments when passed 'assessments'" do
          response = rubric_api_call(@course, { include: "assessments" })
          expect(response).to have_key "assessments"
          expect(response["assessments"].length).to eq 2
        end

        it "returns any rubric assessments used for grading when passed 'graded_assessments'" do
          response = rubric_api_call(@course, { include: "graded_assessments" })
          expect(response["assessments"][0]["assessment_type"]).to eq "grading"
          expect(response["assessments"].length).to eq 1
        end

        it "returns any peer review assessments when passed 'peer_assessments'" do
          response = rubric_api_call(@course, { include: "peer_assessments" })
          expect(response["assessments"][0]["assessment_type"]).to eq "peer_review"
          expect(response["assessments"].length).to eq 1
        end

        it "does not return rubric associations by default" do
          response = rubric_api_call(@course)
          expect(response).not_to have_key "associations"
        end

        it "returns rubric associations when passed 'associations'" do
          response = rubric_api_call(@course, { include: "associations" })
          expect(response).to have_key "associations"
          expect(response["associations"].length).to eq 4
        end

        it "returns any course associations used for grading when passed 'course_associations'" do
          response = rubric_api_call(@course, { include: "course_associations" })
          expect(response["associations"][0]["association_type"]).to eq "Course"
          expect(response["associations"].length).to eq 1
        end

        it "returns any account associations when passed 'account_associations'" do
          response = rubric_api_call(@course, { include: "account_associations" })
          expect(response["associations"][0]["association_type"]).to eq "Account"
          expect(response["associations"].length).to eq 1
        end

        it "returns assignment associations when passed 'assignment_associations'" do
          response = rubric_api_call(@course, { include: "assignment_associations" })
          expect(response["associations"][0]["association_type"]).to eq "Assignment"
          expect(response["associations"].length).to eq 2
        end

        it "returns an error if passed an invalid argument" do
          raw_rubric_call(@course, { include: "cheez" })

          expect(response).not_to be_successful
          json = JSON.parse response.body
          expect(json["errors"]["include"].first["message"]).to start_with "invalid include value requested. Must be one of the following:"
        end

        it "returns an error if passed mutually-exclusive include options" do
          raw_rubric_call(@course, { include: ["assessments", "peer_assessments"] })

          expect(response).not_to be_successful
          json = JSON.parse response.body
          expect(json["errors"]["include"].first["message"]).to start_with "cannot list multiple assessment includes."

          raw_rubric_call(@course, { include: ["associations", "assignment_associations"] })

          expect(response).not_to be_successful
          json = JSON.parse response.body
          expect(json["errors"]["include"].first["message"]).to start_with "cannot list multiple association includes."
        end

        context "style argument" do
          it "returns all data when passed 'full'" do
            response = rubric_api_call(@course, { include: "assessments", style: "full" })
            expect(response["assessments"][0]).to have_key "data"
          end

          it "returns only comments when passed 'comments_only'" do
            response = rubric_api_call(@course, { include: "assessments", style: "comments_only" })
            expect(response["assessments"][0]).to have_key "comments"
          end

          it "returns an error if passed an invalid argument" do
            raw_rubric_call(@course, { include: "assessments", style: "BigMcLargeHuge" })

            expect(response).not_to be_successful
            json = JSON.parse response.body
            expect(json["errors"]["style"].first["message"]).to eq "invalid style requested. Must be one of the following: full, comments_only"
          end

          it "returns an error if passed a style parameter without assessments" do
            raw_rubric_call(@course, { style: "full" })

            expect(response).not_to be_successful
            json = JSON.parse response.body
            expect(json["errors"]["style"].first["message"]).to eq "invalid parameters. Style parameter passed without requesting assessments"
          end
        end
      end
    end

    describe "create action" do
      before :once do
        course_with_teacher active_all: true
      end

      it "creates a rubric" do
        response = create_rubric_api_call(@course)
        expect(response["rubric"]["user_id"]).to eq @user.id
        expect(response["rubric_association"]).to be_nil
      end

      it "creats a rubric with an association" do
        assignment = @course.assignments.create
        response = create_rubric_api_call(@course, { rubric: { title: "new title" }, rubric_association: { association_id: assignment.id, association_type: "Assignment" } })
        expect(response["rubric_association"]["association_id"]).to eq assignment.id
      end
    end

    describe "update action" do
      before :once do
        course_with_teacher active_all: true
        create_rubric(@course)
      end

      it "updates a rubric" do
        points = 9000.0
        new_title = "some new title"
        awesome = "Awesome"
        ratings = {
          "0" => { points: 9000, description: awesome },
          "1" => { points: 100, description: "not good" }
        }
        above = "above 9000"
        criteria = { "0" => { id: 1, points:, description: above, long_description: "he's above 9000!", ratings: } }
        response = update_rubric_api_call(@course, { rubric: { title: new_title, criteria: } })
        rubric = response["rubric"]
        expect(rubric["title"]).to eq new_title
        expect(rubric["points_possible"]).to eq points
        expect(rubric["criteria"][0]["description"]).to eq above
        expect(rubric["criteria"][0]["ratings"][0]["description"]).to eq awesome
        expect(rubric["criteria"][0]["ratings"][0]["points"]).to eq points
      end

      it "updates a rubric with multiple criteria" do
        points0 = 5000.0
        points1 = 2000.0
        points2 = 2001.0
        total_points = points0 + points1 + points2
        criteria1ratings = {
          "0" => { points: points0, description: "awesome" },
          "1" => { points: 100, description: "not good" }
        }
        criteria2ratings = {
          "0" => { points: points1, description: "awesome" },
          "1" => { points: 100, description: "not good" }
        }
        criteria3ratings = {
          "0" => { points: points2, description: "awesome" },
          "1" => { points: 100, description: "not good" }
        }
        criteria = {
          "0" => { id: 1, points: points0, description: "description", long_description: "long description", ratings: criteria1ratings },
          "1" => { id: 2, points: points1, description: "description", long_description: "long description", ratings: criteria2ratings },
          "2" => { id: 3, points: points2, description: "description", long_description: "long description", ratings: criteria3ratings },
        }
        response = update_rubric_api_call(@course, { rubric: { criteria: } })
        rubric = response["rubric"]
        expect(rubric["points_possible"]).to eq total_points
        expect(rubric["criteria"][0]["ratings"][0]["points"]).to eq points0
        expect(rubric["criteria"][1]["ratings"][0]["points"]).to eq points1
        expect(rubric["criteria"][2]["ratings"][0]["points"]).to eq points2
      end

      it "updates a rubric with an outcome criterion" do
        account = Account.default
        outcome = account.created_learning_outcomes.create!(
          title: "My Outcome",
          description: "Description of my outcome",
          vendor_guid: "vendorguid9000"
        )
        rating = {
          "0" => { points: 9000, description: "awesome" },
          "1" => { points: 1000, description: "meh" },
          "2" => { points: 100, description: "not good" }
        }
        criteria = {
          "0" => { id: 1, points: 9000, learning_outcome_id: outcome.id, description: "description", long_description: "long description", ratings: rating },
        }
        response = update_rubric_api_call(@course, { rubric: { criteria: } })
        expect(response["rubric"]["criteria"][0]["learning_outcome_id"]).to eq outcome.id
      end

      it "updates a rubric with an association" do
        assignment = @course.assignments.create
        purpose = "grading"
        use_for_grading = true
        hide_score_total = true
        association_type = "Assignment"
        response = update_rubric_api_call(@course, { rubric: { title: "new title" }, rubric_association: { use_for_grading:, purpose:, hide_score_total:, association_id: assignment.id, association_type: } })
        expect(response["rubric_association"]["association_id"]).to eq assignment.id
        expect(response["rubric_association"]["association_type"]).to eq association_type
        expect(response["rubric_association"]["purpose"]).to eq purpose
        expect(response["rubric_association"]["use_for_grading"]).to eq use_for_grading
        expect(response["rubric_association"]["hide_score_total"]).to eq hide_score_total
      end
    end
  end

  describe "account level rubrics" do
    describe "index action" do
      before :once do
        @user = account_admin_user
        create_rubric(@account)
      end

      it "requires the user to have permission to manage rubrics" do
        @user = @student
        raw_rubric_call(@account, {}, "account")

        assert_status(401)
      end

      it "paginates" do
        paginate_call(@account, "account")
      end

      it "returns an array of all rubrics in an account" do
        create_rubric(@account)
        response = rubrics_api_call(@account, {}, "account")
        expect(response[0].keys.sort).to eq allowed_rubric_fields.sort
        expect(response.length).to eq 2
      end
    end

    describe "show action" do
      before :once do
        @user = account_admin_user
        create_rubric(@account)
      end

      it "returns a rubric" do
        response = rubric_api_call(@account, {}, "account")
        expect(response.keys.sort).to eq allowed_rubric_fields.sort
      end

      it "returns account level rubric with course level association" do
        course_with_teacher(active_all: true)
        assignment = @course.assignments.create
        @rubric.associate_with(assignment, @course, purpose: "grading")
        response = rubric_api_call(@course, {})

        expect(response.keys.sort).to eq allowed_rubric_fields.sort
      end

      it "does not return account level rubric for a course, if the course isn't using it" do
        course_with_teacher(active_all: true)
        rubric_api_call(@course, {})

        assert_status(404)
      end

      it "requires the user to have permission to manage rubrics" do
        @user = @student
        raw_rubric_call(@account, {}, "account")

        assert_status(401)
      end

      context "include parameter" do
        before :once do
          course_with_student(user: @user, active_all: true)
          course_with_teacher active_all: true
          create_rubric(@account)
          ["grading", "peer_review"].each.with_index do |type, index|
            create_rubric_assessment({ type:, comments: "comment #{index}" })
          end
          @user = account_admin_user
        end

        it "does not return rubric assessments by default" do
          response = rubric_api_call(@account, {}, "account")
          expect(response).not_to have_key "assessments"
        end

        it "returns rubric assessments when passed 'assessments'" do
          response = rubric_api_call(@account, { include: "assessments" }, "account")
          expect(response).to have_key "assessments"
          expect(response["assessments"].length).to eq 2
        end

        it "returns any rubric assessments used for grading when passed 'graded_assessments'" do
          response = rubric_api_call(@account, { include: "graded_assessments" }, "account")
          expect(response["assessments"][0]["assessment_type"]).to eq "grading"
          expect(response["assessments"].length).to eq 1
        end

        it "returns any peer review assessments when passed 'peer_assessments'" do
          response = rubric_api_call(@account, { include: "peer_assessments" }, "account")
          expect(response["assessments"][0]["assessment_type"]).to eq "peer_review"
          expect(response["assessments"].length).to eq 1
        end

        it "returns an error if passed an invalid argument" do
          raw_rubric_call(@account, { include: "cheez" }, "account")

          expect(response).not_to be_successful
          json = JSON.parse response.body
          expect(json["errors"]["include"].first["message"]).to start_with "invalid include value requested. Must be one of the following:"
        end

        it "returns an error if passed mutually-exclusive include options" do
          raw_rubric_call(@account, { include: ["assessments", "peer_assessments"] }, "account")

          expect(response).not_to be_successful
          json = JSON.parse response.body
          expect(json["errors"]["include"].first["message"]).to start_with "cannot list multiple assessment includes."

          raw_rubric_call(@account, { include: ["associations", "assignment_associations"] }, "account")

          expect(response).not_to be_successful
          json = JSON.parse response.body
          expect(json["errors"]["include"].first["message"]).to start_with "cannot list multiple association includes."
        end

        context "style argument" do
          before :once do
            @user = account_admin_user
          end

          it "returns all data when passed 'full'" do
            response = rubric_api_call(@account, { include: "assessments", style: "full" }, "account")
            expect(response["assessments"][0]).to have_key "data"
          end

          it "returns only comments when passed 'comments_only'" do
            response = rubric_api_call(@account, { include: "assessments", style: "comments_only" }, "account")
            expect(response["assessments"][0]).to have_key "comments"
          end

          it "returns an error if passed an invalid argument" do
            raw_rubric_call(@account, { include: "assessments", style: "BigMcLargeHuge" }, "account")

            expect(response).not_to be_successful
            json = JSON.parse response.body
            expect(json["errors"]["style"].first["message"]).to eq "invalid style requested. Must be one of the following: full, comments_only"
          end

          it "returns an error if passed a style parameter without assessments" do
            raw_rubric_call(@account, { style: "full" }, "account")

            expect(response).not_to be_successful
            json = JSON.parse response.body
            expect(json["errors"]["style"].first["message"]).to eq "invalid parameters. Style parameter passed without requesting assessments"
          end
        end
      end
    end
  end
end
