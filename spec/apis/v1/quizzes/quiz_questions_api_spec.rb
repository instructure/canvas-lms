
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

require File.expand_path(File.dirname(__FILE__) + '/../../api_spec_helper')

describe Quizzes::QuizQuestionsController, type: :request do
  context 'as a teacher' do
    before do
      @course = course
      teacher_in_course active_all: true
      @quiz = @course.quizzes.create!(:title => "A Sample Quiz")
    end

    describe "GET /courses/:course_id/quizzes/:quiz_id/questions (index)" do
      it "returns a list of questions" do
        questions = (1..10).map do |n|
          @quiz.quiz_questions.create!(:question_data => { :question_name => "Question #{n}" })
        end

        json = api_call(:get, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/questions",
                        :controller => "quizzes/quiz_questions", :action => "index", :format => "json",
                        :course_id => @course.id.to_s, :quiz_id => @quiz.id.to_s)

        question_ids = json.collect { |q| q['id'] }
        question_ids.should == questions.map(&:id)
      end
    end

    describe "GET /courses/:course_id/quizzes/:quiz_id/questions/:id (show)" do
      context "existing question" do
        before do
          @question = @quiz.quiz_questions.create!(:question_data => {
                                                                      "question_name"=>"Example Question", "assessment_question_id"=>"",
                                                                      "question_type"=>"multiple_choice_question", "points_possible"=>"1",
                                                                      "correct_comments"=>"", "incorrect_comments"=>"", "neutral_comments"=>"",
                                                                      "question_text"=>"<p>What's your favorite color?</p>", "position"=>"0",
                                                                      "text_after_answers"=>"", "matching_answer_incorrect_matches"=>"",
                                                                      "answers"=>[]
                                                                      })

          @json = api_call(:get, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/questions/#{@question.id}",
                           :controller => "quizzes/quiz_questions", :action => "show", :format => "json",
                           :course_id => @course.id.to_s, :quiz_id => @quiz.id.to_s, :id => @question.id.to_s)


          @json.symbolize_keys!
        end

        it "has only the allowed question output fields" do
          question_fields = Api::V1::QuizQuestion::API_ALLOWED_QUESTION_OUTPUT_FIELDS[:only].map(&:to_sym) +  Api::V1::QuizQuestion::API_ALLOWED_QUESTION_DATA_OUTPUT_FIELDS.map(&:to_sym)
          @json.keys.each { |key| question_fields.to_s.should include(key.to_s) }
        end

        it "has the question data fields" do
          Api::V1::QuizQuestion::API_ALLOWED_QUESTION_DATA_OUTPUT_FIELDS.map(&:to_sym).each do |field|
            @json.should have_key(field)

            # ugh... due to wonkiness in Question#question_data's treatment of keys,
            # and the fact that symbolize_keys doesn't recurse, we resort to this.
            if @json[field].is_a?(Array) && @question.question_data[field].is_a?(Array)
              @json[field].map(&:symbolize_keys).should == @question.question_data[field].map(&:symbolize_keys)
            else
              @json[field].should == @question.question_data.symbolize_keys[field]
            end
          end
        end
      end

      context "non-existent question" do
        before do
          @json = api_call(:get, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/questions/9034831",
                           {:controller => "quizzes/quiz_questions", :action => "show", :format => "json", :course_id => @course.id.to_s, :quiz_id => @quiz.id.to_s, :id => "9034831"},
                             {}, {}, {:expected_status => 404})
        end

        it "should return a not found error message" do
          @json.inspect.should include "does not exist"
        end
      end
    end
  end

  context 'as a student' do
    before do
      course_with_student_logged_in :active_all => true

      @quiz = @course.quizzes.create!(:title => 'quiz')
      @quiz.published_at = Time.now
      @quiz.workflow_state = 'available'
      @quiz.save!
    end

    describe 'GET /courses/:course_id/quizzes/:quiz_id/questions (index)' do
      it 'returns a censored version of multiple choice questions' do
        @quiz.quiz_questions.create!(:question_data => multiple_choice_question_data)

        json = api_call(:get, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/questions",
                        :controller => "quizzes/quiz_questions", :action => "index", :format => "json",
                        :course_id => @course.id.to_s, :quiz_id => @quiz.id.to_s)

        json.length.should == 1
        json.each do |question|
          question["answers"].class.name.should == 'Array'
          question["answers"].each do |answer|
            answer.include?("weight").should be_false
            answer.include?("comments").should be_false
          end
        end
      end

      it 'returns a censored version of short answer questions' do
        @quiz.quiz_questions.create!(:question_data => short_answer_question_data)

        json = api_call(:get, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/questions",
                        :controller => "quizzes/quiz_questions", :action => "index", :format => "json",
                        :course_id => @course.id.to_s, :quiz_id => @quiz.id.to_s)
p json
        json.length.should == 1
        json.each do |question|
          question.include?("answers").should be_false
        end
      end
    end

    describe 'GET /courses/:course_id/quizzes/:quiz_id/questions/:id (show)' do
      it 'returns a censored version of the question' do
        @quiz.quiz_questions.create!(:question_data => multiple_choice_question_data)

        json = api_call(:get, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/questions",
                        :controller => "quizzes/quiz_questions", :action => "index", :format => "json",
                        :course_id => @course.id.to_s, :quiz_id => @quiz.id.to_s)

        json.length.should == 1
        json.each do |question|
          question["answers"].class.name.should == 'Array'
          question["answers"].each do |answer|
            answer.include?("weight").should be_false
            answer.include?("comments").should be_false
          end
        end
      end

      it 'censors both the question and its assessment multiple choice question' do
        @quiz.quiz_questions.create!(:question_data => multiple_choice_question_data)

        json = api_call(:get,
          "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/questions",
          {
            :controller => "quizzes/quiz_questions",
            :action => "index",
            :format => "json",
            :course_id => @course.id.to_s,
            :quiz_id => @quiz.id.to_s
          }, {
            :include => [ :assessment_question ]
          })

        json.length.should == 1

        question = json[0]
        question["answers"].class.name.should == 'Array'
        question["answers"].each do |answer|
          answer.include?("weight").should be_false
          answer.include?("comments").should be_false
        end

        assessment_question = question["assessment_question"]
        assessment_question.should be_present
        assessment_question["question_data"].should be_present
        assessment_question["question_data"].should be_present
        assessment_question["question_data"]["answers"].class.name.should == 'Array'
        assessment_question["question_data"]["answers"].each do |answer|
          answer.include?("weight").should be_false
        end
      end

      it 'censors both the question and its assessment short answer question' do
        @quiz.quiz_questions.create!(:question_data => short_answer_question_data)

        json = api_call(:get,
          "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/questions",
          {
            :controller => "quizzes/quiz_questions",
            :action => "index",
            :format => "json",
            :course_id => @course.id.to_s,
            :quiz_id => @quiz.id.to_s
          }, {
            :include => [ :assessment_question ]
          })

        json.length.should == 1

        question = json[0]
        question.include?("answers").should be_false

        assessment_question = question["assessment_question"]
        assessment_question.should be_present
        assessment_question["question_data"].should be_present
        assessment_question["question_data"].include?("answers").should be_false
      end

    end
  end
end
