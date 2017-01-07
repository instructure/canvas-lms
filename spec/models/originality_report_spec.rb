require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe OriginalityReport do

  let(:attachment) { attachment_model }
  let(:course) { course_model }
  let(:submission) { submission_model }

  subject {OriginalityReport.create!(attachment: attachment, originality_score: '1', submission: submission, workflow_state: 'pending')}

  it 'can have attachments associated with it' do
    expect(subject.attachment).to eq attachment
  end

  it 'requires an originality score' do
    subject.originality_score = nil
    subject.valid?
    expect(subject.errors[:originality_score]).to eq ["can't be blank", "score must be between 0 and 1"]
  end

  it 'requires an attachment' do
    subject.attachment = nil
    subject.valid?
    expect(subject.errors[:attachment]).to eq ["can't be blank"]
  end

  it 'requies a valid workflow_state' do
    subject.workflow_state = 'invalid_state'
    subject.valid?
    expect(subject.errors).to include :workflow_state
  end

  it 'allows the "pending" workflow state' do
    expect(subject.workflow_state).to eq 'pending'
  end

  it 'allows the "scored" workflow state' do
    subject.workflow_state = 'scored'
    subject.save!
    expect(subject.workflow_state).to eq 'scored'
  end

  it 'allows the "error" workflow state' do
    subject.workflow_state = 'error'
    subject.save!
    expect(subject.workflow_state).to eq 'error'
  end

  it 'can have a submission' do
    subject.submission = nil
    subject.valid?
    expect(subject.errors[:submission]).to eq ["can't be blank"]
  end

  it 'can have an originality report attachment' do
    originality_attachemnt = attachment_model
    subject.originality_report_attachment = originality_attachemnt
    subject.save!
    expect(subject.originality_report_attachment).to eq originality_attachemnt
  end
end
