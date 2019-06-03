require_relative '../../rails_helper'

RSpec.describe UnitsService::GradesCalculator do
  let(:unit) { double('unit', id: 1, position: 1) }
  let(:course) { double('course') }
  let(:submissions) { [checkpoint_submission, discussion_group_submission] }
  let(:checkpoint_submission) do
    double(
      :submission,
      excused?: false,
      score: 70,
      assignment: checkpoint_assignment
    )
  end

  let(:discussion_group_submission) do
    double(
      :submission,
      excused?: false,
      score: 50,
      assignment: discussion_assignment)
  end

  let(:checkpoint_assignment_group) do
    double(:checkpoint_assignment_group, name: 'checkpoints', group_weight: 0.2)
  end

  let(:discussion_assignment_group) do
    double(:discussion_assignment_group, name: 'discussion_groups', group_weight: 0.1)
  end

  let(:exam_assignment_group) do
    double(:exam_assignment_group, name: 'exams', group_weight: 0.25)
  end

  let(:checkpoint_assignment) do
    double(:checkpoint_assignment, assignment_group: checkpoint_assignment_group)
  end

  let(:discussion_assignment) do
    double(:discussion_assignment, assignment_group: discussion_assignment_group)
  end

  let(:exam) do
    double(:exam, assignment_group: exam_assignment_group)
  end

  let(:unit_submissions) do
    result = {}
    result[unit] = submissions
    result
  end

  subject { described_class.new(unit_submissions, course) }

  describe '#call' do
    context 'an assignment without a score' do
      let(:submissions) { [checkpoint_submission, discussion_group_submission, no_score_submission] }
      let(:no_score_submission) do
        double(
          :submission,
          excused?: false,
          score: nil,
          assignment: discussion_assignment)
      end

      it 'wont break the sum of scores' do
        expect {subject.call}.to_not raise_error
      end
    end

    context 'scenario 1' do
      it 'scored 63.33' do
        expect(subject.call[unit]).to be_within(0.1).of(63.33)
        subject.call
      end
    end

    # 70% average checkpoint grade, weighted at 20% (divided by a sum category weight of 30%)
    # 70 * (20/30)  = 46.667
    # +
    # 50% average discussion grade, weighted at 10% (divided by a sum category weight of 30%)
    # 50 * (10/30) = 16.667
    # Then, you add the categories:
    # 46.667 + 16.667 = 63.33% Unit Grade for the student
    context 'scenario 2' do
      let(:checkpoint_submission) do
        double(
          :submission,
          excused?: false,
          score: 70,
          assignment: checkpoint_assignment
        )
      end

      let(:checkpoint_submission_2) do
        double(
          :submission,
          excused?: false,
          score: 85,
          assignment: checkpoint_assignment
        )
      end

      let(:discussion_group_submission) do
        double(
          :submission,
          excused?: false,
          score: 80,
          assignment: discussion_assignment)
      end

      let(:exam_submission) do
        double(
          :submission,
          excused?: false,
          score: 65,
          assignment: exam)
      end

      let(:submissions) do
        [checkpoint_submission, checkpoint_submission_2, discussion_group_submission, exam_submission]
      end

      # 77.5% average checkpoint grade ((70+85) / 2), weighted at 20% (divided by a sum category weight of 55%)
      # 77.5 * (20/55)  = 28.18
      # +
      # 80% average discussion grade, weighted at 10% (divided by a sum category weight of 55%)
      # 80 * (10/55) = 14.54
      # +
      # 65% average Exam grade, weighted at 25% (divided by a sum category weight of 55%)
      # 65 * (25/55) = 29.54
      # Then, you add the categories:
      # 28.18 + 14.54 +29.54 = 72.26% Unit Grade for the student
      it 'scored 72.26' do
        expect(subject.call[unit]).to be_within(0.1).of(72.26)
        subject.call
      end
    end
  end
end
