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
end
