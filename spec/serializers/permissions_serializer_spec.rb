require 'spec_helper'

describe PermissionsSerializer do

  it "returns a hash of the result of calling check_policy with the caller's user and session" do
    user = stub
    session = stub
    object = stub
    policy = stub
    klass = Class.new { include PermissionsSerializer }
    thing = klass.new

    # class.policy.conditions returns an array of arrays
    # each sub array has a lambda (the code to run the check)
    # and a list of permissions that it grants.
    #
    # See vendor/plugins/adheres_to_policy for more information.
    policy.expects(:conditions).returns [ [stub, [:read] ] ]

    klass = Struct.new(:id)
    object = klass.new(1)
    klass.expects(:policy).returns policy

    thing.expects(:current_user).at_least_once.returns user
    thing.expects(:session).at_least_once.returns session
    thing.expects(:object).at_least_once.returns object

    object.expects(:grants_right?).with(user, session, :read).returns true

    thing.permissions.should == {read: true}
  end
end
