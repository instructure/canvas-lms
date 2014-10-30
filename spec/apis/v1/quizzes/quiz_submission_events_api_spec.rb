require File.expand_path(File.dirname(__FILE__) + '/../../api_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../../models/quizzes/quiz_statistics/item_analysis/common')

describe Quizzes::QuizSubmissionEventsController, type: :request do
  require File.expand_path(File.dirname(__FILE__) + '/../../../quiz_spec_helper.rb')

  def api_create(options={}, data={})
    url = "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/submissions/#{@quiz_submission.id}/events"
    params = { controller: 'quizzes/quiz_submission_events',
               action: 'create',
               format: 'json',
               course_id: @course.id.to_s,
               quiz_id: @quiz.id.to_s,
               id: @quiz_submission.id.to_s}
    headers = { 'Accept' => 'application/vnd.api+json' }

    if options[:raw]
      raw_api_call(:post, url, params, data, headers)
    else
      api_call(:post, url, params, data, headers)
    end
  end

  events_data = [{
    "created_at" => Time.now.iso8601,
    "event_type" => "question_answered",
    "event_data" => {"question_id"=>1, "answer"=>"1"}
  }, {
    "created_at" => Time.now.iso8601,
    "event_type" => "question_flagged",
    "event_data" => {"question_id"=>2, "flagged"=>true}
  }]

  describe 'POST /courses/:course_id/quizzes/:quiz_id/submission_event [create]' do
    before :once do
      course_with_teacher :active_all => true

      simple_quiz_with_submissions %w{T T T}, %w{T T T}, %w{T F F}, %w{T F T},
        :user => @user,
        :course => @course

      @user = @teacher
    end

    it 'should deny unauthorized access' do
      student_in_course
      @user = @teacher
      @quiz_submission = @quiz.quiz_submissions.last
      submitter = User.find @quiz_submission.user_id
      api_create({raw: true}, {})
      assert_status(401)
    end

    it "should respond with no_content success" do
      @quiz_submission = @quiz.quiz_submissions.last
      @user = User.find @quiz_submission.user_id
      expect(api_create({raw:true}, {"quiz_submission_events" => events_data })).to eq 204
    end

    it 'should store the passed values into the DB table' do
      scope = Quizzes::QuizSubmissionEvent

      @quiz_submission = @quiz.quiz_submissions.last
      @user = User.find @quiz_submission.user_id

      expect(scope.count).to eq 0
      api_create({raw:true}, {"quiz_submission_events" => events_data })
      expect(scope.count).to eq 2

      scope.where(event_type: 'question_answered').first.tap do |event|
        expect(event.event_type).to eq('question_answered')
        expect(event.event_data.as_json).to eq({
          question_id: '1',
          answer: '1'
        }.as_json)
      end
    end
  end
end
