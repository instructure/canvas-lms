# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require_relative "../../../spec_helper"

class AssignmentApiHarness
  include Api::V1::Assignment

  def value_to_boolean(value)
    Canvas::Plugin.value_to_boolean(value)
  end

  def api_user_content(description, course, user, _)
    "api_user_content(#{description}, #{course.id}, #{user.id})"
  end

  def course_assignment_url(context_id, assignment)
    "assignment/url/#{context_id}/#{assignment.id}"
  end

  def session
    Object.new
  end

  def course_assignment_submissions_url(course, assignment, _options)
    "/course/#{course.id}/assignment/#{assignment.id}/submissions?zip=1"
  end

  def course_quiz_quiz_submissions_url(course, quiz, _options)
    "/course/#{course.id}/quizzes/#{quiz.id}/submissions?zip=1"
  end

  def strong_anything
    ArbitraryStrongishParams::ANYTHING
  end

  def grading_periods?
    false
  end
end

describe "Api::V1::Assignment" do
  subject(:api) { AssignmentApiHarness.new }

  let(:assignment) { assignment_model }

  describe "#assignment_json" do
    let(:user) { user_model }
    let(:session) { Object.new }

    it "returns json" do
      allow(assignment.context).to receive(:grants_right?).and_return(true)
      json = api.assignment_json(assignment, user, session, { override_dates: false })
      expect(json["needs_grading_count"]).to eq(0)
      expect(json["needs_grading_count_by_section"]).to be_nil
    end

    it "includes section-based counts when grading flag is passed" do
      allow(assignment.context).to receive(:grants_right?).and_return(true)
      json = api.assignment_json(assignment, user, session,
                                 { override_dates: false, needs_grading_count_by_section: true })
      expect(json["needs_grading_count"]).to eq(0)
      expect(json["needs_grading_count_by_section"]).to eq []
    end

    it "includes an associated planner override when flag is passed" do
      po = planner_override_model(user: user, plannable: assignment)
      json = api.assignment_json(assignment, user, session,
                                 { include_planner_override: true })
      expect(json).to have_key("planner_override")
      expect(json["planner_override"]["id"]).to eq po.id
    end

    it "includes the assignment's post policy" do
      assignment.post_policy.update!(post_manually: true)

      json = api.assignment_json(assignment, user, session)
      expect(json["post_manually"]).to be true
    end

    it "returns nil for planner override when flag is passed and there is no override" do
      json = api.assignment_json(assignment, user, session, { include_planner_override: true })
      expect(json).to have_key("planner_override")
      expect(json["planner_override"]).to be_nil
    end

    it "includes the original assignment's lti_resource_link_id if the assignment is a duplicate" do
      original_assignment = assignment_model
      allow(original_assignment).to receive(:lti_resource_link_id).and_return("b85797748e3f0ffc2d0c21eb9865e76676cf67d0")
      assignment.update!(duplicate_of: original_assignment)
      json = api.assignment_json(assignment, user, session, { override_dates: false })

      expect(json["original_lti_resource_link_id"]).to eq "b85797748e3f0ffc2d0c21eb9865e76676cf67d0"
    end

    it "returns nil for lti_resource_link_id if the assignment is not a duplicate" do
      json = api.assignment_json(assignment, user, session, { override_dates: false })

      expect(json["original_lti_resource_link_id"]).to be_nil
    end

    describe "the allowed_attempts attribute" do
      it "returns -1 if set to nil" do
        assignment.update_attribute(:allowed_attempts, nil)
        json = api.assignment_json(assignment, user, session, { override_dates: false })
        expect(json["allowed_attempts"]).to eq(-1)
      end

      it "returns -1 if set to -1" do
        assignment.update_attribute(:allowed_attempts, -1)
        json = api.assignment_json(assignment, user, session, { override_dates: false })
        expect(json["allowed_attempts"]).to eq(-1)
      end

      it "returns any other values as set in the databse" do
        assignment.update_attribute(:allowed_attempts, 1)
        json = api.assignment_json(assignment, user, session, { override_dates: false })
        expect(json["allowed_attempts"]).to eq(1)

        assignment.update_attribute(:allowed_attempts, 2)
        json = api.assignment_json(assignment, user, session, { override_dates: false })
        expect(json["allowed_attempts"]).to eq(2)
      end
    end

    context "for an assignment" do
      it "provides a submissions download URL" do
        json = api.assignment_json(assignment, user, session)

        expect(json["submissions_download_url"]).to eq "/course/#{@course.id}/assignment/#{assignment.id}/submissions?zip=1"
      end

      it "optionally includes 'grades_published' for moderated assignments" do
        json = api.assignment_json(assignment, user, session, { include_grades_published: true })
        expect(json["grades_published"]).to eq(true)
      end

      it "excludes 'grades_published' by default" do
        json = api.assignment_json(assignment, user, session)
        expect(json).not_to have_key "grades_published"
      end
    end

    context "include_assessment_requests" do
      before do
        @assignment = assignment_model
        @assignment.update_attribute(:peer_reviews, true)

        @student1 = @assignment.course.enroll_student(User.create!, enrollment_state: "active").user
        @student2 = @assignment.course.enroll_student(User.create!, enrollment_state: "active").user

        @assessment_request = AssessmentRequest.create!(
          asset: @assignment.submission_for_student(@student2),
          user: @student2,
          assessor: @student1,
          assessor_asset: @assignment.submission_for_student(@student1)
        )
      end

      it "includes assessment_requests list when the flag is enabled" do
        json = api.assignment_json(@assignment, @student1, session, { include_assessment_requests: false })
        expect(json["assessment_requests"]).not_to be_present
      end

      it "excludes assessment_requests list when the flag is disabled" do
        json = api.assignment_json(@assignment, @student1, session, { include_assessment_requests: true })
        expect(json["assessment_requests"]).to be_present
      end

      it "includes workflow_state, user_id, user_name when anonymous_peer_reviews is false" do
        @assignment.update_attribute(:anonymous_peer_reviews, false)
        json = api.assignment_json(@assignment, @student1, session, { include_assessment_requests: true })
        assessment_request = json["assessment_requests"][0]
        expect(assessment_request["workflow_state"]).to eq @assessment_request.workflow_state
        expect(assessment_request["user_id"]).to eq @assessment_request.user.id
        expect(assessment_request["user_name"]).to eq @assessment_request.user.name
        expect(assessment_request["available"]).to eq @assessment_request.available?
      end

      it "includes workflow_state, anonymous_id when anonymous_peer_reviews is true" do
        @assignment.update_attribute(:anonymous_peer_reviews, true)
        json = api.assignment_json(@assignment, @student1, session, { include_assessment_requests: true })
        assessment_request = json["assessment_requests"][0]
        expect(assessment_request["workflow_state"]).to eq @assessment_request.workflow_state
        expect(assessment_request["anonymous_id"]).to eq @assessment_request.asset.anonymous_id
        expect(assessment_request["available"]).to eq @assessment_request.available?
      end
    end

    context "for a quiz" do
      before do
        @assignment = assignment_model
        @assignment.submission_types = "online_quiz"
        @quiz = quiz_model(course: @course)
        @assignment.quiz = @quiz
      end

      it "provides a submissions download URL" do
        json = api.assignment_json(@assignment, user, session)

        expect(json["submissions_download_url"]).to eq "/course/#{@course.id}/quizzes/#{@quiz.id}/submissions?zip=1"
      end
    end

    it "includes all assignment overrides fields when an assignment_override exists" do
      assignment.assignment_overrides.create(workflow_state: "active")
      overrides = assignment.assignment_overrides
      json = api.assignment_json(assignment, user, session, { overrides: overrides })
      expect(json).to be_a(Hash)
      expect(json["overrides"].first.keys.sort).to eq %w[assignment_id id title student_ids].sort
    end

    it "excludes descriptions when exclude_response_fields flag is passed and includes 'description'" do
      assignment.description = "Foobers"
      json = api.assignment_json(assignment, user, session,
                                 { override_dates: false })
      expect(json).to be_a(Hash)
      expect(json).to have_key "description"
      expect(json["description"]).to eq(api.api_user_content("Foobers", @course, user, {}))

      json = api.assignment_json(assignment, user, session,
                                 { override_dates: false, exclude_response_fields: ["description"] })
      expect(json).to be_a(Hash)
      expect(json).not_to have_key "description"

      json = api.assignment_json(assignment, user, session,
                                 { override_dates: false })
      expect(json).to be_a(Hash)
      expect(json).to have_key "description"
      expect(json["description"]).to eq(api.api_user_content("Foobers", @course, user, {}))
    end

    it "excludes needs_grading_counts when exclude_response_fields flag is " \
       "passed and includes 'needs_grading_count'" do
      params = { override_dates: false, exclude_response_fields: ["needs_grading_count"] }
      json = api.assignment_json(assignment, user, session, params)
      expect(json).not_to have_key "needs_grading_count"
    end

    describe "include_can_submit" do
      it "includes can_submit when the flag is passed" do
        json = api.assignment_json(assignment, user, session, { include_can_submit: true })
        expect(json).to have_key "can_submit"
      end

      it "returns false when the assignment is in an unpublished module when checking as a student" do
        assignment.update!(submission_types: "online_text_entry", could_be_locked: true)
        course = assignment.course
        student = course.enroll_student(User.create!, enrollment_state: "active").user
        course.update(workflow_state: "available")
        context_module = ContextModule.create!(context: course, workflow_state: "unpublished")
        context_module.content_tags.create!(content: assignment, context: course, tag_type: "context_module")

        expect(context_module.published?).to eq false
        expect(assignment.published?).to eq true
        json = api.assignment_json(assignment, student, session, { include_can_submit: true })
        expect(json).to have_key "can_submit"
        expect(json[:can_submit]).to eq false
      end
    end

    context "rubrics" do
      before do
        rubric_model({
                       context: assignment.course,
                       title: "test rubric",
                       data: [{
                         description: "Some criterion",
                         points: 10,
                         id: "crit1",
                         ignore_for_scoring: true,
                         ratings: [
                           { description: "Good", points: 10, id: "rat1", criterion_id: "crit1" }
                         ]
                       }]
                     })
        @rubric.associate_with(assignment, assignment.course, purpose: "grading")
      end

      it "includes ignore_for_scoring when it is on the rubric" do
        json = api.assignment_json(assignment, user, session)
        expect(json["rubric"][0]["ignore_for_scoring"]).to eq true
      end

      it "includes hide_score_total setting in rubric_settings" do
        json = api.assignment_json(assignment, user, session)
        expect(json["rubric_settings"]["hide_score_total"]).to eq false
      end

      it "returns true for hide_score_total if set to true on the rubric association" do
        ra = assignment.rubric_association
        ra.hide_score_total = true
        ra.save!
        json = api.assignment_json(assignment, user, session)
        expect(json["rubric_settings"]["hide_score_total"]).to eq true
      end

      it "includes hide_points setting in rubric_settings" do
        json = api.assignment_json(assignment, user, session)
        expect(json["rubric_settings"]["hide_points"]).to eq false
      end

      it "returns true for hide_points if set to true on the rubric association" do
        ra = assignment.rubric_association
        ra.hide_points = true
        ra.save!
        json = api.assignment_json(assignment, user, session)
        expect(json["rubric_settings"]["hide_points"]).to eq true
      end

      it "excludes rubric when exclude_response_fields contains 'rubric'" do
        opts = { exclude_response_fields: ["rubric"] }
        json = api.assignment_json(assignment, user, session, opts)
        expect(json).not_to have_key "rubric"
      end

      it "excludes rubric when rubric association is not active" do
        ra = assignment.rubric_association
        ra.workflow_state = "deleted"
        ra.save!
        json = api.assignment_json(assignment, user, session)
        expect(json).not_to have_key "rubric"
      end
    end

    describe "N.Q respondus setting" do
      context "when N.Q respondus setting is on" do
        before do
          assignment.settings = {
            "lockdown_browser" => {
              "require_lockdown_browser" => true
            }
          }
          assignment.save!
        end

        it "serializes require_lockdown_browser to be true" do
          json = api.assignment_json(assignment, user, session, {})
          expect(json).to have_key("require_lockdown_browser")
          expect(json["require_lockdown_browser"]).to be_truthy
        end
      end

      context "when N.Q respondus setting is off" do
        before do
          assignment.settings = {
            "lockdown_browser" => {
              "require_lockdown_browser" => false
            }
          }
          assignment.save!
        end

        it "serializes require_lockdown_browser to be false" do
          json = api.assignment_json(assignment, user, session, {})
          expect(json).to have_key("require_lockdown_browser")
          expect(json["require_lockdown_browser"]).to be_falsy
        end
      end

      context "when N.Q respondus setting is off (default)" do
        it "serializes require_lockdown_browser to be false" do
          json = api.assignment_json(assignment, user, session, {})
          expect(json).to have_key("require_lockdown_browser")
          expect(json["require_lockdown_browser"]).to be_falsy
        end
      end
    end
  end

  describe "*_settings_hash methods" do
    let(:assignment) { AssignmentApiHarness.new }
    let(:test_params) do
      ActionController::Parameters.new({
                                         "turnitin_settings" => {},
                                         "vericite_settings" => {}
                                       })
    end

    it "#turnitin_settings_hash returns a Hash with indifferent access" do
      turnitin_hash = assignment.turnitin_settings_hash(test_params)
      expect(turnitin_hash).to be_instance_of(HashWithIndifferentAccess)
    end

    it "#vericite_settings_hash returns a Hash with indifferent access" do
      vericite_hash = assignment.vericite_settings_hash(test_params)
      expect(vericite_hash).to be_instance_of(HashWithIndifferentAccess)
    end
  end

  describe "#assignment_editable_fields_valid?" do
    let(:user) { Object.new }
    let(:course) { Course.new }
    let(:assignment) do
      Assignment.new do |a|
        a.title = "foo"
        a.submission_types = "online"
        a.course = course
      end
    end

    context "given a user who is an admin" do
      before do
        expect(course).to receive(:account_membership_allows).and_return(true)
      end

      it "is valid when user is an account admin" do
        expect(subject).to be_assignment_editable_fields_valid(assignment, user)
      end
    end

    context "given a user who is not an admin" do
      before do
        expect(assignment.course).to receive(:account_membership_allows).and_return(false)
      end

      it "is valid when not in a closed grading period" do
        expect(assignment).to receive(:in_closed_grading_period?).and_return(false)
        expect(subject).to be_assignment_editable_fields_valid(assignment, user)
      end

      context "in a closed grading period" do
        let(:course) { Course.create! }
        let(:assignment) do
          course.assignments.create!(title: "First Title", submission_types: "online_quiz")
        end

        before do
          expect(assignment).to receive(:in_closed_grading_period?).and_return(true)
        end

        it "is valid when it was not gradeable and is still not gradeable " \
           "(!gradeable_was? && !gradeable?)" do
          assignment.update!(submission_types: "not_gradeable")
          assignment.submission_types = "wiki_page"
          expect(api).to be_assignment_editable_fields_valid(assignment, user)
        end

        it "is invalid when it was gradeable and is now not gradeable" do
          assignment.update!(submission_types: "online")
          assignment.title = "Changed Title"
          assignment.submission_types = "not_graded"
          expect(api).not_to be_assignment_editable_fields_valid(assignment, user)
        end

        it "is invalid when it was not gradeable and is now gradeable" do
          assignment.update!(submission_types: "not_gradeable")
          assignment.title = "Changed Title"
          assignment.submission_types = "online_quiz"
          expect(api).not_to be_assignment_editable_fields_valid(assignment, user)
        end

        it "is invalid when it was gradeable and is still gradeable" do
          assignment.update!(submission_types: "on_paper")
          assignment.title = "Changed Title"
          assignment.submission_types = "online_upload"
          expect(api).not_to be_assignment_editable_fields_valid(assignment, user)
        end

        it "detects changes to title and responds with those errors on the name field" do
          assignment.title = "Changed Title"
          expect(api).not_to be_assignment_editable_fields_valid(assignment, user)
          expect(assignment.errors).to include :name
        end

        it "is valid if description changed" do
          assignment.description = "changing the description is allowed!"
          expect(api).to be_assignment_editable_fields_valid(assignment, user)
          expect(assignment.errors).to be_empty
        end

        it "is valid if submission_types changed" do
          assignment.submission_types = "on_paper"
          expect(api).to be_assignment_editable_fields_valid(assignment, user)
        end

        it "is valid if peer_reviews changed" do
          assignment.toggle(:peer_reviews)
          expect(api).to be_assignment_editable_fields_valid(assignment, user)
        end

        it "is valid if peer_review_count changed" do
          assignment.peer_review_count = 500
          expect(api).to be_assignment_editable_fields_valid(assignment, user)
        end

        it "is valid if time_zone_edited changed" do
          assignment.time_zone_edited = "Some New Time Zone"
          expect(api).to be_assignment_editable_fields_valid(assignment, user)
        end

        it "is valid if anonymous_peer_reviews changed" do
          assignment.toggle(:anonymous_peer_reviews)
          expect(api).to be_assignment_editable_fields_valid(assignment, user)
        end

        it "is valid if peer_reviews_due_at changed" do
          assignment.peer_reviews_due_at = Time.zone.now
          expect(api).to be_assignment_editable_fields_valid(assignment, user)
        end

        it "is valid if automatic_peer_reivews changed" do
          assignment.toggle(:automatic_peer_reviews)
          expect(api).to be_assignment_editable_fields_valid(assignment, user)
        end

        it "is valid if allowed_extensions changed" do
          assignment.allowed_extensions = ["docx"]
          expect(api).to be_assignment_editable_fields_valid(assignment, user)
        end
      end
    end
  end

  describe "update lockdown browser settings" do
    let(:course) { Course.create! }
    let(:teacher) { course.enroll_teacher(User.create!, enrollment_state: "active").user }

    let(:initial_lockdown_browser_params) do
      ActionController::Parameters.new({
                                         "require_lockdown_browser" => "true",
                                         "require_lockdown_browser_for_results" => "false",
                                         "require_lockdown_browser_monitor" => "true",
                                         "lockdown_browser_monitor_data" => "some monitor data",
                                         "access_code" => "magggic code"
                                       })
    end

    let(:lockdown_browser_params) do
      ActionController::Parameters.new({
                                         "require_lockdown_browser_for_results" => "true",
                                         "lockdown_browser_monitor_data" => "some monitor data cchanges",
                                         "access_code" => "magggic coddddde"
                                       })
    end

    let(:assignment) do
      course.assignments.create!(
        title: "hi",
        moderated_grading: true,
        grader_count: 1,
        final_grader: teacher
      )
    end

    before do
      allow(course).to receive(:account_membership_allows).and_return(false)
    end

    it "creates and updates lockdown browser settings" do
      api.update_api_assignment(assignment, initial_lockdown_browser_params, teacher)
      expect(assignment.settings["lockdown_browser"]).to eq(
        "require_lockdown_browser" => true,
        "require_lockdown_browser_for_results" => false,
        "require_lockdown_browser_monitor" => true,
        "lockdown_browser_monitor_data" => "some monitor data",
        "access_code" => "magggic code"
      )

      api.update_api_assignment(assignment, lockdown_browser_params, teacher)
      expect(assignment.settings["lockdown_browser"]).to eq(
        "require_lockdown_browser" => true,
        "require_lockdown_browser_for_results" => true,
        "require_lockdown_browser_monitor" => true,
        "lockdown_browser_monitor_data" => "some monitor data cchanges",
        "access_code" => "magggic coddddde"
      )
    end
  end

  describe "Updating submission type" do
    let(:user) { user_model }
    let(:course) { course_factory }
    let(:student) { course.enroll_student(User.create!, enrollment_state: "active").user }
    let(:assignment_update_params) do
      ActionController::Parameters.new(
        name: "Edited name",
        submission_types: ["on_paper"]
      )
    end

    context "when the assignment does not have student submissions" do
      it "allows updating the submission_types field" do
        expect(assignment.submissions.having_submission.count).to eq 0
        expect(assignment.submission_types).to eq "none"

        response = api.update_api_assignment(assignment, assignment_update_params, user)

        expect(response).to eq :ok
        expect(assignment.submission_types).to eq "on_paper"
      end
    end

    context "when the assignment is an external tool do not allow peer reviews" do
      before do
        assignment.update!(peer_reviews: true)
      end

      let(:assignment_update_params) do
        ActionController::Parameters.new(
          name: "Edited name",
          submission_types: ["external_tool"],
          peer_reviews: true
        )
      end

      it "allows updating the submission_types field" do
        expect(assignment.external_tool?).to eq false

        response = api.update_api_assignment(assignment, assignment_update_params, user)

        expect(response).to eq :ok
        expect(assignment.external_tool?).to eq true
        expect(assignment.peer_reviews).to eq false
      end
    end

    context 'when an assignment with submission type other than "online_quiz" has one student submission' do
      before do
        assignment.submit_homework(student, body: "my homework")
      end

      it "allows updating the submission_types field" do
        expect(assignment.submissions.having_submission.count).to eq 1

        response = api.update_api_assignment(assignment, assignment_update_params, user)

        expect(response).to eq :ok
        expect(assignment.submission_types).to eq "on_paper"
      end
    end

    context 'when an assignment with submission type "online - text entry" has one student submission' do
      before do
        assignment.update!(submission_types: "online_text_entry")
        assignment.submit_homework(student, body: "my homework")
      end

      let(:assignment_update_params) do
        ActionController::Parameters.new(
          name: "Edited name",
          submission_types: ["online_url", "online_upload"]
        )
      end

      it "allows updating the submission entry options" do
        expect(assignment.submissions.having_submission.count).to eq 1

        response = api.update_api_assignment(assignment, assignment_update_params, user)

        expect(response).to eq :ok
        expect(assignment.submission_types).to eq "online_url,online_upload"
      end
    end

    context 'when an assignment with submission type "online_quiz" has one student submission' do
      before do
        assignment.update!(submission_types: "online_quiz")
        assignment.submit_homework(student, body: "my homework")
      end

      it "does not allow updating the submission_types field" do
        expect(assignment.submissions.having_submission.count).to eq 1

        response = api.update_api_assignment(assignment, assignment_update_params, user)

        expect(response).to eq :ok
        expect(assignment.submission_types).to eq "online_quiz"
      end

      it "allows updating other fields" do
        expect(assignment.submissions.having_submission.count).to eq 1

        response = api.update_api_assignment(assignment, assignment_update_params, user)

        expect(response).to eq :ok
        expect(assignment.name).to eq "Edited name"
      end
    end
  end

  describe "update with the 'duplicated_successfully' parameter" do
    let(:user) { user_model }
    let(:assignment) { assignment_model(workflow_state: workflow_state, duplicate_of: original_assignment) }

    let(:assignment_update_params) do
      ActionController::Parameters.new(
        # the 'duplicated_successfully' param is provided by Quiz LTI
        # and triggers the .finish_duplicating action on the assignment
        duplicated_successfully: true
      )
    end

    shared_examples "retains the original publication state" do
      ["published", "unpublished"].each do |original_state|
        context "the orignal assignment state is '#{original_state}'" do
          let(:original_assignment) { assignment_model(workflow_state: original_state) }

          it "sets workflow_state to '#{original_state}'" do
            expect do
              api.update_api_assignment(assignment, assignment_update_params, user)
            end.to change { assignment.workflow_state }.to(original_state)
          end
        end
      end
    end
    shared_examples "falls back to 'unpublished' state" do
      context "when the original assignment state is other than 'published' or 'unpublished'" do
        let(:original_assignment) { assignment_model }

        before do
          original_assignment.update!(workflow_state: "importing")
        end

        it "sets workflow_state to 'unpublished'" do
          expect do
            api.update_api_assignment(assignment, assignment_update_params, user)
          end.to change { assignment.workflow_state }.to("unpublished")
        end
      end

      context "when duplicate_of is nil" do
        let(:original_assignment) { nil }

        it "sets workflow_state to 'unpublished'" do
          expect do
            api.update_api_assignment(assignment, assignment_update_params, user)
          end.to change { assignment.workflow_state }.to("unpublished")
        end
      end
    end

    context "when workflow_state is 'duplicating'" do
      let(:workflow_state) { "duplicating" }

      include_examples "retains the original publication state"
      include_examples "falls back to 'unpublished' state"
    end

    context "when workflow_state is 'failed_to_duplicate'" do
      let(:workflow_state) { "failed_to_duplicate" }

      include_examples "retains the original publication state"
      include_examples "falls back to 'unpublished' state"
    end

    context "when workflow_state is other that 'duplicating' or 'failed_to_duplicate'" do
      let(:original_assignment) { assignment_model(workflow_state: "published") }
      let(:workflow_state) { "failed_to_migrate" }

      it "does not transition to another state" do
        expect do
          api.update_api_assignment(assignment, assignment_update_params, user)
        end.to_not change { assignment.workflow_state }
      end
    end

    context "when there are submissions for the assignment" do
      let(:original_assignment) { assignment_model(workflow_state: "unpublished") }
      let(:workflow_state) { "duplicating" }

      before do
        allow(assignment).to receive(:has_student_submissions?).and_return(true)
      end

      it "sets workflow_state to 'published' regardless of the original assignment state" do
        api.update_api_assignment(assignment, assignment_update_params, user)

        expect(assignment.duplicate_of.workflow_state).to eq "unpublished"
        expect(assignment.workflow_state).to eq "published"
      end
    end
  end

  describe "#update_api_assignment" do
    subject { api.update_api_assignment(assignment, assignment_update_params, user) }

    let(:user) { user_model }

    context "when param[force_updated_at] is true" do
      let(:assignment_update_params) do
        ActionController::Parameters.new(
          force_updated_at: true
        )
      end

      context "and no assignment changes are made" do
        it "sets updated_at" do
          expect { subject }.to change { assignment.updated_at }
        end
      end
    end

    context "when param[force_updated_at] is false" do
      let(:assignment_update_params) do
        ActionController::Parameters.new(
          force_updated_at: false
        )
      end

      context "and no assignment changes are made" do
        it "does not set updated_at" do
          expect { subject }.not_to change { assignment.updated_at }
        end
      end

      context "and assignment changes are made" do
        before do
          assignment_update_params.merge!(name: "new-name62183")
        end

        it "sets updated_at" do
          expect { subject }.to change { assignment.updated_at }
        end
      end
    end
  end
end
