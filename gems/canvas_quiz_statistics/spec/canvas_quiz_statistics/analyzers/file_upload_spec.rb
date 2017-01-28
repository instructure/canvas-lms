require 'spec_helper'

describe CanvasQuizStatistics::Analyzers::FileUpload do
  let(:question_data) { QuestionHelpers.fixture('file_upload_question') }
  subject { described_class.new(question_data) }

  it 'should not blow up when no responses are provided' do
    expect { expect(subject.run([])).to be_present }.to_not raise_error
  end

  describe '[:responses]' do
    it 'should count students who have uploaded an attachment' do
      expect(subject.run([
        {},
        { attachment_ids: nil },
        { attachment_ids: [] },
        { attachment_ids: ['1'] }
      ])[:responses]).to eq(1)
    end
  end
end
