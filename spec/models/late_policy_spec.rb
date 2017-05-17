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
      policy = LatePolicy.new(late_submission_minimum_percent: 100.223)
      expect(policy.late_submission_minimum_percent).to eql BigDecimal.new('100.22')
    end

    it 'rounds late_submission_minimum_percent' do
      policy = LatePolicy.new(late_submission_minimum_percent: 100.225)
      expect(policy.late_submission_minimum_percent).to eql BigDecimal.new('100.23')
    end

    it 'only keeps 2 digits after the decimal for missing_submission_deduction' do
      policy = LatePolicy.new(missing_submission_deduction: 100.223)
      expect(policy.missing_submission_deduction).to eql BigDecimal.new('100.22')
    end

    it 'rounds missing_submission_deduction' do
      policy = LatePolicy.new(missing_submission_deduction: 100.225)
      expect(policy.missing_submission_deduction).to eql BigDecimal.new('100.23')
    end

    it 'only keeps 2 digits after the decimal for late_submission_deduction' do
      policy = LatePolicy.new(late_submission_deduction: 100.223)
      expect(policy.late_submission_deduction).to eql BigDecimal.new('100.22')
    end

    it 'rounds late_submission_deduction' do
      policy = LatePolicy.new(late_submission_deduction: 100.225)
      expect(policy.late_submission_deduction).to eql BigDecimal.new('100.23')
    end
  end

  describe 'deduction' do
    it 'ignores disabled late submission deduction' do
      expect(late_policy_model.points_deducted(score: 500, possible: 1000, late_for: 1.day)).to eq 0
    end

    it 'ignores ungraded assignments' do
      policy = late_policy_model(deduct: 5.0, every: :hour)
      expect(policy.points_deducted(score: 10, possible: nil, late_for: 1.day)).to eq 0
    end

    it 'increases by hour' do
      policy = late_policy_model(deduct: 5.0, every: :hour)
      expect(policy.points_deducted(score: 1000, possible: 1000, late_for: 12.hours)).to eq 600
    end

    it 'increases by day' do
      policy = late_policy_model(deduct: 15.0, every: :day)
      expect(policy.points_deducted(score: 1000, possible: 1000, late_for: 3.days)).to eq 450
    end

    it 'rounds partial late interval count upward' do
      policy = late_policy_model(deduct: 10.0, every: :day)
      expect(policy.points_deducted(score: 1000, possible: 1000, late_for: 25.hours)).to eq 200
    end

    it 'honors the minimum percent deducted' do
      policy = late_policy_model(deduct: 10.0, every: :day, down_to: 30.0)
      expect(policy.points_deducted(score: 800, possible: 1000, late_for: 2.days)).to eq 200
      expect(policy.points_deducted(score: 800, possible: 1000, late_for: 7.days)).to eq 500
      expect(policy.points_deducted(score: 200, possible: 1000, late_for: 8.days)).to eq 0
    end

    it 'can deduct fractional points' do
      policy = late_policy_model(deduct: 1.0, every: :hour)
      expect(policy.points_deducted(score: 10, possible: 10, late_for: 6.hours)).to eq 0.6
    end
  end
end
