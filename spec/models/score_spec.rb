#
# Copyright (C) 2016 - present Instructure, Inc.
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
  before(:once) do
    @grading_periods = grading_periods
    @assignment_group = test_course.assignment_groups.create!(name: 'Assignments')
  end

  let(:test_course) { Course.create! }
  let(:student) { student_in_course(course: test_course) }
  let(:params) do
    {
      course: test_course,
      current_score: 80.2,
      final_score: 74.0,
      updated_at: 1.week.ago
    }
  end

  let(:grading_period_score_params) do
    params.merge(grading_period_id: @grading_periods.first.id)
  end
  let(:assignment_group_score_params) do
    params.merge(assignment_group_id: @assignment_group.id)
  end
  let(:grading_period_score) { student.scores.create!(grading_period_score_params) }
  let(:assignment_group_score) { student.scores.create!(assignment_group_score_params) }

  subject_once(:score) { student.scores.create!(params) }

  it { is_expected.to belong_to(:enrollment) }
  # shoulda-matchers will have an `optional` method in version 4. As a workaround,
  # I've used the validates_presence_of matcher on the line following the belong_to matcher
  it { is_expected.to belong_to(:grading_period) }
  it { is_expected.not_to validate_presence_of(:grading_period) }
  it { is_expected.to belong_to(:assignment_group) }
  it { is_expected.not_to validate_presence_of(:assignment_group) }
  it { is_expected.to have_one(:score_metadata) }
  it { is_expected.to have_one(:course).through(:enrollment) }

  it_behaves_like "soft deletion" do
    subject { student.scores }

    let(:creation_arguments) do
      [
        params.merge(grading_period: @grading_periods.first),
        params.merge(grading_period: @grading_periods.last)
      ]
    end
  end

  describe 'validations' do
    it { is_expected.to be_valid }
    it { is_expected.to validate_numericality_of(:current_score).allow_nil }
    it { is_expected.to validate_numericality_of(:unposted_current_score).allow_nil }
    it { is_expected.to validate_numericality_of(:final_score).allow_nil }
    it { is_expected.to validate_numericality_of(:unposted_final_score).allow_nil }

    it 'is invalid without an enrollment' do
      score.enrollment = nil
      expect(score).to be_invalid
    end

    it { is_expected.to validate_presence_of(:enrollment) }

    it 'is invalid without unique enrollment for course' do
      student.scores.create!(params)
      expect { student.scores.create!(params) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'is invalid without unique enrollment for grading period' do
      student.scores.create!(grading_period_score_params)
      expect { student.scores.create!(grading_period_score_params) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it('is invalid without unique enrollment for assignment group') do
      student.scores.create!(assignment_group_score_params)
      expect { student.scores.create!(assignment_group_score_params) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    context("scorable associations") do
      it 'is valid with course_score true and no scorable associations' do
        expect(student.scores.create!(course_score: true, **params)).to be_valid
      end

      it 'is valid with course_score false and a grading period association' do
        expect(student.scores.create!(course_score: false, **grading_period_score_params)).to be_valid
      end

      it 'is valid with course_score false and an assignment group association' do
        expect(student.scores.create!(course_score: false, **assignment_group_score_params)).to be_valid
      end

      it 'is invalid with course_score false and no scorable associations' do
        expect do
          score = student.scores.create!(params)
          score.update!(course_score: false)
        end.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'is invalid with course_score true and a scorable association' do
        expect do
          student.scores.create!(course_score: true, **grading_period_score_params)
        end.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'is invalid with multiple scorable associations' do
        expect do
          student.scores.create!(grading_period_id: @grading_periods.first.id, **assignment_group_score_params)
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe '#destroy' do
    context 'with score metadata' do
      let(:metadata) { score.create_score_metadata!(calculation_details: { foo: :bar }) }

      describe 'score_metadata association' do
        it 'also destroys score metadata' do
          metadata.score.destroy
          expect(metadata).to be_deleted
        end
      end
    end
  end

  describe '#destroy_permanently' do
    context 'with score metadata' do
      let(:metadata) { score.create_score_metadata!(calculation_details: { foo: :bar }) }

      describe 'score_metadata association' do
        it 'also permanently destroys score metadata' do
          metadata.score.destroy_permanently!
          expect { metadata.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  describe '#undestroy' do
    context 'without score metadata' do
      it 'is active' do
        score.destroy
        score.undestroy
        expect(score).to be_active
      end
    end

    context 'with score metadata' do
      let(:metadata) { score.create_score_metadata!(calculation_details: { foo: :bar }) }

      describe 'score_metadata association' do
        it 'is active' do
          metadata.score.destroy
          metadata.score.undestroy
          expect(metadata).to be_active
        end
      end
    end
  end

  describe '#current_grade' do
    it 'delegates the grade conversion to the course' do
      expect(score.course).to receive(:score_to_grade).once.with(score.current_score)
      score.current_grade
    end

    it 'returns nil if grading schemes are not used in the course' do
      expect(score.course).to receive(:grading_standard_enabled?).and_return(false)
      expect(score.current_grade).to be_nil
    end

    it 'returns the grade according to the course grading scheme' do
      expect(score.course).to receive(:grading_standard_enabled?).and_return(true)
      expect(score.current_grade).to eq 'B-'
    end
  end

  describe '#final_grade' do
    it 'delegates the grade conversion to the course' do
      expect(score.course).to receive(:score_to_grade).once.with(score.final_score)
      score.final_grade
    end

    it 'returns nil if grading schemes are not used in the course' do
      expect(score.course).to receive(:grading_standard_enabled?).and_return(false)
      expect(score.final_grade).to be_nil
    end

    it 'returns the grade according to the course grading scheme' do
      expect(score.course).to receive(:grading_standard_enabled?).and_return(true)
      expect(score.final_grade).to eq 'C'
    end
  end

  describe('#scorable') do
    it 'returns course for course score' do
      expect(score.scorable).to be score.enrollment.course
    end

    it 'returns grading period for grading period score' do
      expect(grading_period_score.scorable).to be grading_period_score.grading_period
    end

    it 'returns assignment group for assignment group score' do
      expect(assignment_group_score.scorable).to be assignment_group_score.assignment_group
    end
  end

  describe('#course_score') do
    it 'sets course_score to true when there are no scorable associations' do
      expect(score.course_score).to be true
    end

    it 'sets course_score to false for grading period scores' do
      expect(grading_period_score.course_score).to be false
    end

    it 'sets course_score to false for assignment group scores' do
      expect(assignment_group_score.course_score).to be false
    end
  end

  describe('#params_for_course') do
    it('uses course_score') do
      expect(Score.params_for_course).to eq(course_score: true)
    end
  end

  context "permissions" do
    it "allows the proper people" do
      expect(score.grants_right?(@enrollment.user, :read)).to eq true

      teacher_in_course(active_all: true)
      expect(score.grants_right?(@teacher, :read)).to eq true
    end

    it "doesn't work for nobody" do
      expect(score.grants_right?(nil, :read)).to eq false
    end

    it "doesn't allow random classmates to read" do
      score
      student_in_course(active_all: true)
      expect(score.grants_right? @student, :read).to eq false
    end

    it "doesn't work for yourself if the course is configured badly" do
      @enrollment.course.hide_final_grade = true
      @enrollment.course.save!
      expect(score.grants_right? @enrollment.user, :read).to eq false
    end
  end

  describe "final grade override" do
    describe "#effective_final_score" do
      it "returns the override score when one is present" do
        score.update!(override_score: 88)
        expect(score.effective_final_score).to eq 88
      end

      it "returns the calculated final score when no override is present" do
        expect(score.effective_final_score).to eq 74
      end
    end

    describe "#effective_final_score_lower_bound" do
      it "returns the lowest possible score in the matching grading scheme, if grading schemes enabled" do
        score.update!(override_score: 89)
        allow(score.course).to receive(:grading_standard_enabled?).and_return(true)
        expect(score.effective_final_score_lower_bound).to eq 87
      end

      it "returns the effective final score if grading schemes are not enabled" do
        score.update!(override_score: 89)
        allow(score.course).to receive(:grading_standard_enabled?).and_return(false)
        expect(score.effective_final_score_lower_bound).to eq 89
      end
    end

    describe "#effective_final_grade" do
      it "returns a grade commensurate with the override score when one is present" do
        score.update!(override_score: 88)
        allow(score.course).to receive(:grading_standard_enabled?).and_return(true)
        expect(score.effective_final_grade).to eq 'B+'
      end

      it "returns the calculated final grade when no override score is present" do
        allow(score.course).to receive(:grading_standard_enabled?).and_return(true)
        expect(score.effective_final_grade).to eq 'C'
      end
    end
  end
end
