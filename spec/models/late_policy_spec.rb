#
# Copyright (C) 2017 Instructure, Inc.
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
  let(:course) { Course.create! }

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
  end

  describe 'default values' do
    it 'sets the late_submission_interval to "day" if not explicitly set' do
      policy = LatePolicy.new(course: course)
      expect(policy.late_submission_interval).to eq('day')
    end

    it 'sets the late_submission_minimum_percent to 0 if not explicitly set' do
      policy = LatePolicy.new(course: course)
      expect(policy.late_submission_minimum_percent).to be_zero
    end
  end

  describe 'rounding' do
    it 'only keeps 2 digits after the decimal for late_submission_minimum_percent' do
      policy = LatePolicy.new(course: course, late_submission_minimum_percent: 100.223)
      expect(policy.late_submission_minimum_percent).to eq(100.22)
    end

    it 'rounds late_submission_minimum_percent' do
      policy = LatePolicy.new(course: course, late_submission_minimum_percent: 100.225)
      expect(policy.late_submission_minimum_percent).to eq(100.23)
    end

    it 'only keeps 2 digits after the decimal for missing_submission_deduction' do
      policy = LatePolicy.new(course: course, missing_submission_deduction: 100.223)
      expect(policy.missing_submission_deduction).to eq(100.22)
    end

    it 'rounds missing_submission_deduction' do
      policy = LatePolicy.new(course: course, missing_submission_deduction: 100.225)
      expect(policy.missing_submission_deduction).to eq(100.23)
    end

    it 'only keeps 2 digits after the decimal for late_submission_deduction' do
      policy = LatePolicy.new(course: course, late_submission_deduction: 100.223)
      expect(policy.late_submission_deduction).to eq(100.22)
    end

    it 'rounds late_submission_deduction' do
      policy = LatePolicy.new(course: course, late_submission_deduction: 100.225)
      expect(policy.late_submission_deduction).to eq(100.23)
    end
  end
end
