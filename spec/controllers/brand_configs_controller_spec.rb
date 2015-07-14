#
# Copyright (C) 2015 Instructure, Inc.
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

describe BrandConfigsController do
  before :each do
    @account = Account.default
    @account.enable_feature!(:use_new_styles)
    @bc = BrandConfig.create(variables: {"ic-brand-primary" => "red"})
  end

  describe '#new' do
    it "should allow authorized admin to create" do
      admin = account_admin_user(account: @account)
      user_session(admin)
      post 'new', {brand_config: @bc}
      assert_status(200)
    end

    it "should not allow non admin access" do
      user = user_with_pseudonym(active_all: true)
      user_session(user)
      post 'new', {brand_config: @bc}
      assert_status(401)
    end
  end
end