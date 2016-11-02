require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe OriginalityReport do

  let(:attachment) { attachment_model }
  let(:course) { course_model }

  subject {OriginalityReport.create!(attachment: attachment, originality_score: '1')}

  it 'can have attachments associated with it' do
    expect(subject.attachment).to eq attachment
  end

  it 'requires an originality score' do
    subject.originality_score = nil
    subject.valid?
    expect(subject.errors[:originality_score]).to eq ["can't be blank"]
  end

  it 'requires an attachment' do
    subject.attachment = nil
    subject.valid?
    expect(subject.errors[:attachment]).to eq ["can't be blank"]
  end

  it 'can have an originality report attachment' do
    originality_attachemnt = attachment_model
    subject.originality_report_attachment = originality_attachemnt
    subject.save!
    expect(subject.originality_report_attachment).to eq originality_attachemnt
  end

end