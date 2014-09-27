shared_examples_for "question bank basic tests" do
  include_examples "in-process server selenium tests"
  before (:each) do
    admin_logged_in
    get url
  end

  def add_question_bank(title = 'bank 1')
    question_bank_title = keep_trying_until do
      f(".add_bank_link").click
      wait_for_ajaximations
      question_bank_title = f("#assessment_question_bank_title")
      question_bank_title.should be_displayed
      question_bank_title
    end
    question_bank_title.send_keys(title, :return)
    wait_for_ajaximations
    question_bank = AssessmentQuestionBank.where(title: title).first
    question_bank.should be_present
    question_bank.workflow_state.should == "active"
    f("#question_bank_adding .title").should include_text title
    question_bank.bookmarked_for?(User.last).should be_true
    question_bank
  end

  it "should verify question bank is found by navigating to bookmark" do
    question_bank = add_question_bank
    expect_new_page_load { f(".see_bookmarked_banks").click }
    wait_for_ajaximations
    f("#question_bank_#{question_bank.id}").should include_text question_bank.title
  end

  it "should un-bookmark a question bank" do
    question_bank = add_question_bank
    fj(".bookmark_bank_link img:visible").should have_attribute(:alt, "Bookmark")
    fj(".bookmark_bank_link:visible").click
    wait_for_ajaximations
    fj(".bookmark_bank_link img:visible").should have_attribute(:alt, "Bookmark_gray")
    question_bank.reload
    question_bank.bookmarked_for?(User.last).should be_false
  end

  it "should edit a question bank" do
    new_title = "bank 2"
    question_bank = add_question_bank
    f("#questions .edit_bank_link").click
    wait_for_ajaximations
    f("#assessment_question_bank_title").send_keys(new_title, :return)
    wait_for_ajaximations
    question_bank.reload
    question_bank.title.should == new_title
    f("#questions .title").should include_text new_title
  end

  it "should delete a question bank" do
    question_bank = add_question_bank
    f("#questions .delete_bank_link").click
    driver.switch_to.alert.accept
    wait_for_ajaximations
    question_bank.reload
    keep_trying_until do
      question_bank.workflow_state.should == "deleted"
      f("#questions .title").should be_nil
    end
  end
end