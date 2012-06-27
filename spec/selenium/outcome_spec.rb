require File.expand_path(File.dirname(__FILE__) + '/helpers/outcome_specs')

describe "course outcomes" do
  describe "shared outcome specs" do
    let(:outcome_url) { "/courses/#{@course.id}/outcomes" }
    let(:who_to_login) { 'teacher' }
    it_should_behave_like "outcome tests"
  end
end
