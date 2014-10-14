require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Quizzes::QuizQuestion::FileUploadAnswer do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  let(:answer_data) do
    {:question_1 => ["1"]}
  end
  let(:question_id) { 1 }
  let(:points_possible) { 100 }
  let(:answer) do
    Quizzes::QuizQuestion::FileUploadAnswer.new(question_id,points_possible,answer_data)
  end

  describe "#initialize" do

    it "saves question_ids" do
      expect(answer.question_id).to eq question_id
    end

    it "saves the points possible" do
      expect(answer.points_possible).to eq points_possible
    end

    it "saves answer_details with attachment_ids" do
      expect(answer.answer_details).to eq({:attachment_ids => ["1"] })
    end

  end

  describe "attachment_ids" do

    it "returns attachment ids when there are attachment ids" do
      expect(answer.attachment_ids).to eq ["1"]
    end

    it "returns nil if no attachment ids" do
      data = {
        :question_1 => [""]
      }
      answer = Quizzes::QuizQuestion::FileUploadAnswer.new(question_id,points_possible,data)
      expect(answer.attachment_ids).to be_nil
    end

    it "handles the case where attachment_ids is nil" do
      data = {}
      data[question_id] = nil
      answer = Quizzes::QuizQuestion::FileUploadAnswer.new(question_id,points_possible,data)
      ids = nil
      expect {
        ids = answer.attachment_ids
      }.to_not raise_error
      expect(ids).to be_nil
    end

  end

end
