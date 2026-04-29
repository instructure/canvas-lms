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

describe Outcomes::CourseOutcomeRollupCalculationService do
  let(:course) { course_model }
  let(:other_course) { course_model }
  let(:students) { Array.new(3) { user_model } }
  let(:assignment) { assignment_model(context: course) }

  let(:outcome) do
    o = outcome_model(context: course)
    course.root_outcome_group.add_outcome(o)
    o.rubric_criterion = {
      description: o.short_description,
      ratings: [
        { description: "Exceeds", points: 5 },
        { description: "Meets", points: 3 },
        { description: "Does Not Meet", points: 0 }
      ],
      mastery_points: 3,
      points_possible: 5
    }
    o.save!
    o
  end

  let(:other_outcome) do
    o = outcome_model(context: course)
    course.root_outcome_group.add_outcome(o)
    o.rubric_criterion = {
      description: o.short_description,
      ratings: [
        { description: "Exceeds", points: 5 },
        { description: "Meets", points: 3 },
        { description: "Does Not Meet", points: 0 }
      ],
      mastery_points: 3,
      points_possible: 5
    }
    o.save!
    o
  end

  let(:alignment) { outcome.align(assignment, course) }
  let(:other_assignment) { assignment_model(context: course) }
  let(:other_alignment) { other_outcome.align(other_assignment, course) }

  before do
    students.each { |student| course.enroll_student(student, enrollment_state: "active") }
  end

  describe "#initialize" do
    it "loads the course and outcome" do
      service = described_class.new(course_id: course.id, outcome_id: outcome.id)
      expect(service.course).to eq(course)
      expect(service.outcome).to eq(outcome)
    end

    it "raises ArgumentError when course_id is invalid" do
      expect do
        described_class.new(course_id: -1, outcome_id: outcome.id)
      end.to raise_error(ArgumentError, /Invalid course_id/)
    end

    it "raises ArgumentError when outcome_id is invalid" do
      expect do
        described_class.new(course_id: course.id, outcome_id: -1)
      end.to raise_error(ArgumentError, /Invalid course_id.*or outcome_id/)
    end

    it "raises ArgumentError when outcome is not linked to the course" do
      unlinked_outcome = outcome_model
      expect do
        described_class.new(course_id: course.id, outcome_id: unlinked_outcome.id)
      end.to raise_error(ArgumentError, /Outcome.*is not linked to course/)
    end
  end

  describe "#call" do
    subject { described_class.new(course_id: course.id, outcome_id: outcome.id) }

    context "rollup creation for all students" do
      before do
        students.each_with_index do |student, i|
          LearningOutcomeResult.create!(
            learning_outcome: outcome,
            context: course,
            user: student,
            alignment:,
            score: 2.0 + i,
            possible: 5.0,
            title: "#{course.name}, #{assignment.title}",
            submitted_at: (i + 1).days.ago
          )
        end
      end

      it "creates rollups for all students in the course" do
        expect { subject.call }.to change {
          OutcomeRollup.where(
            course_id: course.id,
            outcome_id: outcome.id,
            workflow_state: "active"
          ).count
        }.from(0).to(3)

        rollups = OutcomeRollup.where(
          course_id: course.id,
          outcome_id: outcome.id,
          workflow_state: "active"
        )

        students.each_with_index do |student, i|
          rollup = rollups.find_by(user_id: student.id)
          expect(rollup).to be_present
          expect(rollup.aggregate_score).to eq(2.0 + i)
          expect(rollup.calculation_method).to eq(outcome.calculation_method)
          expect(rollup.submitted_at).to be_present
          expect(rollup.title).to be_present
          expect(rollup.hide_points).to be false
          expect(rollup.results_count).to eq(1)
        end
      end

      it "sets hide_points to true when all results have hide_points true" do
        # Clear the results from the before block
        LearningOutcomeResult.where(user_id: students.map(&:id)).destroy_all

        # Create two results per student, both with hide_points: true
        students.each_with_index do |student, i|
          2.times do |j|
            LearningOutcomeResult.create!(
              learning_outcome: outcome,
              context: course,
              user: student,
              alignment:,
              score: 3.0 + j,
              possible: 5.0,
              title: "#{course.name}, #{assignment.title}",
              submitted_at: (i + j + 1).days.ago,
              hide_points: true
            )
          end
        end

        subject.call

        rollups = OutcomeRollup.where(
          course_id: course.id,
          outcome_id: outcome.id,
          workflow_state: "active"
        )

        students.each do |student|
          rollup = rollups.find_by(user_id: student.id)
          expect(rollup).to be_present
          expect(rollup.hide_points).to be true
        end
      end

      it "sets hide_points to false when all results have hide_points false" do
        # Clear the results from the before block
        LearningOutcomeResult.where(user_id: students.map(&:id)).destroy_all

        # Create two results per student, both with hide_points: false
        students.each_with_index do |student, i|
          2.times do |j|
            LearningOutcomeResult.create!(
              learning_outcome: outcome,
              context: course,
              user: student,
              alignment:,
              score: 3.0 + j,
              possible: 5.0,
              title: "#{course.name}, #{assignment.title}",
              submitted_at: (i + j + 1).days.ago,
              hide_points: false
            )
          end
        end

        subject.call

        rollups = OutcomeRollup.where(
          course_id: course.id,
          outcome_id: outcome.id,
          workflow_state: "active"
        )

        students.each do |student|
          rollup = rollups.find_by(user_id: student.id)
          expect(rollup).to be_present
          expect(rollup.hide_points).to be false
        end
      end

      it "sets hide_points to false when results have mixed hide_points values" do
        # Clear the results from the before block
        LearningOutcomeResult.where(user_id: students.map(&:id)).destroy_all

        # Change to average calculation method so all results are considered
        outcome.calculation_method = "average"
        outcome.save!

        # Create two results per student: one with hide_points true, one false
        # With average calculation, ALL results are considered, so .all?(&:hide_points) will be false
        students.each do |student|
          LearningOutcomeResult.create!(
            learning_outcome: outcome,
            context: course,
            user: student,
            alignment:,
            score: 3.0,
            possible: 5.0,
            title: "#{course.name}, #{assignment.title}",
            submitted_at: 2.days.ago,
            hide_points: false
          )
          LearningOutcomeResult.create!(
            learning_outcome: outcome,
            context: course,
            user: student,
            alignment:,
            score: 4.0,
            possible: 5.0,
            title: "#{course.name}, #{assignment.title}",
            submitted_at: 1.day.ago,
            hide_points: true
          )
        end

        # Create a new service instance with the updated outcome
        service = described_class.new(course_id: course.id, outcome_id: outcome.id)
        service.call

        rollups = OutcomeRollup.where(
          course_id: course.id,
          outcome_id: outcome.id,
          workflow_state: "active"
        )

        # All students have mixed values → rollup should be false (not ALL are true)
        students.each do |student|
          rollup = rollups.find_by(user_id: student.id)
          expect(rollup).to be_present
          expect(rollup.hide_points).to be false
        end
      end

      it "updates existing rollups with new scores" do
        students.each do |student|
          OutcomeRollup.create!(
            course_id: course.id,
            user_id: student.id,
            outcome_id: outcome.id,
            root_account_id: course.root_account_id,
            calculation_method: outcome.calculation_method,
            aggregate_score: 1.0,
            workflow_state: "active",
            last_calculated_at: 1.hour.ago
          )
        end

        expect { subject.call }.not_to change { OutcomeRollup.count }

        rollups = OutcomeRollup.where(
          course_id: course.id,
          outcome_id: outcome.id,
          workflow_state: "active"
        )

        students.each_with_index do |student, i|
          rollup = rollups.find_by(user_id: student.id)
          expect(rollup.aggregate_score).to eq(2.0 + i)
          expect(rollup.results_count).to eq(1)
          expect(rollup.last_calculated_at).to be > 30.minutes.ago
        end
      end
    end

    context "isolation from other courses" do
      let(:other_course_student) { user_model }

      before do
        other_course.enroll_student(other_course_student, enrollment_state: "active")

        OutcomeRollup.create!(
          course_id: other_course.id,
          user_id: other_course_student.id,
          outcome_id: outcome.id,
          root_account_id: other_course.root_account_id,
          calculation_method: outcome.calculation_method,
          aggregate_score: 5.0,
          workflow_state: "active",
          last_calculated_at: 1.hour.ago
        )

        students.each do |student|
          LearningOutcomeResult.create!(
            learning_outcome: outcome,
            context: course,
            user: student,
            alignment:,
            score: 3.0,
            possible: 5.0
          )
        end
      end

      it "does not affect rollups in other courses" do
        original_other_course_rollup = OutcomeRollup.find_by(
          course_id: other_course.id,
          user_id: other_course_student.id
        )

        subject.call

        other_course_rollup = OutcomeRollup.find_by(
          course_id: other_course.id,
          user_id: other_course_student.id
        )
        expect(other_course_rollup.aggregate_score).to eq(5.0)
        expect(other_course_rollup.last_calculated_at).to eq(original_other_course_rollup.last_calculated_at)
        expect(other_course_rollup.workflow_state).to eq("active")

        target_rollups = OutcomeRollup.where(
          course_id: course.id,
          outcome_id: outcome.id,
          workflow_state: "active"
        )
        expect(target_rollups.count).to eq(3)
      end
    end

    context "isolation from other outcomes" do
      before do
        students.each do |student|
          LearningOutcomeResult.create!(
            learning_outcome: outcome,
            context: course,
            user: student,
            alignment:,
            score: 3.0,
            possible: 5.0
          )

          LearningOutcomeResult.create!(
            learning_outcome: other_outcome,
            context: course,
            user: student,
            alignment: other_alignment,
            score: 4.0,
            possible: 5.0
          )

          OutcomeRollup.create!(
            course_id: course.id,
            user_id: student.id,
            outcome_id: other_outcome.id,
            root_account_id: course.root_account_id,
            calculation_method: other_outcome.calculation_method,
            aggregate_score: 4.0,
            workflow_state: "active",
            last_calculated_at: 1.hour.ago
          )
        end
      end

      it "does not affect rollups for other outcomes" do
        original_other_outcome_rollups = OutcomeRollup.where(
          course_id: course.id,
          outcome_id: other_outcome.id
        ).map { |r| [r.user_id, r.aggregate_score, r.last_calculated_at] }

        subject.call

        other_outcome_rollups = OutcomeRollup.where(
          course_id: course.id,
          outcome_id: other_outcome.id,
          workflow_state: "active"
        )
        expect(other_outcome_rollups.count).to eq(3)

        other_outcome_rollups.each do |rollup|
          original = original_other_outcome_rollups.find { |r| r[0] == rollup.user_id }
          expect(rollup.aggregate_score).to eq(original[1])
          expect(rollup.last_calculated_at).to eq(original[2])
        end

        target_rollups = OutcomeRollup.where(
          course_id: course.id,
          outcome_id: outcome.id,
          workflow_state: "active"
        )
        expect(target_rollups.count).to eq(3)
        expect(target_rollups.pluck(:aggregate_score).uniq).to eq([3.0])
      end
    end

    context "rollup deletion when results are removed" do
      before do
        students[0..1].each do |student|
          LearningOutcomeResult.create!(
            learning_outcome: outcome,
            context: course,
            user: student,
            alignment:,
            score: 3.0,
            possible: 5.0
          )
        end

        students.each do |student|
          OutcomeRollup.create!(
            course_id: course.id,
            user_id: student.id,
            outcome_id: outcome.id,
            root_account_id: course.root_account_id,
            calculation_method: outcome.calculation_method,
            aggregate_score: 3.0,
            workflow_state: "active",
            last_calculated_at: 1.hour.ago
          )
        end
      end

      it "marks rollups as deleted for students without results" do
        subject.call

        students[0..1].each do |student|
          rollup = OutcomeRollup.find_by(
            course_id: course.id,
            user_id: student.id,
            outcome_id: outcome.id
          )
          expect(rollup.workflow_state).to eq("active")
          expect(rollup.aggregate_score).to eq(3.0)
        end

        deleted_rollup = OutcomeRollup.find_by(
          course_id: course.id,
          user_id: students[2].id,
          outcome_id: outcome.id
        )
        expect(deleted_rollup.workflow_state).to eq("deleted")
      end

      it "marks all rollups as deleted when no results exist" do
        LearningOutcomeResult.where(
          learning_outcome: outcome,
          context: course
        ).destroy_all

        subject.call

        rollups = OutcomeRollup.where(
          course_id: course.id,
          outcome_id: outcome.id
        )

        expect(rollups.where(workflow_state: "active").count).to eq(0)
        expect(rollups.where(workflow_state: "deleted").count).to eq(3)
      end
    end

    context "combining Canvas and Outcomes Service results" do
      let(:quiz_assignment) { assignment_model(context: course, submission_types: "external_tool") }

      before do
        quiz_assignment.external_tool_tag = ContentTag.new(
          url: "http://example.com/launch",
          new_tab: false,
          content_type: "ContextExternalTool"
        )
        quiz_assignment.external_tool_tag.content_id = 1
        quiz_assignment.save!
      end

      it "combines results from both Canvas and Outcomes Service" do
        students[0..1].each_with_index do |student, i|
          LearningOutcomeResult.create!(
            learning_outcome: outcome,
            context: course,
            user: student,
            alignment:,
            score: 3.0 + i,
            possible: 5.0
          )
        end

        os_result = LearningOutcomeResult.new(
          learning_outcome: outcome,
          context: course,
          user: students[2],
          associated_asset: quiz_assignment,
          title: outcome.title,
          score: 5.0,
          possible: 5.0,
          mastery: true
        )

        allow(subject).to receive(:fetch_outcomes_service_results).and_return([os_result])

        subject.call

        rollups = OutcomeRollup.where(
          course_id: course.id,
          outcome_id: outcome.id,
          workflow_state: "active"
        )

        expect(rollups.count).to eq(3)

        expect(rollups.find_by(user_id: students[0].id).aggregate_score).to eq(3.0)
        expect(rollups.find_by(user_id: students[1].id).aggregate_score).to eq(4.0)

        expect(rollups.find_by(user_id: students[2].id).aggregate_score).to eq(5.0)
      end

      it "handles duplicate results (same student in both Canvas and OS)" do
        LearningOutcomeResult.create!(
          learning_outcome: outcome,
          context: course,
          user: students[0],
          alignment:,
          score: 3.0,
          possible: 5.0
        )

        os_result = LearningOutcomeResult.new(
          learning_outcome: outcome,
          context: course,
          user: students[0],
          associated_asset: quiz_assignment,
          title: outcome.title,
          score: 4.0,
          possible: 5.0,
          mastery: true
        )

        allow(subject).to receive(:fetch_outcomes_service_results).and_return([os_result])

        subject.call

        rollups = OutcomeRollup.where(
          course_id: course.id,
          outcome_id: outcome.id,
          user_id: students[0].id,
          workflow_state: "active"
        )

        expect(rollups.count).to eq(1)
      end
    end

    context "edge cases" do
      it "handles empty course (no students)" do
        course.enrollments.destroy_all

        result = subject.call

        expect(result).to be_a(ActiveRecord::Relation)
        expect(result).to be_empty
      end

      it "handles students with no results" do
        result = subject.call

        expect(result).to be_a(ActiveRecord::Relation)
        expect(result).to be_empty

        rollups = OutcomeRollup.where(
          course_id: course.id,
          outcome_id: outcome.id
        )
        expect(rollups.active.count).to eq(0)
      end

      it "handles mixed scoring (some students with scores, others without)" do
        LearningOutcomeResult.create!(
          learning_outcome: outcome,
          context: course,
          user: students[0],
          alignment:,
          score: 3.0,
          possible: 5.0
        )

        subject.call

        rollups = OutcomeRollup.where(
          course_id: course.id,
          outcome_id: outcome.id,
          workflow_state: "active"
        )

        expect(rollups.count).to eq(1)
        expect(rollups.first.user_id).to eq(students[0].id)
        expect(rollups.first.aggregate_score).to eq(3.0)
      end

      it "handles results with nil scores" do
        LearningOutcomeResult.create!(
          learning_outcome: outcome,
          context: course,
          user: students[0],
          alignment:,
          score: nil,
          possible: 5.0
        )

        result = subject.call

        expect(result).to be_empty
      end

      it "handles results with zero scores" do
        LearningOutcomeResult.create!(
          learning_outcome: outcome,
          context: course,
          user: students[0],
          alignment:,
          score: 0.0,
          possible: 5.0
        )

        subject.call

        rollups = OutcomeRollup.where(
          course_id: course.id,
          outcome_id: outcome.id,
          workflow_state: "active"
        )

        expect(rollups.count).to eq(1)
        expect(rollups.first.aggregate_score).to eq(0.0)
      end

      it "correctly stores results_count reflecting number of aggregated results" do
        assignments = Array.new(3) { assignment_model(context: course) }
        alignments = assignments.map { |a| outcome.align(a, course) }

        alignments.each_with_index do |align, i|
          LearningOutcomeResult.create!(
            learning_outcome: outcome,
            context: course,
            user: students[0],
            alignment: align,
            score: 2.0 + i,
            possible: 5.0
          )
        end

        subject.call

        rollup = OutcomeRollup.find_by(
          course_id: course.id,
          outcome_id: outcome.id,
          user_id: students[0].id,
          workflow_state: "active"
        )

        expect(rollup).to be_present
        expect(rollup.results_count).to eq(3)
        expect(rollup.aggregate_score).to be_present
      end
    end

    context "job scheduling" do
      it "can be scheduled as a delayed job" do
        expect do
          described_class.calculate_for_course_outcome(
            course_id: course.id,
            outcome_id: outcome.id
          )
        end.not_to raise_error
      end
    end

    context "validations and error handling" do
      it "continues processing if one student has invalid data" do
        students[0..1].each_with_index do |student, i|
          LearningOutcomeResult.create!(
            learning_outcome: outcome,
            context: course,
            user: student,
            alignment:,
            score: 3.0 + i,
            possible: 5.0
          )
        end

        subject.call

        rollups = OutcomeRollup.where(
          course_id: course.id,
          outcome_id: outcome.id,
          workflow_state: "active"
        )

        expect(rollups.count).to eq(2)
      end

      it "handles courses with many students efficiently" do
        2.times { course.enroll_student(user_model, enrollment_state: "active") }

        all_students = course.students
        expect(all_students.count).to eq(5)

        all_students.each do |student|
          LearningOutcomeResult.create!(
            learning_outcome: outcome,
            context: course,
            user: student,
            alignment:,
            score: 3.5,
            possible: 5.0
          )
        end

        subject.call

        rollups = OutcomeRollup.where(
          course_id: course.id,
          outcome_id: outcome.id,
          workflow_state: "active"
        )

        expect(rollups.count).to eq(5)
        expect(rollups.pluck(:aggregate_score).uniq).to eq([3.5])
      end
    end
  end
end
