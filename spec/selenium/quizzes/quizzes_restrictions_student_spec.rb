require_relative "../common"
require_relative "../helpers/quizzes_common"

describe 'quiz restrictions as a student' do
  include_context "in-process server selenium tests"
  include QuizzesCommon

  def begin_taking_quiz
    get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
    expect_new_page_load { f('#take_quiz_link').click }
  end

  context 'restrict access code' do
    before do
      course_with_student_logged_in
      @password = 'threepwood'
      @quiz = course_quiz(true)
      @quiz.published_at = Time.now
      @quiz.access_code = @password
      @quiz.save!
    end

    def submit_quiz_access_code(access_code)
      begin_taking_quiz
      f('#quiz_access_code').send_keys(access_code)
      expect_new_page_load { f('button.btn').click }
    end

    it 'should allow you to enter in a correct access token password to view the quiz', priority: "1", test_id: 345734 do
      submit_quiz_access_code(@password)
      expect(f('.quiz-header')).to include_text 'Quiz Instructions'
    end

    it 'should not allow you to enter in a incorrect access token password to view the quiz', priority: "1", test_id: 338079 do
      submit_quiz_access_code('lechuck')
      expect(f('#quiz_access_code').text).to eq ''
    end
  end

  context 'filter ip addresses' do
    before do
      course_with_student_logged_in
      @ip = '64.233.160.0'
      @quiz = course_quiz(true)
      @quiz.published_at = Time.now
      @quiz.ip_filter = '64.233.160.0'
      @quiz.save!
    end

    it 'should not be accessible from invalid ip address', priority: "1", test_id: 338081 do
      begin_taking_quiz
      expect(f('#content')).to include_text 'This quiz is protected and is only available from certain locations'
    end
  end
end
