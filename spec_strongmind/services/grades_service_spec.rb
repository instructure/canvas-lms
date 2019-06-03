require_relative '../rails_helper'

RSpec.describe GradesService, skip: 'todo: fix for running under LMS' do
  let(:instance) { double('command_instance', call!: nil)}
  let(:submission) { double('submission') }
  let(:submission_list) { [submission] }

  before do
    allow(GradesService).to receive(:submissions).and_return(submission_list)
    allow(submission_list).to receive(:find_each).and_yield(submission_list)
    allow(GradesService::Commands::ZeroOutAssignmentGrades).to receive(:new).and_return(instance)
    allow(SettingsService).to receive(:get_settings).and_return({'zero_out_past_due' => 'on'})
    allow(Submission).to receive(:where).and_return(submission_list)
    allow(described_class).to receive(:save_audit_log)
  end

  context 'when the zero grader setting is on' do
    it "calls the command and passes on options" do
      expect(instance).to receive(:call!).with(hash_including(dry_run: true))
      described_class.zero_out_grades!(dry_run: true)
    end

    it 'saves the audit log' do
      expect(described_class).to receive(:save_audit)
      described_class.zero_out_grades!
    end
  end

  context 'when the zero grader setting is off' do
    before do
      allow(SettingsService).to receive(:get_settings).and_return({'zero_out_past_due' => 'off'})
    end
    it 'does not call the command' do
      expect(instance).to_not receive(:call!)
      described_class.zero_out_grades!
    end
  end
end
