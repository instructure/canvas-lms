#
# Copyright (C) 2013 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Quizzes::QuizQuestion::AnswerGroup do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  let(:question_data_params) do
    {
      answers: [
        {
          answer_text: "A",
          answer_comments: "Comments for A",
          answer_weight: 0,
        },
        {
          answer_text: "B",
          answer_comments: "Comments for B",
          answer_weight: 0,
        },
        {
          answer_text: "C",
          answer_comments: "Comments for C",
          answer_weight: 0,
        }
      ],
      question_type: "multiple_choice_question",
      regrade_option: false,
      points_possible: 5,
      correct_comments: "This question is correct.",
      incorrect_comments: "This question is correct.",
      neutral_comments: "Answer this question.",
      question_name: "Generic question",
      question_text: "What is better, ruby or javascript?"
    }
  end

  let(:question_data) { Quizzes::QuizQuestion::QuestionData.generate(question_data_params) }

  describe ".generate" do
    it "seeds a question with parsed answers" do
      question_data.answers.should be_instance_of(Quizzes::QuizQuestion::AnswerGroup)
      question_data.answers.to_a.size.should == 3
    end
  end

  describe "#to_a" do
    it "returns an array" do
      question_data.answers.to_a.should be_instance_of(Array)
    end

    it "converts each answer to a hash" do
      question_data.answers.to_a.each do |a|
        a.should be_instance_of(Hash)
      end
    end
  end

  describe "#set_correct_if_none" do
    it "sets the first answer to correct if none are set" do
      question_data.answers.set_correct_if_none
      question_data.answers.to_a.first[:weight].should == 100
    end
  end

  describe "#correct_answer" do
    it "returns the correct answer" do
      question_data.answers.correct_answer[:text].should == "A"
    end

  end
end

describe Quizzes::QuizQuestion::AnswerGroup::Answer do
  let(:params) do
    {
      weight: 100,
      text: "Answer 1",
      comments: "Some comments to Answer 1"
    }
  end

  before(:each) do
    @answer = Quizzes::QuizQuestion::AnswerGroup::Answer.new(params)
  end

  describe "#to_hash" do
    it "returns the internal hash" do
      @answer.to_hash.should be_instance_of(Hash)
      @answer.to_hash[:text].should == "Answer 1"
    end
  end

  describe "#correct?" do
    context "when weight is 100" do
      it "returns true" do
        @answer.correct?.should be_true
      end
    end

    context "when weight isn't 100" do
      it "returns false" do
        @answer[:weight] = 0
        @answer.correct?.should be_false
        @answer[:weight] = nil
        @answer.correct?.should be_false
        @answer[:weight] = ""
        @answer.correct?.should be_false
        @answer[:weight] = 5
        @answer.correct?.should be_false
      end
    end
  end

  describe "#any_value_of" do
    it "returns the value of the first key that exists" do
      @answer.any_value_of([:answer_weight, :weight]).should == 100
    end

    it "ignores any keys supplied that don't exist" do
      @answer.any_value_of([:blah, :weight, :answer_weight, :foo]).should == 100
    end

    it "returns the supplied default if none of the keys are found" do
      @answer.any_value_of([:foo], "default").should == "default"
    end
  end

  describe "#set_id" do
    it "assigns a randomly generated id to the answer" do
      @answer.set_id([])
      @answer[:id].should be_kind_of(Fixnum)
      @answer[:id].should be > 0
    end

    it "takes taken ids into account and prevents collisions" do
      range = [1..1000]
      @answer.set_id(range)
      range.should_not include(@answer[:id])
    end

    it "doesn't reassign a new id if one has already been set" do
      id = @answer.set_id([])
      @answer.set_id([])
      @answer.set_id([])

      @answer[:id].should eql(id)
    end
  end
end
