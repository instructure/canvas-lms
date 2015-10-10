require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/quizzes_common')

describe 'quiz restrictions as a teacher' do
  include_context 'in-process server selenium tests'

  before do
    course_with_teacher_logged_in
  end

  context 'restrict access code' do
    it 'should have a checkbox on the quiz creation page' do
      get "/courses/#{@course.id}/quizzes/new"
      expect('#enable_quiz_access_code').to be
    end

    it 'should show a password field when checking the checkbox' do
      get "/courses/#{@course.id}/quizzes/new"
      expect(f('#quiz_access_code').attribute('tabindex')).to include_text('-1')
      f('#enable_quiz_access_code').click
      expect(f('#quiz_access_code').attribute('tabindex')).to include_text('0')
    end

    it 'should not allow a blank restrict access code password' do
      get "/courses/#{@course.id}/quizzes/new"
      f('#enable_quiz_access_code').click
      wait_for_ajaximations

      # now try and save it and validate the validation text
      f('button.save_quiz_button.btn.btn-primary').click
      wait_for_ajaximations
      expect(ffj('.error_text')[1]).to include_text('You must enter an access code')
    end

    it 'should accept a valid password when creating a quiz' do
      get "/courses/#{@course.id}/quizzes/new"
      f('#enable_quiz_access_code').click
      wait_for_ajaximations
      f('#quiz_access_code').send_keys('guybrush')

      # save and verify that the show page comes up
      f('button.save_quiz_button.btn.btn-primary').click
      wait_for_ajaximations
      expect(f('.unpublished_quiz_warning')).to include_text('This quiz is unpublished')
    end

    it 'should show the access code on the show page' do
      @quiz = course_quiz
      @quiz.access_code = 'threepwood'
      @quiz.save!
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
      show_page = f('#quiz_show')
      expect(show_page).to include_text('Access Code')
      expect(show_page).to include_text('threepwood')
    end
  end

  context 'filter ip addresses' do
    it 'should have a checkbox on the quiz creation page' do
      get "/courses/#{@course.id}/quizzes/new"
      expect('#enable_quiz_ip_filter').to be
    end

    it 'should show a password field when checking the checkbox' do
      get "/courses/#{@course.id}/quizzes/new"
      expect(f('#quiz_ip_filter').attribute('tabindex')).to include_text('-1')
      f('#enable_quiz_ip_filter').click
      expect(f('#quiz_ip_filter').attribute('tabindex')).to include_text('0')
    end

    it 'should not allow a blank ip address' do
      get "/courses/#{@course.id}/quizzes/new"
      f('#enable_quiz_ip_filter').click
      wait_for_ajaximations

      # now try and save it and validate the validation text
      f('button.save_quiz_button.btn.btn-primary').click
      wait_for_ajaximations
      expect(ffj('.error_text')[1]).to include_text('You must enter a valid IP Address')
    end

    it 'should accept a valid ipv4 address when creating a quiz' do
      get "/courses/#{@course.id}/quizzes/new"
      f('#enable_quiz_ip_filter').click
      wait_for_ajaximations
      f('#quiz_ip_filter').send_keys('7.7.7.7')

      # save and verify that the page changes (passes validation)
      expect(f('#quiz_title')).to be
      f('button.save_quiz_button.btn.btn-primary').click
      wait_for_ajaximations
      expect(f('.unpublished_quiz_warning')).to include_text('This quiz is unpublished')
    end

    it 'should accept a valid ipv4 address with subnet mask when creating a quiz' do
      get "/courses/#{@course.id}/quizzes/new"
      f('#enable_quiz_ip_filter').click
      wait_for_ajaximations
      f('#quiz_ip_filter').send_keys('7.7.7.7/255.255.255.0')

      # save and verify that the page changes (passes validation)
      expect(f('#quiz_title')).to be
      f('button.save_quiz_button.btn.btn-primary').click
      wait_for_ajaximations
      expect(f('.unpublished_quiz_warning')).to include_text('This quiz is unpublished')
    end

    it 'should accept a valid ipv6 address when creating a quiz' do
      get "/courses/#{@course.id}/quizzes/new"
      f('#enable_quiz_ip_filter').click
      wait_for_ajaximations
      f('#quiz_ip_filter').send_keys('2001:0db8:85a3:0000:0000:8a2e:0370:7334')

      # save and verify that the page changes (passes validation)
      expect(f('#quiz_title')).to be
      f('button.save_quiz_button.btn.btn-primary').click
      wait_for_ajaximations
      expect(f('.unpublished_quiz_warning')).to include_text('This quiz is unpublished')
    end

    it 'should not accept an invalid ip address when creating a quiz' do
      get "/courses/#{@course.id}/quizzes/new"
      f('#enable_quiz_ip_filter').click
      wait_for_ajaximations
      f('#quiz_ip_filter').send_keys('7')

      f('button.save_quiz_button.btn.btn-primary').click
      wait_for_ajaximations
      expect(ffj('.error_text')[1]).to include_text('IP filter is not valid')
    end

    it 'should have a working link to help with ip address filtering' do
      get "/courses/#{@course.id}/quizzes/new"
      f('#enable_quiz_ip_filter').click
      wait_for_ajaximations

      expect(f('#ip_filters_dialog')).not_to be_displayed
      f('a.ip_filtering_link > img').click
      wait_for_ajaximations
      expect(f('#ip_filters_dialog')).to be_displayed
    end

    it 'should show filtered ip address on the show page' do
      # makes an assumption that your ip address is not '64.233.160.0' (google)
      @quiz = course_quiz
      @quiz.ip_filter = '64.233.160.0'
      @quiz.save!
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
      show_page = f('#quiz_show')
      expect(show_page).to include_text('IP Filter')
      expect(show_page).to include_text('64.233.160.0')
    end
  end
end
