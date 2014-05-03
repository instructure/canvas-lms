require File.expand_path(File.dirname(__FILE__) + '/helpers/quizzes_common')

describe "quizzes question banks" do
  include_examples "quizzes selenium tests"

  before (:each) do
    course_with_teacher_logged_in
  end

  it "should be able to create quiz questions" do
    bank = AssessmentQuestionBank.create!(:context => @course)
    get "/courses/#{@course.id}/question_banks/#{bank.id}"

    f('.add_question_link').click
    wait_for_ajaximations
    expect { create_multiple_choice_question }.to change(AssessmentQuestion, :count).by(1)
  end

  it "should tally up question bank question points" do
    quiz = @course.quizzes.create!(:title => "My Quiz")
    bank = AssessmentQuestionBank.create!(:context => @course)
    3.times { assessment_question_model(bank: bank) }
    harder = bank.assessment_questions.last
    harder.question_data[:points_possible] = 15
    harder.save!
    get "/courses/#{@course.id}/quizzes/#{quiz.id}/edit"
    find_questions_link = f('.find_question_link')
    click_questions_tab
    keep_trying_until {
      find_questions_link.click
      wait_for_ajaximations
      f(".select_all_link")
    }.click
    submit_dialog("#find_question_dialog", '.submit_button')
    wait_for_ajaximations
    click_settings_tab
    keep_trying_until { fj("#quiz_display_points_possible .points_possible").text.should == "17" }
  end

  it "should allow you to use inherited question banks" do
    @course.account = Account.default
    @course.save
    quiz = @course.quizzes.create!(:title => "My Quiz")
    bank = AssessmentQuestionBank.create!(:context => @course.account)
    assessment_question_model(bank: bank)

    get "/courses/#{@course.id}/quizzes/#{quiz.id}/edit"
    click_questions_tab

    keep_trying_until do
      f('.find_question_link').click
      wait_for_ajaximations
      f('#find_question_dialog').should be_displayed
      f(".select_all_link").should be_displayed
    end
    f(".select_all_link").click
    wait_for_ajaximations
    submit_dialog("#find_question_dialog", '.submit_button')
    wait_for_ajaximations
    click_settings_tab
    keep_trying_until { fj("#quiz_display_points_possible .points_possible").text.should == "1" }

    click_questions_tab
    f(".add_question_group_link").click
    wait_for_ajaximations
    f('.find_bank_link').click
    keep_trying_until {
      fj("#find_bank_dialog .bank:visible")
    }.click
    submit_dialog("#find_bank_dialog", '.submit_button')
    submit_form(".quiz_group_form")
    wait_for_ajaximations
    click_settings_tab
    keep_trying_until { fj("#quiz_display_points_possible .points_possible").text.should == "2" }
  end

  it "should allow you to use bookmarked question banks" do
    @course.account = Account.default
    @course.save
    quiz = @course.quizzes.create!(:title => "My Quiz")
    bank = AssessmentQuestionBank.create!(:context => Course.create!)
    assessment_question_model(bank: bank)
    @user.assessment_question_banks << bank

    get "/courses/#{@course.id}/quizzes/#{quiz.id}/edit"
    click_questions_tab

    keep_trying_until do
      f('.find_question_link').click
      wait_for_ajaximations
      f('#find_question_dialog').should be_displayed
      wait_for_ajaximations
      f(".select_all_link").should be_displayed
    end
    f(".select_all_link").click
    wait_for_ajaximations
    submit_dialog("#find_question_dialog", '.submit_button')
    wait_for_ajaximations
    click_settings_tab
    keep_trying_until { fj("#quiz_display_points_possible .points_possible").text.should == "1" }

    click_questions_tab
    f(".add_question_group_link").click
    wait_for_ajaximations
    f(".find_bank_link").click
    wait_for_ajaximations
    keep_trying_until {
      fj("#find_bank_dialog .bank:visible")
    }.click
    submit_dialog("#find_bank_dialog", '.submit_button')
    submit_form(".quiz_group_form")
    wait_for_ajaximations
    click_settings_tab
    keep_trying_until { fj("#quiz_display_points_possible .points_possible").text.should == "2" }
  end

  it "should check permissions when retrieving question banks" do
    @course.account = Account.default
    @course.account.role_overrides.create(:permission => 'read_question_banks', :enrollment_type => 'TeacherEnrollment', :enabled => false)
    @course.save
    quiz = @course.quizzes.create!(:title => "My Quiz")

    course_bank = AssessmentQuestionBank.create!(:context => @course)
    assessment_question_model(bank: course_bank)

    account_bank = AssessmentQuestionBank.create!(:context => @course.account)
    assessment_question_model(bank: account_bank)

    get "/courses/#{@course.id}/quizzes/#{quiz.id}/edit"
    click_questions_tab

    keep_trying_until do
      f('.find_question_link').click
      wait_for_ajaximations
      f('#find_question_dialog').should be_displayed
      f(".select_all_link").should be_displayed
    end
    ffj("#find_question_dialog .bank:visible").size.should == 1

    close_visible_dialog
    keep_trying_until do
      f('.add_question_group_link').click
      wait_for_ajaximations
      f('.find_bank_link').should be_displayed
    end
    f(".find_bank_link").click
    wait_for_ajaximations
    ffj("#find_bank_dialog .bank:visible").size.should == 1
  end

  it "should import questions from a question bank" do
    get "/courses/#{@course.id}/quizzes/new"
    click_questions_tab

    f('.add_question_group_link').click
    wait_for_ajaximations
    group_form = f('#group_top_new .quiz_group_form')
    group_form.find_element(:name, 'quiz_group[name]').send_keys('new group')
    replace_content(group_form.find_element(:name, 'quiz_group[question_points]'), '2')
    submit_form(group_form)
    f('#questions .group_top .group_display.name').should include_text('new group')
  end
end