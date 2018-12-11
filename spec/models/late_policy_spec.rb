#
# Copyright (C) 2017 - present Instructure, Inc.
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

require 'spec_helper'

describe LatePolicy do
  describe 'relationships' do
    it { is_expected.to belong_to(:course).inverse_of(:late_policy) }
  end

  describe 'validations' do
    # Presence
    it { is_expected.to validate_presence_of(:course_id) }
    it { is_expected.to validate_presence_of(:late_submission_interval) }
    it { is_expected.to validate_presence_of(:late_submission_minimum_percent) }
    it { is_expected.to validate_presence_of(:late_submission_deduction) }
    it { is_expected.to validate_presence_of(:missing_submission_deduction) }

    # Numericality
    it do
      is_expected.to validate_numericality_of(:late_submission_minimum_percent).
        is_greater_than_or_equal_to(0).
        is_less_than_or_equal_to(100)
    end

    it do
      is_expected.to validate_numericality_of(:missing_submission_deduction).
        is_greater_than_or_equal_to(0).
        is_less_than_or_equal_to(100)
    end

    it do
      is_expected.to validate_numericality_of(:late_submission_deduction).
        is_greater_than_or_equal_to(0).
        is_less_than_or_equal_to(100)
    end

    # Inclusion
    it { is_expected.to validate_inclusion_of(:late_submission_interval).in_array(['day', 'hour']) }

    # Uniqueness
    describe 'uniqueness' do
      subject { course.create_late_policy }
      let(:course) { Course.create! }

      it { is_expected.to validate_uniqueness_of(:course_id) }
    end
  end

  describe 'default values' do
    it 'sets the late_submission_interval to "day" if not explicitly set' do
      policy = LatePolicy.new
      expect(policy.late_submission_interval).to eq 'day'
    end

    it 'sets the late_submission_minimum_percent to 0 if not explicitly set' do
      policy = LatePolicy.new
      expect(policy.late_submission_minimum_percent).to be_zero
    end
  end

  describe 'rounding' do
    it 'only keeps 2 digits after the decimal for late_submission_minimum_percent' do
      policy = LatePolicy.new(late_submission_minimum_percent: 25.223)
      expect(policy.late_submission_minimum_percent).to eql BigDecimal('25.22')
    end

    it 'rounds late_submission_minimum_percent' do
      policy = LatePolicy.new(late_submission_minimum_percent: 25.225)
      expect(policy.late_submission_minimum_percent).to eql BigDecimal('25.23')
    end

    it 'only keeps 2 digits after the decimal for missing_submission_deduction' do
      policy = LatePolicy.new(missing_submission_deduction: 25.223)
      expect(policy.missing_submission_deduction).to eql BigDecimal('25.22')
    end

    it 'rounds missing_submission_deduction' do
      policy = LatePolicy.new(missing_submission_deduction: 25.225)
      expect(policy.missing_submission_deduction).to eql BigDecimal('25.23')
    end

    it 'only keeps 2 digits after the decimal for late_submission_deduction' do
      policy = LatePolicy.new(late_submission_deduction: 25.223)
      expect(policy.late_submission_deduction).to eql BigDecimal('25.22')
    end

    it 'rounds late_submission_deduction' do
      policy = LatePolicy.new(late_submission_deduction: 25.225)
      expect(policy.late_submission_deduction).to eql BigDecimal('25.23')
    end
  end

  describe '#points_deducted' do
    it 'ignores disabled late submission deduction' do
      expect(late_policy_model.points_deducted(score: 500, possible: 1000, late_for: 1.day, grading_type: 'points')).to eq 0
    end

    it 'ignores ungraded assignments' do
      policy = late_policy_model(deduct: 5.0, every: :hour)
      expect(policy.points_deducted(score: 10, possible: nil, late_for: 1.day, grading_type: 'points')).to eq 0
    end

    it 'ignores pass_fail assignments' do
      policy = late_policy_model(deduct: 5.0, every: :hour)
      expect(policy.points_deducted(score: 10, possible: nil, late_for: 1.day, grading_type: 'pass_fail')).to eq 0
    end

    it 'ignores assignments that are not meant to be graded' do
      policy = late_policy_model(deduct: 5.0, every: :hour)
      expect(policy.points_deducted(score: 10, possible: nil, late_for: 1.day, grading_type: 'not_graded')).to eq 0
    end

    it 'increases by hour' do
      policy = late_policy_model(deduct: 5.0, every: :hour)
      expect(policy.points_deducted(score: 1000, possible: 1000, late_for: 12.hours, grading_type: 'points')).to eq 600
    end

    it 'increases by day' do
      policy = late_policy_model(deduct: 15.0, every: :day)
      expect(policy.points_deducted(score: 1000, possible: 1000, late_for: 3.days, grading_type: 'points')).to eq 450
    end

    it 'rounds partial late interval count upward' do
      policy = late_policy_model(deduct: 10.0, every: :day)
      expect(policy.points_deducted(score: 1000, possible: 1000, late_for: 25.hours, grading_type: 'points')).to eq 200
    end

    it 'honors the minimum percent deducted' do
      policy = late_policy_model(deduct: 10.0, every: :day, down_to: 30.0)
      expect(policy.points_deducted(score: 800, possible: 1000, late_for: 2.days, grading_type: 'points')).to eq 200
      expect(policy.points_deducted(score: 800, possible: 1000, late_for: 7.days, grading_type: 'points')).to eq 500
      expect(policy.points_deducted(score: 200, possible: 1000, late_for: 8.days, grading_type: 'points')).to eq 0
    end

    it 'can deduct fractional points' do
      policy = late_policy_model(deduct: 1.0, every: :hour)
      expect(policy.points_deducted(score: 10, possible: 10, late_for: 6.hours, grading_type: 'points')).to eq 0.6
    end
  end

  describe '#points_for_missing' do
    it 'returns 0 when assignment grading_type is pass_fail' do
      policy = late_policy_model
      expect(policy.points_for_missing(100, 'pass_fail')).to eq(0)
    end

    it 'computes expected value' do
      policy = late_policy_model(missing: 60)
      expect(policy.points_for_missing(100, 'foo')).to eq(40)
    end
  end

  describe '#missing_points_deducted' do
    it 'returns points_possible when assignment grading_type is pass_fail' do
      policy = late_policy_model
      expect(policy.missing_points_deducted(100, 'pass_fail')).to eq(100)
    end

    it 'computes expected value' do
      policy = late_policy_model(missing: 60)
      expect(policy.missing_points_deducted(100, 'foo')).to eq(60)
    end
  end

  describe '#update_late_submissions' do
    before :once do
      @course = Course.create(name: 'Late Policy Course')
      @late_policy = LatePolicy.create(course: @course)
    end

    it 'kicks off a late policy applicator for the course if late_submission_deduction_enabled_changed changes' do
      @late_policy.late_submission_deduction_enabled = !@late_policy.late_submission_deduction_enabled

      expect(LatePolicyApplicator).to receive(:for_course).with(@course)

      @late_policy.save!
    end

    it 'kicks off a late policy applicator for the course if late_submission_deduction changes' do
      @late_policy.late_submission_deduction = 3.14

      expect(LatePolicyApplicator).to receive(:for_course).with(@course)

      @late_policy.save!
    end

    it 'kicks off a late policy applicator for the course if late_submission_interval changes' do
      @late_policy.late_submission_interval = 'hour'

      expect(LatePolicyApplicator).to receive(:for_course).with(@course)

      @late_policy.save!
    end

    it 'kicks off a late policy applicator for the course if late_submission_minimum_percent_enabled changes' do
      @late_policy.late_submission_minimum_percent_enabled = !@late_policy.late_submission_minimum_percent_enabled

      expect(LatePolicyApplicator).to receive(:for_course).with(@course)

      @late_policy.save!
    end

    it 'kicks off a late policy applicator for the course if late_submission_minimum_percent changes' do
      @late_policy.late_submission_minimum_percent = 3.14

      expect(LatePolicyApplicator).to receive(:for_course).with(@course)

      @late_policy.save!
    end

    it 'kicks off a late policy applicator if missing_submission_deduction_enabled changes' do
      @late_policy.missing_submission_deduction_enabled = !@late_policy.missing_submission_deduction_enabled

      expect(LatePolicyApplicator).to receive(:for_course).with(@course)

      @late_policy.save!
    end

    it 'does not kick off a late policy applicator if missing_submission_deduction changes' do
      @late_policy.missing_submission_deduction = 3.14

      expect(LatePolicyApplicator).not_to receive(:for_course)

      @late_policy.save!
    end
  end

end
