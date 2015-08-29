require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/quizzes_common')

describe 'quiz restrictions as a student' do
  include_context 'in-process server selenium tests'

  context 'restrict access code' do
    before do
      course_with_student_logged_in
      @password = 'threepwood'
      @quiz = course_quiz(true)
      @quiz.published_at = Time.now
      @quiz.access_code = @password
      @quiz.save!
    end

    it 'should allow you to enter in a correct access token password to view the quiz' do
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
      f('#take_quiz_link').click
      wait_for_ajaximations

      f('#quiz_access_code').send_keys(@password)
      f('button.btn').click
      wait_for_ajaximations
      expect(f('h2')).to include_text('Quiz Instructions')
    end

    it 'should not allow you to enter in a incorrect access token password to view the quiz' do
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
      f('#take_quiz_link').click
      wait_for_ajaximations

      f('#quiz_access_code').send_keys('lechuck')
      f('button.btn').click
      wait_for_ajaximations

      expect(f('#quiz_access_code')).to be
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

    it 'should not be accessible from invalid ip address' do
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
      f('#take_quiz_link').click
      wait_for_ajaximations
      expect(f('#content')).to include_text('This quiz is protected and is only available from certain locations')
    end
  end
end