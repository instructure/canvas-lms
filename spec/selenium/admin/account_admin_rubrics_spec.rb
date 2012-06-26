require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/rubrics_specs')
describe "account rubrics" do
  it_should_behave_like "rubric tests"

  describe "shared rubric specs" do
    let(:rubric_url) { "/accounts/#{Account.default.id}/rubrics" }
    let(:who_to_login) { 'admin' }
    it_should_behave_like "rubric specs"
  end
end