#
# Copyright (C) 2016 Instructure, Inc.
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

describe Score do
  let(:test_course) { Course.create! }
  let(:student) { student_in_course(course: test_course) }
  let(:params) {
    {
      course: test_course,
      current_score: 80.2,
      final_score: 74.0,
      updated_at: 1.week.ago
    }
  }
  subject_once(:score) { student.scores.create!(params) }

  it_behaves_like "soft deletion" do
    before do
      grading_periods
    end

    let(:creation_arguments) { [
      params.merge(grading_period: GradingPeriod.first),
      params.merge(grading_period: GradingPeriod.last)
    ] }
    subject { student.scores }
  end

  describe 'validations' do
    it { is_expected.to be_valid }

    it 'is invalid without an enrollment' do
      score.enrollment = nil
      expect(score).to be_invalid
    end

    it 'is invalid without unique enrollment' do
      student.scores.create!(params)
      expect { student.scores.create!(params) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    shared_context "score attribute" do
      it 'is valid as nil' do
        score.write_attribute(attribute, nil)
        expect(score).to be_valid
      end

      it 'is valid with a numeric value' do
        score.write_attribute(attribute, 43.2)
        expect(score).to be_valid
      end

      it 'is invalid with a non-numeric value' do
        score.write_attribute(attribute, 'dora')
        expect(score).to be_invalid
      end
    end

    include_context('score attribute') { let(:attribute) { :current_score } }
    include_context('score attribute') { let(:attribute) { :final_score } }
  end

  describe '#current_grade' do
    it 'delegates the grade conversion to the course' do
      score.course.expects(:score_to_grade).once.with(score.current_score)
      score.current_grade
    end

    it 'returns nil if grading schemes are not used in the course' do
      score.course.expects(:grading_standard_enabled?).returns(false)
      expect(score.current_grade).to be_nil
    end

    it 'returns the grade according to the course grading scheme' do
      score.course.expects(:grading_standard_enabled?).returns(true)
      expect(score.current_grade).to eq 'B-'
    end
  end

  describe '#final_grade' do
    it 'delegates the grade conversion to the course' do
      score.course.expects(:score_to_grade).once.with(score.final_score)
      score.final_grade
    end

    it 'returns nil if grading schemes are not used in the course' do
      score.course.expects(:grading_standard_enabled?).returns(false)
      expect(score.final_grade).to be_nil
    end

    it 'returns the grade according to the course grading scheme' do
      score.course.expects(:grading_standard_enabled?).returns(true)
      expect(score.final_grade).to eq 'C'
    end
  end
end
