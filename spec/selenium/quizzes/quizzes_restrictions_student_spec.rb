require_relative '../common'
require_relative '../helpers/quizzes_common'

describe 'quiz restrictions as a student' do
  include_context "in-process server selenium tests"
  include QuizzesCommon

  def begin_taking_quiz
    get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
    expect_new_page_load { f('#take_quiz_link').click }
    sleep 1 # In this case the UI updates on a timer, not an ajax callback
  end

  context 'restrict access code' do
    before do
      course_with_student_logged_in
      @password = 'threepwood'
      @quiz = course_quiz(true)
      @quiz.publish!
      @quiz.access_code = @password
      @quiz.save!
    end

    it 'should require an access code', priority: "1", test_id: 345735 do
      begin_taking_quiz
      expect(fj("input[type=password][name= 'access_code']")).to be_present
    end

    it 'should allow you to enter a correct access token password to view the quiz', priority: "1", test_id: 345734 do
      begin_quiz(@password)
      expect(f('.quiz-header')).to include_text 'Quiz Instructions'
    end

    it 'should not allow you to enter an incorrect access token password to view the quiz', priority: "1", test_id: 338079 do
      begin_quiz('lechuck')
      expect(f('#quiz_access_code').text).to eq ''
    end
  end

  context 'filter ip addresses' do
    before do
      course_with_student_logged_in
      @ip = '64.233.160.0'
      @quiz = course_quiz(true)
      @quiz.publish!
      @quiz.ip_filter = '64.233.160.0'
      @quiz.save!
    end

    it 'should not be accessible from invalid ip address', priority: "1", test_id: 338081 do
      begin_taking_quiz
      expect(f('#content')).to include_text 'This quiz is protected and is only available from certain locations.'\
                  ' The computer you are currently using does not appear to be at a valid location for taking this quiz.'
      expect(f("#content")).not_to contain_css('#submit_quiz_form')
    end
  end
end
