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
    @bc = BrandConfig.create(variables: {"ic-brand-primary" => "#321"})
  end

  describe '#new' do
    it "should allow authorized admin to create" do
      admin = account_admin_user(account: @account)
      user_session(admin)
      post 'new', {brand_config: @bc, account_id: @account.id}
      assert_status(200)
    end

    it "should not allow non admin access" do
      user = user_with_pseudonym(active_all: true)
      user_session(user)
      post 'new', {brand_config: @bc, account_id: @account.id}
      assert_status(401)
    end

    it "should create variableSchema based on parent configs" do
      @account.brand_config_md5 = @bc.md5
      @account.settings= {global_includes: true, sub_account_includes: true}
      @account.save!

      @subaccount = Account.create!(:parent_account => @account)
      @sub_bc = BrandConfig.create(variables: {"ic-brand-global-nav-bgd" => "#123"}, parent_md5: @bc.md5)
      @subaccount.brand_config_md5 = @sub_bc.md5
      @subaccount.save!

      admin = account_admin_user(account: @subaccount)
      user_session(admin)

      get 'new', {brand_config: @sub_bc, account_id: @subaccount.id}

      variable_schema = assigns[:js_env][:variableSchema]
      variable_schema.each do |s|
        expect(s['group_name']).to be_present
      end

      vars = variable_schema.map{|schema| schema['variables']}.flatten
      vars.each do |v|
        expect(v['human_name']).to be_present
      end

      expect(vars.detect{|v| v["variable_name"] == "ic-brand-header-image"}['helper_text']).to be_present

      primary = vars.detect{|v| v["variable_name"] == "ic-brand-primary"}
      expect(primary["default"]).to eq "#321"
    end
  end
end
