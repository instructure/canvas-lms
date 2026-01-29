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
#

require_relative "../apis/api_spec_helper"
require "feature_flag_helper"

describe OutcomeResultsController do
  include FeatureFlagHelper

  def context_outcome(context)
    @outcome_group = context.root_outcome_group
    @outcome = context.created_learning_outcomes.create!(title: "outcome")
    @outcome_group.add_outcome(@outcome)
  end

  def create_outcomes(context, num_outcomes)
    @outcome_group = context.root_outcome_group
    @outcomes = []
    outcome_ids = []
    (1..num_outcomes).each do |i|
      title = "outcome #{i}"
      outcome = context.created_learning_outcomes.create!(title:)
      @outcome_group.add_outcome(outcome)
      @outcomes.append(outcome)
      outcome_ids.append(outcome["id"])
    end

    # Return a list of outcome id's for convenience
    outcome_ids
  end

  def create_outcome_groups_with_one_outcome(context, num_groups)
    content_tags = []
    root_learning_outcome_group_id = context.root_outcome_group.id
    root_account_id = context.root_account_id

    # Make outcomes
    outcomes = (1..num_groups).map do |i|
      {
        context_id: context.id,
        context_type: "Course",
        short_description: "Outcome #{i}",
        workflow_state: "active",
        root_account_ids: [root_account_id]
      }
    end
    outcome_ids = LearningOutcome.upsert_all(outcomes).rows.flatten

    # Make outcome groups
    outcome_groups = (1..num_groups).map do |i|
      {
        context_id: context.id,
        context_type: "Course",
        title: "Group #{i}",
        workflow_state: "active",
        root_learning_outcome_group_id:,
        root_account_id:
      }
    end
    group_ids = LearningOutcomeGroup.upsert_all(outcome_groups).rows.flatten

    # Create content tags to link outcomes to outcome groups
    group_ids.each_with_index do |group_id, index|
      content_tags.append({
                            context_id: context.id,
                            context_type: "Course",
                            tag_type: "learning_outcome_association",
                            content_id: outcome_ids[index],
                            content_type: "LearningOutcome",
                            associated_asset_id: group_id,
                            associated_asset_type: "LearningOutcomeGroup",
                            workflow_state: "active",
                            root_account_id:
                          })
    end
    content_tag_ids = ContentTag.upsert_all(content_tags).rows.flatten

    # Return all id arrays for test use
    [outcome_ids, group_ids, content_tag_ids]
  end

  before :once do
    @account = Account.default
    account_admin_user
  end

  let_once(:outcome_course) do
    course_factory(active_all: true)
    @course
  end

  let_once(:outcome_teacher) do
    teacher_in_course(active_all: true, course: outcome_course)
    @teacher
  end

  let_once(:outcome_student) do
    student_in_course(active_all: true, course: outcome_course, name: "Zebra Animal")
    @student
  end

  let_once(:observer) do
    observer_in_course(active_all: true, course: outcome_course, name: "Observer")
    @observer
  end

  let_once(:outcome_rubric) do
    create_outcome_rubric
  end

  let_once(:outcome_assignment) do
    assignment = create_outcome_assignment
    find_or_create_outcome_submission(assignment:)
    assignment
  end

  let_once(:outcome_rubric_association) do
    create_outcome_rubric_association
  end

  let_once(:outcome_result) do
    create_result(@student.id, @outcome, outcome_assignment, 3)
  end

  let(:outcome_criterion) do
    find_outcome_criterion
  end

  def create_result(user_id, outcome, assignment, score, opts = {})
    rubric_association = outcome_rubric.associate_with(outcome_assignment, outcome_course, purpose: "grading")

    LearningOutcomeResult.new(
      user_id:,
      score:,
      alignment: ContentTag.create!({
                                      title: "content",
                                      context: outcome_course,
                                      learning_outcome: outcome,
                                      content_type: "Assignment",
                                      content_id: assignment.id
                                    }),
      **opts
    ).tap do |lor|
      lor.association_object = rubric_association
      lor.context = outcome_course
      lor.save!
    end
  end

  def find_or_create_outcome_submission(opts = {})
    student = opts[:student] || outcome_student
    assignment = opts[:assignment] ||
                 (create_outcome_assignment if opts[:new]) ||
                 outcome_assignment
    assignment.find_or_create_submission(student)
  end

  def create_outcome_assessment(opts = {})
    association = (create_outcome_rubric_association(opts) if opts[:new]) ||
                  outcome_rubric_association
    criterion = find_outcome_criterion(association.rubric)
    submission = opts[:submission] || find_or_create_outcome_submission(opts)
    student = submission.student
    points = opts[:points] ||
             find_first_rating(criterion)[:points]
    association.assess(
      user: student,
      assessor: outcome_teacher,
      artifact: submission,
      assessment: {
        assessment_type: "grading",
        "criterion_#{criterion[:id]}": {
          points:
        }
      }
    )
  end

  def create_outcome_rubric
    outcome_course
    outcome_with_rubric(mastery_points: 3)
    @outcome.rubric_criterion = find_outcome_criterion(@rubric)
    @outcome.save
    @rubric
  end

  def create_outcome_assignment
    outcome_course.assignments.create!(
      title: "outcome assignment",
      description: "this is an outcome assignment",
      points_possible: outcome_rubric.points_possible
    )
  end

  def create_outcome_rubric_association(opts = {})
    rubric = (create_outcome_rubric if opts[:new]) ||
             outcome_rubric
    assignment = (create_outcome_assignment if opts[:new]) ||
                 outcome_assignment
    rubric.associate_with(assignment, outcome_course, purpose: "grading", use_for_grading: true)
  end

  def find_outcome_criterion(rubric = outcome_rubric)
    rubric.criteria.find { |c| !c[:learning_outcome_id].nil? }
  end

  def find_first_rating(criterion = outcome_criterion)
    criterion[:ratings].first
  end

  def parse_response(response)
    JSON.parse(response.body)
  end

  def mock_os_api_results(user_uuid, outcome_id, associated_asset_id, score, points, points_possible, submitted_at)
    {
      user_uuid:,
      percent_score: score,
      points:,
      points_possible:,
      external_outcome_id: outcome_id,
      submitted_at:,
      attempts: [{ id: 1,
                   authoritative_result_id: 1,
                   points:,
                   points_possible:,
                   event_created_at: Time.zone.now,
                   event_updated_at: Time.zone.now,
                   deleted_at: nil,
                   created_at: Time.zone.now,
                   updated_at: Time.zone.now,
                   metadata: { quiz_metadata: { title: "Quiz Title",
                                                points:,
                                                quiz_id: "1",
                                                points_possible: } },
                   submitted_at:,
                   attempt_number: 1 }],
      associated_asset_type: "canvas.assignment.quizzes",
      associated_asset_id:,
      artifact_type: "quizzes.quiz",
      artifact_id: "1",
      mastery: nil
    }
  end

  def mock_os_lor_results(user, outcome, assignment, score, args = {})
    title = "#{user.name}, #{assignment.name}"
    mastery = (score || 0) >= outcome.mastery_points
    submitted_at = args[:submitted_at] || Time.zone.now
    submission = Submission.find_by(user_id: user.id, assignment_id: assignment.id)
    alignment = ContentTag.create!(
      {
        title: "content",
        context: outcome_course,
        learning_outcome: outcome,
        content_type: "Assignment",
        content_id: assignment.id
      }
    )
    lor = LearningOutcomeResult.new(
      learning_outcome: outcome,
      user:,
      context: outcome_course,
      alignment:,
      artifact: submission,
      associated_asset: assignment,
      title:,
      score:,
      possible: outcome.points_possible,
      mastery:,
      created_at: submitted_at,
      updated_at: submitted_at,
      submitted_at:,
      assessed_at: submitted_at
    )
    if args[:include_rubric]
      lor.association_type = "RubricAssociation"
      lor.association_id = outcome_rubric.id
    end
    lor
  end

  def get_results(params)
    get "index",
        params: {
          context_id: @course.id,
          course_id: @course.id,
          context_type: "Course",
          user_ids: [@student.id],
          outcome_ids: [@outcome.id],
          **params
        },
        format: "json"
  end

  def get_linked_users(rollups)
    rollups.pluck("links")
  end

  describe "retrieving outcome results" do
    it "does not have a false failure if an outcome exists in two places within the same context" do
      user_session(@teacher)
      outcome_group = @course.root_outcome_group.child_outcome_groups.build(
        title: "Child outcome group", context: @course
      )
      outcome_group.save!
      outcome_group.add_outcome(@outcome)
      get "rollups",
          params: { context_id: @course.id,
                    course_id: @course.id,
                    context_type: "Course",
                    user_ids: [@student.id],
                    outcome_ids: [@outcome.id] },
          format: "json"
      expect(response).to be_successful
    end

    it "allows specifying both outcome_ids and include[]=outcome_links" do
      user_session(@teacher)
      context_outcome(@course)
      get "rollups",
          params: { context_id: @course.id,
                    course_id: @course.id,
                    context_type: "Course",
                    user_ids: [@student.id],
                    outcome_ids: [@outcome.id],
                    include: ["outcome_links"] },
          format: "json"
      expect(response).to be_successful
      json = parse_response(response)
      links = json["linked"]["outcome_links"]
      expect(links.length).to eq 1
      expect(links[0]["outcome"]["id"]).to eq @outcome.id
    end

    describe "retrieving outcome rollups with outcome_ids" do
      before do
        @student1 = @student
        @student2 = student_in_course(active_all: true, course: outcome_course, name: "Amy Mammoth").user
        @student3 = student_in_course(active_all: true, course: outcome_course, name: "Barney Youth").user

        create_result(@student2.id, @outcome, outcome_assignment, 1)
      end

      before do
        user_session(@teacher)
      end

      it "returns correct filtered results when providing outcome_ids" do
        get "rollups",
            params: { course_id: @course.id,
                      outcome_ids: @outcome.id },
            format: "json"
        expect(response).to be_successful
        hash = parse_response(response)
        expect(hash["rollups"][0]["scores"][0]["links"]["outcome"].to_i).to eq @outcome.id
        expect(hash["rollups"][1]["scores"][0]["links"]["outcome"].to_i).to eq @outcome.id
      end
    end

    describe "retrieving outcome alignments" do
      before do
        assessment_question_bank_with_questions
        @outcome.align(@bank, @bank.context, mastery_score: 0.7)

        @quiz = @course.quizzes.create!(title: "a quiz")
        @quiz.add_assessment_questions [@q1, @q2]

        @submission = @quiz.generate_submission @student
        @submission.quiz_data = @quiz.generate_quiz_data
        @submission.mark_completed
        Quizzes::SubmissionGrader.new(@submission).grade_submission

        user_session(@teacher)
      end

      it "returns question bank alignments" do
        get "rollups",
            params: { course_id: @course.id,
                      include: ["alignments"] },
            format: "json"
        expect(response).to be_successful
        json = parse_response(response)
        alignments = json["linked"]["alignments"]
        expect(alignments.length).to eq 2
        expect(alignments.pluck("name")).to include("Test Bank")
      end
    end

    describe "retrieving outcome group_id" do
      it "returns group_id for each outcome in the response" do
        user_session(@teacher)
        outcome_group = @course.root_outcome_group.child_outcome_groups.create!(title: "Test Group", context: @course)
        outcome1 = @course.created_learning_outcomes.create!(title: "outcome 1")
        outcome_group.add_outcome(outcome1)

        get "rollups",
            params: { course_id: @course.id,
                      include: ["outcomes"] },
            format: "json"
        expect(response).to be_successful
        json = parse_response(response)
        outcomes = json["linked"]["outcomes"]

        outcome_json = outcomes.find { |o| o["id"] == outcome1.id }
        expect(outcome_json).not_to be_nil
        expect(outcome_json["group_id"]).to eq outcome_group.id.to_s
      end

      it "includes group_id for outcomes in root group" do
        user_session(@teacher)
        root_group = @course.root_outcome_group

        get "rollups",
            params: { course_id: @course.id,
                      include: ["outcomes"] },
            format: "json"
        expect(response).to be_successful
        json = parse_response(response)
        outcomes = json["linked"]["outcomes"]

        # @outcome is added to root_outcome_group in context_outcome helper
        outcome_json = outcomes.find { |o| o["id"] == @outcome.id }
        expect(outcome_json).not_to be_nil
        expect(outcome_json["group_id"]).to eq root_group.id.to_s
      end
    end

    it "validates aggregate_stat parameter" do
      user_session(@teacher)
      get "rollups",
          params: { context_id: @course.id,
                    course_id: @course.id,
                    context_type: "Course",
                    aggregate: "course",
                    aggregate_stat: "powerlaw" },
          format: "json"
      expect(response).not_to be_successful
    end

    context "student lmgb usage tracking" do
      def fetch_student_lmgb_data
        get "rollups",
            params: { context_id: @course.id,
                      course_id: @course.id,
                      context_type: "Course",
                      user_ids: [@student.id],
                      outcome_ids: [@outcome.id] },
            format: "json"
      end

      it "increments statsd if a student is viewing their own sLMGB results" do
        allow(InstStatsd::Statsd).to receive(:distributed_increment)
        user_session(@student)
        fetch_student_lmgb_data
        expect(response).to be_successful
        expect(InstStatsd::Statsd).to have_received(:distributed_increment).with(
          "outcomes_page_views",
          tags: { type: "student_lmgb" }
        ).once
      end

      it "increments statsd if an observer is viewing a linked student\"s sLMGB results" do
        @observer.enrollments.find_by(course_id: @course.id).update!(associated_user_id: @student)
        allow(InstStatsd::Statsd).to receive(:distributed_increment)
        user_session(@observer)
        fetch_student_lmgb_data
        expect(response).to be_successful
        expect(InstStatsd::Statsd).to have_received(:distributed_increment).with(
          "outcomes_page_views",
          tags: { type: "student_lmgb" }
        ).once
      end

      it "doesnt increment statsd if an observer is viewing a non-linked student\"s sLMGB results" do
        allow(InstStatsd::Statsd).to receive(:distributed_increment)
        user_session(@observer)
        fetch_student_lmgb_data
        expect(response).not_to be_successful
        expect(InstStatsd::Statsd).not_to have_received(:distributed_increment).with(
          "outcomes_page_views",
          tags: { type: "student_lmgb" }
        )
      end

      it "doesnt increment a statsd if a teacher is viewing a student\"s sLMGB results" do
        allow(InstStatsd::Statsd).to receive(:distributed_increment)
        user_session(@teacher)
        fetch_student_lmgb_data
        expect(response).to be_successful
        expect(InstStatsd::Statsd).not_to have_received(:distributed_increment).with(
          "outcomes_page_views",
          tags: { type: "student_lmgb" }
        )
      end
    end

    context "with manual post policy assignment" do
      before do
        outcome_assignment.ensure_post_policy(post_manually: true)
      end

      it "teacher should see result" do
        user_session(@teacher)
        get "index",
            params: { context_id: @course.id,
                      course_id: @course.id,
                      context_type: "Course",
                      user_ids: [@student.id],
                      outcome_ids: [@outcome.id] },
            format: "json"
        json = response.parsed_body
        expect(json["outcome_results"].length).to eq 1
      end

      it "student should not see result" do
        user_session(@student)
        get "index",
            params: { context_id: @course.id,
                      course_id: @course.id,
                      context_type: "Course",
                      user_ids: [@student.id],
                      outcome_ids: [@outcome.id] },
            format: "json"
        json = parse_response(response)
        expect(json["outcome_results"].length).to eq 0
      end
    end

    context "with auto post policy (default) assignment" do
      before do
        outcome_assignment.ensure_post_policy(post_manually: false)
      end

      it "teacher should see result" do
        user_session(@teacher)
        get "index",
            params: { context_id: @course.id,
                      course_id: @course.id,
                      context_type: "Course",
                      user_ids: [@student.id],
                      outcome_ids: [@outcome.id] },
            format: "json"
        json = response.parsed_body
        expect(json["outcome_results"].length).to eq 1
      end

      it "student should see result" do
        user_session(@student)
        get "index",
            params: { context_id: @course.id,
                      course_id: @course.id,
                      context_type: "Course",
                      user_ids: [@student.id],
                      outcome_ids: [@outcome.id] },
            format: "json"
        json = parse_response(response)
        expect(json["outcome_results"].length).to eq 1
      end
    end

    it "exclude missing user rollups" do
      user_session(@teacher)
      # save a reference to the 1st student
      student1 = @student
      # create a 2nd student that is saved as @student
      student_in_course(active_all: true, course: outcome_course)
      get "rollups",
          params: { context_id: @course.id,
                    course_id: @course.id,
                    context_type: "Course",
                    user_ids: [student1.id, @student.id],
                    outcome_ids: [@outcome.id],
                    exclude: ["missing_user_rollups"] },
          format: "json"
      json = parse_response(response)
      # the rollups requests for both students, but excludes the 2nd student
      # since they do not have any results, unlike the 1st student,
      # which has a single result in `outcome_result`
      expect(json["rollups"].length).to be 1

      # the pagination count should be 1 for the one student with a rollup
      expect(json["meta"]["pagination"]["count"]).to be 1
    end

    it "exclude outcomes without results" do
      user_session(@teacher)

      outcome1 = @outcome
      outcome2 = outcome_model(context: outcome_course)
      # Explicitly create a result for outcome1 to ensure it has results
      create_result(@student.id, outcome1, outcome_assignment, 3)
      get "rollups",
          params: { context_id: @course.id,
                    course_id: @course.id,
                    context_type: "Course",
                    user_ids: [@student.id],
                    outcome_ids: [outcome1.id, outcome2.id],
                    exclude: ["missing_outcome_results"],
                    include: ["outcomes"] },
          format: "json"
      json = parse_response(response)
      # should only include the outcome with results (outcome1)
      # and exclude outcome2 which has no results
      outcome_ids = json["linked"]["outcomes"].pluck("id")
      expect(outcome_ids).to include(outcome1.id)
      expect(outcome_ids).not_to include(outcome2.id)
      expect(json["linked"]["outcomes"].length).to be 1
    end

    context "user lmgb outcome orderings" do
      def get_response_ordering(outcomes)
        outcomes.pluck("id")
      end

      def set_lmgb_outcome_order(root_account_id, user_id, course_id, outcome_ids)
        outcome_position_map = create_outcome_position_map(outcome_ids)
        UserLmgbOutcomeOrderings.set_lmgb_outcome_ordering(root_account_id, user_id, course_id, outcome_position_map)
      end

      def create_outcome_position_map(outcome_ids)
        entries = []
        outcome_ids.each_with_index do |id, index|
          entry = { "outcome_id" => id, "position" => index }
          entries.append(entry)
        end
        entries
      end

      def set_outcome_arrangement(arrangement, user: @teacher, course: @course)
        user.set_preference(:learning_mastery_gradebook_settings, course.global_id, { "outcome_arrangement" => arrangement })
      end

      it "set ordering through API endpoint" do
        user_session(@teacher)
        outcome_ids = create_outcomes(@course, 3)
        outcome_ids.unshift(@outcome.id)
        outcome_position_map = create_outcome_position_map(outcome_ids)

        post "outcome_order",
             params: { course_id: @course.id, },
             body: outcome_position_map.to_json,
             as: :json

        set_outcome_arrangement("custom")

        get "rollups",
            params: { context_id: @course.id,
                      course_id: @course.id,
                      context_type: "Course",
                      user_outcome_ordering: "true",
                      include: ["outcomes"] },
            format: "json"
        json = response.parsed_body
        response_outcomes = json["linked"]["outcomes"]
        response_outcomes_ordering = get_response_ordering(response_outcomes)
        expect(response_outcomes_ordering).to eq(outcome_ids)
      end

      it "ordering request is rejected without manage_grade rights" do
        user_session(@student)
        outcome_ids = create_outcomes(@course, 3)
        outcome_ids.unshift(@outcome.id)
        outcome_position_map = create_outcome_position_map(outcome_ids)

        post "outcome_order",
             params: { course_id: @course.id, },
             body: outcome_position_map.to_json,
             as: :json

        json = response.parsed_body
        expect(json["status"]).to eq("forbidden")
        expect(json["message"]).to eq("users not specified and no access to all grades")
      end

      it "ordering request is rejected if user is not enrolled in course or site admin" do
        second_course = course_factory

        user_session(@teacher)
        outcome_position_map = create_outcome_position_map([1, 2, 3, 4])

        # Second teacher is trying to reorder outcomes for a course they do not belong to
        post "outcome_order",
             params: { course_id: second_course.id, },
             body: outcome_position_map.to_json,
             as: :json

        json = response.parsed_body
        expect(json["status"]).to eq("forbidden")
        expect(json["message"]).to eq("users not specified and no access to all grades")
      end

      it "outcomes ordered correctly when loading rollups" do
        user_session(@teacher)
        outcome_ids = create_outcomes(@course, 3)
        outcome_ids.unshift(@outcome.id)
        set_lmgb_outcome_order(@course.root_account_id, @teacher.id, @course.id, outcome_ids)

        set_outcome_arrangement("custom")

        get "rollups",
            params: { context_id: @course.id,
                      course_id: @course.id,
                      context_type: "Course",
                      user_outcome_ordering: "true",
                      include: ["outcomes"] },
            format: "json"
        json = response.parsed_body
        response_outcomes = json["linked"]["outcomes"]
        response_outcomes_ordering = get_response_ordering(response_outcomes)
        expect(response_outcomes_ordering).to eq(outcome_ids)
      end

      it "outcomes ordered correctly when reordered before loading rollups" do
        user_session(@teacher)
        outcome_ids = create_outcomes(@course, 3)
        outcome_ids.unshift(@outcome.id)

        # Reorder two outcomes in list and save
        outcome_ids[1], outcome_ids[2] = outcome_ids[2], outcome_ids[1]
        set_lmgb_outcome_order(@course.root_account_id, @teacher.id, @course.id, outcome_ids)

        set_outcome_arrangement("custom")

        get "rollups",
            params: { context_id: @course.id,
                      course_id: @course.id,
                      context_type: "Course",
                      user_outcome_ordering: "true",
                      include: ["outcomes"] },
            format: "json"
        json = response.parsed_body
        response_outcomes = json["linked"]["outcomes"]
        response_outcomes_ordering = get_response_ordering(response_outcomes)
        expect(response_outcomes_ordering).to eq(outcome_ids)
      end

      it "outcomes ordered correctly when an outcome is deleted before loading rollups" do
        user_session(@teacher)
        outcome_ids = create_outcomes(@course, 3)
        outcome_ids.unshift(@outcome.id)

        # Save outcome ordering and then delete an outcome
        set_lmgb_outcome_order(@course.root_account_id, @teacher.id, @course.id, outcome_ids)
        outcome_ids = outcome_ids.reject { |o| o == @outcomes[0]["id"] }
        @outcomes[0].destroy!

        set_outcome_arrangement("custom")

        get "rollups",
            params: { context_id: @course.id,
                      course_id: @course.id,
                      context_type: "Course",
                      user_outcome_ordering: "true",
                      include: ["outcomes"] },
            format: "json"
        json = response.parsed_body
        response_outcomes = json["linked"]["outcomes"]
        response_outcomes_ordering = get_response_ordering(response_outcomes)
        expect(response_outcomes_ordering).to eq(outcome_ids)
      end

      it "outcomes ordered correctly when an outcome is added before loading rollups" do
        user_session(@teacher)
        outcome_ids = create_outcomes(@course, 3)
        outcome_ids.unshift(@outcome.id)

        # Save outcome ordering and then add an outcome
        set_lmgb_outcome_order(@course.root_account_id, @teacher.id, @course.id, outcome_ids)
        outcome = @course.created_learning_outcomes.create!(title: "outcome after lmgb order set")
        @outcome_group.add_outcome(outcome)
        outcome_ids.append(outcome["id"])

        set_outcome_arrangement("custom")

        get "rollups",
            params: { context_id: @course.id,
                      course_id: @course.id,
                      context_type: "Course",
                      user_outcome_ordering: "true",
                      include: ["outcomes"] },
            format: "json"
        json = response.parsed_body
        response_outcomes = json["linked"]["outcomes"]
        response_outcomes_ordering = get_response_ordering(response_outcomes)
        expect(response_outcomes_ordering).to eq(outcome_ids)
      end

      context "outcome arrangement sorting" do
        it "sorts outcomes alphabetically when arrangement is set to alphabetical" do
          user_session(@teacher)

          outcome_a = @course.created_learning_outcomes.create!(title: "A Outcome")
          outcome_c = @course.created_learning_outcomes.create!(title: "C Outcome")
          outcome_b = @course.created_learning_outcomes.create!(title: "B Outcome")
          @outcome_group.add_outcome(outcome_a)
          @outcome_group.add_outcome(outcome_c)
          @outcome_group.add_outcome(outcome_b)

          set_outcome_arrangement("alphabetical")

          get "rollups",
              params: { context_id: @course.id,
                        course_id: @course.id,
                        context_type: "Course",
                        include: ["outcomes"] },
              format: "json"

          json = response.parsed_body
          response_outcomes = json["linked"]["outcomes"]
          outcome_titles = response_outcomes.pluck("title")

          expect(outcome_titles).to eq(outcome_titles.sort_by(&:downcase))
        end

        it "sorts outcomes by custom drag & drop order when arrangement is set to custom" do
          user_session(@teacher)
          outcome_ids = create_outcomes(@course, 3)
          outcome_ids.unshift(@outcome.id)

          custom_order = [outcome_ids[2], outcome_ids[0], outcome_ids[3], outcome_ids[1]]
          set_lmgb_outcome_order(@course.root_account_id, @teacher.id, @course.id, custom_order)

          set_outcome_arrangement("custom")

          get "rollups",
              params: { context_id: @course.id,
                        course_id: @course.id,
                        context_type: "Course",
                        include: ["outcomes"] },
              format: "json"

          json = response.parsed_body
          response_outcomes = json["linked"]["outcomes"]
          response_outcomes_ordering = get_response_ordering(response_outcomes)

          expect(response_outcomes_ordering).to eq(custom_order)
        end

        it "sorts outcomes by upload order (creation time) when arrangement is set to upload_order" do
          user_session(@teacher)
          outcome_ids = create_outcomes(@course, 3)
          outcome_ids.unshift(@outcome.id)

          set_outcome_arrangement("upload_order")

          get "rollups",
              params: { context_id: @course.id,
                        course_id: @course.id,
                        context_type: "Course",
                        include: ["outcomes"] },
              format: "json"

          json = response.parsed_body
          response_outcomes = json["linked"]["outcomes"]
          response_outcomes_ordering = get_response_ordering(response_outcomes)

          expect(response_outcomes_ordering).to eq(outcome_ids.sort)
        end

        it "defaults to upload_order when no arrangement preference is set" do
          user_session(@teacher)
          outcome_ids = create_outcomes(@course, 3)
          outcome_ids.unshift(@outcome.id)

          get "rollups",
              params: { context_id: @course.id,
                        course_id: @course.id,
                        context_type: "Course",
                        include: ["outcomes"] },
              format: "json"

          json = response.parsed_body
          response_outcomes = json["linked"]["outcomes"]
          response_outcomes_ordering = get_response_ordering(response_outcomes)

          expect(response_outcomes_ordering).to eq(outcome_ids.sort)
        end

        it "places outcomes without custom position at the end when using custom arrangement" do
          user_session(@teacher)
          outcome_ids = create_outcomes(@course, 4)

          custom_order = [outcome_ids[1], outcome_ids[0]]
          set_lmgb_outcome_order(@course.root_account_id, @teacher.id, @course.id, custom_order)

          set_outcome_arrangement("custom")

          get "rollups",
              params: { context_id: @course.id,
                        course_id: @course.id,
                        context_type: "Course",
                        include: ["outcomes"] },
              format: "json"

          json = response.parsed_body
          response_outcomes = json["linked"]["outcomes"]
          response_outcomes_ordering = get_response_ordering(response_outcomes)

          expect(response_outcomes_ordering.first(2)).to eq(custom_order)
          expect(response_outcomes_ordering.last(2)).to eq([outcome_ids[2], outcome_ids[3]].sort)
        end
      end

      context "cross-shard access" do
        specs_require_sharding

        before do
          @shard1.activate do
            @shard1_account = Account.create!
            @shard1_course = course_factory(account: @shard1_account)
          end
        end

        it "ordering request is successful if site-admin user is from a different shard" do
          admin_user = nil

          @shard2.activate do
            opts = { active_user: true, account: Account.site_admin, name: "site-admin", short_name: "site-admin" }
            admin_user = Account.site_admin.account_users.create!(user: user_factory(opts)).user
          end

          @shard1.activate do
            outcome_ids = create_outcomes(@shard1_course, 3)
            position_map = create_outcome_position_map(outcome_ids)

            user_session(admin_user)

            post "outcome_order",
                 params: { course_id: @shard1_course.id, },
                 body: position_map.to_json,
                 as: :json

            expect(response.successful?).to be_truthy

            set_outcome_arrangement("custom", user: admin_user, course: @shard1_course)

            get "rollups",
                params: { context_id: @shard1_course.id,
                          course_id: @shard1_course.id,
                          context_type: "Course",
                          user_outcome_ordering: "true",
                          include: ["outcomes"] },
                format: "json"

            json = response.parsed_body
            response_outcomes = json["linked"]["outcomes"]
            response_outcomes_ordering = get_response_ordering(response_outcomes)
            expect(response_outcomes_ordering).to eq(outcome_ids)
          end
        end
      end

      context "with multiple outcome groups" do
        it "outcomes ordered correctly with large number of outcome groups" do
          user_session(@teacher)
          outcome_ids = create_outcome_groups_with_one_outcome(@course, 101)[0]
          outcome_ids.unshift(@outcome.id)

          # Swap the first and last outcomes
          outcome_ids[0], outcome_ids[101] = outcome_ids[101], outcome_ids[0]
          set_lmgb_outcome_order(@course.root_account_id, @teacher.id, @course.id, outcome_ids)

          set_outcome_arrangement("custom")

          get "rollups",
              params: { context_id: @course.id,
                        course_id: @course.id,
                        context_type: "Course",
                        user_outcome_ordering: "true",
                        include: ["outcomes"] },
              format: "json"
          json = response.parsed_body
          response_outcomes = json["linked"]["outcomes"]
          response_outcomes_ordering = get_response_ordering(response_outcomes)
          expect(response_outcomes_ordering).to eq(outcome_ids)
        end
      end
    end

    context "with outcome_service_results_to_canvas FF" do
      shared_examples "outcome results" do
        before do
          user_session(user)
          @assignment = create_outcome_assignment
          find_or_create_outcome_submission({ student:, assignment: @assignment })
          @assignment2 = create_outcome_assignment
          find_or_create_outcome_submission({ student:, assignment: @assignment2 })
        end

        context "FF enabled" do
          before do
            user_session(user)
          end

          it "no OS results found - display canvas results only" do
            create_result(student.id, @outcome, @assignment, 2, { possible: 5 })
            expect(controller).to receive(:fetch_and_convert_os_results).with(any_args).and_return(nil)
            json = parse_response(get_results({ user_ids: [student], include: ["assignments"] }))
            expect(json["outcome_results"].length).to be 1
            expect(json["linked"]["assignments"].length).to be 1
          end

          it "OS results found - no Canvas results - displays only OS results" do
            mocked_results = mock_os_lor_results(student, @outcome, @assignment2, 2)
            expect(controller).to receive(:fetch_and_convert_os_results).with(any_args).and_return(
              [mocked_results]
            )
            json = parse_response(get_results({ user_ids: [student], include: ["assignments"] }))
            expect(json["outcome_results"].length).to be 1
            expect(json["outcome_results"][0]["links"]["alignment"]).to eq("assignment_" + @assignment2.id.to_s)
            expect(json["linked"]["assignments"].length).to be 1
            expect(json["linked"]["assignments"][0]["id"]).to eq("assignment_" + @assignment2.id.to_s)
          end

          it "OS results found - display both Canvas and OS results" do
            create_result(student.id, @outcome, @assignment, 2, { possible: 5 })
            mocked_results = mock_os_lor_results(student, @outcome, @assignment2, 2)
            expect(controller).to receive(:fetch_and_convert_os_results).with(any_args).and_return(
              [mocked_results]
            )
            json = parse_response(get_results({ user_ids: [student], include: ["assignments"] }))
            expect(json["outcome_results"].length).to be 2
            expect(json["linked"]["assignments"].length).to be 2
            expect(json["linked"]["assignments"][0]["id"]).to eq("assignment_" + @assignment2.id.to_s)
            expect(json["linked"]["assignments"][1]["id"]).to eq("assignment_" + @assignment.id.to_s)
          end

          it "OS results found - assignments are unique when aligned to two outcomes" do
            outcome2 = @course.created_learning_outcomes.create!(title: "outcome 2")
            og = @course.root_outcome_group
            og.add_outcome(outcome2)
            create_result(student.id, @outcome, @assignment, 2, { possible: 5 })
            mocked_results_1 = mock_os_lor_results(student, @outcome, @assignment2, 2)
            mocked_results_2 = mock_os_lor_results(student, outcome2, @assignment2, 2)
            expect(controller).to receive(:fetch_and_convert_os_results).with(any_args).and_return(
              [mocked_results_1, mocked_results_2]
            )
            json = parse_response(get_results({ user_ids: [student], include: ["assignments"], outcome_ids: [outcome2.id, @outcome.id] }))
            expect(json["outcome_results"].length).to be 3
            expect(json["linked"]["assignments"].length).to be 2
          end

          it "OS results found - OS data is filtered correctly" do
            assignment3 = create_outcome_assignment
            find_or_create_outcome_submission({ student:, assignment: assignment3 })
            outcome2 = @course.created_learning_outcomes.create!(title: "outcome 2")
            outcome3 = @course.created_learning_outcomes.create!(title: "outcome 3")
            og = @course.root_outcome_group
            og.add_outcome(outcome2)
            og.add_outcome(outcome3)
            create_result(student.id, @outcome, @assignment, 2, { possible: 5 })
            mocked_results_1 = mock_os_lor_results(student, @outcome, @assignment2, 2)
            mocked_results_2 = mock_os_lor_results(student, outcome2, @assignment, 2)
            mocked_results_3 = mock_os_lor_results(student, outcome3, assignment3, 2)
            expect(controller).to receive(:fetch_and_convert_os_results).with(any_args).and_return(
              [mocked_results_1, mocked_results_2, mocked_results_3]
            )
            json = parse_response(get_results({ user_ids: [student], include: ["assignments"], outcome_ids: [@outcome.id] }))
            # we should get 2 result: 1 from canvas and the other from OS
            expect(json["outcome_results"].length).to be 2
            expect(json["linked"]["assignments"].length).to be 2
          end

          context 'with nil "outcome_ids" parameter' do
            subject do
              get "index", params: {
                context_id: @course.id,
                course_id: @course.id,
                context_type: "Course",
                user_ids: [@student.id]
              }

              response.parsed_body
            end

            before do
              outcome2 = @course.created_learning_outcomes.create!(title: "outcome 2")
              og = @course.root_outcome_group
              og.add_outcome(outcome2)
              create_result(student.id, @outcome, @assignment, 2, { possible: 5 })

              mocked_results_1 = mock_os_lor_results(student, @outcome, @assignment2, 2)
              mocked_results_2 = mock_os_lor_results(student, outcome2, @assignment2, 2)
              allow(controller).to receive(:fetch_and_convert_os_results).with(any_args).and_return(
                [mocked_results_1, mocked_results_2]
              )
            end

            it "returns all the results" do
              expect(subject["outcome_results"].count).to eq 3
            end

            it "has empty linked assignments in the response" do
              expect(subject.dig("linked", "assignments")).to be_nil
            end

            it "responds with a 200" do
              expect(response).to be_successful
            end
          end
        end
      end

      describe "for different users" do
        let(:student) { student_in_course(active_all: true, course: outcome_course, name: "Hello Kitty").user }

        it_behaves_like "outcome results" do
          let(:user) { student }
        end

        it_behaves_like "outcome results" do
          let(:user) { @teacher }
        end
      end
    end
  end

  describe "retrieving outcome rollups" do
    before do
      @student1 = @student
      @student2 = student_in_course(active_all: true, course: outcome_course, name: "Amy Mammoth").user
      @student3 = student_in_course(active_all: true, course: outcome_course, name: "Barney Youth").user

      create_result(@student2.id, @outcome, outcome_assignment, 1)
    end

    before do
      user_session(@teacher)
    end

    def get_rollups(params)
      get "rollups",
          params: {
            context_id: @course.id,
            course_id: @course.id,
            context_type: "Course",
            **params
          },
          format: "json"
    end

    def outcome_rollups_url(context, params = {})
      api_v1_course_outcome_rollups_url(context, params)
    end

    it "includes rating percents" do
      json = parse_response(get_rollups(rating_percents: true, include: ["outcomes"]))
      expect(json["linked"]["outcomes"][0]["ratings"].pluck("percent")).to eq [50, 50]
    end

    context "with outcome_service_results_to_canvas FF" do
      context "user_rollups" do
        context "enabled" do
          before do
            new_quizzes_assignment(course: @course, title: "new quiz")
          end

          context "caching - converted OS LearningOutcomeResults are stored" do
            it "OS results founds" do
              # removing LearningOutcomeResults for those users that have results
              # creating in the first before do after the rollups context
              student4 = student_in_course(active_all: true, course: outcome_course, name: "OS user").user
              submitted_at = Time.zone.now
              mocked_results = mock_os_api_results(student4.uuid, @outcome.id, outcome_assignment.id, "2.0", "2.0", "2.0", submitted_at)
              expect(controller).to receive(:find_outcomes_service_outcome_results).with(any_args).and_return(
                [mocked_results]
              ).once
              expect(controller).to receive(:handle_outcomes_service_results).with(any_args).once

              enable_cache do
                user_session @teacher
                get_rollups(sort_by: "student", sort_order: "desc", per_page: 5, page: 1)
                # should have one key in the cache for OS
                expect(Rails.cache.exist?(["lmgb", "context_uuid", @course.uuid, "current_user_uuid", @teacher.uuid, "account_uuid", @account.uuid])).to be_truthy
              end
            end
          end

          it "no OS results found - Canvas results found" do
            create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
            expect(controller).to receive(:fetch_and_convert_os_results).with(any_args).and_return(nil)
            json = parse_response(get_rollups(sort_by: "student", sort_order: "desc", per_page: 1, page: 1))
            expect(json["rollups"].length).to be 1
          end

          it "OS results found - no Canvas results found" do
            # removing LearningOutcomeResults for those users that have results
            # creating in the first before do after the rollups context
            LearningOutcomeResult.where(user_id: @student.id).update(workflow_state: "deleted")
            LearningOutcomeResult.where(user_id: @student1.id).update(workflow_state: "deleted")
            LearningOutcomeResult.where(user_id: @student2.id).update(workflow_state: "deleted")
            student4 = student_in_course(active_all: true, course: outcome_course, name: "OS user").user
            mocked_results = mock_os_lor_results(student4, @outcome, outcome_assignment, 2)
            expect(controller).to receive(:fetch_and_convert_os_results).with(any_args).and_return(
              [mocked_results]
            )
            json = parse_response(get_rollups(sort_by: "student", sort_order: "desc", per_page: 5, page: 1))
            # will be 4 because the exclude: "missing_user_results" parameter is not included
            # in the rollups call
            expect(json["rollups"].length).to be 4
            # need to loop through each rollup to make sure there is only 1 rollup with scores
            score_count = 0
            json["rollups"].each do |r|
              score_count += 1 unless r["scores"].empty?
            end
            expect(score_count).to be 1
          end

          it "Canvas and OS results found" do
            # already existing results for @student1 & @student2
            # creating result for @student
            create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
            # results are already created for @student2 in Canvas
            student4 = student_in_course(active_all: true, course: outcome_course, name: "OS user").user
            mocked_results = mock_os_lor_results(student4, @outcome, outcome_assignment, 2)
            expect(controller).to receive(:fetch_and_convert_os_results).with(any_args).and_return(
              [mocked_results]
            )
            json = parse_response(get_rollups(sort_by: "student", sort_order: "desc", per_page: 5, page: 1))
            expect(json["rollups"].length).to be 4
          end
        end

        context "aggregate_user_rollups" do
          context "enabled" do
            it "no OS results found - Canvas results found" do
              # already existing results for @student1 & @student2
              # creating result for @student
              create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
              expect(controller).to receive(:fetch_and_convert_os_results).with(any_args).and_return(nil)
              json = parse_response(get_rollups(aggregate: "course", aggregate_stat: "mean", per_page: 5, page: 1))
              expect(json["rollups"].length).to be 1
              expect(json["rollups"][0]["scores"][0]["count"]).to be 3
            end

            it "OS results found - no Canvas results found" do
              # removing LearningOutcomeResults for users that have results (@student1, @student, @student2)
              # creating in the first before do after the rollups context
              LearningOutcomeResult.where(user_id: @student.id).update(workflow_state: "deleted")
              LearningOutcomeResult.where(user_id: @student1.id).update(workflow_state: "deleted")
              LearningOutcomeResult.where(user_id: @student2.id).update(workflow_state: "deleted")
              student4 = student_in_course(active_all: true, course: outcome_course, name: "OS user").user
              mocked_results = mock_os_lor_results(student4, @outcome, outcome_assignment, 2)
              expect(controller).to receive(:fetch_and_convert_os_results).with(any_args).and_return(
                [mocked_results]
              )
              json = parse_response(get_rollups(aggregate: "course", aggregate_stat: "mean", per_page: 5, page: 1))
              expect(json["rollups"].length).to be 1
              expect(json["rollups"][0]["scores"][0]["count"]).to be 1
            end

            it "Canvas and OS results found" do
              # already existing results for @student1 & @student2
              # creating result for @student
              create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
              # results are already created for @student2 in Canvas
              student4 = student_in_course(active_all: true, course: outcome_course, name: "OS user").user
              mocked_results = mock_os_lor_results(student4, @outcome, outcome_assignment, 2)
              expect(controller).to receive(:fetch_and_convert_os_results).with(any_args).and_return(
                [mocked_results]
              )
              json = parse_response(get_rollups(aggregate: "course", aggregate_stat: "mean", per_page: 5, page: 1))
              expect(json["rollups"].length).to be 1
              expect(json["rollups"][0]["scores"][0]["count"]).to be 4
            end
          end
        end

        context "remove_users_with_no_results" do
          context "enabled" do
            it "No OS results found" do
              # already existing results for @student1 & @student2
              # creating result for @student
              create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
              expect(controller).to receive(:fetch_and_convert_os_results).with(any_args).once.and_return(nil)
              json = parse_response(get_rollups(sort_by: "student",
                                                sort_order: "desc",
                                                exclude: ["missing_user_rollups"],
                                                per_page: 5,
                                                page: 1))
              expect(json["rollups"].length).to be 3
            end

            it "OS results found - no Canvas results found" do
              # removing LearningOutcomeResults for those users that have results
              # creating in the first before do after the rollups context
              LearningOutcomeResult.where(user_id: @student.id).update(workflow_state: "deleted")
              LearningOutcomeResult.where(user_id: @student1.id).update(workflow_state: "deleted")
              LearningOutcomeResult.where(user_id: @student2.id).update(workflow_state: "deleted")
              student4 = student_in_course(active_all: true, course: outcome_course, name: "OS user").user
              mocked_results = mock_os_lor_results(student4, @outcome, outcome_assignment, 2)
              expect(controller).to receive(:fetch_and_convert_os_results).with(any_args).once.and_return(
                [mocked_results]
              )
              # per_page is the number of students to display on 1 page of results
              json = parse_response(get_rollups(sort_by: "student",
                                                sort_order: "desc",
                                                exclude: ["missing_user_rollups"],
                                                per_page: 5,
                                                page: 1))
              expect(json["rollups"].length).to be 1
            end

            it "Canvas and OS results found" do
              # already existing results for @student1 & @student2
              # creating result for @student
              create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
              # results are already created for @student2 in Canvas
              student4 = student_in_course(active_all: true, course: outcome_course, name: "OS user").user
              mocked_results = mock_os_lor_results(student4, @outcome, outcome_assignment, 2)
              expect(controller).to receive(:fetch_and_convert_os_results).with(any_args).once.and_return(
                [mocked_results]
              )
              # per_page is the number of students to display on 1 page of results
              json = parse_response(get_rollups(sort_by: "student",
                                                sort_order: "desc",
                                                exclude: ["missing_user_rollups"],
                                                per_page: 5,
                                                page: 1))
              expect(json["rollups"].length).to be 4
            end

            it "removes student with no results" do
              # already existing results for @student1 & @student2
              # creating result for @student
              create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
              # results are already created for @student2 in Canvas
              student4 = student_in_course(active_all: true, course: outcome_course, name: "OS user").user
              # Creating another student in the course which will make 5 students enrolled
              # and will not create results for this student
              student_in_course(active_all: true, course: outcome_course)
              mocked_results = mock_os_lor_results(student4, @outcome, outcome_assignment, 2)
              expect(controller).to receive(:fetch_and_convert_os_results).with(any_args).once.and_return(
                [mocked_results]
              )
              # per_page is the number of students to display on 1 page of results
              json = parse_response(get_rollups(sort_by: "student",
                                                sort_order: "desc",
                                                exclude: ["missing_user_rollups"],
                                                per_page: 5,
                                                page: 1))
              # the rollups should be for only the 4 that have results
              expect(json["rollups"].length).to be 4
            end

            it "removes concluded student" do
              # already existing results for @student1 & @student2
              # creating result for @student
              create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
              # creating and enrolling student 4 in the course
              student4 = student_in_course(active_all: true, course: outcome_course, name: "OS user").user
              mocked_results = mock_os_lor_results(student4, @outcome, outcome_assignment, 2)
              expect(controller).to receive(:fetch_and_convert_os_results).with(any_args).and_return(
                [mocked_results]
              )
              # concluding student 3 in the course which will remove the student from the results
              StudentEnrollment.find_by(user_id: @student3.id).conclude
              json = parse_response(get_rollups(sort_by: "student",
                                                sort_order: "desc",
                                                exclude: ["concluded_enrollments"],
                                                per_page: 5,
                                                page: 1))
              expect(json["rollups"].length).to be 3
            end

            it "removes inactive student" do
              # already existing results for @student1 & @student2
              # creating result for @student
              create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
              # creating and enrolling student 4 in the course
              student4 = student_in_course(active_all: true, course: outcome_course, name: "OS user").user
              mocked_results = mock_os_lor_results(student4, @outcome, outcome_assignment, 2)
              expect(controller).to receive(:fetch_and_convert_os_results).with(any_args).and_return(
                [mocked_results]
              )
              # deactivating student 3 in the course which will remove the student from the results
              StudentEnrollment.find_by(user_id: @student3.id).deactivate
              json = parse_response(get_rollups(sort_by: "student",
                                                sort_order: "desc",
                                                exclude: ["inactive_enrollments"],
                                                per_page: 5,
                                                page: 1))
              expect(json["rollups"].length).to be 3
            end

            it "removes inactive student if they have no results, even though they are not explicitly excluded" do
              create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
              student4 = student_in_course(active_all: true, course: outcome_course, name: "OS user").user
              # deactivating student 4 will cause them to be inactive
              StudentEnrollment.find_by(user_id: student4.id).deactivate
              json = parse_response(get_rollups(sort_by: "student",
                                                sort_order: "desc",
                                                exclude: ["missing_user_rollups"],
                                                per_page: 5,
                                                page: 1))
              expect(json["rollups"].length).to be 3
            end

            it "removes concluded student if they have no results, even though they are not explicitly excluded" do
              create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
              student4 = student_in_course(active_all: true, course: outcome_course, name: "OS user").user
              # concluding student 4 will cause them to be concluded
              StudentEnrollment.find_by(user_id: student4.id).conclude
              json = parse_response(get_rollups(sort_by: "student",
                                                sort_order: "desc",
                                                exclude: ["missing_user_rollups"],
                                                per_page: 5,
                                                page: 1))
              expect(json["rollups"].length).to be 3
            end

            context "multiple excludes with rollups" do
              it "inactive & concluded" do
                create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
                inactive_student = student_in_course(active_all: true, course: outcome_course, name: "Inactive User").user
                concluded_student = student_in_course(active_all: true, course: outcome_course, name: "Concluded User").user
                # Set appropriate status for each student
                StudentEnrollment.find_by(user_id: inactive_student.id).deactivate
                StudentEnrollment.find_by(user_id: concluded_student.id).conclude
                # Create results for each student
                create_result(inactive_student.id, @outcome, outcome_assignment, 2, { possible: 5 })
                create_result(concluded_student.id, @outcome, outcome_assignment, 2, { possible: 5 })

                json = parse_response(get_rollups(sort_by: "student",
                                                  sort_order: "desc",
                                                  exclude: ["inactive_enrollments", "concluded_enrollments"],
                                                  per_page: 5,
                                                  page: 1))
                expect(json["rollups"].length).to be 3
                user_links = get_linked_users(json["rollups"])
                user_links.each do |user|
                  expect(user["status"]).not_to eq("inactive")
                  expect(user["status"]).not_to eq("completed")
                end
              end

              it "inactive & unassessed" do
                inactive_student = student_in_course(active_all: true, course: outcome_course, name: "Inactive User").user
                concluded_student = student_in_course(active_all: true, course: outcome_course, name: "Concluded User").user
                # Set appropriate status for each student
                StudentEnrollment.find_by(user_id: inactive_student.id).deactivate
                StudentEnrollment.find_by(user_id: concluded_student.id).conclude
                # Create results for each student
                create_result(inactive_student.id, @outcome, outcome_assignment, 2, { possible: 5 })
                create_result(concluded_student.id, @outcome, outcome_assignment, 2, { possible: 5 })

                json = parse_response(get_rollups(sort_by: "student",
                                                  sort_order: "desc",
                                                  exclude: ["inactive_enrollments", "missing_user_rollups"],
                                                  per_page: 5,
                                                  page: 1))
                expect(json["rollups"].length).to be 3
                user_links = get_linked_users(json["rollups"])
                user_links.each do |user|
                  expect(user["status"]).not_to eq("inactive")
                end
              end

              it "concluded & unassessed" do
                inactive_student = student_in_course(active_all: true, course: outcome_course, name: "Inactive User").user
                concluded_student = student_in_course(active_all: true, course: outcome_course, name: "Concluded User").user
                # Set appropriate status for each student
                StudentEnrollment.find_by(user_id: inactive_student.id).deactivate
                StudentEnrollment.find_by(user_id: concluded_student.id).conclude
                # Create results for each student
                create_result(inactive_student.id, @outcome, outcome_assignment, 2, { possible: 5 })
                create_result(concluded_student.id, @outcome, outcome_assignment, 2, { possible: 5 })

                json = parse_response(get_rollups(sort_by: "student",
                                                  sort_order: "desc",
                                                  exclude: ["concluded_enrollments", "missing_user_rollups"],
                                                  per_page: 5,
                                                  page: 1))
                expect(json["rollups"].length).to be 3
                user_links = get_linked_users(json["rollups"])
                user_links.each do |user|
                  expect(user["status"]).not_to eq("completed")
                end
              end

              it "inactive, concluded, and unassessed" do
                inactive_student = student_in_course(active_all: true, course: outcome_course, name: "Inactive User").user
                concluded_student = student_in_course(active_all: true, course: outcome_course, name: "Concluded User").user
                # Set appropriate status for each student
                StudentEnrollment.find_by(user_id: inactive_student.id).deactivate
                StudentEnrollment.find_by(user_id: concluded_student.id).conclude
                # Create results for each student
                create_result(inactive_student.id, @outcome, outcome_assignment, 2, { possible: 5 })
                create_result(concluded_student.id, @outcome, outcome_assignment, 2, { possible: 5 })

                json = parse_response(get_rollups(sort_by: "student",
                                                  sort_order: "desc",
                                                  exclude: %w[inactive_enrollments concluded_enrollments missing_user_rollups],
                                                  per_page: 5,
                                                  page: 1))
                expect(json["rollups"].length).to be 2
                user_links = get_linked_users(json["rollups"])
                user_links.each do |user|
                  expect(user["status"]).not_to eq("inactive")
                  expect(user["status"]).not_to eq("completed")
                end
              end
            end
          end
        end

        context "remove_outcomes_with_no_results" do
          context "enabled" do
            it "No OS results found" do
              outcome1 = @outcome
              outcome2 = outcome_model(context: outcome_course, title: "unassessed outcome")
              # already existing results for @student1 & @student2 for outcome1
              # creating result for @student for outcome1
              create_result(@student.id, outcome1, outcome_assignment, 2, { possible: 5 })
              expect(controller).to receive(:fetch_and_convert_os_results).with(any_args).once.and_return(nil)
              json = parse_response(get_rollups(sort_by: "student",
                                                sort_order: "desc",
                                                exclude: ["missing_outcome_results"],
                                                include: ["outcomes"],
                                                per_page: 5,
                                                page: 1))
              # should only include outcome1, not outcome2
              outcome_ids = json["linked"]["outcomes"].pluck("id")
              expect(outcome_ids).to include(outcome1.id)
              expect(outcome_ids).not_to include(outcome2.id)
              expect(json["linked"]["outcomes"].length).to be 1
            end

            it "OS results found - no Canvas results found" do
              outcome1 = @outcome
              outcome2 = outcome_model(context: outcome_course, title: "OS only outcome")
              # removing LearningOutcomeResults for outcome1 in Canvas
              LearningOutcomeResult.where(learning_outcome_id: outcome1.id).update(workflow_state: "deleted")
              # Mock OS results for outcome2
              mocked_results = mock_os_lor_results(@student, outcome2, outcome_assignment, 2)
              expect(controller).to receive(:fetch_and_convert_os_results).with(any_args).once.and_return(
                [mocked_results]
              )
              json = parse_response(get_rollups(sort_by: "student",
                                                sort_order: "desc",
                                                exclude: ["missing_outcome_results"],
                                                include: ["outcomes"],
                                                per_page: 5,
                                                page: 1))
              # should only include outcome2 which has OS results
              outcome_ids = json["linked"]["outcomes"].pluck("id")
              expect(outcome_ids).to include(outcome2.id)
              expect(outcome_ids).not_to include(outcome1.id)
              expect(json["linked"]["outcomes"].length).to be 1
            end

            it "Canvas and OS results found" do
              outcome1 = @outcome
              outcome2 = outcome_model(context: outcome_course, title: "OS outcome")
              # outcome1 already has Canvas results for @student1 & @student2
              # creating result for @student for outcome1
              create_result(@student.id, outcome1, outcome_assignment, 2, { possible: 5 })
              # Mock OS results for outcome2
              mocked_results = mock_os_lor_results(@student, outcome2, outcome_assignment, 2)
              expect(controller).to receive(:fetch_and_convert_os_results).with(any_args).once.and_return(
                [mocked_results]
              )
              json = parse_response(get_rollups(sort_by: "student",
                                                sort_order: "desc",
                                                exclude: ["missing_outcome_results"],
                                                include: ["outcomes"],
                                                per_page: 5,
                                                page: 1))
              # should include both outcomes
              outcome_ids = json["linked"]["outcomes"].pluck("id")
              expect(outcome_ids).to include(outcome1.id)
              expect(outcome_ids).to include(outcome2.id)
              expect(json["linked"]["outcomes"].length).to be 2
            end

            it "removes outcomes with no results" do
              outcome1 = @outcome
              outcome2 = outcome_model(context: outcome_course, title: "unassessed outcome")
              outcome3 = outcome_model(context: outcome_course, title: "OS results outcome")
              outcome4 = outcome_model(context: outcome_course, title: "Canvas results outcome")
              # outcome1 already has Canvas results for @student1 & @student2
              # creating result for @student for outcome1
              create_result(@student.id, outcome1, outcome_assignment, 2, { possible: 5 })
              # Create Canvas result for outcome4
              create_result(@student.id, outcome4, outcome_assignment, 2, { possible: 5 })
              # Mock OS results for outcome3 only
              mocked_results = mock_os_lor_results(@student, outcome3, outcome_assignment, 2)
              expect(controller).to receive(:fetch_and_convert_os_results).with(any_args).once.and_return(
                [mocked_results]
              )
              json = parse_response(get_rollups(sort_by: "student",
                                                sort_order: "desc",
                                                exclude: ["missing_outcome_results"],
                                                outcome_ids: [outcome1.id, outcome2.id, outcome3.id, outcome4.id],
                                                include: ["outcomes"],
                                                per_page: 5,
                                                page: 1))
              # should include outcome1 (Canvas), outcome3 (OS), and outcome4 (Canvas)
              # should exclude outcome2 (no results)
              outcome_ids = json["linked"]["outcomes"].pluck("id")
              expect(outcome_ids).to include(outcome1.id)
              expect(outcome_ids).to include(outcome3.id)
              expect(outcome_ids).to include(outcome4.id)
              expect(outcome_ids).not_to include(outcome2.id)
              expect(json["linked"]["outcomes"].length).to be 3
            end
          end
        end
      end
    end

    context "with the account_mastery_scales FF" do
      context "enabled" do
        before do
          @course.account.enable_feature!(:account_level_mastery_scales)
        end

        it "uses the default outcome proficiency for points scaling if no outcome proficiency exists" do
          create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
          json = parse_response(get_rollups(sort_by: "student", sort_order: "desc", per_page: 1, page: 1))
          points_possible = OutcomeProficiency.find_or_create_default!(@course.account).points_possible
          score = (2.to_f / 5.to_f) * points_possible
          expect(json["rollups"][0]["scores"][0]["score"]).to eq score
        end

        it "uses resolved_outcome_proficiency for points scaling if one exists" do
          proficiency = outcome_proficiency_model(@course)
          create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
          json = parse_response(get_rollups(sort_by: "student", sort_order: "desc", per_page: 1, page: 1))
          score = (2.to_f / 5.to_f) * proficiency.points_possible
          expect(json["rollups"][0]["scores"][0]["score"]).to eq score
        end

        it "returns outcomes with outcome_proficiency.ratings and their percents" do
          outcome_proficiency_model(@course)
          json = parse_response(get_rollups(rating_percents: true, include: ["outcomes"]))
          ratings = json["linked"]["outcomes"][0]["ratings"]
          expect(ratings.pluck("percent")).to eq [50, 50]
          expect(ratings.pluck("points")).to eq [10, 0]
        end
      end

      context "disabled" do
        before do
          @course.account.disable_feature!(:account_level_mastery_scales)
        end

        it "ignores the outcome proficiency for points scaling" do
          outcome_proficiency_model(@course)
          create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
          json = parse_response(get_rollups(sort_by: "student", sort_order: "desc", per_page: 1, page: 1))
          expect(json["rollups"][0]["scores"][0]["score"]).to eq 1.2 # ( score of 2 / possible 5) * outcome.points_possible
        end

        it "contains mastery and color information for ratings" do
          outcome_proficiency_model(@course)
          create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
          json = parse_response(get_rollups(sort_by: "student", sort_order: "desc", add_defaults: true, per_page: 1, page: 1, include: ["outcomes"]))
          ratings = json["linked"]["outcomes"][0]["ratings"]
          expect(ratings.pluck("mastery")).to eq [true, false]
          expect(ratings.pluck("color")).to eq ["03893D", "555555"]
        end

        it "does not contain mastery and color information if \"add_defaults\" parameter is not provided" do
          outcome_proficiency_model(@course)
          create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
          json = parse_response(get_rollups(sort_by: "student", sort_order: "desc", per_page: 1, page: 1, include: ["outcomes"]))
          ratings = json["linked"]["outcomes"][0]["ratings"]
          expect(ratings.pluck("mastery")).to eq [nil, nil]
          expect(ratings.pluck("color")).to eq [nil, nil]
        end
      end
    end

    context "with outcomes_friendly_description and improved_outcomes_management FFs" do
      before do
        OutcomeFriendlyDescription.create!(learning_outcome: @outcome, context: @course, description: "A friendly description")
      end

      context "enabled" do
        before do
          @course.root_account.enable_feature!(:improved_outcomes_management)
        end

        it "returns outcomes with friendly_description" do
          create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
          json = parse_response(get_rollups(include: ["outcomes"]))
          expect(json["linked"]["outcomes"][0]["friendly_description"]).to eq "A friendly description"
        end
      end

      context "outcomes_friendly_description disabled" do
        before do
          mock_feature_flag_on_account(:outcomes_friendly_description, false)
        end

        it "returns outcomes without friendlly_description" do
          create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
          json = parse_response(get_rollups(include: ["outcomes"]))
          expect(json["linked"]["outcomes"][0]["friendly_description"]).to be_nil
        end
      end

      context "outcomes_friendly_description enabled, but improved_outcomes_management disabled" do
        before do
          mock_feature_flag_on_account(:outcomes_friendly_description, true)
          mock_feature_flag_on_account(:improved_outcomes_management, false)
        end

        it "returns outcomes without friendlly_description" do
          create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
          json = parse_response(get_rollups(include: ["outcomes"]))
          expect(json["linked"]["outcomes"][0]["friendly_description"]).to be_nil
        end
      end
    end

    context "inactive/concluded LMGB filters" do
      it "displays rollups for concluded enrollments when they are included" do
        StudentEnrollment.find_by(user_id: @student2.id).conclude
        json = parse_response(get_rollups({}))
        rollups = json["rollups"].select { |r| r["links"]["user"] == @student2.id.to_s }
        expect(rollups.count).to eq(1)
        expect(rollups.first["scores"][0]["score"]).to eq 1.0
      end

      it "does not display rollups for concluded enrollments when they are not included" do
        StudentEnrollment.find_by(user_id: @student2.id).conclude
        json = parse_response(get_rollups(exclude: "concluded_enrollments"))
        expect(json["rollups"].count { |r| r["links"]["user"] == @student2.id.to_s }).to eq(0)
      end

      it "displays rollups for a student who has an active and a concluded enrolllment regardless of filter" do
        section1 = add_section "s1", course: outcome_course
        student_in_section section1, user: @student2, allow_multiple_enrollments: true
        StudentEnrollment.find_by(course_section_id: section1.id).conclude
        json = parse_response(get_rollups(exclude: "concluded_enrollments"))
        rollups = json["rollups"].select { |r| r["links"]["user"] == @student2.id.to_s }
        expect(rollups.count).to eq(2)
        expect(rollups.first["scores"][0]["score"]).to eq 1.0
        expect(rollups.second["scores"][0]["score"]).to eq 1.0
      end

      it "displays rollups for inactive enrollments when they are included" do
        StudentEnrollment.find_by(user_id: @student2.id).deactivate
        json = parse_response(get_rollups({}))
        rollups = json["rollups"].select { |r| r["links"]["user"] == @student2.id.to_s }
        expect(rollups.count).to eq(1)
        expect(rollups.first["scores"][0]["score"]).to eq 1.0
      end

      it "does not display rollups for inactive enrollments when they are not included" do
        StudentEnrollment.find_by(user_id: @student2.id).deactivate
        json = parse_response(get_rollups(exclude: "inactive_enrollments"))
        expect(json["rollups"].count { |r| r["links"]["user"] == @student2.id.to_s }).to eq(0)
      end

      it "does not display rollups for deleted enrollments" do
        StudentEnrollment.find_by(user_id: @student2.id).update(workflow_state: "deleted")
        json = parse_response(get_rollups({}))
        expect(json["rollups"].count { |r| r["links"]["user"] == @student2.id.to_s }).to eq(0)
      end

      context "with user enrollments from different shards (trust relationships)" do
        specs_require_sharding

        before do
          @shard1.activate do
            @student_from_another_shard = user_factory(name: "Distant Traveler", short_name: "Traveler")
          end
          student_in_course(active_all: true, course: outcome_course, user: @student_from_another_shard)
        end

        it "student is not canonical in the current shard" do
          student = outcome_course.students.find_by(id: @student_from_another_shard.id)
          expect(student.canonical?).to be_falsey
        end

        it "displays rollups for students from different shards" do
          json = parse_response(get_rollups(exclude: ["inactive_enrollments", "concluded_enrollments"]))
          expect(json["rollups"].count { |r| r["links"]["user"] == @student_from_another_shard.id.to_s }).to eq(1)
        end

        it "does not display rollups for students from different shards when they are inactive" do
          outcome_course.enrollments.find_by(user_id: @student_from_another_shard.id).deactivate
          json = parse_response(get_rollups(exclude: "inactive_enrollments"))
          expect(json["rollups"].count { |r| r["links"]["user"] == @student_from_another_shard.id.to_s }).to eq(0)
        end

        it "does not display rollups for students from different shards when they are concluded" do
          outcome_course.enrollments.find_by(user_id: @student_from_another_shard.id).conclude
          json = parse_response(get_rollups(exclude: "concluded_enrollments"))
          expect(json["rollups"].count { |r| r["links"]["user"] == @student_from_another_shard.id.to_s }).to eq(0)
        end

        it "does not display rollups for students from different shards when they are deleted" do
          outcome_course.enrollments.find_by(user_id: @student_from_another_shard.id).update(workflow_state: "deleted")
          json = parse_response(get_rollups({}))
          expect(json["rollups"].count { |r| r["links"]["user"] == @student_from_another_shard.id.to_s }).to eq(0)
        end
      end

      context "users with enrollments of different enrollment states" do
        before do
          StudentEnrollment.find_by(user_id: @student2.id).deactivate
          @section1 = add_section "s1", course: outcome_course
          student_in_section @section1, user: @student2, allow_multiple_enrollments: true
          StudentEnrollment.find_by(course_section_id: @section1.id).conclude
        end

        it "users whose enrollments are all excluded are not included" do
          json = parse_response(get_rollups(exclude: ["concluded_enrollments", "inactive_enrollments"]))
          rollups = json["rollups"].select { |r| r["links"]["user"] == @student2.id.to_s }
          expect(rollups.count).to eq(0)
        end

        it "users whose enrollments are all excluded are not included in a specified section" do
          json = parse_response(get_rollups(exclude: ["concluded_enrollments", "inactive_enrollments"],
                                            section_id: @section1.id))
          rollups = json["rollups"].select { |r| r["links"]["user"] == @student2.id.to_s }
          expect(rollups.count).to eq(0)
        end

        it "users who contain an active enrollment are always included" do
          section3 = add_section "s3", course: outcome_course
          student_in_section section3, user: @student2, allow_multiple_enrollments: true
          json = parse_response(get_rollups(exclude: ["concluded_enrollments", "inactive_enrollments"]))
          rollups = json["rollups"].select { |r| r["links"]["user"] == @student2.id.to_s }
          expect(rollups.count).to eq(3)
          expect(rollups.first["scores"][0]["score"]).to eq 1.0
          expect(rollups.second["scores"][0]["score"]).to eq 1.0
          expect(rollups.third["scores"][0]["score"]).to eq 1.0
        end
      end

      context "students enrolled in multiple sections" do
        before do
          @section1 = add_section "s1", course: outcome_course
          @section2 = add_section "s2", course: outcome_course

          student_in_section @section1, user: @student1, allow_multiple_enrollments: true
          student_in_section @section2, user: @student2, allow_multiple_enrollments: true
          student_in_section @section1, user: @student2, allow_multiple_enrollments: true
          student_in_section @section2, user: @student3, allow_multiple_enrollments: true
        end

        it "returns active students who are in section 1" do
          json = parse_response(get_rollups({ exclude: ["concluded_enrollments", "inactive_enrollments"], section_id: @section1.id }))
          # student 3 is only enrolled in section 2
          rollups = json["rollups"].select { |r| r["links"]["user"] == @student3.id.to_s }
          expect(rollups.count).to eq(0)
          # student 1 & student 2 are enrolled in section 1
          expect(json["rollups"].first["links"]["user"]).to eq @student1.id.to_s
          expect(json["rollups"].second["links"]["user"]).to eq @student2.id.to_s
        end

        it "returns only active students by default when inactive students are enrolled" do
          StudentEnrollment.find_by(user_id: @student2.id, course_section_id: @section1.id).deactivate
          json = parse_response(get_rollups({ exclude: ["concluded_enrollments", "inactive_enrollments"], section_id: @section1.id }))
          rollups = json["rollups"].select { |r| r["links"]["user"] == @student2.id.to_s }
          expect(rollups.count).to eq(0)
          expect(json["rollups"].count).to eq(1)
          expect(json["rollups"].first["links"]["user"]).to eq @student1.id.to_s
        end

        it "returns only active students by default when concluded and inactive students are enrolled" do
          student_in_section @section1, user: @student3, allow_multiple_enrollments: true
          StudentEnrollment.find_by(user_id: @student2.id, course_section_id: @section1.id).deactivate
          StudentEnrollment.find_by(user_id: @student3.id, course_section_id: @section1.id).conclude
          json = parse_response(get_rollups({ exclude: ["concluded_enrollments", "inactive_enrollments"], section_id: @section1.id }))
          rollups = json["rollups"].select { |r| r["links"]["user"] == @student2.id.to_s }
          expect(rollups.count).to eq(0)
          expect(json["rollups"].count).to eq(1)
          expect(json["rollups"].first["links"]["user"]).to eq @student1.id.to_s
        end

        it "returns active and concluded students but not inactive" do
          student_in_section @section1, user: @student3, allow_multiple_enrollments: true
          StudentEnrollment.find_by(user_id: @student2.id, course_section_id: @section1.id).deactivate
          StudentEnrollment.find_by(user_id: @student3.id, course_section_id: @section1.id).conclude
          json = parse_response(get_rollups({ exclude: ["inactive_enrollments"], section_id: @section1.id }))
          rollups = json["rollups"].select { |r| r["links"]["user"] == @student2.id.to_s }
          expect(rollups.count).to eq(0)
          expect(json["rollups"].count).to eq(2)
          expect(json["rollups"].first["links"]["user"]).to eq @student1.id.to_s
          expect(json["rollups"].second["links"]["user"]).to eq @student3.id.to_s
        end

        it "returns active, concluded and inactive students" do
          student_in_section @section1, user: @student3, allow_multiple_enrollments: true
          StudentEnrollment.find_by(user_id: @student2.id, course_section_id: @section1.id).deactivate
          StudentEnrollment.find_by(user_id: @student3.id, course_section_id: @section1.id).conclude
          json = parse_response(get_rollups({ section_id: @section1.id }))
          expect(json["rollups"].count).to eq(3)
          expect(json["rollups"].first["links"]["user"]).to eq @student1.id.to_s
          expect(json["rollups"].second["links"]["user"]).to eq @student2.id.to_s
          expect(json["rollups"].third["links"]["user"]).to eq @student3.id.to_s
        end

        it "returns active by default for all sections in a course" do
          json = parse_response(get_rollups({ exclude: ["concluded_enrollments", "inactive_enrollments"] }))
          rollups_student1 = json["rollups"].select { |r| r["links"]["user"] == @student1.id.to_s }
          rollups_student2 = json["rollups"].select { |r| r["links"]["user"] == @student2.id.to_s }
          rollups_student3 = json["rollups"].select { |r| r["links"]["user"] == @student3.id.to_s }
          expect(rollups_student1.count).to eq(2) # enrolled in 2 sections
          expect(rollups_student2.count).to eq(3) # enrolled in 3 sections
          expect(rollups_student3.count).to eq(2) # enrolled in 2 sections
        end

        it "returns students that are active in 1 section in the course but inactive in another by default" do
          StudentEnrollment.find_by(user_id: @student2.id, course_section_id: @section1.id).deactivate
          json = parse_response(get_rollups({ exclude: ["concluded_enrollments", "inactive_enrollments"] }))
          rollups_student1 = json["rollups"].select { |r| r["links"]["user"] == @student1.id.to_s }
          rollups_student2 = json["rollups"].select { |r| r["links"]["user"] == @student2.id.to_s }
          rollups_student3 = json["rollups"].select { |r| r["links"]["user"] == @student3.id.to_s }
          expect(rollups_student1.count).to eq(2) # enrolled in 2 sections
          expect(rollups_student2.count).to eq(3) # enrolled in 3 sections
          expect(rollups_student3.count).to eq(2) # enrolled in 2 sections
        end

        it "returns students that are active in 1 section in the course but concluded in another by default" do
          StudentEnrollment.find_by(user_id: @student2.id, course_section_id: @section1.id).conclude
          json = parse_response(get_rollups({ exclude: ["concluded_enrollments", "inactive_enrollments"] }))
          rollups_student1 = json["rollups"].select { |r| r["links"]["user"] == @student1.id.to_s }
          rollups_student2 = json["rollups"].select { |r| r["links"]["user"] == @student2.id.to_s }
          rollups_student3 = json["rollups"].select { |r| r["links"]["user"] == @student3.id.to_s }
          expect(rollups_student1.count).to eq(2) # enrolled in 2 sections
          expect(rollups_student2.count).to eq(3) # enrolled in 3 sections
          expect(rollups_student3.count).to eq(2) # enrolled in 2 sections
        end

        it "handles section_id as a string" do
          json = parse_response(get_rollups({ section_id: @section1.id.to_s }))
          rollups = json["rollups"].select { |r| r["links"]["user"] == @student1.id.to_s }
          expect(rollups.count).to eq(1)
          expect(json["rollups"].first["links"]["user"]).to eq @student1.id.to_s
        end
      end
    end

    context "sorting" do
      it "validates sort_by parameter" do
        get_rollups(sort_by: "garbage")
        expect(response).not_to be_successful
      end

      it "validates sort_order parameter" do
        get_rollups(sort_by: "student", sort_order: "random")
        expect(response).not_to be_successful
      end

      context "by outcome" do
        it "validates a missing sort_outcome_id parameter" do
          get_rollups(sort_by: "outcome")
          expect(response).not_to be_successful
        end

        it "validates an invalid sort_outcome_id parameter" do
          get_rollups(sort_by: "outcome", sort_outcome_id: "NaN")
          expect(response).not_to be_successful
        end

        it "sorts rollups by ascending rollup score" do
          get_rollups(sort_by: "outcome", sort_outcome_id: @outcome.id)
          expect(response).to be_successful
          json = parse_response(response)
          expect_user_order(json["rollups"], [@student2, @student1, @student3])
          expect_score_order(json["rollups"], [1, 3, nil])
        end

        it "sorts rollups by descending rollup score" do
          get_rollups(sort_by: "outcome", sort_outcome_id: @outcome.id, sort_order: "desc")
          expect(response).to be_successful
          json = parse_response(response)
          expect_user_order(json["rollups"], [@student1, @student2, @student3])
          expect_score_order(json["rollups"], [3, 1, nil])
        end

        context "with pagination" do
          def expect_students_in_pagination(page, students, scores, sort_order = "asc")
            get_rollups(sort_by: "outcome", sort_outcome_id: @outcome.id, sort_order:, per_page: 1, page:)
            expect(response).to be_successful
            json = parse_response(response)
            expect_user_order(json["rollups"], students)
            expect_score_order(json["rollups"], scores)
          end

          context "ascending" do
            it "return student2 in first page" do
              expect_students_in_pagination(1, [@student2], [1])
            end

            it "return student1 in second page" do
              expect_students_in_pagination(2, [@student1], [3])
            end

            it "return student3 in third page" do
              expect_students_in_pagination(3, [@student3], [nil])
            end

            it "return no student in fourth page" do
              expect_students_in_pagination(4, [], [])
            end
          end

          context "descending" do
            it "return student1 in first page" do
              expect_students_in_pagination(1, [@student1], [3], "desc")
            end

            it "return student2 in second page" do
              expect_students_in_pagination(2, [@student2], [1], "desc")
            end

            it "return student3 in third page" do
              expect_students_in_pagination(3, [@student3], [nil], "desc")
            end

            it "return no student in fourth page" do
              expect_students_in_pagination(4, [], [], "desc")
            end
          end
        end
      end

      def expect_user_order(rollups, users)
        rollup_user_ids = rollups.map { |r| r["links"]["user"].to_i }
        user_ids = users.map(&:id)
        expect(rollup_user_ids).to eq user_ids
      end

      def expect_score_order(rollups, scores)
        rollup_scores = rollups.map do |r|
          r["scores"].empty? ? nil : r["scores"][0]["score"].to_i
        end
        expect(rollup_scores).to eq scores
      end

      context "by contributing_score" do
        before do
          # Use the alignment from outcome_result (for @student1)
          @alignment = outcome_result.alignment
          @alignment_id = "A_#{@alignment.id}"

          # Find the existing result for @student2 and update it to use the same alignment
          existing_result = LearningOutcomeResult.where(user_id: @student2.id, learning_outcome_id: @outcome.id).first
          existing_result&.update_columns(content_tag_id: @alignment.id, score: 1, workflow_state: "active")

          # @student3 has no result for this alignment, so their score will be nil
        end

        it "validates a missing sort_alignment_id parameter" do
          get_rollups(sort_by: "contributing_score")
          expect(response).not_to be_successful
        end

        it "validates an invalid sort_alignment_id parameter format" do
          get_rollups(sort_by: "contributing_score", sort_alignment_id: "invalid_format")
          expect(response).not_to be_successful
        end

        it "validates an invalid sort_alignment_id parameter with wrong prefix" do
          get_rollups(sort_by: "contributing_score", sort_alignment_id: "123")
          expect(response).not_to be_successful
        end

        it "sorts rollups by ascending alignment score" do
          get_rollups(sort_by: "contributing_score", sort_alignment_id: @alignment_id)
          expect(response).to be_successful
          json = parse_response(response)
          expect(json["rollups"].length).to eq(3)
        end

        it "sorts rollups by descending alignment score" do
          get_rollups(sort_by: "contributing_score", sort_alignment_id: @alignment_id, sort_order: "desc")
          expect(response).to be_successful
          json = parse_response(response)
          expect_user_order(json["rollups"], [@student1, @student2, @student3])
          expect_score_order(json["rollups"], [3, 1, nil])
        end

        context "with pagination" do
          def expect_students_in_pagination_by_alignment(page, students, scores, sort_order = "asc")
            get_rollups(sort_by: "contributing_score", sort_alignment_id: @alignment_id, sort_order:, per_page: 1, page:)
            expect(response).to be_successful
            json = parse_response(response)
            expect_user_order(json["rollups"], students)
            expect_score_order(json["rollups"], scores)
          end

          context "ascending" do
            it "return student2 in first page" do
              expect_students_in_pagination_by_alignment(1, [@student2], [1])
            end

            it "return student1 in second page" do
              expect_students_in_pagination_by_alignment(2, [@student1], [3])
            end

            it "return student3 in third page" do
              expect_students_in_pagination_by_alignment(3, [@student3], [nil])
            end

            it "return no student in fourth page" do
              expect_students_in_pagination_by_alignment(4, [], [])
            end
          end

          context "descending" do
            it "return student1 in first page" do
              expect_students_in_pagination_by_alignment(1, [@student1], [3], "desc")
            end

            it "return student2 in second page" do
              expect_students_in_pagination_by_alignment(2, [@student2], [1], "desc")
            end

            it "return student3 in third page" do
              expect_students_in_pagination_by_alignment(3, [@student3], [nil], "desc")
            end

            it "return no student in fourth page" do
              expect_students_in_pagination_by_alignment(4, [], [], "desc")
            end
          end
        end

        context "with alignment that has no scores" do
          before do
            # Create a new outcome with a new alignment that has no scores
            @outcome2 = @course.created_learning_outcomes.create!(
              title: "Outcome 2",
              description: "second outcome",
              vendor_guid: "vendorguid9002"
            )
            @assignment2 = @course.assignments.create!(title: "Assignment 2")
            @alignment2 = @outcome2.align(@assignment2, @course, mastery_type: "points", mastery_score: 3)
            @alignment2_id = "A_#{@alignment2.id}"
          end

          it "returns all students when sorting by alignment with no scores (descending)" do
            # Before the fix, this would return 0 students when exclude[]=missing_user_rollups
            get_rollups(
              sort_by: "contributing_score",
              sort_alignment_id: @alignment2_id,
              sort_order: "desc",
              exclude: ["missing_user_rollups"],
              outcome_ids: [@outcome2.id]
            )
            expect(response).to be_successful
            json = parse_response(response)
            # All 3 students should be returned even though they have no scores for this alignment
            # With no scores, they're sorted by name and reversed (desc)
            expect(json["rollups"].length).to eq(3)
            expect_user_order(json["rollups"], [@student3, @student2, @student1])
          end

          it "returns all students when sorting by alignment with no scores (ascending)" do
            # Before the fix, this would return 0 students when exclude[]=missing_user_rollups
            get_rollups(
              sort_by: "contributing_score",
              sort_alignment_id: @alignment2_id,
              sort_order: "asc",
              exclude: ["missing_user_rollups"],
              outcome_ids: [@outcome2.id]
            )
            expect(response).to be_successful
            json = parse_response(response)
            # All 3 students should be returned even though they have no scores for this alignment
            expect(json["rollups"].length).to eq(3)
            expect_user_order(json["rollups"], [@student1, @student2, @student3])
          end
        end
      end

      context "by student" do
        it "sorts rollups by ascending student sortable name" do
          get_rollups(sort_by: "student")
          expect(response).to be_successful
          json = parse_response(response)
          expect_user_order(json["rollups"], [@student1, @student2, @student3])
        end

        it "sorts rollups by descending student sortable name" do
          get_rollups(sort_by: "student", sort_order: "desc")
          expect(response).to be_successful
          json = parse_response(response)
          expect_user_order(json["rollups"], [@student3, @student2, @student1])
        end

        it "sorts rollups by ascending student name" do
          get_rollups(sort_by: "student_name", sort_order: "asc")
          expect(response).to be_successful
          json = parse_response(response)
          expect_user_order(json["rollups"], [@student1, @student2, @student3])
        end

        it "sorts rollups by ascending student sis id" do
          get_rollups(sort_by: "student_sis_id", sort_order: "asc")
          expect(response).to be_successful
          json = parse_response(response)
          expect_user_order(json["rollups"], [@student1, @student2, @student3])
        end

        it "sorts rollups by ascending student integration id" do
          get_rollups(sort_by: "student_integration_id", sort_order: "asc")
          expect(response).to be_successful
          json = parse_response(response)
          expect_user_order(json["rollups"], [@student1, @student2, @student3])
        end

        it "sorts rollups by ascending student login id" do
          get_rollups(sort_by: "student_login_id", sort_order: "asc")
          expect(response).to be_successful
          json = parse_response(response)
          expect_user_order(json["rollups"], [@student1, @student2, @student3])
        end

        context "with teachers who have limited privilege" do
          before do
            @section1 = add_section "s1", course: outcome_course
            @section2 = add_section "s2", course: outcome_course
            @section3 = add_section "s3", course: outcome_course

            student_in_section @section1, user: @student1, allow_multiple_enrollments: false
            student_in_section @section2, user: @student2, allow_multiple_enrollments: false
            student_in_section @section3, user: @student3, allow_multiple_enrollments: false
            @teacher = teacher_in_section(@section2, limit_privileges_to_course_section: true)
            user_session(@teacher)
          end

          context "with the .limit_section_visibility_in_lmgb FF enabled" do
            before do
              @course.root_account.enable_feature!(:limit_section_visibility_in_lmgb)
            end

            it "only returns students in the teachers section" do
              get_rollups(sort_by: "student", sort_order: "desc")
              json = parse_response(response)
              expect_user_order(json["rollups"], [@student2])
            end
          end
        end

        context "with pagination" do
          let(:json) { parse_response(response) }

          def expect_students_in_pagination(page, students, sort_order = "asc", include: nil)
            get_rollups(sort_by: "student", sort_order:, per_page: 1, page:, include:)
            expect(response).to be_successful
            expect_user_order(json["rollups"], students)
          end

          context "ascending" do
            it "return student1 in first page" do
              expect_students_in_pagination(1, [@student1])
            end

            it "return student2 in second page" do
              expect_students_in_pagination(2, [@student2])
            end

            it "return student3 in third page" do
              expect_students_in_pagination(3, [@student3])
            end

            it "return no student in fourth page" do
              expect_students_in_pagination(4, [])
            end
          end

          context "descending" do
            it "return student3 in first page" do
              expect_students_in_pagination(1, [@student3], "desc")
            end

            it "return student2 in second page" do
              expect_students_in_pagination(2, [@student2], "desc")
            end

            it "return student1 in third page" do
              expect_students_in_pagination(3, [@student1], "desc")
            end

            it "return no student in fourth page" do
              expect_students_in_pagination(4, [], "desc")
            end
          end

          context "with multiple enrollments" do
            before do
              @section1 = add_section "s1", course: outcome_course
              @section2 = add_section "s2", course: outcome_course
              student_in_section @section1, user: @student2, allow_multiple_enrollments: true
              student_in_section @section2, user: @student2, allow_multiple_enrollments: true
              student_in_section @section2, user: @student3, allow_multiple_enrollments: true
            end

            context "should paginate by user, rather than by enrollment" do
              it "returns student1 on first page" do
                expect_students_in_pagination(1, [@student1], include: ["users"])
                expect(json["linked"]["users"].pluck("id")).to eq [@student1.id.to_s]
              end

              it "returns student2 on second page" do
                expect_students_in_pagination(2, [@student2, @student2, @student2], include: ["users"])
                expect(json["linked"]["users"].pluck("id")).to eq [@student2.id.to_s]
              end

              it "returns student3 on third page" do
                expect_students_in_pagination(3, [@student3, @student3], include: ["users"])
                expect(json["linked"]["users"].pluck("id")).to eq [@student3.id.to_s]
              end

              it "return no student in fourth page" do
                expect_students_in_pagination(4, [], include: ["users"])
                expect(json["linked"]["users"].length).to be 0
              end
            end
          end
        end
      end
    end

    context "outcomes_rollup_read feature flag" do
      it "uses stored_outcome_rollups when feature flag is enabled" do
        Account.site_admin.enable_feature!(:outcomes_rollup_read)

        OutcomeRollup.create!(
          course: @course,
          user: @student1,
          outcome: @outcome,
          calculation_method: "highest",
          aggregate_score: 4.5,
          last_calculated_at: Time.zone.now
        )

        allow(controller).to receive(:stored_outcome_rollups).and_call_original
        allow(controller).to receive(:find_canvas_os_results).and_call_original

        get_rollups({})

        expect(controller).to have_received(:stored_outcome_rollups)
        expect(controller).not_to have_received(:find_canvas_os_results)
      end

      it "uses calculated rollups when feature flag is disabled" do
        Account.site_admin.disable_feature!(:outcomes_rollup_read)

        create_result(@student1.id, @outcome, outcome_assignment, 3)

        allow(controller).to receive(:stored_outcome_rollups).and_call_original
        allow(controller).to receive(:find_canvas_os_results).and_call_original

        get_rollups({})

        expect(controller).not_to have_received(:stored_outcome_rollups)
        expect(controller).to have_received(:find_canvas_os_results)
      end

      it "respects excludes parameter when feature flag is enabled" do
        Account.site_admin.enable_feature!(:outcomes_rollup_read)

        OutcomeRollup.create!(
          course: @course,
          user: @student1,
          outcome: @outcome,
          calculation_method: "highest",
          aggregate_score: 4.5,
          last_calculated_at: Time.zone.now
        )

        allow(controller).to receive(:stored_outcome_rollups).and_call_original

        get_rollups({ exclude: ["missing_user_rollups"] })

        expect(controller).to have_received(:stored_outcome_rollups).with(
          hash_including(excludes: ["missing_user_rollups"])
        )
      end

      it "passes correct users parameter based on all_users option" do
        Account.site_admin.enable_feature!(:outcomes_rollup_read)

        OutcomeRollup.create!(
          course: @course,
          user: @student1,
          outcome: @outcome,
          calculation_method: "highest",
          aggregate_score: 4.5,
          last_calculated_at: Time.zone.now
        )

        allow(controller).to receive(:stored_outcome_rollups).and_call_original

        get_rollups({})

        expect(controller).to have_received(:stored_outcome_rollups).with(
          hash_including(users: kind_of(Enumerable))
        )
      end

      it "returns rollup data structure with both flag states" do
        create_result(@student1.id, @outcome, outcome_assignment, 3)
        create_result(@student2.id, @outcome, outcome_assignment, 4)

        Account.site_admin.disable_feature!(:outcomes_rollup_read)
        calculated_json = parse_response(get_rollups({}))

        expect(calculated_json).to have_key("rollups")
        expect(calculated_json["rollups"]).to be_an(Array)
        expect(calculated_json["rollups"].length).to be > 0
        expect(calculated_json["rollups"].first).to have_key("scores")
        expect(calculated_json["rollups"].first).to have_key("links")

        OutcomeRollup.create!(
          course: @course,
          user: @student1,
          outcome: @outcome,
          calculation_method: "highest",
          aggregate_score: 3.0,
          last_calculated_at: Time.zone.now
        )
        OutcomeRollup.create!(
          course: @course,
          user: @student2,
          outcome: @outcome,
          calculation_method: "highest",
          aggregate_score: 4.0,
          last_calculated_at: Time.zone.now
        )

        Account.site_admin.enable_feature!(:outcomes_rollup_read)
        stored_rollups = controller.send(:user_rollups)

        expect(stored_rollups).to be_an(Array)
        expect(stored_rollups.length).to be > 0
        expect(stored_rollups.first).to respond_to(:context)
        expect(stored_rollups.first).to respond_to(:scores)
        expect(stored_rollups.first.scores).to be_an(Array)
      end

      it "returns alignments when feature flag is enabled" do
        Account.site_admin.enable_feature!(:outcomes_rollup_read)

        # Create an assignment aligned to the outcome
        assignment = outcome_assignment

        # Create a result for the alignment
        create_result(@student1.id, @outcome, assignment, 3)

        # Create stored rollup
        OutcomeRollup.create!(
          course: @course,
          user: @student1,
          outcome: @outcome,
          calculation_method: "highest",
          aggregate_score: 3.0,
          last_calculated_at: Time.zone.now
        )

        get "rollups",
            params: { course_id: @course.id,
                      include: ["alignments"] },
            format: "json"

        expect(response).to be_successful
        json = parse_response(response)
        expect(json["linked"]).to have_key("alignments")
        alignments = json["linked"]["alignments"]
        expect(alignments).to be_an(Array)
        expect(alignments.length).to be > 0
        expect(alignments.pluck("name")).to include(assignment.name)
      end

      it "returns both Canvas and outcomes service alignments when feature flag is disabled" do
        Account.site_admin.disable_feature!(:outcomes_rollup_read)

        # Create a Canvas assignment with result
        canvas_assignment = outcome_assignment
        create_result(@student1.id, @outcome, canvas_assignment, 3)

        # Create a New Quiz assignment for outcomes service results
        new_quiz_assignment = @course.assignments.create!(
          title: "New Quiz Assignment",
          submission_types: "external_tool"
        )
        @outcome.align(new_quiz_assignment, @course)
        find_or_create_outcome_submission({ student: @student1, assignment: new_quiz_assignment })

        # Mock outcomes service results for the new quiz
        os_result = mock_os_lor_results(@student1, @outcome, new_quiz_assignment, 4)

        # Stub fetch_and_convert_os_results to return the mocked OS results
        expect(controller).to receive(:fetch_and_convert_os_results).with(all_users: false).and_return([os_result])

        get "rollups",
            params: { course_id: @course.id,
                      include: ["alignments"] },
            format: "json"

        expect(response).to be_successful
        json = parse_response(response)
        expect(json["linked"]).to have_key("alignments")
        alignments = json["linked"]["alignments"]
        expect(alignments).to be_an(Array)
        expect(alignments.length).to eq(2)
        expect(alignments.pluck("name")).to include(canvas_assignment.name)
        expect(alignments.pluck("name")).to include(new_quiz_assignment.name)
      end

      it "returns both Canvas and outcomes service alignments when feature flag is enabled" do
        Account.site_admin.enable_feature!(:outcomes_rollup_read)

        # Create a Canvas assignment with result
        canvas_assignment = outcome_assignment
        create_result(@student1.id, @outcome, canvas_assignment, 3)

        # Create a New Quiz assignment for outcomes service results
        new_quiz_assignment = @course.assignments.create!(
          title: "New Quiz Assignment",
          submission_types: "external_tool"
        )
        @outcome.align(new_quiz_assignment, @course)
        find_or_create_outcome_submission({ student: @student1, assignment: new_quiz_assignment })

        # Mock outcomes service results for the new quiz
        os_result = mock_os_lor_results(@student1, @outcome, new_quiz_assignment, 4)

        # Stub fetch_and_convert_os_results to return the mocked OS results
        expect(controller).to receive(:fetch_and_convert_os_results).with(all_users: false).and_return([os_result])

        # Create stored rollup
        OutcomeRollup.create!(
          course: @course,
          user: @student1,
          outcome: @outcome,
          calculation_method: "highest",
          aggregate_score: 4.0,
          last_calculated_at: Time.zone.now
        )

        get "rollups",
            params: { course_id: @course.id,
                      include: ["alignments"] },
            format: "json"

        expect(response).to be_successful
        json = parse_response(response)
        expect(json["linked"]).to have_key("alignments")
        alignments = json["linked"]["alignments"]
        expect(alignments).to be_an(Array)
        expect(alignments.length).to eq(2)
        expect(alignments.pluck("name")).to include(canvas_assignment.name)
        expect(alignments.pluck("name")).to include(new_quiz_assignment.name)
      end

      it "filters outcomes without results when feature flag is enabled" do
        Account.site_admin.enable_feature!(:outcomes_rollup_read)

        # Create two outcomes
        outcome1 = outcome_model(context: @course, title: "Outcome with results")
        outcome2 = outcome_model(context: @course, title: "Outcome without results")

        # Create assignment and results for outcome1 only
        assignment = outcome_assignment
        create_result(@student1.id, outcome1, assignment, 3)

        # Create stored rollup for outcome1 only (outcome2 has no results)
        OutcomeRollup.create!(
          course: @course,
          user: @student1,
          outcome: outcome1,
          calculation_method: "highest",
          aggregate_score: 3.0,
          last_calculated_at: Time.zone.now
        )

        get "rollups",
            params: {
              course_id: @course.id,
              outcome_ids: [outcome1.id, outcome2.id],
              exclude: ["missing_outcome_results"],
              include: ["outcomes"]
            },
            format: "json"

        expect(response).to be_successful
        json = parse_response(response)
        outcome_ids = json["linked"]["outcomes"].pluck("id")

        # Should include outcome1 (has results) but not outcome2 (no results)
        expect(outcome_ids).to include(outcome1.id)
        expect(outcome_ids).not_to include(outcome2.id)
        expect(json["linked"]["outcomes"].length).to eq(1)
      end

      it "includes all outcomes when filter is not applied and feature flag is enabled" do
        Account.site_admin.enable_feature!(:outcomes_rollup_read)

        # Create two outcomes
        outcome1 = outcome_model(context: @course, title: "Outcome with results")
        outcome2 = outcome_model(context: @course, title: "Outcome without results")

        # Create assignment and results for outcome1 only
        assignment = outcome_assignment
        create_result(@student1.id, outcome1, assignment, 3)

        # Create stored rollup for outcome1 only
        OutcomeRollup.create!(
          course: @course,
          user: @student1,
          outcome: outcome1,
          calculation_method: "highest",
          aggregate_score: 3.0,
          last_calculated_at: Time.zone.now
        )

        # Don't pass the exclude parameter
        get "rollups",
            params: {
              course_id: @course.id,
              outcome_ids: [outcome1.id, outcome2.id],
              include: ["outcomes"]
            },
            format: "json"

        expect(response).to be_successful
        json = parse_response(response)
        outcome_ids = json["linked"]["outcomes"].pluck("id")

        # Should include both outcomes when filter is not applied
        expect(outcome_ids).to include(outcome1.id)
        expect(outcome_ids).to include(outcome2.id)
        expect(json["linked"]["outcomes"].length).to eq(2)
      end

      it "filters students without results when feature flag is enabled" do
        Account.site_admin.enable_feature!(:outcomes_rollup_read)

        # student1 has results, student2 does not
        assignment = outcome_assignment
        create_result(@student1.id, @outcome, assignment, 3)

        # Create stored rollup for student1 only
        OutcomeRollup.create!(
          course: @course,
          user: @student1,
          outcome: @outcome,
          calculation_method: "highest",
          aggregate_score: 3.0,
          last_calculated_at: Time.zone.now
        )

        get "rollups",
            params: {
              course_id: @course.id,
              user_ids: [@student1.id, @student2.id],
              exclude: ["missing_user_rollups"],
              include: ["users"]
            },
            format: "json"

        expect(response).to be_successful
        json = parse_response(response)

        # Check rollups array
        user_ids_in_rollups = json["rollups"].pluck("links").pluck("user").map(&:to_i)
        expect(user_ids_in_rollups).to include(@student1.id)
        expect(user_ids_in_rollups).not_to include(@student2.id)
        expect(json["rollups"].length).to eq(1)

        # Check linked.users array - should match rollups
        user_ids_in_linked = json["linked"]["users"].pluck("id").map(&:to_i)
        expect(user_ids_in_linked).to include(@student1.id)
        expect(user_ids_in_linked).not_to include(@student2.id)
        expect(json["linked"]["users"].length).to eq(1)
      end

      it "includes all students when filter is not applied and feature flag is enabled" do
        Account.site_admin.enable_feature!(:outcomes_rollup_read)

        # student1 has results, student2 does not
        assignment = outcome_assignment
        create_result(@student1.id, @outcome, assignment, 3)

        # Create stored rollup for student1 only
        OutcomeRollup.create!(
          course: @course,
          user: @student1,
          outcome: @outcome,
          calculation_method: "highest",
          aggregate_score: 3.0,
          last_calculated_at: Time.zone.now
        )

        # Don't pass the exclude parameter
        get "rollups",
            params: {
              course_id: @course.id,
              user_ids: [@student1.id, @student2.id],
              include: ["users"]
            },
            format: "json"

        expect(response).to be_successful
        json = parse_response(response)

        # Check rollups array - should include both students
        user_ids_in_rollups = json["rollups"].pluck("links").pluck("user").map(&:to_i)
        expect(user_ids_in_rollups).to include(@student1.id)
        expect(user_ids_in_rollups).to include(@student2.id)
        expect(json["rollups"].length).to eq(2)

        # Check linked.users array - should also include both
        user_ids_in_linked = json["linked"]["users"].pluck("id").map(&:to_i)
        expect(user_ids_in_linked).to include(@student1.id)
        expect(user_ids_in_linked).to include(@student2.id)
        expect(json["linked"]["users"].length).to eq(2)
      end
    end

    context "StatsD metrics" do
      before do
        allow(InstStatsd::Statsd).to receive(:time).and_call_original
      end

      it "tracks runtime with outcomes_rollup_read tag when feature flag is off" do
        Account.site_admin.disable_feature!(:outcomes_rollup_read)
        get_rollups({})

        expect(InstStatsd::Statsd).to have_received(:time).with(
          "lmgb.rollup.endpoint.runtime",
          tags: { outcomes_rollup_read: "off" }
        )
      end

      it "tracks runtime with outcomes_rollup_read tag when feature flag is on" do
        Account.site_admin.enable_feature!(:outcomes_rollup_read)
        get_rollups({})

        expect(InstStatsd::Statsd).to have_received(:time).with(
          "lmgb.rollup.endpoint.runtime",
          tags: { outcomes_rollup_read: "on" }
        )
      end

      it "tracks runtime for CSV format" do
        Account.site_admin.disable_feature!(:outcomes_rollup_read)
        get "rollups",
            params: {
              context_id: @course.id,
              course_id: @course.id,
              context_type: "Course"
            },
            format: "csv"

        expect(InstStatsd::Statsd).to have_received(:time).with(
          "lmgb.rollup.endpoint.runtime",
          tags: { outcomes_rollup_read: "off" }
        )
      end

      it "does not track metrics for aggregate rollups since feature flag doesn't affect them" do
        Account.site_admin.disable_feature!(:outcomes_rollup_read)
        get_rollups({ aggregate: "course" })

        expect(InstStatsd::Statsd).not_to have_received(:time)
      end
    end
  end

  describe "enqueue_outcome_rollup_calculation" do
    before :once do
      course_with_teacher(active_all: true)
      course_with_student(course: @course, active_all: true)
      account_admin_user
    end

    let(:course) { @course }
    let(:teacher) { @teacher }
    let(:student) { @student }

    context "with valid parameters" do
      before do
        allow(Account.site_admin).to receive(:feature_enabled?).and_call_original
        allow(Account.site_admin).to receive(:feature_enabled?).with(:outcomes_rollup_propagation).and_return(true)
      end

      it "enqueues rollup calculation for specific student" do
        user_session(@teacher)
        expect(Outcomes::StudentOutcomeRollupCalculationService).to receive(:calculate_for_student)
          .with(course_id: course.id.to_s, student_id: student.id)

        post :enqueue_outcome_rollup_calculation,
             params: {
               course_id: course.id,
               student_uuid: student.uuid
             },
             format: :json

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body
        expect(json_response["message"]).to eq("Rollup calculation enqueued for student #{student.id} in course #{course.id}")
        expect(json_response["type"]).to eq("student")
      end
    end

    context "with missing or invalid course or student" do
      before do
        allow(Account.site_admin).to receive(:feature_enabled?).and_call_original
        allow(Account.site_admin).to receive(:feature_enabled?).with(:outcomes_rollup_propagation).and_return(true)
      end

      it "returns no content if student does not exist" do
        user_session(@teacher)
        non_existent_student_uuid = "888"
        post :enqueue_outcome_rollup_calculation, params: { course_id: course.id, student_uuid: non_existent_student_uuid }, format: :json
        expect(response).to have_http_status(:not_found)
        json_response = response.parsed_body
        expect(json_response["error"]).to match(/Invalid course or student/i)
      end
    end

    context "when service raises an exception" do
      before do
        allow(Account.site_admin).to receive(:feature_enabled?).and_call_original
        allow(Account.site_admin).to receive(:feature_enabled?).with(:outcomes_rollup_propagation).and_return(true)
      end

      it "returns unprocessable entity with error message for student calculation" do
        user_session(@teacher)
        error_message = "Something went wrong with student calculation"
        expect(Outcomes::StudentOutcomeRollupCalculationService).to receive(:calculate_for_student)
          .with(course_id: course.id.to_s, student_id: student.id)
          .and_raise(StandardError.new(error_message))

        post :enqueue_outcome_rollup_calculation,
             params: {
               course_id: course.id,
               student_uuid: student.uuid
             },
             format: :json

        expect(response).to have_http_status(:unprocessable_content)
        json_response = response.parsed_body
        expect(json_response["error"]).to eq(error_message)
      end

      it "returns no content when FF disabled" do
        allow(Account.site_admin).to receive(:feature_enabled?).and_call_original
        allow(Account.site_admin).to receive(:feature_enabled?).with(:outcomes_rollup_propagation).and_return(false)
        user_session(@teacher)
        post :enqueue_outcome_rollup_calculation, params: { course_id: course.id, student_uuid: student.uuid }, format: :json
        expect(response).to have_http_status(:no_content)
      end
    end
  end

  describe "#contributing_scores" do
    before :once do
      @course = outcome_course
      @teacher = outcome_teacher
      @student1 = outcome_student
      @student2 = student_in_course(active_all: true, course: @course, name: "Student 2").user

      outcome_rubric
      @assignment = @course.assignments.create!(title: "Test Assignment", points_possible: 10)
      @alignment = @outcome.align(@assignment, @course, mastery_score: 3)
      @rubric_association = @rubric.associate_with(@assignment, @course, purpose: "grading")
      @result1 = create_result(@student1.id, @outcome, @assignment, 8)
      @result2 = create_result(@student2.id, @outcome, @assignment, 6)
    end

    before do
      user_session(@teacher)
    end

    it "returns contributing scores for specified outcome and users" do
      alignments = @outcome.alignments.where(context: @course, content_type: "Assignment")
      expect(alignments.count).to be > 0, "Expected to find alignments for outcome"

      get :contributing_scores,
          params: {
            course_id: @course.id,
            outcome_id: @outcome.id,
            user_ids: [@student1.id, @student2.id]
          },
          format: :json

      expect(response).to be_successful
      json = response.parsed_body

      expect(json).to have_key("outcome")
      expect(json).to have_key("alignments")
      expect(json).to have_key("scores")

      expect(json["outcome"]["id"]).to eq(@outcome.id.to_s)
      expect(json["outcome"]["title"]).to eq(@outcome.title)

      expect(json["alignments"]).to be_an(Array)
      expect(json["alignments"].length).to be > 0

      alignment = json["alignments"].first
      expect(alignment).to have_key("alignment_id")
      expect(alignment).to have_key("associated_asset_id")
      expect(alignment).to have_key("associated_asset_name")
      expect(alignment).to have_key("associated_asset_type")
      expect(alignment["associated_asset_id"]).to be_present
      expect(alignment["associated_asset_name"]).to be_present
      expect(alignment["associated_asset_type"]).to be_present
      expect(alignment["alignment_id"]).to match(/^(D|I|E)_\d+/)

      expect(json["scores"]).to be_an(Array)

      if json["scores"].any?
        score = json["scores"].first
        expect(score).to have_key("user_id")
        expect(score).to have_key("alignment_id")
        expect(score).to have_key("score")
        expect(score["alignment_id"]).to match(/^(D|I|E)_\d+/)

        user_ids = json["scores"].pluck("user_id")
        expect(user_ids).to include(@student1.id.to_s, @student2.id.to_s)
      end
    end

    it "returns empty scores for users with no results" do
      @student3 = student_in_course(active_all: true, course: @course, name: "Student 3").user

      get :contributing_scores,
          params: {
            course_id: @course.id,
            outcome_id: @outcome.id,
            user_ids: [@student3.id]
          },
          format: :json

      expect(response).to be_successful
      json = response.parsed_body

      expect(json["scores"]).to be_an(Array)
      expect(json["scores"].length).to eq(0)
    end

    it "requires outcome to exist in context" do
      other_outcome = LearningOutcome.create!(title: "Other Outcome")

      get :contributing_scores,
          params: {
            course_id: @course.id,
            outcome_id: other_outcome.id,
            user_ids: [@student1.id]
          },
          format: :json

      expect(response).to have_http_status(:bad_request)
    end

    context "with unpublished assignments" do
      before :once do
        @published_assignment = @course.assignments.create!(title: "Published Assignment", workflow_state: "published")
        @unpublished_assignment = @course.assignments.create!(title: "Unpublished Assignment", workflow_state: "unpublished")
        @published_alignment = @outcome.align(@published_assignment, @course, mastery_score: 3)
        @unpublished_alignment = @outcome.align(@unpublished_assignment, @course, mastery_score: 3)
      end

      it "excludes unpublished assignments by default" do
        get :contributing_scores,
            params: {
              course_id: @course.id,
              outcome_id: @outcome.id,
              user_ids: [@student1.id],
              only_assignment_alignments: true
            },
            format: :json

        expect(response).to be_successful
        json = response.parsed_body

        alignment_names = json["alignments"].pluck("associated_asset_name")
        expect(alignment_names).to include("Published Assignment")
        expect(alignment_names).not_to include("Unpublished Assignment")
      end

      it "includes unpublished assignments when show_unpublished_assignments=true" do
        get :contributing_scores,
            params: {
              course_id: @course.id,
              outcome_id: @outcome.id,
              user_ids: [@student1.id],
              only_assignment_alignments: true,
              show_unpublished_assignments: true
            },
            format: :json

        expect(response).to be_successful
        json = response.parsed_body

        alignment_names = json["alignments"].pluck("associated_asset_name")
        expect(alignment_names).to include("Published Assignment")
        expect(alignment_names).to include("Unpublished Assignment")
      end

      it "excludes unpublished assignments when show_unpublished_assignments=false" do
        get :contributing_scores,
            params: {
              course_id: @course.id,
              outcome_id: @outcome.id,
              user_ids: [@student1.id],
              only_assignment_alignments: true,
              show_unpublished_assignments: false
            },
            format: :json

        expect(response).to be_successful
        json = response.parsed_body

        alignment_names = json["alignments"].pluck("associated_asset_name")
        expect(alignment_names).to include("Published Assignment")
        expect(alignment_names).not_to include("Unpublished Assignment")
      end
    end

    it "requires proper permissions" do
      @student_session = user_session(@student1)

      get :contributing_scores,
          params: {
            course_id: @course.id,
            outcome_id: @outcome.id,
            user_ids: [@student1.id]
          },
          format: :json

      expect(response).to have_http_status(:forbidden)
    end

    context "with only_assignment_alignments parameter" do
      before :once do
        @quiz = @course.quizzes.create!(title: "Test Quiz")
        @quiz_alignment = @outcome.align(@quiz, @course, mastery_score: 3)
      end

      it "returns only assignment alignments when only_assignment_alignments is true" do
        get :contributing_scores,
            params: {
              course_id: @course.id,
              outcome_id: @outcome.id,
              user_ids: [@student1.id, @student2.id],
              only_assignment_alignments: true
            },
            format: :json

        expect(response).to be_successful
        json = response.parsed_body

        expect(json["alignments"]).to be_an(Array)
        expect(json["alignments"].length).to be > 0

        json["alignments"].each do |alignment|
          expect(alignment["associated_asset_type"]).to eq("Assignment")
        end
      end

      it "returns all alignments when only_assignment_alignments is false" do
        get :contributing_scores,
            params: {
              course_id: @course.id,
              outcome_id: @outcome.id,
              user_ids: [@student1.id, @student2.id],
              only_assignment_alignments: false
            },
            format: :json

        expect(response).to be_successful
        json = response.parsed_body

        expect(json["alignments"]).to be_an(Array)
        alignment_types = json["alignments"].pluck("associated_asset_type").uniq
        expect(alignment_types.length).to be > 1
      end

      it "returns all alignments when only_assignment_alignments is not provided" do
        get :contributing_scores,
            params: {
              course_id: @course.id,
              outcome_id: @outcome.id,
              user_ids: [@student1.id, @student2.id]
            },
            format: :json

        expect(response).to be_successful
        json = response.parsed_body

        expect(json["alignments"]).to be_an(Array)
        alignment_types = json["alignments"].pluck("associated_asset_type").uniq
        expect(alignment_types.length).to be > 1
      end
    end
  end
end
