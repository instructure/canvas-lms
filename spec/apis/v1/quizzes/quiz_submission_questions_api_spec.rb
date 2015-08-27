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

require File.expand_path(File.dirname(__FILE__) + '/../../api_spec_helper')

describe Quizzes::QuizSubmissionQuestionsController, :type => :request do

  module Helpers
    def create_question(type, factory_options = {}, quiz=@quiz)
      factory = method(:"#{type}_question_data")

      # can't test for #arity directly since it might be an optional parameter
      data = factory.parameters.include?([ :opt, :options ]) ?
        factory.call(factory_options) :
        factory.call

      data = data.except('id', 'assessment_question_id')

      qq = quiz.quiz_questions.create!({ question_data: data })
      qq.assessment_question.question_data = data
      qq.assessment_question.save!

      qq
    end

    def create_question_set
      @qq1 = create_question 'multiple_choice'
      @qq2 = create_question 'true_false'
      create_answers
    end

    def create_answers(opts={correct: true})
      @quiz_submission.submission_data = {
        "question_#{@qq1.id}" => opts[:correct] ? "1658" : "2405",
        "question_#{@qq2.id}" => opts[:correct] ? "8950" : "8403"
      }
    end

    def api_index(data = {}, options = {})
      url = "/api/v1/quiz_submissions/#{@quiz_submission.id}/questions"
      params = { :controller => 'quizzes/quiz_submission_questions',
                 :action => 'index',
                 :format => 'json',
                 :quiz_submission_id => @quiz_submission.id.to_s,
                 :quiz_submission_attempt => options[:quiz_submission_attempt]}
      if options[:raw]
        raw_api_call(:get, url, params, data)
      else
        api_call(:get, url, params, data)
      end

    end

    def api_show(data = {}, options = {})
      url = "/api/v1/quiz_submissions/#{@quiz_submission.id}/questions/#{@question[:id]}"
      params = { :controller => 'quizzes/quiz_submission_questions',
                 :action => 'show',
                 :format => 'json',
                 :quiz_submission_id => @quiz_submission.id.to_s,
                 :id => @question[:id].to_s }
      if options[:raw]
        raw_api_call(:get, url, params, data)
      else
        api_call(:get, url, params, data)
      end
    end

    def api_answer(data = {}, options = {})
      url = "/api/v1/quiz_submissions/#{@quiz_submission.id}/questions"
      params = { :controller => 'quizzes/quiz_submission_questions',
                 :action => 'answer',
                 :format => 'json',
                 :quiz_submission_id => @quiz_submission.id.to_s }
      data = {
        validation_token: @quiz_submission.validation_token,
        attempt: @quiz_submission.attempt
      }.merge(data)

      if options[:raw]
        raw_api_call(:post, url, params, data)
      else
        api_call(:post, url, params, data)
      end
    end

    def api_flag(data = {}, options = {})
      url = "/api/v1/quiz_submissions/#{@quiz_submission.id}/questions/#{@question[:id]}/flag"
      params = { :controller => 'quizzes/quiz_submission_questions',
                 :action => 'flag',
                 :format => 'json',
                 :quiz_submission_id => @quiz_submission.id.to_s,
                 :id => @question[:id].to_s }
      data = {
        validation_token: @quiz_submission.validation_token,
        attempt: @quiz_submission.attempt
      }.merge(data)

      if options[:raw]
        raw_api_call(:put, url, params, data)
      else
        api_call(:put, url, params, data)
      end
    end

    def api_unflag(data = {}, options = {})
      url = "/api/v1/quiz_submissions/#{@quiz_submission.id}/questions/#{@question[:id]}/unflag"
      params = { :controller => 'quizzes/quiz_submission_questions',
                 :action => 'unflag',
                 :format => 'json',
                 :quiz_submission_id => @quiz_submission.id.to_s,
                 :id => @question[:id].to_s }
      data = {
        validation_token: @quiz_submission.validation_token,
        attempt: @quiz_submission.attempt
      }.merge(data)

      if options[:raw]
        raw_api_call(:put, url, params, data)
      else
        api_call(:put, url, params, data)
      end
    end
  end

  include Helpers


  describe 'GET /quiz_submissions/:quiz_submission_id/questions [index]' do
    before :all do
      course_with_student(:active_all => true)
      @quiz = @course.quizzes.create!({
          title: 'test quiz',
          show_correct_answers: true,
          show_correct_answers_last_attempt: true,
          allowed_attempts: 2
        })
      @quiz_submission = @quiz.generate_submission(@student)
    end

    it 'should be authorized for student' do
      json = api_index({}, { raw: true })
      assert_status(200)
    end

    it 'should return an empty list' do
      json = api_index
      expect(json.has_key?('quiz_submission_questions')).to be_truthy
      expect(json['quiz_submission_questions'].size).to eq 0
    end

    describe "with data" do
      before :all do
        create_question_set
      end
      it 'should list all items' do
        Quizzes::QuizSubmission.any_instance.stubs(:quiz_questions).returns([@qq1,@qq2])
        json = api_index
        expect(json['quiz_submission_questions'].size).to eq 2
      end

      it "should return questions for a previous version of the quiz" do
        @quiz.generate_quiz_data
        @quiz.save!
        @quiz_submission = @quiz.generate_submission(@student)
        @quiz_submission.complete!(create_answers)
        @quiz_submission = @quiz.generate_submission(@student)
        @quiz_submission.complete!(create_answers({correct: false}))
        json = api_index
        expect(json['quiz_submission_questions'].map {|q| q['correct']}.all?).to be_falsey
        json = api_index({}, {quiz_submission_attempt: 2})
        expect(json['quiz_submission_questions'].map {|q| q['correct']}.all?).to be_truthy
      end
    end

    it "should deny student access when quiz is OQAAT" do
      @quiz = @course.quizzes.create!({
        title: "oqaat quiz",
        one_question_at_a_time: true
      })
      @quiz_submission = @quiz.generate_submission(@student)
      api_index({}, {raw: true})
      assert_status(401)
    end

    it "should allow teacher access even if quiz is OQAAT" do
      api_index({}, {raw:true})
      assert_status(200)
    end

    it "should deny access to another student" do
      student_in_course
      api_index({}, {raw: true})
      assert_status(401)
    end
  end

  describe 'GET /quiz_submissions/:quiz_submission_id/questions/:id [show]' do
    before :once do
      course_with_student(:active_all => true)
      @quiz = quiz_model(course: @course)
      @quiz_submission = @quiz.generate_submission(@student)

      create_question_set
      @question = @qq1
    end

    it 'should be unauthorized' do
      skip
      json = api_show({}, { raw: true })
      assert_status(401)
    end

    it 'should grant access to its student' do
      skip
      json = api_show
      expect(json.has_key?('quiz_submission_questions')).to be_truthy
      expect(json['quiz_submission_questions'].length).to eq 1
    end

    it 'should deny access by other students' do
      skip
      student_in_course
      api_show({}, { raw: true })
      assert_status(401)
    end

    context 'Output' do
      it 'should include the quiz question id' do
        skip
        json = api_show
        expect(json.has_key?('quiz_submission_questions')).to be_truthy
        expect(json['quiz_submission_questions'][0]['id']).to eq(
          @question.id
        )
      end

      it 'should include the flagged status' do
        skip
        json = api_show
        expect(json.has_key?('quiz_submission_questions')).to be_truthy
        expect(json['quiz_submission_questions'][0].has_key?('flagged')).to be_truthy
        expect(json['quiz_submission_questions'][0]['flagged']).to be_falsey
      end
    end

    context 'Links' do
      it 'should include its linked quiz_question' do
        skip
        json = api_show({
          :include => %w[ quiz_question ]
        })

        expect(json.has_key?('quiz_submission_questions')).to be_truthy
        expect(json['quiz_submission_questions'].size).to eq 1

        expect(json.has_key?('quiz_questions')).to be_truthy
        expect(json['quiz_questions'].size).to eq 1
        expect(json['quiz_questions'][0]['id']).to eq(
          json['quiz_submission_questions'][0]['id']
        )
      end
    end

    context 'JSON-API compliance' do
      it 'should conform to the JSON-API spec when returning the object' do
        skip
        json = api_show
        assert_jsonapi_compliance(json, 'quiz_submission_questions')
      end

      it 'should conform to the JSON-API spec when returning linked objects' do
        skip
        includables = Api::V1::QuizSubmissionQuestion::Includables

        json = api_show({
          :include => includables
        })

        assert_jsonapi_compliance(json, 'quiz_submission_questions', includables)
      end
    end
  end

  describe 'POST /quiz_submissions/:quiz_submission_id/questions [answer]' do
    context 'access policy' do
      it 'should grant access to the teacher' do
        course_with_teacher_logged_in(:active_all => true)
        @quiz = quiz_model(course: @course)
        @quiz_submission = @quiz.generate_submission(@teacher)

        json = api_answer
        expect(json.has_key?('quiz_submission_questions')).to be_truthy
        expect(json['quiz_submission_questions'].length).to eq 0
      end

      it 'should grant access to its student' do
        course_with_student_logged_in(:active_all => true)
        @quiz = quiz_model(course: @course)
        @quiz_submission = @quiz.generate_submission(@student)

        json = api_answer
        expect(json.has_key?('quiz_submission_questions')).to be_truthy
        expect(json['quiz_submission_questions'].length).to eq 0
      end
    end

    context 'as a student' do
      before :once do
        course_with_student(:active_all => true)
        @quiz = quiz_model(course: @course)
        @quiz_submission = @quiz.generate_submission(@student)
      end

      it "shouldn't give any answers information" do
        mc = create_question 'multiple_choice'
        formula = create_question 'numerical'

        json = api_answer({
          quiz_questions: [{
            id: mc.id,
            answer: 1658
          }, {
            id: formula.id,
            answer: 40.0
            }]
        })

        expect(json['quiz_submission_questions'][0]["answers"].map(&:keys).uniq.include? "weight").to be_falsey
        expect(json['quiz_submission_questions'][1]["answers"]).to equal(nil)
      end

      context 'answering questions' do
        it 'should answer a MultipleChoice question' do
          question = create_question 'multiple_choice'

          json = api_answer({
            quiz_questions: [{
              id: question.id,
              answer: 1658
            }]
          })

          expect(json['quiz_submission_questions']).to be_present
          expect(json['quiz_submission_questions'].length).to eq 1
          expect(json['quiz_submission_questions'][0]['answer']).to eq '1658'
        end

        it 'should answer a TrueFalse question' do
          question = create_question 'true_false'

          json = api_answer({
            quiz_questions: [{
              id: question.id,
              answer: 8403
            }]
          })

          expect(json['quiz_submission_questions']).to be_present
          expect(json['quiz_submission_questions'].length).to eq 1
          expect(json['quiz_submission_questions'][0]['answer']).to eq '8403'
        end

        it 'should answer a ShortAnswer question' do
          question = create_question 'short_answer'

          json = api_answer({
            quiz_questions: [{
              id: question.id,
              answer: 'Hello World!'
            }]
          })

          expect(json['quiz_submission_questions']).to be_present
          expect(json['quiz_submission_questions'].length).to eq 1
          expect(json['quiz_submission_questions'][0]['answer']).to eq 'hello world!'
        end

        it 'should answer a FillInMultipleBlanks question' do
          question = create_question 'fill_in_multiple_blanks'

          json = api_answer({
            quiz_questions: [{
              id: question.id,
              answer: {
                answer1: 'red',
                answer3: 'green',
                answer4: 'blue'
              }
            }]
          })

          expect(json['quiz_submission_questions']).to be_present
          expect(json['quiz_submission_questions'].length).to eq 1
          expect(json['quiz_submission_questions'][0]['answer']).to eq({
            answer1: 'red',
            answer2: nil,
            answer3: 'green',
            answer4: 'blue',
            answer5: nil,
            answer6: nil
          }.with_indifferent_access)
        end

        it 'should answer a MultipleAnswers question and allow deseleciton' do
          question = create_question 'multiple_answers', {
            answer_parser_compatibility: true
          }

          first_json = api_answer({
            quiz_questions: [{
              id: question.id,
              answer: [ 9761, 5194 ]
            }]
          })

          expect(first_json['quiz_submission_questions']).to be_present
          expect(first_json['quiz_submission_questions'][0]['answer'].include?('9761')).to be_truthy
          expect(first_json['quiz_submission_questions'][0]['answer'].include?('5194')).to be_truthy

          second_json = api_answer({
            quiz_questions: [{
              id: question.id,
              answer: []
            }]
          })

          expect(second_json['quiz_submission_questions']).to be_present
          expect(second_json['quiz_submission_questions'][0]['answer'].include?('9761')).to be_falsey
          expect(second_json['quiz_submission_questions'][0]['answer'].include?('5194')).to be_falsey
        end

        it 'should answer an Essay question' do
          question = create_question 'essay'

          json = api_answer({
            quiz_questions: [{
              id: question.id,
              answer: 'Foobar'
            }]
          })

          expect(json['quiz_submission_questions']).to be_present
          expect(json['quiz_submission_questions'][0]['answer']).to eq 'Foobar'
        end

        it 'should answer a MultipleDropdowns question' do
          question = create_question 'multiple_dropdowns'

          json = api_answer({
            quiz_questions: [{
              id: question.id,
              answer: {
                structure1: 4390,
                event2: 599
              }
            }]
          })

          expect(json['quiz_submission_questions']).to be_present
          expect(json['quiz_submission_questions'][0]['answer']).to eq({
            structure1: '4390',
            structure2: nil,
            structure3: nil,
            structure4: nil,
            structure5: nil,
            structure6: nil,
            structure7: nil,
            event1: nil,
            event2: '599'
          }.with_indifferent_access)
        end

        it 'should answer a Matching question' do
          question = create_question 'matching', {
            answer_parser_compatibility: true
          }

          json = api_answer({
            quiz_questions: [{
              id: question.id,
              answer: [
                { answer_id: 7396, match_id: 6061 },
                { answer_id: 4224, match_id: 3855 }
              ]
            }]
          })

          expect(json['quiz_submission_questions']).to be_present

          answer = json['quiz_submission_questions'][0]['answer']
          expect(answer
            .include?({ answer_id: '7396', match_id: '6061' }.with_indifferent_access))
            .to be_truthy

          expect(answer
            .include?({ answer_id: '4224', match_id: '3855' }.with_indifferent_access))
            .to be_truthy
        end

        it 'should answer a Numerical question' do
          question = create_question 'numerical'

          json = api_answer({
            quiz_questions: [{
              id: question.id,
              answer: 2.5e-3
            }]
          })

          expect(json['quiz_submission_questions']).to be_present
          expect(json['quiz_submission_questions'][0]['answer']).to eq 0.0025
        end

        it 'should answer a Calculated question' do
          question = create_question 'calculated'

          json = api_answer({
            quiz_questions: [{
              id: question.id,
              answer: '122.1'
            }]
          })

          expect(json['quiz_submission_questions']).to be_present
          expect(json['quiz_submission_questions'][0]['answer']).to eq 122.1
        end
      end

      it 'should update an answer' do
        question = create_question 'multiple_choice'

        json = api_answer({
          quiz_questions: [{
            id: question.id,
            answer: 1658
          }]
        })

        expect(json['quiz_submission_questions']).to be_present
        expect(json['quiz_submission_questions'].length).to eq 1
        expect(json['quiz_submission_questions'][0]['answer']).to eq '1658'

        json = api_answer({
          quiz_questions: [{
            id: question.id,
            answer: 2405
          }]
        })

        expect(json['quiz_submission_questions']).to be_present
        expect(json['quiz_submission_questions'].length).to eq 1
        expect(json['quiz_submission_questions'][0]['answer']).to eq '2405'
      end

      it 'should answer according to the published state of the question' do
        question = create_question 'multiple_choice'

        new_question_data = question.question_data
        new_question_data[:answers].each do |answer_record|
          answer_record[:id] += 1
        end
        question.question_data = new_question_data
        question.save!

        api_answer({
          quiz_questions: [{
            id: question.id,
            answer: 1658
          }]
        }, { raw: true })

        assert_status(400)
        expect(response.body).to match(/unknown answer '1658'/i)

        json = api_answer({
          quiz_questions: [{
            id: question.id,
            answer: 1659
          }]
        })

        expect(json['quiz_submission_questions']).to be_present
        expect(json['quiz_submission_questions'].length).to eq 1
        expect(json['quiz_submission_questions'][0]['answer']).to eq '1659'
      end

      it 'should present errors' do
        question = create_question 'multiple_choice'

        api_answer({
          quiz_questions: [{
            id: question.id,
            answer: 'asdf'
          }]
        }, { raw: true })

        assert_status(400)
        expect(response.body).to match(/must be of type integer/i)
      end

      # This is duplicated from QuizSubmissionsApiController spec and will be
      # moved into a Controller Filter spec once CNVS-10071 is in.
      #
      # [Transient:CNVS-10071]
      it 'should respect the quiz LDB requirement' do
        question = create_question 'multiple_choice'
        @quiz.require_lockdown_browser = true
        @quiz.save

        Quizzes::Quiz.stubs(:lockdown_browser_plugin_enabled?).returns true

        fake_plugin = Object.new
        fake_plugin.stubs(:authorized?).returns false
        fake_plugin.stubs(:base).returns fake_plugin

        subject.stubs(:ldb_plugin).returns fake_plugin
        Canvas::LockdownBrowser.stubs(:plugin).returns fake_plugin

        api_answer({
          quiz_questions: [{
            id: question.id,
            answer: nil
          }]
        }, { raw: true })

        assert_status(403)
        expect(response.body).to match(/requires the lockdown browser/i)
      end

      it 'should support answering multiple questions at the same time' do
        question1 = create_question 'multiple_choice'
        question2 = create_question 'numerical'

        json = api_answer({
          quiz_questions: [{
            id: question1.id,
            answer: 1658
          }, {
            id: question2.id,
            answer: 2.5e-3
          }]
        })

        expect(json['quiz_submission_questions']).to be_present
        expect(json['quiz_submission_questions'].length).to eq 2
        expect(json['quiz_submission_questions'].detect do |q|
          q['id'] == question1.id
        end['answer']).to eq '1658'

        expect(json['quiz_submission_questions'].detect do |q|
          q['id'] == question2.id
        end['answer']).to eq 0.0025
      end
    end
  end

  describe 'PUT /quiz_submissions/:quiz_submission_id/questions/:id/flag [flag]' do
    before :each do
      course_with_student_logged_in(:active_all => true)
      @quiz = quiz_model(course: @course)
      @quiz_submission = @quiz.generate_submission(@student)
    end

    it 'should flag the question' do
      @question = create_question('multiple_choice')

      json = api_flag

      expect(json['quiz_submission_questions']).to be_present
      expect(json['quiz_submission_questions'].length).to eq 1
      expect(json['quiz_submission_questions'][0]['flagged']).to eq true
    end

    it "should prevent unauthorized flagging" do
      @question = create_question('multiple_choice')
      student_in_course
      api_flag({}, {raw: true})
      assert_status(403)
    end
  end

  describe 'PUT /quiz_submissions/:quiz_submission_id/questions/:id/unflag [unflag]' do
    before :each do
      course_with_student_logged_in(:active_all => true)
      @quiz = quiz_model(course: @course)
      @quiz_submission = @quiz.generate_submission(@student)
    end

    it 'should unflag the question' do
      @question = create_question('multiple_choice')

      json = api_unflag

      expect(json['quiz_submission_questions']).to be_present
      expect(json['quiz_submission_questions'].length).to eq 1
      expect(json['quiz_submission_questions'][0]['flagged']).to eq false
    end

    it "should prevent unauthorized unflagging" do
      @question = create_question('multiple_choice')
      student_in_course
      api_unflag({}, {raw: true})
      assert_status(403)
    end
  end
end
