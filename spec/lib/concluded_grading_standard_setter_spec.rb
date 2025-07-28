# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe ConcludedGradingStandardSetter do
  describe ".preserve_grading_standard_inheritance" do
    it "invokes #preserve_grading_standard_inheritance" do
      dbl = instance_double(ConcludedGradingStandardSetter)
      allow(described_class).to receive(:new).and_return(dbl)
      expect(dbl).to receive(:preserve_grading_standard_inheritance)

      described_class.preserve_grading_standard_inheritance
    end
  end

  describe "#preserve_grading_standard_inheritance" do
    before do
      @term = Account.default.enrollment_terms.create!
      @course = Account.default.courses.create!(enrollment_term: @term)
      @gs = GradingStandard.create!(context: Account.default, data: { "A" => 0.90, "B" => 0.80, "C" => 0.70, "D" => 0.50, "F" => 0.0 })
      Account.default.update!(grading_standard: @gs)
      @setter = ConcludedGradingStandardSetter.new
    end

    it "updates the grading_standard_id for recently concluded courses inheriting the account default" do
      @course.update!(conclude_at: 1.hour.ago, restrict_enrollments_to_course_dates: true)
      @setter.preserve_grading_standard_inheritance
      expect(@course.reload.grading_standard_id).to eq(@gs.id)
    end

    it "does not update the grading_standard_id for recently concluded courses with a grading standard set" do
      @course.update!(conclude_at: 1.hour.ago, restrict_enrollments_to_course_dates: true)
      course_gs = GradingStandard.create!(context: Account.default, data: { "A" => 0.90, "B" => 0.80, "C" => 0.70, "D" => 0.50, "F" => 0.0 })
      @course.update!(grading_standard: course_gs)
      @setter.preserve_grading_standard_inheritance
      expect(@course.reload.grading_standard_id).to eq(course_gs.id)
    end

    it "does not update the grading_standard_id for courses that is linked to a term that has ended, but has it's own conclude_at that has not been reached" do
      @course.update!(conclude_at: 1.hour.from_now, restrict_enrollments_to_course_dates: true)
      @term.update!(end_at: 1.hour.ago)
      @setter.preserve_grading_standard_inheritance
      expect(@course.reload.grading_standard_id).to be_nil
    end

    it "updates the grading_standard_id for recently concluded courses with enrollment term end" do
      @term.update!(end_at: 1.hour.ago)
      @setter.preserve_grading_standard_inheritance
      expect(@course.reload.grading_standard_id).to eq(@gs.id)
    end

    it "does not update the grading_standard_id for courses that are not recently concluded" do
      @term.update!(end_at: 1.hour.from_now)
      @setter.preserve_grading_standard_inheritance
      expect(@course.reload.grading_standard_id).to be_nil
    end
  end
end
