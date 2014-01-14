require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')
require 'ostruct'

describe QuizQuestion::AnswerParsers::AnswerParser do
  context "#parse" do
    let(:answer_parser) { QuizQuestion::AnswerParsers::AnswerParser.new([]) }

    it "returns the question with answers assigned" do
      question = OpenStruct.new
      answer_parser.parse(question).answers.should == []
    end
  end
end
