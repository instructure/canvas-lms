require File.expand_path(File.dirname(__FILE__) + '/../../common')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/outcome_specs')

describe "sub account outcomes" do
  describe "shared outcome specs" do
    let(:account) { Account.create(:name => 'sub account from default account', :parent_account => Account.default) }
    let(:outcome_url) { "/accounts/#{account.id}/outcomes" }
    let(:who_to_login) { 'admin' }
    it_should_behave_like "outcome tests"

    describe "find/import dialog" do
      it "should not allow importing top level groups" do
        get outcome_url
        wait_for_ajaximations

        f('.find_outcome').click
        wait_for_ajaximations
        groups = ff('.outcome-group')
        groups.size.should == 2
        groups.each do |g|
          g.click
          f('.ui-dialog-buttonpane .btn-primary').should_not be_displayed
        end
      end
    end
  end
end