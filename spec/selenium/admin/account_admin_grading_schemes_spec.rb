require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/basic/grading_schemes_specs')

describe "account admin grading schemes" do
  describe "shared grading scheme specs" do
    let(:account) { Account.default }
    let(:url) { "/accounts/#{Account.default.id}/grading_standards" }
    it_should_behave_like "grading scheme basic tests"
  end
end
