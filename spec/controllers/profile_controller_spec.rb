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

describe ProfileController do

  describe "update" do
    it "should allow changing the default e-mail address and nothing else" do
      user_with_pseudonym
      user_session(@user, @pseudonym)
      @cc.position.should == 1
      @cc2 = @user.communication_channels.create!(:path => 'email2@example.com')
      @cc2.position.should == 2
      put 'update', :user_id => @user.id, :default_email_id => @cc2.id, :format => 'json'
      response.should be_success
      @cc2.reload.position.should == 1
      @cc.reload.position.should == 2
    end

    it "should allow changing the default e-mail address and nothing else (name changing disabled)" do
      @account = Account.default
      @account.settings = { :users_can_edit_name => false }
      @account.save!
      user_with_pseudonym
      user_session(@user, @pseudonym)
      @cc.position.should == 1
      @cc2 = @user.communication_channels.create!(:path => 'email2@example.com')
      @cc2.position.should == 2
      put 'update', :user_id => @user.id, :default_email_id => @cc2.id, :format => 'json'
      response.should be_success
      @cc2.reload.position.should == 1
      @cc.reload.position.should == 2
    end
  end
end
