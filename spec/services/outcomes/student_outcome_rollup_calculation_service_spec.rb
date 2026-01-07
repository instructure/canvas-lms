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

describe Outcomes::StudentOutcomeRollupCalculationService do
  subject { Outcomes::StudentOutcomeRollupCalculationService.new(course_id: course.id, student_id: student.id) }

  let(:course) { course_model }
  let(:student) { user_model }

  before do
    course.enroll_student(student, enrollment_state: "active")
  end

  describe ".calculate_for_student" do
    let(:delay_mock) { class_double(described_class) }

    it "enqueues a delayed job to calculate student outcome rollups" do
      Timecop.freeze do
        delay_args = {
          run_at: 1.minute.from_now,
          on_conflict: :overwrite,
          singleton: "calculate_for_student:#{course.id}:#{student.id}"
        }

        expect(Outcomes::StudentOutcomeRollupCalculationService).to receive(:delay).with(delay_args).and_return(delay_mock)
        expect(delay_mock).to receive(:call).with(course_id: course.id, student_id: student.id)

        Outcomes::StudentOutcomeRollupCalculationService.calculate_for_student(course_id: course.id, student_id: student.id)
      end
    end
  end

  describe ".calculate_for_course" do
    let(:students) { Array.new(15) { user_model } }

    before do
      # Enroll 15 students in the course
      students.each { |student| course.enroll_student(student) }
    end

    it "calls calculate_for_student for each student in the course" do
      # Get all enrolled student IDs to account for any existing enrollments
      enrolled_student_ids = course.students.pluck(:id)

      # Expect calculate_for_student to be called exactly once for each enrolled student
      expect(Outcomes::StudentOutcomeRollupCalculationService).to receive(:calculate_for_student)
        .exactly(enrolled_student_ids.count).times do |args|
        expect(args[:course_id]).to eq(course.id)
        expect(enrolled_student_ids).to include(args[:student_id])
      end

      Outcomes::StudentOutcomeRollupCalculationService.calculate_for_course(course_id: course.id)
    end

    it "finds the course by ID" do
      expect(Course).to receive(:find).with(course.id).and_return(course)

      # We need to stub calculate_for_student here to prevent actual calls
      allow(Outcomes::StudentOutcomeRollupCalculationService).to receive(:calculate_for_student)

      Outcomes::StudentOutcomeRollupCalculationService.calculate_for_course(course_id: course.id)
    end

    it "calls the students method on the course" do
      # Set up Course.find to return our course
      expect(Course).to receive(:find).with(course.id).and_return(course)

      # Expect the students method to be called on the course and allow it to return its normal value
      expect(course).to receive(:students).and_call_original

      # We need to stub calculate_for_student to prevent actual calls
      allow(Outcomes::StudentOutcomeRollupCalculationService).to receive(:calculate_for_student)

      Outcomes::StudentOutcomeRollupCalculationService.calculate_for_course(course_id: course.id)
    end
  end

  describe "#initialize" do
    it "loads the course and student after initialization" do
      expect(subject.course).to eq(course)
      expect(subject.student).to eq(student)
    end

    it "raises ArgumentError when course_id is invalid" do
      expect do
        Outcomes::StudentOutcomeRollupCalculationService.new(course_id: -1, student_id: student.id)
      end.to raise_error(ArgumentError, /Invalid course_id \(-1\) or student_id \(#{student.id}\)/)
    end

    it "raises ArgumentError when student_id is invalid" do
      expect do
        Outcomes::StudentOutcomeRollupCalculationService.new(course_id: course.id, student_id: -1)
      end.to raise_error(ArgumentError, /Invalid course_id \(#{course.id}\) or student_id \(-1\)/)
    end

    it "raises ArgumentError when both course_id and student_id are invalid" do
      expect do
        Outcomes::StudentOutcomeRollupCalculationService.new(course_id: -1, student_id: -1)
      end.to raise_error(ArgumentError, /Invalid course_id \(-1\) or student_id \(-1\)/)
    end

    it "raises ArgumentError when student is not enrolled in the course" do
      other_student = user_model
      expect do
        Outcomes::StudentOutcomeRollupCalculationService.new(course_id: course.id, student_id: other_student.id)
      end.to raise_error(ArgumentError, /Invalid course_id \(#{course.id}\) or student_id \(#{other_student.id}\)/)
    end
  end

  describe "#fetch_canvas_results" do
    let(:outcome) { outcome_model(context: course) }
    let(:assignment) { assignment_model(context: course) }
    let(:alignment) { outcome.align(assignment, course) }

    it "returns an empty relation when no results exist" do
      results = subject.send(:fetch_canvas_results, course:, users: [student])
      expect(results).to be_empty
    end

    context "with learning outcome results" do
      let(:user2) { user_model }

      before do
        [student, user2].each do |user|
          LearningOutcomeResult.create!(
            learning_outcome: outcome,
            user:,
            context: course,
            alignment:
          )
        end
      end

      it "returns learning outcome results associated to the user" do
        results = subject.send(:fetch_canvas_results, course:, users: [student])
        expect(results.count).to eq(1)
        expect(results.first.user_id).to eq(student.id)
      end
    end

    context "with results in different states" do
      let(:outcome1) { outcome_model(context: course) }
      let(:outcome2) { outcome_model(context: course) }
      let(:assignment1) { assignment_model(context: course) }
      let(:assignment2) { assignment_model(context: course) }
      let(:alignment1) { outcome1.align(assignment1, course) }
      let(:alignment2) { outcome2.align(assignment2, course) }
      let(:other_user) { user_model }

      before do
        @active_result = LearningOutcomeResult.create!(
          learning_outcome: outcome1,
          user: student,
          context: course,
          alignment: alignment1,
          score: 3,
          possible: 5,
          workflow_state: "active",
          hidden: false
        )

        # Hidden result (should be excluded)
        @hidden_result = LearningOutcomeResult.create!(
          learning_outcome: outcome1,
          user: student,
          context: course,
          alignment: alignment1,
          score: 4,
          possible: 5,
          workflow_state: "active",
          hidden: true
        )

        # Deleted result (should be excluded)
        @deleted_result = LearningOutcomeResult.create!(
          learning_outcome: outcome1,
          user: student,
          context: course,
          alignment: alignment1,
          score: 2,
          possible: 5,
          workflow_state: "deleted",
          hidden: false
        )

        # Result with deleted alignment (should be excluded)
        alignment2.update!(workflow_state: "deleted")
        @deleted_link_result = LearningOutcomeResult.create!(
          learning_outcome: outcome2,
          user: student,
          context: course,
          alignment: alignment2,
          score: 5,
          possible: 5,
          workflow_state: "active",
          hidden: false
        )

        # Result for different user (should be excluded)
        @other_user_result = LearningOutcomeResult.create!(
          learning_outcome: outcome1,
          user: other_user,
          context: course,
          alignment: alignment1,
          score: 1,
          possible: 5,
          workflow_state: "active",
          hidden: false
        )
      end

      it "only returns active results with active links" do
        results = subject.send(:fetch_canvas_results, course:, users: [student])

        # Verify results - should only include the active result with active link
        expect(results.count).to eq(1)
        expect(results.first).to eq(@active_result)
        expect(results.first.workflow_state).to eq("active")
        expect(results.first.hidden).to be false
        expect(results.first.user_id).to eq(student.id)
        expect(results.first.alignment.workflow_state).to eq("active")
      end
    end
  end

  describe "#combine_results" do
    let(:outcome) { outcome_model(context: course) }
    let(:outcome2) { outcome_model(context: course) }
    let(:assignment) { assignment_model(context: course) }
    let(:assignment2) { assignment_model(context: course) }

    it "returns canvas results when outcomes service results are empty" do
      canvas_results = [LearningOutcomeResult.new]
      result = subject.send(:combine_results, canvas_results, [])
      expect(result).to eq(canvas_results)

      relation = instance_double(ActiveRecord::Relation)
      allow(relation).to receive(:to_a).and_return(canvas_results)
      result = subject.send(:combine_results, relation, [])
      expect(result).to eq(canvas_results)
    end

    it "returns outcomes service results when canvas results are empty" do
      os_results = [LearningOutcomeResult.new]
      result = subject.send(:combine_results, [], os_results)
      expect(result).to eq(os_results)
    end

    it "handles nil parameters by treating them as empty arrays" do
      canvas_results = [LearningOutcomeResult.new]
      result = subject.send(:combine_results, canvas_results, nil)
      expect(result).to eq(canvas_results)

      os_results = [LearningOutcomeResult.new]
      result = subject.send(:combine_results, nil, os_results)
      expect(result).to eq(os_results)
    end

    context "with results from both sources" do
      let(:canvas_result) { LearningOutcomeResult.new(learning_outcome_id: outcome.id) }
      let(:os_result) { LearningOutcomeResult.new(learning_outcome_id: outcome2.id) }

      it "combines results from both sources" do
        result = subject.send(:combine_results, [canvas_result], [os_result])
        expect(result.length).to eq(2)
        expect(result).to include(canvas_result)
        expect(result).to include(os_result)
      end
    end

    context "with duplicate results" do
      let(:canvas_result) do
        LearningOutcomeResult.new(
          learning_outcome_id: outcome.id,
          user_uuid: student.uuid,
          associated_asset_id: assignment.id
        )
      end

      let(:os_result) do
        LearningOutcomeResult.new(
          learning_outcome_id: outcome.id,
          user_uuid: student.uuid,
          associated_asset_id: assignment.id
        )
      end

      it "deduplicates results with same outcome, user, and assignment" do
        result = subject.send(:combine_results, [canvas_result], [os_result])
        expect(result.length).to eq(1)
        # Canvas results should be preferred over OS results when keys are identical
        expect(result.first).to eq(canvas_result)
      end
    end

    context "with different outcomes" do
      let(:canvas_result) do
        LearningOutcomeResult.new(
          learning_outcome_id: outcome.id,
          user_uuid: student.uuid,
          associated_asset_id: assignment.id
        )
      end

      let(:os_result) do
        LearningOutcomeResult.new(
          learning_outcome_id: outcome2.id,
          user_uuid: student.uuid,
          associated_asset_id: assignment.id
        )
      end

      it "keeps results with different outcomes" do
        result = subject.send(:combine_results, [canvas_result], [os_result])
        expect(result.length).to eq(2)
      end
    end

    context "with different assignments" do
      let(:canvas_result) do
        LearningOutcomeResult.new(
          learning_outcome_id: outcome.id,
          user_uuid: student.uuid,
          associated_asset_id: assignment.id
        )
      end

      let(:os_result) do
        LearningOutcomeResult.new(
          learning_outcome_id: outcome.id,
          user_uuid: student.uuid,
          associated_asset_id: assignment2.id
        )
      end

      it "keeps results with different assignments" do
        result = subject.send(:combine_results, [canvas_result], [os_result])
        expect(result.length).to eq(2)
      end
    end
  end

  describe "#call" do
    let(:outcome) { outcome_model(context: course) }
    let(:assignment) { assignment_model(context: course) }
    let(:alignment) { outcome.align(assignment, course) }
    let(:rubric) { rubric_model(context: course) }
    let(:rubric_association) { rubric.associate_with(assignment, course, purpose: "grading") }

    it "returns an empty relation when no results exist" do
      results = subject.call
      expect(results).to be_empty
    end

    context "with outcome results" do
      before do
        # Set up the outcome with proper rubric criterion
        outcome.rubric_criterion = {
          mastery_points: 3,
          points_possible: 5,
          ratings: [
            { points: 5, description: "Exceeds" },
            { points: 3, description: "Meets" },
            { points: 0, description: "Does Not Meet" }
          ]
        }
        outcome.calculation_method = "highest"
        outcome.save!

        # Create an outcome result for the student
        LearningOutcomeResult.create!(
          learning_outcome: outcome,
          user: student,
          context: course,
          alignment:,
          score: 3,
          possible: 5
        )
      end

      it "returns rollups with the correct structure" do
        rollups = subject.call

        # Verify the structure
        expect(rollups.size).to eq(1)

        rollup = rollups.first
        expect(rollup).to be_an(OutcomeRollup)
        expect(rollup.outcome_id).to eq(outcome.id)
        expect(rollup.aggregate_score).to eq(3)
      end
    end

    context "combining Canvas and Outcomes Service results" do
      before do
        # Set up the outcome with proper rubric criterion and calculation method
        outcome.rubric_criterion = {
          mastery_points: 3,
          points_possible: 5,
          ratings: [
            { points: 5, description: "Exceeds" },
            { points: 3, description: "Meets" },
            { points: 0, description: "Does Not Meet" }
          ]
        }
        outcome.calculation_method = "highest"
        outcome.save!
      end

      let(:canvas_result) do
        LearningOutcomeResult.create!(
          learning_outcome: outcome,
          user: student,
          context: course,
          alignment:,
          score: 3,
          possible: 5
        )
      end

      let(:os_result) do
        LearningOutcomeResult.new(
          learning_outcome: outcome,
          user: student,
          context: course,
          alignment:,
          score: 4,
          possible: 5,
          associated_asset_id: assignment.id + 1
        )
      end

      before do
        canvas_result # Create the canvas result
        # Mock the fetching of Outcomes Service results
        allow(subject).to receive(:fetch_outcomes_service_results).and_return([os_result])
      end

      it "combines Canvas and Outcomes Service results" do
        rollups = subject.call

        # We should get one rollup
        expect(rollups).to be_an(ActiveRecord::Relation)
        expect(rollups.size).to eq(1)

        rollup = rollups.find_by(outcome_id: outcome.id)
        expect(rollup).to be_present
        expect(rollup.aggregate_score).to eq(4)
      end

      context "with different outcomes in Canvas and Outcomes Service" do
        let(:outcome2) { outcome_model(context: course) }
        let(:assignment2) { assignment_model(context: course) }
        let(:alignment2) { outcome2.align(assignment2, course) }

        let(:canvas_result) do
          LearningOutcomeResult.create!(
            learning_outcome: outcome,
            user: student,
            context: course,
            alignment:,
            score: 3,
            possible: 5
          )
        end

        let(:os_result) do
          LearningOutcomeResult.new(
            learning_outcome: outcome2,
            user: student,
            context: course,
            alignment: alignment2,
            score: 4,
            possible: 5,
            associated_asset_id: assignment2.id
          )
        end

        before do
          # Set up second outcome with proper rubric criterion and calculation method
          outcome2.rubric_criterion = {
            mastery_points: 3,
            points_possible: 5,
            ratings: [
              { points: 5, description: "Exceeds" },
              { points: 3, description: "Meets" },
              { points: 0, description: "Does Not Meet" }
            ]
          }
          outcome2.calculation_method = "highest"
          outcome2.save!

          canvas_result # Create the canvas result
          # Mock the fetching of Outcomes Service results
          allow(subject).to receive(:fetch_outcomes_service_results).and_return([os_result])
        end

        it "creates separate rollups for different outcomes" do
          rollups = subject.call

          # We should get two rollups, one for each outcome
          expect(rollups.size).to eq(2)

          outcome1_rollup = rollups.find_by(outcome_id: outcome.id)
          outcome2_rollup = rollups.find_by(outcome_id: outcome2.id)

          expect(outcome1_rollup).to be_present
          expect(outcome1_rollup.aggregate_score).to eq(3) # Canvas result score

          expect(outcome2_rollup).to be_present
          expect(outcome2_rollup.aggregate_score).to eq(4) # OS result score
        end
      end
    end
  end

  describe "#generate_student_rollups" do
    let(:outcome1) { outcome_model(context: course) }
    let(:outcome2) { outcome_model(context: course) }
    let(:assignment) { assignment_model(context: course) }

    it "returns an empty array when no results are provided" do
      rollups = subject.send(:generate_rollups, [], [student], course)
      expect(rollups).to be_an(Array)
      expect(rollups).to be_empty
    end

    context "with multiple outcomes" do
      let(:alignment1) { outcome1.align(assignment, course) }
      let(:alignment2) { outcome2.align(assignment, course) }

      before do
        # Set up the outcomes with proper rubric criterion and calculation methods
        [outcome1, outcome2].each do |outcome|
          outcome.rubric_criterion = {
            mastery_points: 3,
            points_possible: 5,
            ratings: [
              { points: 5, description: "Exceeds" },
              { points: 3, description: "Meets" },
              { points: 0, description: "Does Not Meet" }
            ]
          }
          outcome.calculation_method = "highest"
          outcome.save!
        end

        # Create learning outcome results for different outcomes
        @result1 = LearningOutcomeResult.create!(
          learning_outcome: outcome1,
          user: student,
          context: course,
          alignment: alignment1,
          score: 3,
          possible: 5
        )

        @result2 = LearningOutcomeResult.create!(
          learning_outcome: outcome2,
          user: student,
          context: course,
          alignment: alignment2,
          score: 4,
          possible: 5
        )
      end

      it "correctly groups results by outcome" do
        # Generate rollups
        rollups = subject.send(:generate_rollups, [@result1, @result2], [student], course)

        # We should have one rollup for the student
        expect(rollups.size).to eq(1)

        # The rollup should have two scores (one for each outcome)
        expect(rollups.first.scores.size).to eq(2)

        # Verify each outcome has the correct score
        outcome1_score = rollups.first.scores.find { |s| s.outcome.id == outcome1.id }
        outcome2_score = rollups.first.scores.find { |s| s.outcome.id == outcome2.id }

        expect(outcome1_score.score).to eq(3)
        expect(outcome2_score.score).to eq(4)
      end
    end
  end

  describe "error handling" do
    subject { Outcomes::StudentOutcomeRollupCalculationService.new(course_id: course.id, student_id: student.id) }

    let(:course) { course_model }
    let(:student) { user_model }
    let(:outcome) { outcome_model(context: course) }
    let(:assignment) { assignment_model(context: course) }
    let(:alignment) { outcome.align(assignment, course) }

    context "with Outcomes Service errors" do
      let(:quiz_assignment) { assignment_model(context: course) }

      before do
        # Mock only the quiz_lti scope to return our quiz assignment
        where_scope = class_double(Assignment)
        active_scope = class_double(Assignment)

        allow(Assignment).to receive(:active).and_return(active_scope)
        allow(active_scope).to receive(:where).and_return(where_scope)
        allow(where_scope).to receive(:quiz_lti).and_return([quiz_assignment])

        # Stub course.linked_learning_outcomes to return our outcome
        allow(course).to receive(:linked_learning_outcomes).and_return([outcome])

        # Create a Canvas result first
        @canvas_result = LearningOutcomeResult.create!(
          learning_outcome: outcome,
          user: student,
          context: course,
          alignment:,
          score: 3,
          possible: 5
        )
      end

      it "raises an error when Outcomes Service fails to prevent inaccurate rollups" do
        # Mock the outcomes service to throw an error
        allow(subject).to receive(:get_lmgb_results).and_raise(StandardError, "API error")

        # Service should fail when OS call fails to prevent inaccurate rollups
        expect { subject.call }.to raise_error(StandardError, "API error")
      end
    end
  end

  describe "instrumentation metrics" do
    subject { Outcomes::StudentOutcomeRollupCalculationService.new(course_id: course.id, student_id: student.id) }

    let(:course) { course_model }
    let(:student) { user_model }
    let(:outcome) { outcome_model(context: course) }
    let(:assignment) { assignment_model(context: course) }
    let(:alignment) { outcome.align(assignment, course) }

    before do
      outcome.rubric_criterion = {
        mastery_points: 3,
        points_possible: 5,
        ratings: [
          { points: 5, description: "Exceeds" },
          { points: 3, description: "Meets" },
          { points: 0, description: "Does Not Meet" }
        ]
      }
      outcome.calculation_method = "highest"
      outcome.save!
    end

    it "records all metrics on successful execution" do
      LearningOutcomeResult.create!(
        learning_outcome: outcome,
        user: student,
        context: course,
        alignment:,
        score: 3,
        possible: 5
      )

      expect(Utils::InstStatsdUtils::Timing).to receive(:track).with("rollup.student.runtime").and_call_original
      expect(InstStatsd::Statsd).to receive(:distributed_increment).with("rollup.student.success", tags: { cluster: course.shard.database_server&.id }).at_least(:once)
      expect(InstStatsd::Statsd).to receive(:count).with("rollup.student.records_processed", 1, tags: { cluster: course.shard.database_server&.id }).at_least(:once)
      allow(InstStatsd::Statsd).to receive(:distributed_increment)

      subject.call
    end

    it "records metrics on error" do
      allow(subject).to receive(:fetch_canvas_results).and_raise(StandardError, "Database error")

      expect(Utils::InstStatsdUtils::Timing).to receive(:track).with("rollup.student.runtime").and_call_original
      expect(InstStatsd::Statsd).to receive(:distributed_increment).with("rollup.student.error", tags: { cluster: course.shard.database_server&.id }).at_least(:once)
      expect(InstStatsd::Statsd).to receive(:count).with("rollup.student.records_processed", 0, tags: { cluster: course.shard.database_server&.id }).at_least(:once)
      allow(InstStatsd::Statsd).to receive(:distributed_increment)

      expect { subject.call }.to raise_error(StandardError, "Database error")
    end

    it "records metrics for empty results" do
      expect(Utils::InstStatsdUtils::Timing).to receive(:track).with("rollup.student.runtime").and_call_original
      expect(InstStatsd::Statsd).to receive(:distributed_increment).with("rollup.student.success", tags: { cluster: course.shard.database_server&.id }).at_least(:once)
      expect(InstStatsd::Statsd).to receive(:count).with("rollup.student.records_processed", 0, tags: { cluster: course.shard.database_server&.id }).at_least(:once)
      allow(InstStatsd::Statsd).to receive(:distributed_increment)

      subject.call
    end
  end

  describe "edge cases" do
    subject { Outcomes::StudentOutcomeRollupCalculationService.new(course_id: course.id, student_id: student.id) }

    let(:course) { course_model }
    let(:student) { user_model }

    context "with large number of outcomes" do
      before do
        # Create a large number of outcomes and results
        @outcomes = []
        5.times do |i|
          outcome = outcome_model(context: course)
          outcome.rubric_criterion = {
            mastery_points: 3,
            points_possible: 5,
            ratings: [
              { points: 5, description: "Exceeds" },
              { points: 3, description: "Meets" },
              { points: 0, description: "Does Not Meet" }
            ]
          }
          outcome.save!
          @outcomes << outcome

          assignment = assignment_model(context: course)
          alignment = outcome.align(assignment, course)

          LearningOutcomeResult.create!(
            learning_outcome: outcome,
            user: student,
            context: course,
            alignment:,
            score: i,
            possible: 5
          )
        end
      end

      it "handles a large number of outcomes" do
        # Service should handle multiple outcomes
        rollups = subject.call
        expect(rollups.size).to eq(5) # Five rollups, one per outcome
      end
    end
  end

  describe "calculation scenarios" do
    let(:outcome) { outcome_model(context: course) }
    let(:assignment) { assignment_model(context: course) }
    let(:alignment) { outcome.align(assignment, course) }

    let(:common_scores) { [1.0, 2.0, 3.0, 4.0, 5.0] }
    let(:assignments) { Array.new(5) { assignment_model(context: course) } }
    let(:alignments) { assignments.map { |a| outcome.align(a, course) } }

    before do
      outcome.rubric_criterion = {
        mastery_points: 3,
        points_possible: 5,
        ratings: [
          { points: 5, description: "Exceeds" },
          { points: 3, description: "Meets" },
          { points: 0, description: "Does Not Meet" }
        ]
      }
      outcome.save!
    end

    context "calculation methods" do
      context "with highest calculation method" do
        before do
          outcome.calculation_method = "highest"
          outcome.save!

          # Create results with common scores: [1, 2, 3, 4, 5]
          common_scores.each_with_index do |score_value, i|
            LearningOutcomeResult.create!(
              learning_outcome: outcome,
              user: student,
              context: course,
              alignment: alignments[i],
              score: score_value,
              possible: 5,
              created_at: (5 - i).days.ago # oldest to newest
            )
          end
        end

        it "uses highest score when calculation method is 'highest'" do
          rollups = subject.call

          expect(rollups).to be_an(ActiveRecord::Relation)
          expect(rollups.size).to eq(1)
          rollup = rollups.find_by(outcome_id: outcome.id)
          expect(rollup.aggregate_score).to eq(5) # Highest from [1, 2, 3, 4, 5]
        end
      end

      context "with latest calculation method" do
        before do
          outcome.calculation_method = "latest"
          outcome.save!

          scores_with_timestamps = [
            { score: 1, days_ago: 5 },
            { score: 2, days_ago: 4 },
            { score: 4, days_ago: 3 },
            { score: 5, days_ago: 2 },
            { score: 3, days_ago: 1 }
          ]

          scores_with_timestamps.each_with_index do |score_data, i|
            LearningOutcomeResult.create!(
              learning_outcome: outcome,
              user: student,
              context: course,
              alignment: alignments[i],
              score: score_data[:score],
              possible: 5,
              created_at: score_data[:days_ago].days.ago
            )
          end
        end

        it "uses latest score when calculation method is 'latest'" do
          rollups = subject.call

          expect(rollups.size).to eq(1)
          rollup = rollups.find_by(outcome_id: outcome.id)
          expect(rollup.aggregate_score).to eq(3) # Latest (most recent) from [1, 2, 4, 5, 3]
        end
      end

      context "with average calculation method" do
        before do
          outcome.calculation_method = "average"
          outcome.save!

          # Create results with common scores: [1, 2, 3, 4, 5]
          common_scores.each_with_index do |score_value, i|
            LearningOutcomeResult.create!(
              learning_outcome: outcome,
              user: student,
              context: course,
              alignment: alignments[i],
              score: score_value,
              possible: 5,
              created_at: i.hours.ago
            )
          end
        end

        it "calculates average across multiple assignments" do
          rollups = subject.call
          rollup = rollups.find_by(outcome_id: outcome.id)

          # Average of [1, 2, 3, 4, 5] = 15/5 = 3.0
          expect(rollup.aggregate_score).to eq(3.0)
        end
      end

      context "with decaying average calculation method" do
        before do
          # Disable the feature flag to use the legacy decaying average calculation
          course.root_account.disable_feature!(:outcomes_new_decaying_average_calculation)

          outcome.calculation_method = "decaying_average"
          outcome.calculation_int = 65
          outcome.save!

          # Create results with common scores: [1, 2, 3, 4, 5] - newer results should have more weight
          # Use fixed timestamps with sufficient gaps to ensure consistent ordering
          base_time = 10.days.ago
          common_scores.each_with_index do |score_value, i|
            LearningOutcomeResult.create!(
              learning_outcome: outcome,
              user: student,
              context: course,
              alignment: alignments[i],
              score: score_value,
              possible: 5,
              created_at: base_time + (i * 1.day) # oldest to newest: 1 is oldest, 5 is newest
            )
          end
        end

        it "calculates decaying average with more weight on recent scores" do
          rollups = subject.call
          rollup = rollups.find_by(outcome_id: outcome.id)
          # Legacy decaying average: (5 * 0.65) + ((1+2+3+4)/4 * 0.35) = 3.25 + 0.875 = 4.125
          expect(rollup.aggregate_score).to be 4.13
        end
      end

      context "with standard_decaying_average calculation method" do
        before do
          # Enable the feature flag to use the new decaying average calculation
          course.root_account.enable_feature!(:outcomes_new_decaying_average_calculation)

          outcome.calculation_method = "standard_decaying_average"
          outcome.calculation_int = 65
          outcome.save!

          # Create results with common scores: [1, 2, 3, 4, 5]
          # Use fixed timestamps with sufficient gaps to ensure consistent ordering
          base_time = 10.days.ago
          common_scores.each_with_index do |score_value, i|
            LearningOutcomeResult.create!(
              learning_outcome: outcome,
              user: student,
              context: course,
              alignment: alignments[i],
              score: score_value,
              possible: 5,
              created_at: base_time + (i * 1.day) # oldest to newest with 1 day gaps
            )
          end
        end

        it "calculates standard_decaying_average with newer scores weighted more" do
          rollups = subject.call
          rollup = rollups.find_by(outcome_id: outcome.id)
          # True decaying average: iterative decay through pairs
          # [1,2] -> 1.65, [1.65,3] -> 2.5275, [2.5275,4] -> 3.485, [3.485,5] -> 4.47
          expect(rollup.aggregate_score).to be 4.47
        end
      end

      context "with n_mastery calculation method" do
        before do
          outcome.calculation_method = "n_mastery"
          outcome.calculation_int = 3 # Need 3 mastery scores (>= 3 points)
          outcome.save!

          # Create results with common scores: [1, 2, 3, 4, 5]
          # Mastery scores (>= 3): [3, 4, 5] = 3 scores meet mastery
          common_scores.each_with_index do |score_value, i|
            LearningOutcomeResult.create!(
              learning_outcome: outcome,
              user: student,
              context: course,
              alignment: alignments[i],
              score: score_value,
              possible: 5,
              created_at: i.hours.ago
            )
          end
        end

        it "calculates n_mastery when sufficient mastery attempts exist" do
          rollups = subject.call
          rollup = rollups.find_by(outcome_id: outcome.id)

          # From [1, 2, 3, 4, 5], mastery scores are [3, 4, 5]
          expect(rollup.aggregate_score).to eq(4)
        end
      end

      context "with n_mastery insufficient attempts" do
        before do
          outcome.calculation_method = "n_mastery"
          outcome.calculation_int = 4 # Need 4 mastery scores (>= 3 points)
          outcome.save!

          # Create results with common scores: [1, 2, 3, 4, 5]
          # Mastery scores (>= 3): [3, 4, 5] = only 3 scores meet mastery (need 4)
          common_scores.each_with_index do |score_value, i|
            LearningOutcomeResult.create!(
              learning_outcome: outcome,
              user: student,
              context: course,
              alignment: alignments[i],
              score: score_value,
              possible: 5,
              created_at: i.hours.ago
            )
          end
        end

        it "returns no rollup when insufficient mastery attempts exist" do
          rollups = subject.call

          # Should return no rollups since the score is nil (insufficient mastery attempts)
          # and nil scores are filtered out by our implementation
          expect(rollups).to be_empty
        end
      end
    end

    context "with nil or zero scores" do
      context "with nil score" do
        before do
          outcome.calculation_method = "highest"
          outcome.save!

          # Create a result with nil score
          @result = LearningOutcomeResult.create!(
            learning_outcome: outcome,
            user: student,
            context: course,
            alignment:,
            score: nil,
            possible: 5
          )
        end

        it "excludes results with nil scores from rollup calculations" do
          rollups = subject.call

          # Should return no rollups since the only result had a nil score
          # and nil scores are filtered out by our implementation
          expect(rollups).to be_empty
        end
      end

      context "with zero score" do
        before do
          outcome.calculation_method = "highest"
          outcome.save!

          # Create a result with zero score
          @result = LearningOutcomeResult.create!(
            learning_outcome: outcome,
            user: student,
            context: course,
            alignment:,
            score: 0,
            possible: 5
          )
        end

        it "handles zero scores correctly" do
          rollups = subject.call

          # Should handle zero scores correctly
          expect(rollups.size).to eq(1)
          rollup = rollups.find_by(outcome_id: outcome.id)
          expect(rollup.aggregate_score).to eq(0)
        end
      end
    end

    context "with mastery scale integration" do
      let(:account) { course.account }

      context "with outcome proficiency enabled" do
        let(:proficiency_ratings) do
          [
            OutcomeProficiencyRating.new(points: 4, color: "127A1B", description: "Exceeds Mastery", mastery: false),
            OutcomeProficiencyRating.new(points: 3, color: "0B874B", description: "Mastery", mastery: true),
            OutcomeProficiencyRating.new(points: 2, color: "FC5E13", description: "Near Mastery", mastery: false),
            OutcomeProficiencyRating.new(points: 1, color: "E0061F", description: "Below Mastery", mastery: false)
          ]
        end

        let(:proficiency) do
          OutcomeProficiency.new(
            account:,
            outcome_proficiency_ratings: proficiency_ratings
          )
        end

        before do
          # Enable the feature and set up proficiency
          account.root_account.enable_feature!(:account_level_mastery_scales)

          # Mock the account's resolved_outcome_proficiency to return our proficiency
          allow(account).to receive(:resolved_outcome_proficiency).and_return(proficiency)
          allow(course).to receive(:resolved_outcome_proficiency).and_return(proficiency)

          outcome.rubric_criterion = {
            mastery_points: 3,
            points_possible: 5,
            ratings: proficiency_ratings.map do |rating|
              { points: rating.points, description: rating.description }
            end
          }
          outcome.calculation_method = "highest"
          outcome.save!

          LearningOutcomeResult.create!(
            learning_outcome: outcome,
            user: student,
            context: course,
            alignment:,
            score: 2,
            possible: 5
          )
        end

        it "uses outcome proficiency for score scaling when feature is enabled" do
          rollups = subject.call
          rollup = rollups.find_by(outcome_id: outcome.id)

          # Score should be scaled according to outcome proficiency
          # With a score of 2 out of 5, and proficiency max of 4, scaled score should be (2/5) * 4 = 1.6
          expect(rollup.aggregate_score).to eq(1.6) # Canvas scales based on outcome proficiency
        end
      end

      context "with no account proficiency" do
        before do
          account.root_account.disable_feature!(:account_level_mastery_scales)

          outcome.rubric_criterion = {
            mastery_points: 3,
            points_possible: 5,
            ratings: [
              { points: 5, description: "Exceeds" },
              { points: 3, description: "Meets" },
              { points: 0, description: "Does Not Meet" }
            ]
          }
          outcome.calculation_method = "highest"
          outcome.save!

          LearningOutcomeResult.create!(
            learning_outcome: outcome,
            user: student,
            context: course,
            alignment:,
            score: 4,
            possible: 5
          )
        end

        it "falls back to outcome settings when no account proficiency exists" do
          rollups = subject.call
          rollup = rollups.find_by(outcome_id: outcome.id)

          # Should use the outcome's own rubric criterion
          expect(rollup.aggregate_score).to eq(4)
        end
      end
    end

    context "with cross-assignment results for same outcome" do
      let(:assignment2) { assignment_model(context: course) }
      let(:assignment3) { assignment_model(context: course) }
      let(:alignment2) { outcome.align(assignment2, course) }
      let(:alignment3) { outcome.align(assignment3, course) }

      before do
        outcome.rubric_criterion = {
          mastery_points: 3,
          points_possible: 5,
          ratings: [
            { points: 5, description: "Exceeds" },
            { points: 3, description: "Meets" },
            { points: 0, description: "Does Not Meet" }
          ]
        }
        outcome.save!
      end

      context "with highest calculation method" do
        before do
          outcome.calculation_method = "highest"
          outcome.save!

          # Results from different assignments using subset of common scores: [2, 4, 3]
          @result1 = LearningOutcomeResult.create!(
            learning_outcome: outcome,
            user: student,
            context: course,
            alignment:,
            score: 2,
            possible: 5,
            created_at: 3.days.ago
          )

          @result2 = LearningOutcomeResult.create!(
            learning_outcome: outcome,
            user: student,
            context: course,
            alignment: alignment2,
            score: 4,
            possible: 5,
            created_at: 2.days.ago
          )

          @result3 = LearningOutcomeResult.create!(
            learning_outcome: outcome,
            user: student,
            context: course,
            alignment: alignment3,
            score: 3,
            possible: 5,
            created_at: 1.day.ago
          )
        end

        it "combines results from different assignments for the same outcome using highest method" do
          rollups = subject.call
          expect(rollups.size).to eq(1)

          rollup = rollups.find_by(outcome_id: outcome.id)
          expect(rollup).to be_present

          # With highest calculation method, should use the highest score from [2, 4, 3] = 4
          expect(rollup.aggregate_score).to eq(4)
        end
      end

      context "with average calculation method" do
        before do
          outcome.calculation_method = "average"
          outcome.save!

          # Results from different assignments using subset of common scores: [2, 4, 3]
          LearningOutcomeResult.create!(
            learning_outcome: outcome,
            user: student,
            context: course,
            alignment:,
            score: 2,
            possible: 5
          )

          LearningOutcomeResult.create!(
            learning_outcome: outcome,
            user: student,
            context: course,
            alignment: alignment2,
            score: 4,
            possible: 5
          )

          LearningOutcomeResult.create!(
            learning_outcome: outcome,
            user: student,
            context: course,
            alignment: alignment3,
            score: 3,
            possible: 5
          )
        end

        it "properly calculates average across multiple assignments" do
          rollups = subject.call
          rollup = rollups.find_by(outcome_id: outcome.id)

          # Average of [2, 4, 3] = 9/3 = 3.0
          expect(rollup.aggregate_score).to eq(3.0)
        end
      end

      context "with mixed assignment types" do
        let(:quiz_assignment) { assignment_model(context: course) }
        let(:quiz_alignment) { outcome.align(quiz_assignment, course) }

        before do
          outcome.calculation_method = "highest"
          outcome.save!

          # Mock only the quiz_lti scope to return our quiz assignment
          where_scope = class_double(Assignment)
          active_scope = class_double(Assignment)

          allow(Assignment).to receive(:active).and_return(active_scope)
          allow(active_scope).to receive(:where).and_return(where_scope)
          allow(where_scope).to receive(:quiz_lti).and_return([quiz_assignment])

          # Regular Canvas result - using score from our common set
          @canvas_result = LearningOutcomeResult.create!(
            learning_outcome: outcome,
            user: student,
            context: course,
            alignment:,
            score: 3,
            possible: 5
          )

          # Mock an Outcomes Service result from quiz - using score from our common set
          @os_result = LearningOutcomeResult.new(
            learning_outcome: outcome,
            user: student,
            context: course,
            alignment: quiz_alignment,
            score: 4,
            possible: 5,
            user_uuid: student.uuid,
            associated_asset_id: quiz_assignment.id
          )

          # Mock the Outcomes Service call
          allow(subject).to receive(:fetch_outcomes_service_results).and_return([@os_result])
        end

        it "handles mixed assignment types (regular and quiz LTI)" do
          rollups = subject.call
          rollup = rollups.find_by(outcome_id: outcome.id)

          # Should combine both results [3, 4] and use highest (4)
          expect(rollup.aggregate_score).to eq(4)
        end
      end
    end

    context "with Canvas and Outcomes Service integration" do
      let(:quiz_assignment) { assignment_model(context: course) }
      let(:quiz_alignment) { outcome.align(quiz_assignment, course) }

      before do
        outcome.rubric_criterion = {
          mastery_points: 3,
          points_possible: 5,
          ratings: [
            { points: 5, description: "Exceeds" },
            { points: 3, description: "Meets" },
            { points: 0, description: "Does Not Meet" }
          ]
        }
        outcome.calculation_method = "highest"
        outcome.save!

        where_scope = class_double(Assignment)
        active_scope = class_double(Assignment)

        allow(Assignment).to receive(:active).and_return(active_scope)
        allow(active_scope).to receive(:where).and_return(where_scope)
        allow(where_scope).to receive(:quiz_lti).and_return([quiz_assignment])
      end

      context "with deduplication and multiple outcomes" do
        let(:outcome2) { outcome_model(context: course) }
        let(:assignment2) { assignment_model(context: course) }

        before do
          # Set up second outcome with average calculation
          outcome2.rubric_criterion = {
            mastery_points: 3,
            points_possible: 5,
            ratings: [
              { points: 5, description: "Exceeds" },
              { points: 3, description: "Meets" },
              { points: 0, description: "Does Not Meet" }
            ]
          }
          outcome2.calculation_method = "average"
          outcome2.save!

          # Create Canvas results using our common scores
          LearningOutcomeResult.create!(
            learning_outcome: outcome,
            user: student,
            context: course,
            alignment: outcome.align(assignment, course),
            score: 3,
            possible: 5
          )

          LearningOutcomeResult.create!(
            learning_outcome: outcome2,
            user: student,
            context: course,
            alignment: outcome2.align(assignment2, course),
            score: 2,
            possible: 5
          )

          # Mock Outcomes Service results (one unique per outcome) using our common scores
          os_results = [
            LearningOutcomeResult.new(
              learning_outcome: outcome,
              user: student,
              context: course,
              score: 5,
              possible: 5,
              user_uuid: student.uuid,
              associated_asset_id: quiz_assignment.id
            ),
            LearningOutcomeResult.new(
              learning_outcome: outcome2,
              user: student,
              context: course,
              score: 4,
              possible: 5,
              user_uuid: student.uuid,
              associated_asset_id: quiz_assignment.id
            )
          ]
          allow(subject).to receive(:fetch_outcomes_service_results).and_return(os_results)
        end

        it "combines results from Canvas and Outcomes Service for multiple outcomes" do
          rollups = subject.call
          expect(rollups.size).to eq(2) # Two rollups, one per outcome

          outcome1_rollup = rollups.find_by(outcome_id: outcome.id)
          outcome2_rollup = rollups.find_by(outcome_id: outcome2.id)

          # Outcome1: Canvas(3) + OS(5) with highest method = 5
          expect(outcome1_rollup.aggregate_score).to eq(5)

          # Outcome2: Canvas(2) + OS(4) with average method = (2+4)/2 = 3.0
          expect(outcome2_rollup.aggregate_score).to eq(3.0)
        end
      end
    end
  end

  describe "#store_rollups" do
    let(:outcome1) { outcome_model(context: course) }
    let(:outcome2) { outcome_model(context: course) }

    # Helper to create a RollupScore using a LearningOutcomeResult objects
    def create_rollup_score(outcome, score_value, calculation_method = "average", submission_time = nil)
      # Set up the outcome with proper calculation method
      outcome.calculation_method = calculation_method
      outcome.rubric_criterion = {
        mastery_points: 3,
        points_possible: 5,
        ratings: [
          { points: 5, description: "Exceeds" },
          { points: 3, description: "Meets" },
          { points: 0, description: "Does Not Meet" }
        ]
      }
      outcome.save!

      assignment = assignment_model(context: course)
      alignment = outcome.align(assignment, course)
      submitted_at = submission_time || 1.day.ago
      result = LearningOutcomeResult.create!(
        learning_outcome: outcome,
        user: student,
        context: course,
        alignment:,
        score: score_value,
        possible: 5,
        title: "#{course.name}, #{assignment.title}",
        submitted_at:
      )

      RollupScore.new(outcome_results: [result])
    end

    def create_rollup_collection_with_scores(context, rollup_scores)
      Outcomes::ResultAnalytics::Rollup.new(context, rollup_scores)
    end

    it "creates new OutcomeRollup records" do
      rollup_score = create_rollup_score(outcome1, 2.0, "average")
      rollup_collection = create_rollup_collection_with_scores(student, [rollup_score])

      expect do
        subject.send(:store_rollups, [rollup_collection])
      end.to change {
        OutcomeRollup.where(course_id: course.id, user_id: student.id).count
      }.from(0).to(1)

      stored_rollup = OutcomeRollup.find_by(course_id: course.id, user_id: student.id, outcome_id: outcome1.id)
      expect(stored_rollup.aggregate_score).to eq(2.0)
    end

    it "updates an existing rollup instead of inserting a duplicate" do
      existing = OutcomeRollup.create!(
        root_account_id: course.root_account_id,
        course_id: course.id,
        user_id: student.id,
        outcome_id: outcome1.id,
        calculation_method: "average",
        aggregate_score: 1.0,
        last_calculated_at: 1.hour.ago
      )

      rollup_score = create_rollup_score(outcome1, 3.0, "average")
      rollup_collection = create_rollup_collection_with_scores(student, [rollup_score])

      expect do
        subject.send(:store_rollups, [rollup_collection])
      end.not_to change { OutcomeRollup.count }

      expect(existing.reload.aggregate_score).to eq(3.0)
    end

    it "removes stale rollups not included in the current batch" do
      stale = OutcomeRollup.create!(
        root_account_id: course.root_account_id,
        course_id: course.id,
        user_id: student.id,
        outcome_id: outcome1.id,
        calculation_method: "average",
        aggregate_score: 1.0,
        last_calculated_at: Time.current
      )

      fresh_rollup_score = create_rollup_score(outcome2, 4.0, "highest")
      fresh_rollup_collection = create_rollup_collection_with_scores(student, [fresh_rollup_score])
      subject.send(:store_rollups, [fresh_rollup_collection])

      expect(stale.reload.workflow_state).to eq("deleted")
      expect(
        OutcomeRollup.active.where(course_id: course.id, user_id: student.id).pluck(:outcome_id)
      ).to contain_exactly(outcome2.id)
    end

    it "handles multiple scores in a single rollup" do
      rollup_score1 = create_rollup_score(outcome1, 2.0, "average")
      rollup_score2 = create_rollup_score(outcome2, 4.0, "highest")
      rollup_collection = create_rollup_collection_with_scores(student, [rollup_score1, rollup_score2])

      expect do
        subject.send(:store_rollups, [rollup_collection])
      end.to change {
        OutcomeRollup.where(course_id: course.id, user_id: student.id).count
      }.from(0).to(2)

      stored_rollup1 = OutcomeRollup.find_by(course_id: course.id, user_id: student.id, outcome_id: outcome1.id)
      stored_rollup2 = OutcomeRollup.find_by(course_id: course.id, user_id: student.id, outcome_id: outcome2.id)

      expect(stored_rollup1.aggregate_score).to eq(2.0)
      expect(stored_rollup1.calculation_method).to eq("average")
      expect(stored_rollup2.aggregate_score).to eq(4.0)
      expect(stored_rollup2.calculation_method).to eq("highest")
    end

    it "handles empty rollups array" do
      expect(subject.send(:store_rollups, [])).to eq([])
    end

    it "handles transaction rollback on error" do
      score = create_rollup_score(outcome1, 2.0, "average")
      rollup = create_rollup_collection_with_scores(student, [score])

      # Mock upsert_all to raise an error
      allow(OutcomeRollup).to receive(:upsert_all).and_raise(StandardError, "Database error")

      expect do
        subject.send(:store_rollups, [rollup])
      end.to raise_error(StandardError, "Database error")

      # Should not have created any rollups due to transaction rollback
      expect(OutcomeRollup.where(course_id: course.id, user_id: student.id).count).to eq(0)
    end

    it "sets all existing rollups to deleted when no current rollups" do
      # Create some existing rollups
      existing1 = OutcomeRollup.create!(
        root_account_id: course.root_account_id,
        course_id: course.id,
        user_id: student.id,
        outcome_id: outcome1.id,
        calculation_method: "average",
        aggregate_score: 1.0,
        last_calculated_at: 1.hour.ago
      )

      existing2 = OutcomeRollup.create!(
        root_account_id: course.root_account_id,
        course_id: course.id,
        user_id: student.id,
        outcome_id: outcome2.id,
        calculation_method: "highest",
        aggregate_score: 2.0,
        last_calculated_at: 1.hour.ago
      )

      # Store empty rollups (no current scores)
      empty_rollup_collection = create_rollup_collection_with_scores(student, [])
      subject.send(:store_rollups, [empty_rollup_collection])

      # All existing rollups should be marked as deleted
      expect(existing1.reload.workflow_state).to eq("deleted")
      expect(existing2.reload.workflow_state).to eq("deleted")
    end

    it "correctly identifies and preserves active rollups for same outcomes" do
      # Create existing rollups for outcome1 and outcome2
      existing1 = OutcomeRollup.create!(
        root_account_id: course.root_account_id,
        course_id: course.id,
        user_id: student.id,
        outcome_id: outcome1.id,
        calculation_method: "average",
        aggregate_score: 1.0,
        last_calculated_at: 1.hour.ago
      )

      existing2 = OutcomeRollup.create!(
        root_account_id: course.root_account_id,
        course_id: course.id,
        user_id: student.id,
        outcome_id: outcome2.id,
        calculation_method: "highest",
        aggregate_score: 2.0,
        last_calculated_at: 1.hour.ago
      )

      # Store rollups for outcome1 and outcome2 (updating both)
      rollup_score1 = create_rollup_score(outcome1, 3.0, "average")
      rollup_score2 = create_rollup_score(outcome2, 4.0, "highest")
      rollup_collection = create_rollup_collection_with_scores(student, [rollup_score1, rollup_score2])
      subject.send(:store_rollups, [rollup_collection])

      # Both should be updated, neither marked as deleted
      expect(existing1.reload.workflow_state).to eq("active")
      expect(existing1.aggregate_score).to eq(3.0)
      expect(existing2.reload.workflow_state).to eq("active")
      expect(existing2.aggregate_score).to eq(4.0)
    end

    it "returns an array of OutcomeRollup objects that were upserted" do
      rollup_score1 = create_rollup_score(outcome1, 2.5, "average")
      rollup_score2 = create_rollup_score(outcome2, 3.5, "highest")
      rollup_collection = create_rollup_collection_with_scores(student, [rollup_score1, rollup_score2])

      result = subject.send(:store_rollups, [rollup_collection])

      expect(result.size).to eq(2)
      expect(result).to all(be_an(OutcomeRollup))

      # Should include the correct outcome IDs
      returned_outcome_ids = result.map(&:outcome_id)
      expect(returned_outcome_ids).to contain_exactly(outcome1.id, outcome2.id)

      # Should have the correct scores
      outcome1_rollup = result.find { |r| r.outcome_id == outcome1.id }
      outcome2_rollup = result.find { |r| r.outcome_id == outcome2.id }

      expect(outcome1_rollup.aggregate_score).to eq(2.5)
      expect(outcome1_rollup.calculation_method).to eq("average")
      expect(outcome2_rollup.aggregate_score).to eq(3.5)
      expect(outcome2_rollup.calculation_method).to eq("highest")
    end

    it "persists submitted_at from the rollup score" do
      submitted_at = 3.days.ago
      rollup_score = create_rollup_score(outcome1, 4.0, "highest", submitted_at)
      rollup_collection = create_rollup_collection_with_scores(student, [rollup_score])

      result = subject.send(:store_rollups, [rollup_collection])

      expect(result.size).to eq(1)
      stored_rollup = result.first
      expect(stored_rollup.submitted_at).to be_within(1.second).of(submitted_at)
    end

    it "updates submitted_at when updating an existing rollup" do
      old_time = 5.days.ago
      new_time = 1.day.ago

      # Create existing rollup with old submitted_at
      existing = OutcomeRollup.create!(
        root_account_id: course.root_account_id,
        course_id: course.id,
        user_id: student.id,
        outcome_id: outcome1.id,
        calculation_method: "highest",
        aggregate_score: 3.0,
        submitted_at: old_time,
        last_calculated_at: 1.hour.ago
      )

      # Update with new result
      rollup_score = create_rollup_score(outcome1, 4.5, "highest", new_time)
      rollup_collection = create_rollup_collection_with_scores(student, [rollup_score])

      subject.send(:store_rollups, [rollup_collection])

      # Verify submitted_at was updated
      expect(existing.reload.submitted_at).to be_within(1.second).of(new_time)
      expect(existing.aggregate_score).to eq(4.5)
    end
  end
end
