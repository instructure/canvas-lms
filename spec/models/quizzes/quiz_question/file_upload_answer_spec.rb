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
      answer.question_id.should == question_id
    end

    it "saves the points possible" do
      answer.points_possible.should == points_possible
    end

    it "saves answer_details with attachment_ids" do
      answer.answer_details.should == {:attachment_ids => ["1"] }
    end

  end

  describe "attachment_ids" do

    it "returns attachment ids when there are attachment ids" do
      answer.attachment_ids.should == ["1"]
    end

    it "returns nil if no attachment ids" do
      data = {
        :question_1 => [""]
      }
      answer = Quizzes::QuizQuestion::FileUploadAnswer.new(question_id,points_possible,data)
      answer.attachment_ids.should be_nil
    end

    it "handles the case where attachment_ids is nil" do
      data = {}
      data[question_id] = nil
      answer = Quizzes::QuizQuestion::FileUploadAnswer.new(question_id,points_possible,data)
      ids = nil
      expect {
        ids = answer.attachment_ids
      }.to_not raise_error
      ids.should be_nil
    end

  end

end
