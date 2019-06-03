require_relative '../../../rails_helper'

RSpec.describe GradesService::Commands::ZeroOutAssignmentGradesRollback do
  subject { described_class.new }

  let(:user) { double('user', id: 1) }
  let(:assignment) { double('assignment') }
  let(:account_admin) { double('account_admin') }
  let(:submission) { double('submission', user: user, assignment: assignment, score: 0, id: 1) }

  before do
    allow(subject).to receive(:load_audit)
    allow(CSV).to receive(:foreach).and_yield([1, 30])
    allow(Submission).to receive(:find).and_return(submission)
    allow(GradesService::Account).to receive(:account_admin).and_return(account_admin)
  end

  describe '#call' do
    it 'grades the student' do
      expect(assignment).to receive(:grade_student).with(user, grader: account_admin, score: 30)
      subject.call!
    end
  end
end
