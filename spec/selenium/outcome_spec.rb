require File.expand_path(File.dirname(__FILE__) + '/helpers/outcome_specs')

describe "course outcomes" do
  describe "shared outcome specs" do
    let(:outcome_url) { "/courses/#{@course.id}/outcomes" }
    let(:who_to_login) { 'teacher' }
    it_should_behave_like "outcome tests"

    describe "find/import dialog" do
      it "should not allow importing top level groups" do
        get outcome_url
        wait_for_ajaximations

        f('.find_outcome').click
        wait_for_ajaximations
        groups = ff('.outcome-group')
        groups.size.should == 1
        groups.each do |g|
          g.click
          f('.ui-dialog-buttonpane .btn-primary').should_not be_displayed
        end
      end
    end
  end
end
