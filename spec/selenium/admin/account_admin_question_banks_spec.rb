require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/basic/question_bank_common.rb')

describe "account admin question banks" do
  it_should_behave_like "in-process server selenium tests"
  let(:url) { "/accounts/#{Account.default.id}/question_banks" }


  before (:each) do
    admin_logged_in
    get url
  end

  it "should verify question bank is found by navigating to bookmark" do
    should_verify_question_bank_is_found_by_navigating_to_bookmark
  end

  it "should unbookmark a question bank" do
    should_unbookmark_a_question_bank
  end

  it "should edit a question bank" do
    should_edit_a_question_bank
  end

  it "should delete a question bank" do
    should_delete_a_question_bank
  end
end
