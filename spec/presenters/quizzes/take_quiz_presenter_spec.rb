#
# Copyright (C) 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Quizzes::TakeQuizPresenter do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  let(:quiz) { Quizzes::Quiz.new }
  let(:submission) { Quizzes::QuizSubmission.new }
  let(:params) { {} }
  let(:question1) { {:id => 1, :name => "Question 1"} }
  let(:question2) { {:id => 2, :name => "Question 2"} }
  let(:question3) { {:id => 3, :name => "Question 3"} }
  let(:all_questions) { [question1, question2, question3] }

  let(:presenter) { Quizzes::TakeQuizPresenter.new(quiz, submission, params) }

  def set_current_question(question)
    params[:question_id] = question[:id]
    submission.stubs(:question).with(question[:id]).returns(question)
  end

  before do
    submission.stubs(:questions_as_object).returns all_questions
  end

  describe "current_questions" do
    context "when the question ID is set" do
      it "queries the submission for that question and returns it in an array" do
        set_current_question question1
        presenter.current_questions.should == [question1]
      end
    end

    context "when the question ID is not set" do
      it "returns all the quiz data" do
        presenter.current_questions.should == all_questions
      end
    end

    context "when one question at a time" do
      it "returns the first question" do
        presenter.stubs(:one_question_at_a_time?).returns(true)
        presenter.current_questions.should == [question1]
      end
    end
  end

  describe "all_questions" do
    it "returns all questions" do
      presenter.all_questions.should == all_questions
    end
  end

  describe "neighboring_question" do
    before do
      quiz.stubs(:one_question_at_a_time?) { true }
    end

    context "when on the first question" do
      it "previous_question returns nil" do
        presenter.previous_question.should be_nil
      end

      it "next_question returns the second question" do
        presenter.next_question.should == question2
      end
    end

    context "when on the second question" do
      before do
        set_current_question question2
      end

      it "previous_question returns the first question" do
        presenter.previous_question.should == question1
      end

      it "next_question returns the third question" do
        presenter.next_question.should == question3
      end
    end

    context "when on the last question" do
      before do
        set_current_question question3
      end

      it "previous_question returns the second question" do
        presenter.previous_question.should == question2
      end

      it "next_question returns nil" do
        presenter.next_question.should be_nil
      end
    end
  end

  describe "previous_question_viewable?" do

    it "returns false if no previous_question" do
      presenter.expects(:previous_question).returns false
      presenter.previous_question_viewable?.should == false
    end

    it "returns true if there is a previous question and quiz allows "+
      "user to go back" do
      presenter.expects(:previous_question).returns true
      presenter.expects(:cant_go_back?).returns false
      presenter.previous_question_viewable?.should == true
    end
  end

  describe "marked?" do
    before do
      submission.stubs(:submission_data).returns(
        "question_#{question1[:id]}_marked" => true,
        "question_#{question2[:id]}_marked" => false
      )
    end

    it "returns true if the submission is marked" do
      presenter.marked?(question1).should be_true
    end

    it "returns false if the submission is not marked" do
      presenter.marked?(question2).should be_false
    end
  end

  describe "answered_icon" do
    before do
      submission.stubs(:submission_data).returns({
        "question_#{question1[:id]}" => true,
        "question_#{question2[:id]}" => nil
      })
    end

    it 'returns icon-check for answered questions' do
      presenter.answered_icon(question1).should == 'icon-check'
    end

    it 'returns icon-question for unanswered questions' do
      presenter.answered_icon(question2).should == 'icon-question'
    end
  end

  describe "answered_text" do
    before do
      submission.stubs(:submission_data).returns({
        "question_#{question1[:id]}" => true,
        "question_#{question2[:id]}" => nil
      })
    end

    it 'returns icon-check for answered questions' do
      presenter.answered_text(question1).should == 'Answered'
    end

    it 'returns icon-question for unanswered questions' do
      presenter.answered_text(question2).should == 'Haven\'t Answered Yet'
    end
  end

  describe "marked_text" do
    before do
      submission.stubs(:submission_data).returns(
        "question_#{question1[:id]}_marked" => true,
        "question_#{question2[:id]}_marked" => false
      )
    end

    it "returns text if the submission is marked" do
      text = "You marked this question to come back to later"
      presenter.marked_text(question1).should == text
    end

    it "returns empty string if the submission is not marked" do
      presenter.marked_text(question2).should be_nil
    end
  end

  describe "current_question?" do
    before do
      set_current_question question2
    end

    it "returns true if the current question is the one passed in" do
      presenter.current_question?(question2).should be_true
    end

    it "returns false when not the current question" do
      presenter.current_question?(question1).should be_false
    end
  end

  describe "last_question?" do
    it "returns true when on the last question" do
      set_current_question question3
      presenter.last_question?.should be_true
    end

    it "returns false when not on the last question" do
      set_current_question question2
      presenter.last_question?.should be_false
    end
  end

  describe "question_index" do
    it "returns the index of the question" do
      presenter.question_index(question2).should == 1
    end
  end

  describe "question_seen?" do
    it "returns true when the question is the current question" do
      presenter.question_seen?(question1).should be_true
    end

    it "returns false when the question is after the current question" do
      presenter.question_seen?(question2).should be_false
    end

    it "returns true when the question is before the current question" do
      presenter.stubs(:current_question).returns(question3)
      presenter.question_seen?(question2).should be_true
    end
  end

  describe "question_answered?" do
    before do
      submission.stubs(:submission_data).returns(
        "question_#{question1[:id]}" => true,
        "question_#{question2[:id]}" => nil
      )
    end

    it 'returns true for answered questions' do
      presenter.question_answered?(question1).should be_true
    end

    it 'returns false for unanswered questions' do
      presenter.question_answered?(question2).should be_false
    end
  end

  describe "#question_class" do
    it "always returns 'list_question'" do
      presenter.question_class(question1).should =~ /list_question/
      presenter.question_class(question2).should =~/list_question/
    end

    it "adds 'answered' if the question was answered" do
      submission.stubs(:submission_data).returns(
        "question_#{question1[:id]}" => true,
        "question_#{question2[:id]}" => nil
      )

      presenter.question_class(question1).should =~ /answered/
      presenter.question_class(question2).should_not =~ /answered/
    end

    it "adds 'marked' if the question was marked" do
      submission.stubs(:submission_data).returns(
        "question_#{question1[:id]}_marked" => true,
        "question_#{question2[:id]}_marked" => false
      )

      presenter.question_class(question1).should =~ /marked/
      presenter.question_class(question2).should_not =~ /marked/
    end

    it "adds 'seen' if the question was seen" do
      presenter.question_class(question1).should =~ /seen/
      presenter.question_class(question2).should_not =~ /seen/

    end

    it "adds 'text_only' if the question is a text only question" do
      q2 = question2.dup
      q2['question_type'] = 'text_only_question'

      presenter.question_class(question1).should_not =~ /text_only/
      presenter.question_class(q2).should =~ /text_only/
    end
  end

  describe 'building the answer set' do
    it 'should discard irrelevant entries' do
      submission.stubs(:submission_data).returns({
        'foo' => 'bar',
        "question_#{question1[:id]}_marked" => true
      })

      p = Quizzes::TakeQuizPresenter.new(quiz, submission, params)
      p.answers.empty?.should be_true
    end

    it 'marks a question as answered' do
      submission.stubs(:submission_data).returns({
        "question_#{question1[:id]}" => '123',
        "question_#{question2[:id]}" => true
      })

      p = Quizzes::TakeQuizPresenter.new(quiz, submission, params)

      p.answers.has_key?(question1[:id]).should be_true
      p.answers.has_key?(question2[:id]).should be_true
      p.answers.has_key?(question3[:id]).should be_false
    end

    it 'rejects zeroes for an answer' do
      submission.stubs(:submission_data).returns({
        "question_#{question1[:id]}" => '0'
      })

      p = Quizzes::TakeQuizPresenter.new(quiz, submission, params)
      p.answers.has_key?(question1[:id]).should be_false
    end
  end

end
