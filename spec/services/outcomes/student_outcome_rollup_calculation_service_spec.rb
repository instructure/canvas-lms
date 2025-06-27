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

  describe ".calculate_for_student" do
    let(:delay_mock) { double("delay") }

    before do
      allow(Outcomes::StudentOutcomeRollupCalculationService).to receive(:delay).and_return(delay_mock)
      allow(delay_mock).to receive(:call)
    end

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
      # Create a list of expected parameters using map
      expected_params = students.map do |student|
        { course_id: course.id, student_id: student.id }
      end

      # Expect calculate_for_student to be called exactly once for each student
      expected_params.each do |params|
        expect(Outcomes::StudentOutcomeRollupCalculationService).to receive(:calculate_for_student)
          .with(params).once
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
  end

  describe ".call" do
    it "executes without raising an error" do
      # At this skeleton stage, we're just verifying the service can be called without errors
      expect do
        Outcomes::StudentOutcomeRollupCalculationService.call(course_id: course.id, student_id: student.id)
      end.not_to raise_error
    end
  end

  describe "#fetch_canvas_results" do
    let(:outcome) { outcome_model(context: course) }
    let(:alignment) { outcome.align(assignment_model(context: course), course) }

    it "returns an empty array when no results exist" do
      results = subject.send(:fetch_canvas_results)
      expect(results).to eq([])
    end

    it "returns a learning outcome result associated to the user" do
      user2 = user_model

      [student, user2].each do |user|
        LearningOutcomeResult.create!(
          learning_outcome: outcome,
          user:,
          context: course,
          alignment:
        )
      end

      results = subject.send(:fetch_canvas_results)
      expect(results.count).to eq(1)
    end
  end
end
