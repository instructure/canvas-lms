require 'spec_helper'

describe ModeratedGrading::ProvisionalGrade do
  subject(:provisional_grade) do
    submission.provisional_grades.new(grade: 'A', score: 100.0, position: 1, scorer: user).tap do |grade|
      grade.scorer = user
    end
  end
  let(:submission) { assignment.submissions.create!(user: user) }
  let(:assignment) { course.assignments.create! }
  let(:course) { Course.create! }
  let(:user) { User.create! }
  let(:now) { Time.zone.now }

  it { is_expected.to be_valid }
  it { is_expected.to validate_presence_of(:position) }
  it { is_expected.to validate_presence_of(:scorer) }
  it { is_expected.to validate_presence_of(:submission) }
  it { is_expected.to validate_uniqueness_of(:position).scoped_to(:submission_id) }

  describe '#graded_at when a grade changes' do
    it { expect(provisional_grade.graded_at).to be_nil }
    it 'updates the graded_at timestamp' do
      Timecop.freeze(now) do
        provisional_grade.update_attributes(grade: 'B')
        expect(provisional_grade.graded_at).to eql now
      end
    end
  end
end
