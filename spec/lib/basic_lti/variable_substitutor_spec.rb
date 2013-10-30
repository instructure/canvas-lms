#
# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.dirname(__FILE__) + '/../../sharding_spec_helper.rb')


describe BasicLTI::VariableSubstitutor do

  before do
    @launch = mock()
    @subber = BasicLTI::VariableSubstitutor.new(@launch)
  end

  it "should substitute user info if allowed" do
    @launch.stubs(:user).returns(@launch)
    @launch.stubs(:tool).returns(@launch)
    @launch.stubs("include_name?").returns(true)
    @launch.stubs(:name).returns("full name")
    @launch.stubs(:first_name).returns("full")
    @launch.stubs(:last_name).returns("name")
    @hash = {'full' => '$Person.name.full', 'last' => '$Person.name.family', 'first' => '$Person.name.given'}
    @launch.stubs(:hash).returns(@hash)

    @subber.substitute!
    @hash.should == {'full' => 'full name', 'last' => 'name', 'first' => 'full'}
  end

  it "should leave variable if not supported" do
    @hash = {
        'invalid_namespace' => '$Person.private_info.social_security_number',
        'invalid_method' => '$Person.name.secret_identity',
    }

    @launch.stubs(:hash).returns(@hash)

    @subber.substitute!
    @hash.should == {
        'invalid_namespace' => '$Person.private_info.social_security_number',
        'invalid_method' => '$Person.name.secret_identity',
    }
  end

  it "should add concluded enrollments" do
    @hash = {'concluded_roles' => '$Canvas.membership.concludedRoles'}
    @launch.stubs(:hash).returns(@hash)
    @launch.stubs(:user_data).returns({'concluded_role_types' => ['hey']})

    @subber.substitute!
    @hash.should == {'concluded_roles' => 'hey'}
  end


end