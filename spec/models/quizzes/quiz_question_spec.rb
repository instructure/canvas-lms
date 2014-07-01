#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Quizzes::QuizQuestion do

  it "should deserialize its json data" do
    answers = [{'id' => 1}, {'id' => 2}]
    qd = {'name' => 'test question', 'question_type' => 'multiple_choice_question', 'answers' => answers}
    course
    bank = @course.assessment_question_banks.create!
    a = bank.assessment_questions.create!
    q = Quizzes::QuizQuestion.create(:question_data => qd, :assessment_question => a)
    q.question_data.should_not be_nil
    q.question_data.class.should == Quizzes::QuizQuestion::QuestionData
    q.assessment_question_id.should eql(a.id)
    q.question_data == qd

    data = q.data
    data[:assessment_question_id].should eql(a.id)
    data[:answers].should_not be_empty
    data[:answers].length.should eql(2)
    data[:answers][0][:weight].should == 100
    data[:answers][1][:weight].should eql(0.0)
  end

  describe "#question_data=" do
    before do
      course_with_teacher

      @quiz = @course.quizzes.create

      @data = {:question_name   => 'test question',
               :points_possible => '1',
               :question_type   => 'multiple_choice_question',
               :answers         => [{'answer_text' => '1', 'id' => 1},
                                    {'answer_text' => '2', 'id' => 2},
                                    {'answer_text' => '3', 'id' => 3},
                                    {'answer_text' => '4', 'id' => 4}]}

      @question = @quiz.quiz_questions.create(:question_data => @data)
    end

    it "should save regrade if passed in regrade option in data hash" do
      Quizzes::QuizQuestionRegrade.first.should be_nil

      Quizzes::QuizRegrade.create(quiz_id: @quiz.id, user_id: @user.id, quiz_version: @quiz.version_number)
      @question.question_data = @data.merge(:regrade_option => 'full_credit',
                                            :regrade_user   => @user)
      @question.save

      question_regrade = Quizzes::QuizQuestionRegrade.first
      question_regrade.should be
      question_regrade.regrade_option.should == 'full_credit'
    end
  end

  describe ".update_all_positions" do
    def question_positions(object)
      object.quiz_questions.active.sort_by{|q| q.position }.map {|q| q.id }
    end

    before :once do
      course
      @quiz = @course.quizzes.create!(:title => "some quiz")
      @question1 = @quiz.quiz_questions.create!(:question_data => {'name' => 'test question 1', 'answers' => [{'id' => 1}, {'id' => 2}]})
      @question2 = @quiz.quiz_questions.create!(:question_data => {'name' => 'test question 2', 'answers' => [{'id' => 3}, {'id' => 4}]})
      @question3 = @quiz.quiz_questions.create!(:question_data => {'name' => 'test question 3', 'answers' => [{'id' => 5}, {'id' => 6}]})
    end

    it "should noop if list of items is empty" do
      group = @quiz.quiz_groups.create(:name => "question group")
      group.quiz_questions = [@question1, @question2, @question3]
      before = question_positions(group)

      Quizzes::QuizQuestion.update_all_positions!([], group)
      before.should == question_positions(group)
    end

    it "should update positions for quiz questions within a group" do
      group = @quiz.quiz_groups.create(:name => "question group")
      group.quiz_questions = [@question1, @question2, @question3]

      @question3.position = 1
      @question1.position = 2
      @question2.position = 3

      Quizzes::QuizQuestion.update_all_positions!([@question3, @question1, @question2], group)
      question_positions(group).should == [@question3.id, @question1.id, @question2.id]
    end

    it "should update positions for quiz questions outside a group" do
      group = @quiz.quiz_groups.create(:name => "question group")
      group.quiz_questions = [@question1, @question2]

      @question3.position = 1
      @question1.position = 2
      @question2.position = 3

      Quizzes::QuizQuestion.update_all_positions!([@question3, @question1, @question2], group)
      question_positions(group).should == [@question3.id, @question1.id, @question2.id]
    end

    it "should update positions for quiz without a group" do
      @question3.position = 1
      @question1.position = 2
      @question2.position = 3

      Quizzes::QuizQuestion.update_all_positions!([@question3, @question1, @question2])
      question_positions(@quiz).should == [@question3.id, @question1.id, @question2.id]
    end
  end

  describe "#destroy" do

    it "does not remove the record from the database, but changes workflow_state" do
      course_with_teacher
      course_quiz

      question = @quiz.quiz_questions.create!
      question.destroy
      question = Quizzes::QuizQuestion.find(question.id)

      question.should_not be_nil
      question.should be_deleted
    end
  end
end
