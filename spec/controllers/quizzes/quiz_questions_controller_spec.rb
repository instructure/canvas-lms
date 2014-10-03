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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Quizzes::QuizQuestionsController do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  def course_quiz(active=false)
    @quiz = @course.quizzes.create
    @quiz.workflow_state = "available" if active
    @quiz.save!
    @quiz
  end

  def quiz_question
    @question = @quiz.quiz_questions.build
    @question.write_attribute(:question_data, {:answers => [
      {:id => 123456, :answer_text => 'asdf', :weight => 100},
      {:id => 654321, :answer_text => 'jkl;', :weight => 0}
    ]})
    @question.save!
    @question
  end

  def quiz_group
    @quiz.quiz_groups.create
  end

  before :once do
    course_with_teacher(active_all: true)
    course_quiz
  end

  describe "POST 'create'" do
    it "should require authorization" do
      post 'create', :course_id => @course.id, :quiz_id => @quiz, :question => {}
      assert_unauthorized
    end

    it "should create a quiz question" do
      user_session(@teacher)
      post 'create', :course_id => @course.id, :quiz_id => @quiz, :question => {
        :question_type => "multiple_choice_question",
        :answers => {
          '0' => {
            :answer_text => 'asdf',
            :weight => 100
          },
          '1' => {
            :answer_text => 'jkl;',
            :weight => 0
          }
        }
      }
      assigns[:question].should_not be_nil
      assigns[:question].question_data.should_not be_nil
      assigns[:question].question_data[:answers].length.should eql(2)
      assigns[:quiz].should eql(@quiz)
    end
    it "should preserve ids, if provided, on create" do
      user_session(@teacher)
      post 'create', :course_id => @course.id, :quiz_id => @quiz, :question => {
        :question_type => "multiple_choice_question",
        :answers => [
          {
            :id => 123456,
            :answer_text => 'asdf',
            :weight => 100
          },
          {
            :id => 654321,
            :answer_text => 'jkl;',
            :weight => 0
          },
          {
            :id => 654321,
            :answer_text => 'qwer',
            :weight => 0
          }
        ]
      }
      assigns[:question].should_not be_nil
      assigns[:question].question_data.should_not be_nil
      data = assigns[:question].question_data[:answers]

      data.length.should eql(3)
      data[0][:id].should eql(123456)
      data[1][:id].should eql(654321)
      data[2][:id].should_not eql(654321)
    end

    it 'bounces data thats too long' do
      long_data = "abcdefghijklmnopqrstuvwxyz"
      16.times do
        long_data = "#{long_data}abcdefghijklmnopqrstuvwxyz#{long_data}"
      end
      user_session(@teacher)
      xhr :post, 'create', course_id: @course.id, quiz_id: @quiz, question: {
        question_text: long_data
      }
      response.body.should =~ /max length is 16384/
    end
  end

  describe "PUT 'update'" do
    before(:once) { quiz_question }

    it "should require authorization" do
      put 'update', :course_id => @course.id, :quiz_id => @quiz, :id => @question.id, :question => {}
      assert_unauthorized
    end

    it "should update a quiz question" do
      user_session(@teacher)
      put 'update', :course_id => @course.id, :quiz_id => @quiz, :id => @question.id, :question => {
        :question_type => "multiple_choice_question",
        :answers => {
          '0' => {
            :answer_text => 'asdf',
            :weight => 100
          },
          '1' => {
            :answer_text => 'jkl;',
            :weight => 0
          },
          '2' => {
            :answert_text => 'qwer',
            :weight => 0
          }
        }
      }
      assigns[:question].should_not be_nil
      assigns[:question].question_data.should_not be_nil
      assigns[:question].question_data[:answers].length.should eql(3)
      assigns[:quiz].should eql(@quiz)
    end

    it "should preserve ids, if provided, on update" do
      user_session(@teacher)
      put 'update', :course_id => @course.id, :quiz_id => @quiz, :id => @question.id, :question => {
        :question_type => "multiple_choice_question",
        :answers => {
          '0' => {
            :id => 123456,
            :answer_text => 'asdf',
            :weight => 100
          },
          '1' => {
            :id => 654321,
            :answer_text => 'jkl;',
            :weight => 0
          },
          '2' => {
            :id => 654321,
            :answer_text => 'qwer',
            :weight => 0
          }
        }
      }
      assigns[:question].should_not be_nil
      assigns[:question].question_data.should_not be_nil
      data = assigns[:question].question_data[:answers]
      data.length.should eql(3)
      data[0][:id].should eql(123456)
      data[1][:id].should eql(654321)
      data[2][:id].should_not eql(654321)
    end

    it 'bounces data thats too long' do
      long_data = "abcdefghijklmnopqrstuvwxyz"
      16.times do
        long_data = "#{long_data}abcdefghijklmnopqrstuvwxyz#{long_data}"
      end
      user_session(@teacher)
      xhr :put, 'update', course_id: @course.id, quiz_id: @quiz, id: @question.id, question: {
        question_text: long_data
      }
      response.body.should =~ /max length is 16384/
    end
  end
end
