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

require_relative "../spec_helper"
require_relative "../apis/api_spec_helper"

describe AssignmentGroupsController do
  def course_group
    @group = @course.assignment_groups.create(name: "some group")
  end

  def course_group_with_integration_data
    @course.assignment_groups.create(name: "some group", integration_data: { "something" => "else" })
  end

  describe "GET index" do
    let(:assignments_ids) do
      json_response = json_parse(response.body)
      json_response.first["assignments"].pluck("id")
    end

    describe "filtering by grading period and overrides" do
      let!(:assignment) { course.assignments.create!(name: "Assignment without overrides", due_at: Date.new(2015, 1, 15)) }
      let!(:assignment_with_override) do
        course.assignments.create!(name: "Assignment with override", due_at: Date.new(2015, 1, 15))
      end
      let!(:feb_override) do
        # mass assignment is disabled for AssigmentOverride
        student_override = assignment_with_override.assignment_overrides.new.tap do |override|
          override.title = "feb override"
          override.due_at = Time.zone.local(2015, 2, 15)
          override.due_at_overridden = true
        end
        student_override.save!
        student_override.assignment_override_students.create!(user: student)
      end

      let(:student) do
        dora = User.create!(name: "Dora")
        course_with_student(course:, user: dora, active_enrollment: true)
        course_with_student(course:, user: User.create!, active_enrollment: true)
        dora
      end

      let(:jan_grading_period) do
        grading_period_group.grading_periods.create!(
          start_date: Date.new(2015, 1, 1),
          end_date: Date.new(2015, 1, 31),
          title: "Jan Period"
        )
      end

      let(:feb_grading_period) do
        grading_period_group.grading_periods.create!(
          start_date: Date.new(2015, 2, 1),
          end_date: Date.new(2015, 2, 28),
          title: "Feb Period"
        )
      end

      let(:grading_period_group) { Factories::GradingPeriodGroupHelper.new.legacy_create_for_course(course) }
      let(:course) do
        course = sub_account.courses.create!
        course.offer!
        course
      end
      let(:root_account) { Account.default }
      let(:sub_account) { root_account.sub_accounts.create! }

      context "given an assignment group with and without integration data" do
        before(:once) do
          account_admin_user(account: root_account)
        end

        let(:index_params) do
          {
            params: {
              course_id: @course.id,
              exclude_response_fields: ["description"],
              include: %w[assignments assignment_visibility overrides]
            },
            format: :json
          }
        end

        it "returns an empty hash when created without integration data" do
          user_session(@admin)
          course_group
          @assignment = @course.assignments.create!(
            title: "assignment",
            assignment_group: @group,
            only_visible_to_overrides: true,
            workflow_state: "published"
          )
          get :index, **index_params
          assignment_group_response = json_parse(response.body).first
          expect(assignment_group_response["integration_data"]).to eq({})
        end

        it "returns the assignment group with integration data when it was created with it" do
          user_session(@admin)
          group_with_integration_data = course_group_with_integration_data
          @assignment = @course.assignments.create!(
            title: "assignment",
            assignment_group: group_with_integration_data,
            only_visible_to_overrides: true,
            workflow_state: "published"
          )
          get "index", **index_params
          assignment_group_response = json_parse(response.body).last
          expect(assignment_group_response["integration_data"]).to eq({ "something" => "else" })
        end
      end

      context "given a root account with a grading period and a sub account with a grading period" do
        before(:once) do
          account_admin_user(account: root_account)
        end

        let(:index_params) do
          {
            course_id: course.id,
            exclude_response_fields: ["description"],
            include: %w[assignments assignment_visibility overrides]
          }
        end

        it "when there is an assignment with overrides, filter grading periods by the override's due_at" do
          user_session(@admin)
          get :index, params: index_params.merge(grading_period_id: feb_grading_period.id), format: :json
          expect(assignments_ids).to include assignment_with_override.id
          expect(assignments_ids).to_not include assignment.id
        end

        it "includes an assignment if any of its overrides fall within the given grading period" do
          user_session(student)
          get :index, params: index_params.merge(grading_period_id: jan_grading_period.id), format: :json
          expect(assignments_ids).to include assignment_with_override.id
          expect(assignments_ids).to include assignment.id
        end

        it "if scope_assignments_to_student is passed in and the requesting user " \
           "is a student, it should only include an assignment if its effective due " \
           "date for the requesting user falls within the given grading period" do
          user_session(student)
          get :index, params: index_params.merge(grading_period_id: jan_grading_period.id, scope_assignments_to_student: true), format: :json
          expect(assignments_ids).to_not include assignment_with_override.id
          expect(assignments_ids).to include assignment.id
        end

        it "if scope_assignments_to_student is passed in and the requesting user " \
           "is a fake student, it should only include an assignment if its effective due " \
           "date for the requesting user falls within the given grading period" do
          fake_student = course.student_view_student
          override = assignment_with_override.assignment_overrides.first
          override.assignment_override_students.create!(user: fake_student)
          user_session(fake_student)
          get :index, params: index_params.merge(grading_period_id: jan_grading_period.id, scope_assignments_to_student: true), format: :json
          expect(assignments_ids).to_not include assignment_with_override.id
          expect(assignments_ids).to include assignment.id
        end

        it "if scope_assignments_to_student is passed in and the requesting user " \
           "is not a student or fake student, it should behave as though " \
           "scope_assignments_to_student was not passed in" do
          user_session(@admin)
          get :index, params: index_params.merge(grading_period_id: jan_grading_period.id, scope_assignments_to_student: true), format: :json
          expect(assignments_ids).to include assignment_with_override.id
          expect(assignments_ids).to include assignment.id
        end
      end
    end

    describe "filtering assignments by submission type" do
      before(:once) do
        course_with_teacher(active_all: true)
        @vanilla_assignment = @course.assignments.create!(name: "Boring assignment")
        @discussion_assignment = @course.assignments.create!(
          name: "Discussable assignment",
          submission_types: "discussion_topic"
        )
      end

      it "filters assignments by the submission_type" do
        user_session(@teacher)
        get :index,
            params: {
              course_id: @course.id,
              include: ["assignments"],
              exclude_assignment_submission_types: ["discussion_topic"]
            },
            format: :json
        expect(assignments_ids).to include @vanilla_assignment.id
        expect(assignments_ids).not_to include @discussion_assignment.id
      end
    end

    describe "filtering assignments by ID" do
      before(:once) do
        course_with_teacher(active_all: true)
        @first_assignment = @course.assignments.create!(name: "Assignment 1")
        @second_assignment = @course.assignments.create!(name: "Assignment 2")
      end

      it "optionally filters assignments by ID" do
        user_session(@teacher)
        get :index,
            params: {
              course_id: @course.id,
              include: ["assignments"],
              assignment_ids: [@second_assignment.id]
            },
            format: :json
        expect(assignments_ids).to match_array [@second_assignment.id]
      end

      it "optionally filters assignments by ID when passed assignment_ids as a comma separated string" do
        new_assignment = @course.assignments.create!(name: "Assignment 3")
        user_session(@teacher)
        get :index,
            params: {
              course_id: @course.id,
              include: ["assignments"],
              assignment_ids: [@second_assignment.id, new_assignment.id].join(",")
            },
            format: :json
        expect(assignments_ids).to match_array [@second_assignment.id, new_assignment.id]
      end

      it "does not return assignments outside the scope of the original result set" do
        new_course = Course.create!
        new_assignment = new_course.assignments.create!(name: "New Assignment")

        user_session(@teacher)
        get :index,
            params: {
              course_id: @course.id,
              include: ["assignments"],
              assignment_ids: [@second_assignment.id, new_assignment.id]
            },
            format: :json
        expect(assignments_ids).to match_array [@second_assignment.id]
      end
    end

    describe "filtering out hidden zero point quizzes" do
      before(:once) do
        course_with_teacher(active_all: true)
        @first_quiz = @course.assignments.create!(name: "Quiz", points_possible: 10, submission_types: ["external_tool"], omit_from_final_grade: true, hide_in_gradebook: false)
        @second_quiz = @course.assignments.create!(name: "Practice Quiz", points_possible: 0, submission_types: ["external_tool"], omit_from_final_grade: true, hide_in_gradebook: true)
      end

      it "filters out assignments that have been hidden from gradebook if 'hide_zero_point_quizzes' param is set to true" do
        user_session(@teacher)
        get :index,
            params: {
              hide_zero_point_quizzes: true,
              course_id: @course.id,
              include: ["assignments"],
            },
            format: :json
        expect(assignments_ids).to match_array [@first_quiz.id]
      end

      it "does not filter out assignments that have been hidden from gradebook if 'hide_zero_point_quizzes_option' param is set to false" do
        user_session(@teacher)
        get :index,
            params: {
              hide_zero_point_quizzes: false,
              course_id: @course.id,
              include: ["assignments"],
            },
            format: :json
        expect(assignments_ids).to match_array [@first_quiz.id, @second_quiz.id]
      end
    end

    context "given a course with a teacher and a student" do
      before :once do
        course_with_teacher(active_all: true)
        student_in_course(active_all: true)
      end

      it "requires authorization" do
        get "index", params: { course_id: @course.id }
        assert_unauthorized
      end

      context "differentiated assignments" do
        before do
          user_session(@teacher)
          course_group
          @group = course_group
          @assignment = @course.assignments.create!(
            title: "assignment",
            assignment_group: @group,
            only_visible_to_overrides: true,
            workflow_state: "published"
          )
        end

        it "does not check visibilities on individual assignemnts" do
          # ensures that check is not an N+1 from the gradebook
          expect_any_instance_of(Assignment).not_to receive(:students_with_visibility)
          get "index", params: { course_id: @course.id, include: ["assignments", "assignment_visibility"] }, format: :json
          expect(response).to be_successful
        end
      end
    end

    describe "passing include_param submission", type: :request do
      before(:once) do
        student_in_course(active_all: true)
        @assignment = @course.assignments.create!(
          title: "assignment",
          assignment_group: @group,
          workflow_state: "published",
          submission_types: "online_url",
          points_possible: 25
        )
        @submission = bare_submission_model(@assignment, @student, {
                                              score: "25",
                                              grade: "25",
                                              grader_id: @teacher.id,
                                              submitted_at: Time.zone.now
                                            })
      end

      it "returns assignment and submission" do
        json = api_call_as_user(@student,
                                :get,
                                "/api/v1/courses/#{@course.id}/assignment_groups?include[]=assignments&include[]=submission",
                                {
                                  controller: "assignment_groups",
                                  action: "index",
                                  format: "json",
                                  course_id: @course.id,
                                  include: ["assignments", "submission"]
                                })
        expect(json[0]["assignments"][0]["submission"]).to be_present
        expect(json[0]["assignments"][0]["submission"]["id"]).to eq @submission.id
      end

      context "submission in_closed_grading_period" do
        before(:once) do
          @gp_group = @course.account.grading_period_groups.create!
          @course.enrollment_term.update!(grading_period_group: @gp_group)
        end

        it "any_assignment_in_closed_grading_period is false if no assignments exist, but a closed grading period does" do
          @gp_group.grading_periods.create!(
            start_date: 4.days.ago,
            end_date: 2.days.ago,
            close_date: 1.day.ago,
            title: "closed gp"
          )
          @course.assignments.destroy_all
          json = api_call_as_user(@student,
                                  :get,
                                  "/api/v1/courses/#{@course.id}/assignment_groups?include[]=assignments&include[]=submission",
                                  {
                                    controller: "assignment_groups",
                                    action: "index",
                                    format: "json",
                                    course_id: @course.id,
                                    include: ["assignments", "submission"]
                                  })
          expect(json.first.fetch("any_assignment_in_closed_grading_period")).to be false
        end

        it "returns in_closed_grading_period when 'assignments' are included in params" do
          @course.assignments.create!
          json = api_call_as_user(@teacher,
                                  :get,
                                  "/api/v1/courses/#{@course.id}/assignment_groups",
                                  {
                                    controller: "assignment_groups",
                                    action: "index",
                                    format: "json",
                                    course_id: @course.id,
                                    include: ["assignments"]
                                  })
          assignment_json = json.first.fetch("assignments").first
          expect(assignment_json).to have_key "in_closed_grading_period"
        end

        it "deals with non-array include" do
          api_call_as_user(@teacher,
                           :get,
                           "/api/v1/courses/#{@course.id}/assignment_groups",
                           {
                             controller: "assignment_groups",
                             action: "index",
                             format: "json",
                             course_id: @course.id,
                             include: "assignments"
                           },
                           {},
                           {},
                           { expected_status: 200 })
        end

        it "in_closed_grading_period is true when any submission is in a closed grading period" do
          @gp_group.grading_periods.create!(
            start_date: 4.days.ago,
            end_date: 2.days.ago,
            close_date: 1.day.ago,
            title: "closed gp"
          )
          closed_gp_assignment = @course.assignments.create!(due_at: 2.days.ago)
          json = api_call_as_user(@teacher,
                                  :get,
                                  "/api/v1/courses/#{@course.id}/assignment_groups",
                                  {
                                    controller: "assignment_groups",
                                    action: "index",
                                    format: "json",
                                    course_id: @course.id,
                                    include: ["assignments"]
                                  })
          assignments_json = json.first.fetch("assignments")
          assignment_json = assignments_json.find { |a| a.fetch("id") == closed_gp_assignment.id }
          expect(assignment_json.fetch("in_closed_grading_period")).to be true
        end

        it "in_closed_grading_period is false when all submissions are in open grading periods" do
          @gp_group.grading_periods.create!(
            start_date: 4.days.ago,
            end_date: 1.day.from_now,
            close_date: 2.days.from_now,
            title: "open gp"
          )
          open_gp_assignment = @course.assignments.create!(due_at: 2.days.ago)
          json = api_call_as_user(@teacher,
                                  :get,
                                  "/api/v1/courses/#{@course.id}/assignment_groups",
                                  {
                                    controller: "assignment_groups",
                                    action: "index",
                                    format: "json",
                                    course_id: @course.id,
                                    include: ["assignments"]
                                  })
          assignments_json = json.first.fetch("assignments")
          assignment_json = assignments_json.find { |a| a.fetch("id") == open_gp_assignment.id }
          expect(assignment_json.fetch("in_closed_grading_period")).to be false
        end

        it "submissions with no due date and last period is open do not cause in_closed_grading_period to be true" do
          @gp_group.grading_periods.create!(
            start_date: 4.days.ago,
            end_date: 1.day.from_now,
            close_date: 2.days.from_now,
            title: "open gp"
          )
          assignment = @course.assignments.create!
          json = api_call_as_user(@teacher,
                                  :get,
                                  "/api/v1/courses/#{@course.id}/assignment_groups",
                                  {
                                    controller: "assignment_groups",
                                    action: "index",
                                    format: "json",
                                    course_id: @course.id,
                                    include: ["assignments"]
                                  })
          assignments_json = json.first.fetch("assignments")
          assignment_json = assignments_json.find { |a| a.fetch("id") == assignment.id }
          expect(assignment_json.fetch("in_closed_grading_period")).to be false
        end

        it "submissions with no due date and last period is closed cause in_closed_grading_period to be true" do
          @gp_group.grading_periods.create!(
            start_date: 4.days.ago,
            end_date: 2.days.ago,
            close_date: 1.day.ago,
            title: "closed gp"
          )
          assignment = @course.assignments.create!
          json = api_call_as_user(@teacher,
                                  :get,
                                  "/api/v1/courses/#{@course.id}/assignment_groups",
                                  {
                                    controller: "assignment_groups",
                                    action: "index",
                                    format: "json",
                                    course_id: @course.id,
                                    include: ["assignments"]
                                  })
          assignments_json = json.first.fetch("assignments")
          assignment_json = assignments_json.find { |a| a.fetch("id") == assignment.id }
          expect(assignment_json.fetch("in_closed_grading_period")).to be true
        end
      end

      context "cross shard observer" do
        specs_require_sharding

        it "fetches observees submissions" do
          @shard1.activate do
            student_in_course(active_all: true)
            @cross_shard_observer = User.create!
            @course.enroll_student(@cross_shard_observer, enrollment_state: "active")
          end
          @shard2.activate do
            account = Account.create!
            @course2 = Course.create!(account:, workflow_state: "available")
            @teacher = @course2.enroll_teacher(@teacher, enrollment_state: "active").user
            @observer_enrollment = @course2.enroll_user(@cross_shard_observer, "ObserverEnrollment", enrollment_state: "active")
            @course2.enroll_student(@student, enrollment_state: "active")
            @observer_enrollment.update_attribute(:associated_user_id, @student.id)
            @assignment = @course2.assignments.create!(name: "Assignment 1", submission_types: "online_text_entry")
            @assignment.grade_student(@student, grade: 9, grader: @teacher)
          end

          json = api_call_as_user(@cross_shard_observer,
                                  :get,
                                  "/api/v1/courses/#{@course2.id}/assignment_groups",
                                  {
                                    controller: "assignment_groups",
                                    action: "index",
                                    format: "json",
                                    course_id: @course2.id,
                                    include: %w[assignments observed_users submission]
                                  })

          expect(json[0]["assignments"][0]["submission"]).to be_present
          expect(json[0]["assignments"][0]["submission"][0]["grade"]).to eq "9"
          expect(json[0]["assignments"][0]["submission"][0]["user_id"]).to eq @student.id
        end
      end
    end

    context "passing include_param assessment_requests", type: :request do
      before(:once) do
        course_with_teacher(active_all: true)
        @student1 = student_in_course(course: @course, active_enrollment: true).user
        @student2 = student_in_course(course: @course, active_enrollment: true).user

        @assignment = @course.assignments.create!(name: "Assignment 1", peer_reviews: true, submission_types: "online_text_entry")

        @assessment_request = AssessmentRequest.create!(
          asset: @assignment.submit_homework(@student2, body: "hi"),
          user: @student2,
          assessor: @student1,
          assessor_asset: @assignment.submit_homework(@student1, body: "hi")
        )

        @assignment2 = @course.assignments.create!(name: "Assignment 2", peer_reviews: true, submission_types: "online_text_entry")

        AssessmentRequest.create!(
          asset: @assignment2.submission_for_student(@student2),
          user: @student2,
          assessor: @student1,
          assessor_asset: @assignment2.submission_for_student(@student1)
        )
      end

      let(:json) do
        api_call_as_user(
          @student1,
          :get,
          "/api/v1/courses/#{@course.id}/assignment_groups?include[]=assignments&include[]=assessment_requests",
          {
            controller: "assignment_groups",
            action: "index",
            format: "json",
            course_id: @course.id,
            include: ["assignments", "assessment_requests"]
          }
        )
      end

      context "peer_reviews_for_a2 FF disabled" do
        before(:once) do
          @course.disable_feature! :peer_reviews_for_a2
        end

        it "does not include assessment_requests when the current user is a teacher" do
          json = api_call_as_user(@teacher,
                                  :get,
                                  "/api/v1/courses/#{@course.id}/assignment_groups?include[]=assignments&include[]=assessment_requests",
                                  {
                                    controller: "assignment_groups",
                                    action: "index",
                                    format: "json",
                                    course_id: @course.id,
                                    include: ["assignments", "assessment_requests"]
                                  })
          expect(json[0]["assignments"][0]["assessment_requests"]).not_to be_present
        end

        it "does not include assessment_requests when the current user is a student" do
          expect(json[0]["assignments"][0]["assessment_requests"]).not_to be_present
        end
      end

      context "peer_reviews_for_a2 FF enabled" do
        before(:once) do
          @course.enable_feature! :peer_reviews_for_a2
        end

        it "does not include assessment_requests when the current user is a teacher" do
          json = api_call_as_user(@teacher,
                                  :get,
                                  "/api/v1/courses/#{@course.id}/assignment_groups?include[]=assignments&include[]=assessment_requests",
                                  {
                                    controller: "assignment_groups",
                                    action: "index",
                                    format: "json",
                                    course_id: @course.id,
                                    include: ["assignments", "assessment_requests"]
                                  })
          expect(json[0]["assignments"][0]["assessment_requests"]).not_to be_present
        end

        it "includes assessment_requests when the current user is a student" do
          expect(json[0]["assignments"][0]["assessment_requests"]).to be_present
        end

        it "includes workflow_state, anonymous_id when the assignment has anonymous_peer_reviews enabled" do
          @assignment.update_attribute(:anonymous_peer_reviews, true)

          assessment_request = json[0]["assignments"][0]["assessment_requests"][0]
          expect(assessment_request["workflow_state"]).to eq @assessment_request.workflow_state
          expect(assessment_request["anonymous_id"]).to eq @assessment_request.asset.anonymous_id
          expect(assessment_request["available"]).to be true
        end

        it "includes workflow_state, user_id, user_name when the assignment has anonymous_peer_reviews disabled" do
          @assignment.update_attribute(:anonymous_peer_reviews, false)

          assessment_request = json[0]["assignments"][0]["assessment_requests"][0]
          expect(assessment_request["workflow_state"]).to eq @assessment_request.workflow_state
          expect(assessment_request["user_id"]).to eq @assessment_request.user.id
          expect(assessment_request["user_name"]).to eq @assessment_request.user.name
          expect(assessment_request["available"]).to be true
        end

        it "has available set correctly if both asset and assessor_asset have submitted_at" do
          assessment_request0 = json[0]["assignments"][0]["assessment_requests"][0]
          assessment_request1 = json[0]["assignments"][1]["assessment_requests"][0]
          expect(assessment_request0["available"]).to be true
          expect(assessment_request1["available"]).to be false
        end
      end
    end
  end

  describe "POST 'reorder'" do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
    end

    it "requires authorization" do
      post "reorder", params: { course_id: @course.id }
      assert_unauthorized
    end

    it "does not allow students to reorder" do
      user_session(@student)
      post "reorder", params: { course_id: @course.id }
      assert_unauthorized
    end

    it "reorders assignment groups" do
      user_session(@teacher)
      groups = Array.new(3) { course_group }
      expect(groups.map(&:position)).to eq [1, 2, 3]
      g1, g2, _ = groups
      post "reorder", params: { course_id: @course.id, order: "#{g2.id},#{g1.id}" }
      expect(response).to be_successful
      groups.each(&:reload)
      expect(groups.map(&:position)).to eq [2, 1, 3]
    end
  end

  describe "POST 'reorder_assignments'" do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
      @group1 = @course.assignment_groups.create!(name: "group 1")
      @group2 = @course.assignment_groups.create!(name: "group 2")
      @assignment1 = @course.assignments.create!(title: "assignment 1", assignment_group: @group1)
      @assignment2 = @course.assignments.create!(title: "assignment 2", assignment_group: @group1)
      @assignment3 = @course.assignments.create!(title: "assignment 3", assignment_group: @group2)
      @order = "#{@assignment1.id},#{@assignment2.id},#{@assignment3.id}"
    end

    it "requires authorization" do
      post :reorder_assignments, params: { course_id: @course.id, assignment_group_id: @group1.id, order: @order }
      assert_unauthorized
    end

    it "does not allow students to reorder" do
      user_session(@student)
      post :reorder_assignments, params: { course_id: @course.id, assignment_group_id: @group1.id, order: @order }
      assert_unauthorized
    end

    it "moves the assignment from its current assignment group to another assignment group" do
      user_session(@teacher)
      post :reorder_assignments, params: { course_id: @course.id, assignment_group_id: @group1.id, order: @order }
      expect(response).to be_successful
      @assignment3.reload
      expect(@assignment3.assignment_group_id).to eq(@group1.id)
      expect(@group2.assignments.count).to eq(0)
      expect(@group1.assignments.count).to eq(3)
    end

    it "moves an associated Quiz to the correct assignment group along with the assignment" do
      @quiz = @course.quizzes.create!(title: "teh quiz", quiz_type: "assignment", assignment_group_id: @group2)
      user_session(@teacher)
      post :reorder_assignments, params: { course_id: @course.id,
                                           assignment_group_id: @group1.id,
                                           order: @order + ",#{@quiz.assignment.id}" }
      @quiz.reload
      expect(@quiz.assignment.assignment_group_id).to eq(@group1.id)
      expect(@quiz.assignment_group_id).to eq(@group1.id)
    end

    it "marks downstream_changes for master courses" do
      @quiz = @course.quizzes.create!(title: "teh quiz", quiz_type: "assignment", assignment_group_id: @group1)
      mc_course = Course.create!
      @template = MasterCourses::MasterTemplate.set_as_master_course(mc_course)
      sub = @template.add_child_course!(@course)
      @course.reload.assignments.map { |a| sub.content_tag_for(a) }

      user_session(@teacher)
      post :reorder_assignments, params: { course_id: @course.id, assignment_group_id: @group2.id, order: @order + ",#{@quiz.assignment.id}" }
      expect(response).to be_successful
      [@assignment1, @assignment2, @quiz].each do |obj|
        expect(sub.content_tag_for(obj).reload.downstream_changes).to include("assignment_group_id")
      end
      expect(sub.content_tag_for(@assignment3).reload.downstream_changes).to be_empty # already was in group2
    end

    context "with grading periods" do
      before :once do
        group = Factories::GradingPeriodGroupHelper.new.create_for_account(@course.root_account)
        term = @course.enrollment_term
        term.grading_period_group = group
        term.save!
        Factories::GradingPeriodHelper.new.create_for_group(group, {
                                                              start_date: 2.weeks.ago, end_date: 2.days.ago, close_date: 1.day.ago
                                                            })
        Factories::GradingPeriodHelper.new.create_for_group(group, {
                                                              start_date: 2.days.ago, end_date: 2.days.from_now, close_date: 3.days.from_now
                                                            })
        @assignment1.update(due_at: 1.week.ago)
      end

      it "does not allow assignments in closed grading periods to be moved into different assignment groups" do
        user_session(@teacher)
        post :reorder_assignments, params: { course_id: @course.id, assignment_group_id: @group2.id, order: @order }
        assert_unauthorized
        expect(@assignment1.reload.assignment_group_id).to eq(@group1.id)
        expect(@assignment2.reload.assignment_group_id).to eq(@group1.id)
        expect(@assignment3.reload.assignment_group_id).to eq(@group2.id)
      end

      it "allows assignments with no effective due date in a closed grading period to be moved into different groups" do
        user_session(@teacher)
        student = @course.students.first

        override = @assignment2.assignment_overrides.create!(due_at: 1.month.from_now, due_at_overridden: true)
        override.assignment_override_students.create!(user: student)

        @order = "#{@assignment3.id},#{@assignment2.id}"

        post :reorder_assignments, params: { course_id: @course.id, assignment_group_id: @group2.id, order: @order }
        expect(response).to be_successful
        expect(@assignment1.reload.assignment_group_id).to eq(@group1.id)
        expect(@assignment2.reload.assignment_group_id).to eq(@group2.id)
        expect(@assignment3.reload.assignment_group_id).to eq(@group2.id)
        expect(@assignment2.position).to be(2)
        expect(@assignment3.position).to be(1)
      end

      it "allows assignments not in closed grading periods to be moved into different assignment groups" do
        user_session(@teacher)
        order = "#{@assignment3.id},#{@assignment2.id}"
        post :reorder_assignments, params: { course_id: @course.id, assignment_group_id: @group2.id, order: }
        expect(response).to be_successful
        expect(@assignment1.reload.assignment_group_id).to eq(@group1.id)
        expect(@assignment2.reload.assignment_group_id).to eq(@group2.id)
        expect(@assignment3.reload.assignment_group_id).to eq(@group2.id)
        expect(@assignment2.position).to be(2)
        expect(@assignment3.position).to be(1)
      end

      it "allows assignments in closed grading periods to be reordered within the same assignment group" do
        user_session(@teacher)
        order = "#{@assignment3.id},#{@assignment1.id},#{@assignment2.id}"
        post :reorder_assignments, params: { course_id: @course.id, assignment_group_id: @group1.id, order: }
        expect(response).to be_successful
        expect(@assignment1.reload.assignment_group_id).to eq(@group1.id)
        expect(@assignment2.reload.assignment_group_id).to eq(@group1.id)
        expect(@assignment3.reload.assignment_group_id).to eq(@group1.id)
        expect(@assignment1.position).to be(2)
        expect(@assignment2.position).to be(3)
        expect(@assignment3.position).to be(1)
      end

      it "allows assignments in closed grading periods when the user is a root admin" do
        admin = account_admin_user(account: @course.root_account)
        user_session(admin)
        post :reorder_assignments, params: { course_id: @course.id, assignment_group_id: @group2.id, order: @order }
        expect(response).to be_successful
        expect(@assignment1.reload.assignment_group_id).to eq(@group2.id)
        expect(@assignment2.reload.assignment_group_id).to eq(@group2.id)
        expect(@assignment3.reload.assignment_group_id).to eq(@group2.id)
      end

      it "ignores deleted assignments" do
        @assignment1.destroy
        user_session(@teacher)
        post :reorder_assignments, params: { course_id: @course.id, assignment_group_id: @group2.id, order: @order }
        expect(response).to be_successful
        expect(@assignment1.reload.assignment_group_id).to eq(@group1.id)
        expect(@assignment2.reload.assignment_group_id).to eq(@group2.id)
        expect(@assignment3.reload.assignment_group_id).to eq(@group2.id)
      end
    end
  end

  describe "GET 'show'" do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
      course_group
    end

    it "requires authorization" do
      get "show", params: { course_id: @course.id, id: @group.id }
      assert_unauthorized
    end

    it "assigns variables" do
      user_session(@student)
      get "show", params: { course_id: @course.id, id: @group.id }, format: :json
      expect(assigns[:assignment_group]).to eql(@group)
    end
  end

  describe "POST 'create'" do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
    end

    let(:name) { "some test group" }

    it "requires authorization" do
      post "create", params: { course_id: @course.id, assignment_group: { name: } }
      assert_unauthorized
    end

    it "does not allow students to create" do
      user_session(@student)
      post "create", params: { course_id: @course.id, assignment_group: { name: } }
      assert_unauthorized
    end

    it "creates a new group with valid integration_data" do
      user_session(@teacher)
      group_integration_data = { "something" => "else" }
      post "create", params: { course_id: @course.id,
                               assignment_group: { name:,
                                                   integration_data: group_integration_data } }
      expect(response).to be_redirect
      expect(assigns[:assignment_group].name).to eql(name)
      expect(assigns[:assignment_group].position).to be(1)
      expect(assigns[:assignment_group].integration_data).to eql(group_integration_data)
    end

    it "creates a new group with no integration_data" do
      user_session(@teacher)
      post "create", params: { course_id: @course.id,
                               assignment_group: { name:,
                                                   integration_data: {} } }
      expect(response).to be_redirect
      expect(assigns[:assignment_group].name).to eql(name)
      expect(assigns[:assignment_group].position).to be(1)
      expect(assigns[:assignment_group].integration_data).to eql({})
    end

    it "creates a new group where integration_data is not present" do
      user_session(@teacher)
      post "create", params: { course_id: @course.id,
                               assignment_group: { name:,
                                                   integration_data: nil } }
      expect(response).to be_redirect
      expect(assigns[:assignment_group].name).to eql(name)
      expect(assigns[:assignment_group].position).to be(1)
      expect(assigns[:assignment_group].integration_data).to eql({})
    end

    it "returns a 400 when trying to create a new group with invalid integration_data" do
      user_session(@teacher)
      integration_data = "something"
      post "create", params: { course_id: @course.id,
                               assignment_group: { name:,
                                                   integration_data: } }
      expect(response).to have_http_status(:bad_request)
    end

    it "creates a new group when integration_data is not present" do
      user_session(@teacher)
      post "create", params: { course_id: @course.id, assignment_group: { name: } }
      expect(response).to be_redirect
      expect(assigns[:assignment_group].name).to eql(name)
      expect(assigns[:assignment_group].position).to be(1)
      expect(assigns[:assignment_group].integration_data).to eql({})
    end
  end

  describe "PUT 'update'" do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
      course_group
    end

    let(:name) { "new group name" }

    it "requires authorization" do
      put "update", params: { course_id: @course.id, id: @group.id, assignment_group: { name: } }
      assert_unauthorized
    end

    it "does not allow students to update" do
      user_session(@student)
      put "update", params: { course_id: @course.id, id: @group.id, assignment_group: { name: } }
      assert_unauthorized
    end

    it "updates group" do
      user_session(@teacher)
      group_integration_data = { "something" => "else", "foo" => "bar" }
      put "update", params: { course_id: @course.id,
                              id: @group.id,
                              assignment_group: { name:,
                                                  sis_source_id: "5678",
                                                  integration_data: group_integration_data } }
      expect(assigns[:assignment_group]).to eql(@group)
      expect(assigns[:assignment_group].name).to eql("new group name")
      expect(assigns[:assignment_group].sis_source_id).to eql("5678")
      expect(assigns[:assignment_group].integration_data).to eql(group_integration_data)
    end

    it "updates group with existing integration_data" do
      existing_integration_data = { "existing" => "data" }
      @group.integration_data = existing_integration_data
      @group.save

      user_session(@teacher)
      new_integration_data = { "oh" => "hello", "hi" => "there" }
      put "update", params: { course_id: @course.id,
                              id: @group.id,
                              assignment_group: { name:,
                                                  sis_source_id: "5678",
                                                  integration_data: new_integration_data } }

      expect(AssignmentGroup.find(@group.id).integration_data).to eq(
        existing_integration_data.merge(new_integration_data)
      )
    end

    it "updates a group with no integration_data" do
      user_session(@teacher)
      put "update", params: { course_id: @course.id,
                              id: @group.id,
                              assignment_group: { name:,
                                                  sis_source_id: "5678",
                                                  integration_data: {} } }
      expect(assigns[:assignment_group]).to eql(@group)
      expect(assigns[:assignment_group].name).to eql("new group name")
      expect(assigns[:assignment_group].sis_source_id).to eql("5678")
      expect(assigns[:assignment_group].integration_data).to eql({})
    end

    it "updates a group where integration_data is not present" do
      user_session(@teacher)
      put "update", params: { course_id: @course.id,
                              id: @group.id,
                              assignment_group: { name: "updated name",
                                                  sis_source_id: "5678",
                                                  integration_data: nil } }
      expect(assigns[:assignment_group]).to eql(@group)
      expect(assigns[:assignment_group].name).to eql("updated name")
      expect(assigns[:assignment_group].sis_source_id).to eql("5678")
      expect(assigns[:assignment_group].integration_data).to eql({})
    end

    it "returns a 400 when trying to update a group with invalid integration_data" do
      user_session(@teacher)
      integration_data = "test"
      put "update", params: { course_id: @course.id,
                              id: @group.id,
                              assignment_group: { name:,
                                                  integration_data: } }
      expect(response).to have_http_status(:bad_request)
    end

    it "retains integration_data when updating a group" do
      user_session(@teacher)
      group = course_group_with_integration_data
      expect(group.name).to eq("some group")
      expect(group.integration_data).to eq({ "something" => "else" })
      put "update", params: { course_id: @course.id,
                              id: group.id,
                              assignment_group: { name: "new new new group name" } }
      expect(assigns[:assignment_group]).to eql(group)
      expect(assigns[:assignment_group].name).to eql("new new new group name")
      expect(assigns[:assignment_group].integration_data).to eql({ "something" => "else" })
    end
  end

  describe "DELETE 'destroy'" do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
      course_group
    end

    it "requires authorization" do
      delete "destroy", params: { course_id: @course.id, id: @group.id }
      assert_unauthorized
    end

    it "does not allow students to delete" do
      user_session(@student)
      delete "destroy", params: { course_id: @course.id, id: @group.id }
      assert_unauthorized
    end

    it "deletes group" do
      user_session(@teacher)
      delete "destroy", params: { course_id: @course.id, id: @group.id }
      expect(assigns[:assignment_group]).to eql(@group)
      expect(assigns[:assignment_group]).not_to be_frozen
      expect(assigns[:assignment_group]).to be_deleted
    end

    it "delete assignments in the group" do
      user_session(@teacher)
      @group1 = @course.assignment_groups.create!(name: "group 1")
      @assignment1 = @course.assignments.create!(title: "assignment 1", assignment_group: @group1)
      delete "destroy", params: { course_id: @course.id, id: @group1.id }
      expect(assigns[:assignment_group]).to eql(@group1)
      expect(assigns[:assignment_group]).to be_deleted
      expect(@group1.reload.assignments.length).to be(1)
      expect(@group1.reload.assignments[0]).to eql(@assignment1)
      expect(@group1.assignments.active.length).to be(0)
    end

    it "moves assignments to a different group if specified" do
      user_session(@teacher)
      @group1 = @course.assignment_groups.create!(name: "group 1")
      @assignment1 = @course.assignments.create!(title: "assignment 1", assignment_group: @group1)
      @group2 = @course.assignment_groups.create!(name: "group 2")
      @assignment2 = @course.assignments.create!(title: "assignment 2", assignment_group: @group2)
      expect(@assignment1.position).to be(1)
      expect(@assignment1.assignment_group_id).to eql(@group1.id)
      expect(@assignment2.position).to be(1)
      expect(@assignment2.assignment_group_id).to eql(@group2.id)

      delete "destroy", params: { course_id: @course.id, id: @group2.id, move_assignments_to: @group1.id }

      expect(assigns[:assignment_group]).to eql(@group2)
      expect(assigns[:assignment_group]).to be_deleted
      expect(@group2.reload.assignments.length).to be(0)
      expect(@group1.reload.assignments.length).to be(2)
      expect(@group1.assignments.active.length).to be(2)
      expect(@assignment1.reload.position).to be(1)
      expect(@assignment1.assignment_group_id).to eql(@group1.id)
      expect(@assignment2.reload.position).to be(2)
      expect(@assignment2.assignment_group_id).to eql(@group1.id)
    end

    it "does not allow users to delete assignment groups with frozen assignments" do
      allow(PluginSetting).to receive(:settings_for_plugin).and_return(title: "yes")
      user_session(@teacher)
      group = @course.assignment_groups.create!(name: "group 1")
      assignment = @course.assignments.create!(
        title: "assignment",
        assignment_group: group,
        freeze_on_copy: true
      )
      expect(assignment.position).to eq 1
      assignment.copied = true
      assignment.save!
      delete "destroy", format: :json, params: { course_id: @course.id, id: group.id }
      expect(response).not_to be_successful
    end

    it "returns JSON if requested" do
      user_session(@teacher)
      delete "destroy", format: "json", params: { course_id: @course.id, id: @group.id }
      expect(response).to be_successful
    end
  end
end
