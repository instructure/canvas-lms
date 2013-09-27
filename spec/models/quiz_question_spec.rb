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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe QuizQuestion do
  
  it "should deserialize its json data" do
    answers = {'answer_0' => {'id' => 1}, 'answer_1' => {'id' => 2}}
    qd = {'name' => 'test question', 'question_type' => 'multiple_choice_question', 'answers' => answers}
    course
    bank = @course.assessment_question_banks.create!
    a = bank.assessment_questions.create!
    q = QuizQuestion.create(:question_data => qd, :assessment_question => a)
    q.question_data.should_not be_nil
    q.question_data.class.should == HashWithIndifferentAccess
    q.assessment_question_id.should eql(a.id)
    q.question_data == qd

    data = q.data
    data[:assessment_question_id].should eql(a.id)
    data[:answers].should_not be_empty
    data[:answers].length.should eql(2)
    data[:answers][0][:weight].should eql(100)
    data[:answers][1][:weight].should eql(0.0)
  end

  describe "#question_data=" do
    before do
      course_with_teacher
      course.root_account.enable_quiz_regrade!

      @quiz = @course.quizzes.create

      @data = {:question_name   => 'test question',
               :points_possible => '1',
               :question_type   => 'multiple_choice_question',
               :answers         => {'answer_0' => {'answer_text' => '1', 'id' => 1},
                                    'answer_1' => {'answer_text' => '2', 'id' => 2},
                                    'answer_1' => {'answer_text' => '3', 'id' => 3},
                                    'answer_1' => {'answer_text' => '4', 'id' => 4}}}
      @question = @quiz.quiz_questions.create(:question_data => @data)
    end

    it "should save regrade if passed in regrade option in data hash" do
      QuizQuestionRegrade.first.should be_nil

      QuizRegrade.create(quiz_id: @quiz.id, user_id: @user.id, quiz_version: @quiz.version_number)
      @question.question_data = @data.merge(:regrade_option => 'full_credit',
                                            :regrade_user   => @user)
      @question.save

      question_regrade = QuizQuestionRegrade.first
      question_regrade.should be
      question_regrade.regrade_option.should == 'full_credit'
    end
  end

  describe "#destroy" do

    it "does not remove the record from the database, but changes workflow_state" do
      course_with_teacher
      course_quiz

      question = @quiz.quiz_questions.create!
      question.destroy
      question = QuizQuestion.find(question.id)

      question.should_not be_nil
      question.should be_deleted
    end
  end
end
