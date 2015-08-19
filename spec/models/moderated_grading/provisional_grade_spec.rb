require 'spec_helper'

describe ModeratedGrading::ProvisionalGrade do
  subject(:provisional_grade) do
    submission.provisional_grades.new(grade: 'A', score: 100.0, scorer: user).tap do |grade|
      grade.scorer = user
    end
  end
  let(:submission) { assignment.submissions.create!(user: user) }
  let(:assignment) { course.assignments.create! }
  let(:course) { Course.create! }
  let(:user) { User.create! }
  let(:now) { Time.zone.now }

  it { is_expected.to be_valid }
  it { is_expected.to validate_presence_of(:scorer) }
  it { is_expected.to validate_presence_of(:submission) }

  describe 'unique constraint' do
    it "disallows multiple provisional grades from the same user" do
      pg1 = submission.provisional_grades.build(score: 75)
      pg1.scorer = user
      pg1.save!
      pg2 = submission.provisional_grades.build(score: 80)
      pg2.scorer = user
      expect { pg2.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe '#graded_at when a grade changes' do
    it { expect(provisional_grade.graded_at).to be_nil }
    it 'updates the graded_at timestamp when changing grade' do
      Timecop.freeze(now) do
        provisional_grade.update_attributes(grade: 'B')
        expect(provisional_grade.graded_at).to eql now
      end
    end
    it 'updates the graded_at timestamp when changing score' do
      Timecop.freeze(now) do
        provisional_grade.update_attributes(score: 80)
        expect(provisional_grade.graded_at).to eql now
      end
    end
  end
end
