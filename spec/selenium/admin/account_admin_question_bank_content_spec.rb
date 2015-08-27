require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/external_tools_common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/testrail_report')


describe "account admin question bank" do
  include_context "in-process server selenium tests"

  before(:each) do
    admin_logged_in
    @question_bank = create_question_bank
    @question = create_question
    @outcome = create_outcome
    get "/accounts/#{Account.default.id}/question_banks/#{@question_bank.id}"
  end

  def create_question_bank(title = "question bank 1")
    Account.default.assessment_question_banks.create!(:title => title)
  end

  def create_question(name = "question 1", bank = @question_bank)
    answers = [{:text => "correct answer", :weight => 100}]
    3.times do
      answer = {:text => "incorrect answer", :weight => 0}
      answers.push answer
    end
    data = {:question_text => "what is the answer to #{name}?", :question_type => 'multiple_choice_question', :answers => answers}
    data[:question_name] = name
    question = AssessmentQuestion.create(:question_data => data)
    bank.assessment_questions << question
    question
  end

  def create_outcome (short_description = "good student")
    outcome = Account.default.learning_outcomes.create!(
        :short_description => short_description,
        :rubric_criterion => {
            :description => "test description",
            :points_possible => 10,
            :mastery_points => 9,
            :ratings => [
                {:description => "Exceeds Expectations", :points => 5},
                {:description => "Meets Expectations", :points => 3},
                {:description => "Does Not Meet Expectations", :points => 0}
            ]
        })
    Account.default.root_outcome_group.add_outcome(outcome)
    outcome
  end


  def verify_added_question(name, question_text, chosen_question_type)
    question = AssessmentQuestion.where(name: name).first
    expect(question).to be_present
    question_data = question.question_data
    expect(question_data[:question_type]).to eq chosen_question_type
    expect(question_data[:question_text]).to include question_text
    answers = question_data[:answers]
    expect(answers[0][:weight]).to eq 100
    (1..3).each do |i|
      expect(answers[i][:weight]).to eq 0
    end
    expect(f("#question_#{question.id}")).to include_text name
    expect(f("#question_#{question.id}")).to include_text question_text
    question
  end

  def add_multiple_choice_question(name = "question 2", points = "3")
    multiple_choice_value = "multiple_choice_question"
    question_text = "what is the answer to #{name}?"
    f(".add_question_link").click
    wait_for_ajaximations
    question_form = f(".question_form")
    question_form.find_element(:css, "[name='question_name']").send_keys(name)
    replace_content(question_form.find_element(:css, "[name='question_points']"), points)
    wait_for_ajaximations
    click_option(".header .question_type", multiple_choice_value, :value)
    wait_for_ajaximations
    type_in_tiny(".question_content", question_text)
    wait_for_ajaximations
    answer_inputs = ff(".form_answers .select_answer input")
    answer_inputs[0].send_keys("correct answer")
    (1..3).each do |i|
      answer_inputs[i*2].send_keys("incorrect answer")
      wait_for_ajaximations
    end
    submit_form(question_form)
    wait_for_ajaximations
    verify_added_question(name, question_text, multiple_choice_value)
  end

  it "should add bank and multiple choice question" do
    report_test(71462) do
      question_bank2 = create_question_bank('question bank 2')
      get "/accounts/#{Account.default.id}/question_banks/#{question_bank2.id}"
      add_multiple_choice_question
    end
  end

  it "should add a multiple choice question" do
    add_multiple_choice_question
  end

  it "should edit a multiple choice question" do
    new_name = "question 2"
    new_question_text = "what is the answer to #{new_name}?"
    hover_and_click("#question_#{@question.id} .edit_question_link")
    wait_for_ajax_requests
    replace_content(f(".question_form [name='question_name']"), new_name)
    type_in_tiny(".question_content", new_question_text)
    submit_form(".question_form")
    wait_for_ajaximations
    verify_added_question(new_name, new_question_text, "multiple_choice_question")
  end

  it "should show question details" do
    f("#show_question_details").click
    answers = ff(".answers #answer_template")
    answers.each_with_index do |answer, i|
      question_answer = @question.question_data[:answers][i][:text]
      expect(answer).to include_text(question_answer)
    end
  end

  it "should move question to another bank" do
    question_bank_2 = create_question_bank("bank 2")
    f(".move_question_link").click
    wait_for_ajaximations
    f("#move_question_dialog #question_bank_#{question_bank_2.id}").click
    wait_for_ajaximations
    submit_dialog("#move_question_dialog", '.submit_button')
    wait_for_ajaximations
    expect(question_bank_2.assessment_questions.where(name: @question.name).first).to be_present
  end

  it "should bookmark a question bank" do
    expect(@question_bank.bookmarked_for?(User.last)).to be_falsey
    f("#right-side-wrapper .bookmark_bank_link").click
    wait_for_ajaximations
    @question_bank.reload
    expect(@question_bank.bookmarked_for?(User.last)).to be_truthy
    expect(f("#right-side .bookmark_bank_link")).to include_text "Already Bookmarked"
  end

  it "should edit bank details" do
    f("#right-side .edit_bank_link").click
    wait_for_ajaximations
    question_bank_title = f("#assessment_question_bank_title")
    new_title = "bank 2"
    replace_content(question_bank_title, new_title)
    question_bank_title.send_keys(:return)
    wait_for_ajaximations
    expect(AssessmentQuestionBank.where(title: new_title).first).to be_present
  end

  it "should delete a question bank" do
    f("#right-side .delete_bank_link").click
    driver.switch_to.alert.accept
    wait_for_ajaximations
    @question_bank.reload
    keep_trying_until { expect(@question_bank.workflow_state).to eq "deleted" }
  end

  it "should delete a multiple choice question" do
    hover_and_click("#question_#{@question.id} .delete_question_link")
    driver.switch_to.alert.accept
    wait_for_ajaximations
    @question.reload
    keep_trying_until do
      expect(@question.workflow_state).to eq "deleted"
      expect(fj("#questions .question_name")).to be_nil
    end
  end

  context "moving multiple questions" do
    def add_questions_and_move(question_count = 1)
      question_number = question_count + 1
      questions = []
      questions.push @question
      question_count.times { |i| questions.push create_question("question #{question_number+i}") }
      f(".move_questions_link").click
      wait_for_ajaximations
      question_list = ffj(".list_question:visible")
      expect(question_list.count).to eq questions.count
      question_list.each_with_index do |question, i|
        expect(question).to include_text questions[i].name
        f("#list_question_#{questions[i].id}").click
        wait_for_ajaximations
      end
      questions
    end

    def move_questions_validation(bank_name, questions)
      new_question_bank = AssessmentQuestionBank.where(title: bank_name).first
      expect(new_question_bank).to be_present
      new_questions = AssessmentQuestion.where(:assessment_question_bank_id => new_question_bank).to_a
      expect(new_questions).to be_present
      expect(new_questions).to match_array questions
    end

    it "should move multiple questions to a new bank" do
      new_bank = "new bank 2"
      questions = add_questions_and_move(2)
      expect(questions.count).to eq 3
      f("#bank_new").click
      f("#new_question_bank_name").send_keys(new_bank)
      submit_dialog("#move_question_dialog", '.submit_button')
      wait_for_ajaximations
      expect(AssessmentQuestionBank.count).to eq 2
      move_questions_validation(new_bank, questions)
    end

    it "should move multiple questions to an existing bank" do
      bank_name = "bank 2"
      question_bank_2 = create_question_bank(bank_name)
      questions = add_questions_and_move
      expect(questions.count).to eq 2
      expect(f(".bank .bank_name")).to include_text bank_name
      f("#question_bank_#{question_bank_2.id}").click
      submit_dialog("#move_question_dialog", '.submit_button')
      wait_for_ajaximations
      move_questions_validation(bank_name, questions)
    end
  end

  context "outcome alignment" do
    def add_outcome_to_bank(outcome, mastery_percent = 60)
      f('.add_outcome_link').click
      wait_for_ajaximations
      f('.outcome-link').click
      wait_for_ajaximations
      replace_content(f('#outcome_mastery_at'), mastery_percent)
      fj('.btn-primary:visible').click
      driver.switch_to.alert.accept
      wait_for_ajax_requests
      expect(fj("[data-id=#{outcome.id}]:visible")).to include_text outcome.short_description
    end

    it "should align an outcome" do
      mastery_points, possible_points = @outcome.data[:rubric_criterion].values_at(:mastery_points, :points_possible)
      percentage = mastery_points.to_f / possible_points.to_f
      add_outcome_to_bank(@outcome)
      expect(fj("[data-id=#{@outcome.id}]:visible")).to include_text("60%")
      expect(@question_bank.reload.learning_outcome_alignments.count).to be > 0
      learning_outcome_tag = @question_bank.learning_outcome_alignments.where(mastery_score: 0.6).first
      expect(learning_outcome_tag).to be_present
    end

    it "should change the outcome set mastery score" do
      f(".add_outcome_link").click
      wait_for_ajax_requests
      add_outcome_to_bank(@outcome, 40)
      expect(fj("[data-id=#{@outcome.id}]:visible .content")).to include_text("mastery at 40%")
      learning_outcome_tag = AssessmentQuestionBank.last.learning_outcome_alignments.where(mastery_score: 0.4).first
      expect(learning_outcome_tag).to be_present
    end

    it "should delete an aligned outcome" do
      add_outcome_to_bank(@outcome)
      fj("[data-id='#{@outcome.id}']:visible .delete_outcome_link").click
      driver.switch_to.alert.accept
      wait_for_ajaximations
      expect(fj("[data-id='#{@outcome.id}']:visible .delete_outcome_link")).to be_nil
    end
  end
end
