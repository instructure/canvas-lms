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

describe AccountAuthorizationConfigsController do
  def account_with_admin_logged_in(opts = {})
    @account = Account.default
    account_admin_user
    user_session(@admin)
  end

  describe "PUT 'update'" do
    it "should disable open registration when setting delegated auth" do
      account_with_admin_logged_in
      @account.settings = { :open_registration => true }
      @account.save!
      put 'update_all', :account_id => @account.id, :account_authorization_config => [ [0, {:auth_type => 'cas'}]]
      response.should be_success
      @account.reload
      @account.open_registration?.should be_false
    end
  end
end
