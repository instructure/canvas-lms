shared_examples_for "question bank basic tests" do
  include_context "in-process server selenium tests"
  before (:each) do
    admin_logged_in
    get url
  end

  def add_question_bank(title = 'bank 1')
    f(".add_bank_link").click
    wait_for_ajaximations
    question_bank_title = f("#assessment_question_bank_title")
    expect(question_bank_title).to be_displayed
    question_bank_title.send_keys(title, :return)
    wait_for_ajaximations
    question_bank = AssessmentQuestionBank.where(title: title).first
    expect(question_bank).to be_present
    expect(question_bank.workflow_state).to eq "active"
    expect(f("#question_bank_adding .title")).to include_text title
    expect(question_bank.bookmarked_for?(User.last)).to be_truthy
    question_bank
  end

  it "should verify question bank is found by navigating to bookmark" do
    question_bank = add_question_bank
    expect_new_page_load { f(".see_bookmarked_banks").click }
    wait_for_ajaximations
    expect(f("#question_bank_#{question_bank.id}")).to include_text question_bank.title
  end

  it "should un-bookmark a question bank" do
    question_bank = add_question_bank
    expect(fj(".bookmark_bank_link i:visible")).to have_class("icon-remove-bookmark")
    expect(fj(".bookmark_bank_link i:visible")).not_to have_class("icon-bookmark")
    fj(".bookmark_bank_link:visible").click
    wait_for_ajaximations
    expect(fj(".bookmark_bank_link i:visible")).to have_class("icon-bookmark")
    question_bank.reload
    expect(question_bank.bookmarked_for?(User.last)).to be_falsey
  end

  it "should edit a question bank" do
    new_title = "bank 2"
    question_bank = add_question_bank
    wait_for_ajaximations
    f("#questions .edit_bank_link").click
    wait_for_ajaximations
    f("#assessment_question_bank_title").send_keys(new_title, :return)
    wait_for_ajaximations
    question_bank.reload
    expect(question_bank.title).to eq new_title
    expect(f("#questions .title")).to include_text new_title
  end

  it "should delete a question bank" do
    question_bank = add_question_bank
    f("#questions .delete_bank_link").click
    driver.switch_to.alert.accept
    keep_trying_until { question_bank.reload.workflow_state == "deleted" }
    expect(f("#content")).not_to contain_css("#questions .title")
  end
end
