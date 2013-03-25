require File.expand_path(File.dirname(__FILE__) + '/../../common')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/basic/users_specs')

describe "sub account users" do
  describe "shared users specs" do
    it_should_behave_like "in-process server selenium tests"

    it "should add a new user" do
      pending('newly added user in sub account does not show up')
      should_add_a_new_user
    end

  end
end