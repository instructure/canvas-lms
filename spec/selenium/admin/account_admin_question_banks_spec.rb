require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/basic/question_banks_specs')

describe "account admin question banks" do
  describe "shared question bank specs" do
    let(:url) { "/accounts/#{Account.default.id}/question_banks" }
    it_should_behave_like "question bank basic tests"
  end
end