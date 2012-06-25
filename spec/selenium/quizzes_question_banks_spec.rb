require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/quizzes_common')

describe "quizzes question banks" do
  it_should_behave_like "quizzes selenium tests"

  before (:each) do
    course_with_teacher_logged_in
  end

  it "should be able to create quiz questions" do
    bank = AssessmentQuestionBank.create!(:context => @course)
    get "/courses/#{@course.id}/question_banks/#{bank.id}"

    driver.find_element(:css, '.add_question_link').click
    wait_for_animations

    expect { create_multiple_choice_question }.to change(AssessmentQuestion, :count).by(1)
  end

  it "should tally up question bank question points" do
    quiz = @course.quizzes.create!(:title => "My Quiz")
    bank = AssessmentQuestionBank.create!(:context => @course)
    3.times { bank.assessment_questions << assessment_question_model }
    harder = bank.assessment_questions.last
    harder.question_data[:points_possible] = 15
    harder.save!
    get "/courses/#{@course.id}/quizzes/#{quiz.id}/edit"
    find_questions_link = driver.find_element(:css, '.find_question_link')
    keep_trying_until {
      find_questions_link.click
      driver.find_element(:css, ".select_all_link")
    }.click
    submit_dialog("div#find_question_dialog")
    keep_trying_until { find_with_jquery("#quiz_display_points_possible .points_possible").text.should == "17" }
  end

  it "should allow you to use inherited question banks" do
    skip_if_ie('Out of memory')
    @course.account = Account.default
    @course.save
    quiz = @course.quizzes.create!(:title => "My Quiz")
    bank = AssessmentQuestionBank.create!(:context => @course.account)
    bank.assessment_questions << assessment_question_model

    get "/courses/#{@course.id}/quizzes/#{quiz.id}/edit"

    keep_trying_until {
      driver.find_element(:css, '.find_question_link').click
      driver.find_element(:id, 'find_question_dialog').should be_displayed
      wait_for_ajaximations
      driver.find_element(:css, ".select_all_link").should be_displayed
    }
    driver.find_element(:css, ".select_all_link").click
    submit_dialog("div#find_question_dialog")
    keep_trying_until { find_with_jquery("#quiz_display_points_possible .points_possible").text.should == "1" }

    driver.find_element(:css, ".add_question_group_link").click
    driver.find_element(:css, '.find_bank_link').click
    keep_trying_until {
      find_with_jquery("#find_bank_dialog .bank:visible")
    }.click
    submit_dialog("#find_bank_dialog")
    submit_form(".quiz_group_form")
    keep_trying_until { find_with_jquery("#quiz_display_points_possible .points_possible").text.should == "2" }
  end

  it "should allow you to use bookmarked question banks" do
    skip_if_ie('Out of memory')
    @course.account = Account.default
    @course.save
    quiz = @course.quizzes.create!(:title => "My Quiz")
    bank = AssessmentQuestionBank.create!(:context => Course.create)
    bank.assessment_questions << assessment_question_model
    @user.assessment_question_banks << bank

    get "/courses/#{@course.id}/quizzes/#{quiz.id}/edit"

    keep_trying_until {
      driver.find_element(:css, '.find_question_link').click
      driver.find_element(:id, 'find_question_dialog').should be_displayed
      wait_for_ajaximations
      driver.find_element(:css, ".select_all_link").should be_displayed
    }
    driver.find_element(:css, ".select_all_link").click
    submit_dialog("div#find_question_dialog")
    keep_trying_until { find_with_jquery("#quiz_display_points_possible .points_possible").text.should == "1" }

    driver.find_element(:css, ".add_question_group_link").click
    driver.find_element(:css, ".find_bank_link").click
    keep_trying_until {
      find_with_jquery("#find_bank_dialog .bank:visible")
    }.click
    submit_dialog("#find_bank_dialog")
    submit_form(".quiz_group_form")
    keep_trying_until { find_with_jquery("#quiz_display_points_possible .points_possible").text.should == "2" }
  end

  it "should check permissions when retrieving question banks" do
    skip_if_ie('Out of memory')
    @course.account = Account.default
    @course.account.role_overrides.create(:permission => 'read_question_banks', :enrollment_type => 'TeacherEnrollment', :enabled => false)
    @course.save
    quiz = @course.quizzes.create!(:title => "My Quiz")

    course_bank = AssessmentQuestionBank.create!(:context => @course)
    course_bank.assessment_questions << assessment_question_model

    account_bank = AssessmentQuestionBank.create!(:context => @course.account)
    account_bank.assessment_questions << assessment_question_model

    get "/courses/#{@course.id}/quizzes/#{quiz.id}/edit"

    keep_trying_until {
      driver.find_element(:css, '.find_question_link').click
      driver.find_element(:id, 'find_question_dialog').should be_displayed
      wait_for_ajaximations
      driver.find_element(:css, ".select_all_link").should be_displayed
    }
    find_all_with_jquery("#find_question_dialog .bank:visible").size.should eql 1

    close_visible_dialog
    keep_trying_until {
      driver.find_element(:css, '.add_question_group_link').click
      driver.find_element(:css, '.find_bank_link').should be_displayed
    }
    driver.find_element(:css, ".find_bank_link").click
    wait_for_ajaximations
    find_all_with_jquery("#find_bank_dialog .bank:visible").size.should eql 1
  end

  it "should import questions from a question bank" do
    skip_if_ie('Out of memory')

    get "/courses/#{@course.id}/quizzes/new"

    driver.find_element(:css, '.add_question_group_link').click
    group_form = driver.find_element(:css, '#group_top_new .quiz_group_form')
    group_form.find_element(:name, 'quiz_group[name]').send_keys('new group')
    replace_content(group_form.find_element(:name, 'quiz_group[question_points]'), '2')
    submit_form(group_form)
    driver.find_element(:css, '#questions .group_top .group_display.name').should include_text('new group')
  end
end