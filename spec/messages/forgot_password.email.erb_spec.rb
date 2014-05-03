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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/messages_helper')

describe 'forgot_password.email' do
  it "should render" do
    user
    @pseudonym = @user.pseudonyms.create!(:unique_id => 'unique@example.com', :password => 'password', :password_confirmation => 'password')
    @object = @user.communication_channels.create!(:path_type => 'email', :path => 'bob@example.com', :user => @user)
    @object.reload
    @user.all_active_pseudonyms.length.should > 0
    @user.all_active_pseudonyms.first.unique_id.should_not be_nil
    @user.all_active_pseudonyms.first.managed_password?.should eql(false)
    @user.reload
    generate_message(:forgot_password, :email, @object)
  end
end
