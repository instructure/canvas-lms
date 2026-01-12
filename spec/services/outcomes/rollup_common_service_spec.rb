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

describe Outcomes::RollupCommonService do
  subject { test_service_class.new }

  let(:test_service_class) do
    Class.new(Outcomes::RollupCommonService)
  end

  let(:course) { course_model }
  let(:student) { user_model }
  let(:teacher) { user_model }
  let(:outcome) { outcome_model(context: course) }
  let(:assignment) { assignment_model(course:) }

  before do
    course.enroll_student(student, enrollment_state: "active")
    course.enroll_teacher(teacher, enrollment_state: "active")
    course.root_outcome_group.add_outcome(outcome)
  end

  describe "#fetch_canvas_results" do
    let!(:learning_outcome_result) do
      LearningOutcomeResult.create!(
        learning_outcome: outcome,
        user: student,
        context: course,
        alignment: ContentTag.create!(
          content: assignment,
          context: course,
          learning_outcome: outcome,
          tag_type: "learning_outcome",
          workflow_state: "active"
        ),
        score: 3.0,
        possible: 5.0,
        mastery: false,
        workflow_state: "active"
      )
    end

    it "fetches Canvas results for specified users and course" do
      results = subject.fetch_canvas_results(course:, users: [student])

      expect(results).to be_a(ActiveRecord::Relation)
      expect(results.count).to eq(1)
      expect(results.first).to eq(learning_outcome_result)
    end

    it "returns empty relation when no results exist" do
      LearningOutcomeResult.destroy_all
      results = subject.fetch_canvas_results(course:, users: [student])

      expect(results).to be_empty
    end

    it "filters by specific outcomes when provided" do
      outcome2 = outcome_model(context: course)
      course.root_outcome_group.add_outcome(outcome2)

      LearningOutcomeResult.create!(
        learning_outcome: outcome2,
        user: student,
        context: course,
        alignment: ContentTag.create!(
          content: assignment,
          context: course,
          learning_outcome: outcome2,
          tag_type: "learning_outcome",
          workflow_state: "active"
        ),
        score: 4.0,
        possible: 5.0,
        mastery: true,
        workflow_state: "active"
      )

      results = subject.fetch_canvas_results(
        course:,
        users: [student],
        outcomes: [outcome]
      )

      expect(results.count).to eq(1)
      expect(results.first.learning_outcome).to eq(outcome)
    end

    it "uses all course linked outcomes when outcomes parameter is nil" do
      results = subject.fetch_canvas_results(course:, users: [student])

      expect(results.count).to eq(1)
    end

    it "handles multiple users" do
      student2 = user_model
      course.enroll_student(student2, enrollment_state: "active")

      LearningOutcomeResult.create!(
        learning_outcome: outcome,
        user: student2,
        context: course,
        alignment: ContentTag.create!(
          content: assignment,
          context: course,
          learning_outcome: outcome,
          tag_type: "learning_outcome",
          workflow_state: "active"
        ),
        score: 2.5,
        possible: 5.0,
        mastery: false,
        workflow_state: "active"
      )

      results = subject.fetch_canvas_results(
        course:,
        users: [student, student2]
      )

      expect(results.count).to eq(2)
      expect(results.map(&:user)).to contain_exactly(student, student2)
    end

    it "directly queries LearningOutcomeResult without permission checks" do
      results = subject.fetch_canvas_results(course:, users: [student])

      expect(results).to be_a(ActiveRecord::Relation)
      expect(results.to_sql).to include("learning_outcome_results")
      expect(results.to_sql).to include("hidden")
      expect(results.to_sql).not_to include("exclude_muted")
    end
  end

  describe "#fetch_outcomes_service_results" do
    let(:quiz_lti_assignment) do
      assignment_model(
        course:,
        submission_types: "external_tool"
      ).tap do |a|
        a.external_tool_tag = ContentTag.create!(
          content_type: "ContextExternalTool",
          context: course,
          url: "http://example.com/launch"
        )
        a.save!
      end
    end

    before do
      where_scope = class_double(Assignment)
      active_scope = class_double(Assignment)

      allow(Assignment).to receive(:active).and_return(active_scope)
      allow(active_scope).to receive(:where).and_return(where_scope)
      allow(where_scope).to receive(:quiz_lti).and_return([quiz_lti_assignment])
    end

    it "returns empty array when no quiz LTI assignments exist" do
      where_scope = class_double(Assignment)
      active_scope = class_double(Assignment)

      allow(Assignment).to receive(:active).and_return(active_scope)
      allow(active_scope).to receive(:where).and_return(where_scope)
      allow(where_scope).to receive(:quiz_lti).and_return([])

      results = subject.fetch_outcomes_service_results(
        course:,
        users: [student]
      )

      expect(results).to eq([])
    end

    it "returns empty array when no outcomes are linked" do
      course.root_outcome_group.child_outcome_links.destroy_all

      results = subject.fetch_outcomes_service_results(
        course:,
        users: [student]
      )

      expect(results).to eq([])
    end

    it "calls find_outcomes_service_outcome_results with correct parameters" do
      expect(subject).to receive(:find_outcomes_service_outcome_results).with(
        users: [student],
        context: course,
        outcomes: course.linked_learning_outcomes,
        assignments: [quiz_lti_assignment]
      ).and_return(nil)

      subject.fetch_outcomes_service_results(
        course:,
        users: [student]
      )
    end

    it "handles outcomes service results when present" do
      os_results_json = [
        {
          "user_uuid" => student.uuid,
          "outcome_id" => outcome.id,
          "score" => 4.0,
          "possible" => 5.0
        }
      ]

      allow(subject).to receive(:find_outcomes_service_outcome_results)
        .and_return(os_results_json)

      expect(subject).to receive(:handle_outcomes_service_results).with(
        os_results_json,
        course,
        course.linked_learning_outcomes,
        [student],
        [quiz_lti_assignment]
      ).and_return([])

      subject.fetch_outcomes_service_results(
        course:,
        users: [student]
      )
    end

    it "filters by specific outcomes when provided" do
      specific_outcomes = [outcome]

      expect(subject).to receive(:find_outcomes_service_outcome_results).with(
        users: [student],
        context: course,
        outcomes: specific_outcomes,
        assignments: [quiz_lti_assignment]
      ).and_return(nil)

      subject.fetch_outcomes_service_results(
        course:,
        users: [student],
        outcomes: specific_outcomes
      )
    end

    it "filters by specific assignments when provided" do
      specific_assignments = [quiz_lti_assignment]

      expect(subject).to receive(:find_outcomes_service_outcome_results).with(
        users: [student],
        context: course,
        outcomes: course.linked_learning_outcomes,
        assignments: specific_assignments
      ).and_return(nil)

      subject.fetch_outcomes_service_results(
        course:,
        users: [student],
        assignments: specific_assignments
      )
    end
  end

  describe "#combine_results" do
    let(:canvas_result1) do
      LearningOutcomeResult.new(
        learning_outcome_id: 1,
        user_id: 10,
        artifact_id: 100,
        score: 3.0
      )
    end

    let(:canvas_result2) do
      LearningOutcomeResult.new(
        learning_outcome_id: 2,
        user_id: 10,
        artifact_id: 200,
        score: 4.0
      )
    end

    let(:os_result1) do
      LearningOutcomeResult.new(
        learning_outcome_id: 1,
        user_uuid: "uuid-10",
        user_id: 10,
        associated_asset_id: 300,
        score: 5.0
      )
    end

    let(:os_result_duplicate) do
      LearningOutcomeResult.new(
        learning_outcome_id: 1,
        user_id: 10,
        user_uuid: nil,
        artifact_id: 100,
        associated_asset_id: nil,
        score: 6.0
      )
    end

    it "returns canvas results when outcomes results are blank" do
      canvas_results = [canvas_result1, canvas_result2]
      combined = subject.combine_results(canvas_results, [])

      expect(combined).to eq(canvas_results)
    end

    it "returns outcomes results when canvas results are blank" do
      os_results = [os_result1]
      combined = subject.combine_results([], os_results)

      expect(combined).to eq(os_results)
    end

    it "returns empty array when both sources are blank" do
      combined = subject.combine_results([], [])

      expect(combined).to eq([])
    end

    it "combines results from both sources" do
      canvas_results = [canvas_result1, canvas_result2]
      os_results = [os_result1]

      combined = subject.combine_results(canvas_results, os_results)

      expect(combined.size).to eq(3)
      expect(combined).to include(canvas_result1, canvas_result2, os_result1)
    end

    it "deduplicates results based on outcome, user, and asset" do
      canvas_results = [canvas_result1]
      os_results = [os_result_duplicate]

      combined = subject.combine_results(canvas_results, os_results)

      expect(combined.size).to eq(1)
      expect(combined.first).to eq(canvas_result1)
    end

    it "handles ActiveRecord relations" do
      canvas_results = double("ActiveRecord::Relation", to_a: [canvas_result1])
      os_results = [os_result1]

      combined = subject.combine_results(canvas_results, os_results)

      expect(combined.size).to eq(2)
    end
  end

  describe "#generate_rollups" do
    let(:result1) do
      LearningOutcomeResult.new(
        learning_outcome: outcome,
        user: student,
        score: 4.0,
        possible: 5.0
      )
    end

    let(:result2) do
      LearningOutcomeResult.new(
        learning_outcome: outcome,
        user: student,
        score: 3.0,
        possible: 5.0
      )
    end

    it "returns empty array for empty results" do
      rollups = subject.generate_rollups([], [student], course)

      expect(rollups).to eq([])
    end

    it "preloads learning outcomes" do
      results = [result1, result2]

      expect(ActiveRecord::Associations).to receive(:preload)
        .with(results, :learning_outcome)

      allow(subject).to receive(:outcome_results_rollups).and_return([])

      subject.generate_rollups(results, [student], course)
    end

    it "calls outcome_results_rollups with correct parameters" do
      results = [result1, result2]
      users = [student]

      expect(subject).to receive(:outcome_results_rollups).with(
        results:,
        users:,
        context: course
      ).and_return([])

      subject.generate_rollups(results, users, course)
    end

    it "returns rollup objects from outcome_results_rollups" do
      results = [result1]
      mock_rollup = double("Rollup")

      allow(subject).to receive(:outcome_results_rollups)
        .and_return([mock_rollup])

      rollups = subject.generate_rollups(results, [student], course)

      expect(rollups).to eq([mock_rollup])
    end
  end

  describe "#build_rollup_rows" do
    let(:submitted_at1) { 2.days.ago }
    let(:submitted_at2) { 1.day.ago }

    let(:score1) do
      double("Score",
             outcome:,
             score: 4.0,
             submitted_at: submitted_at1,
             title: "Assignment 1")
    end

    let(:score2) do
      double("Score",
             outcome: double("Outcome", id: 2, calculation_method: "highest"),
             score: 3.5,
             submitted_at: submitted_at2,
             title: "Assignment 2")
    end

    let(:nil_score) do
      double("Score",
             outcome: double("Outcome", id: 3, calculation_method: "n_mastery"),
             score: nil,
             submitted_at: nil,
             title: nil)
    end

    let(:rollup) do
      double("Rollup", scores: [score1, score2, nil_score])
    end

    before do
      allow(outcome).to receive_messages(id: 1, calculation_method: "average")
      allow(course).to receive(:root_account_id).and_return(100)
    end

    it "builds database rows from rollup scores" do
      rows = subject.build_rollup_rows(rollup, course, student)

      expect(rows.size).to eq(2)

      expect(rows[0]).to include(
        root_account_id: 100,
        course_id: course.id,
        user_id: student.id,
        outcome_id: 1,
        calculation_method: "average",
        aggregate_score: 4.0,
        submitted_at: submitted_at1,
        title: "Assignment 1",
        workflow_state: "active"
      )

      expect(rows[1]).to include(
        outcome_id: 2,
        calculation_method: "highest",
        aggregate_score: 3.5,
        submitted_at: submitted_at2,
        title: "Assignment 2"
      )
    end

    it "filters out scores with nil values" do
      rollup_with_nil = double("Rollup", scores: [nil_score])

      rows = subject.build_rollup_rows(rollup_with_nil, course, student)

      expect(rows).to be_empty
    end

    it "handles empty scores array" do
      empty_rollup = double("Rollup", scores: [])

      rows = subject.build_rollup_rows(empty_rollup, course, student)

      expect(rows).to be_empty
    end

    it "includes all required fields for database insertion" do
      rollup_with_one_score = double("Rollup", scores: [score1])

      rows = subject.build_rollup_rows(rollup_with_one_score, course, student)

      expect(rows.first.keys).to contain_exactly(
        :root_account_id,
        :course_id,
        :user_id,
        :outcome_id,
        :calculation_method,
        :aggregate_score,
        :submitted_at,
        :title,
        :workflow_state,
        :last_calculated_at
      )
    end
  end
end
