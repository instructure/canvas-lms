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
  before :once do
    @account = Account.default
    @bc = BrandConfig.create(variables: {"ic-brand-primary" => "#321"})
  end

  describe '#index' do
    it "should allow authorized admin to view" do
      admin = account_admin_user(account: @account)
      user_session(admin)
      get 'index', account_id: @account.id
      assert_status(200)
    end

    it 'should not allow non admin access' do
      user = user_with_pseudonym(active_all: true)
      user_session(user)
      get 'index', account_id: @account.id
      assert_status(401)
    end

    it 'requires branding enabled on the account' do
      subaccount = @account.sub_accounts.create!(name: "sub")
      admin = account_admin_user(account: @account)
      user_session(admin)
      get 'index', account_id: subaccount.id
      assert_status(302)
      expect(flash[:error]).to match(/cannot edit themes/)
    end
  end

  describe '#new' do
    it "should allow authorized admin to see create" do
      admin = account_admin_user(account: @account)
      user_session(admin)
      get 'new', {brand_config: @bc, account_id: @account.id}
      assert_status(200)
    end

    it "should not allow non admin access" do
      user = user_with_pseudonym(active_all: true)
      user_session(user)
      get 'new', {brand_config: @bc, account_id: @account.id}
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

  describe '#create' do
    let_once(:admin) { account_admin_user(account: @account) }
    let(:bcin) { { variables: { "ic-brand-primary" => "#000000" } } }

    it "should allow authorized admin to create" do
      user_session(admin)
      post 'create', account_id: @account.id, brand_config: bcin
      assert_status(200)
      json = JSON.parse(response.body)
      expect(json['brand_config']['variables']['ic-brand-primary']).to eq "#000000"
    end

    it 'should not allow non admin access' do
      user = user_with_pseudonym(active_all: true)
      user_session(user)
      post 'create', account_id: @account.id, brand_config: bcin
      assert_status(401)
    end

    it 'should return an existing brand config' do
      user_session(admin)
      post 'create', account_id: @account.id, brand_config: { 
        variables: {
          "ic-brand-primary" => "#321"
        }
      }
      assert_status(200)
      json = JSON.parse(response.body)
      expect(json['brand_config']['md5']).to eq @bc.md5
    end

    it 'should upload a js file successfully' do
      user_session(admin)
      tf = Tempfile.new('test.js')
      uf = ActionDispatch::Http::UploadedFile.new(tempfile: tf)
      post 'create', account_id: @account.id, brand_config: bcin, js_overrides: uf
      assert_status(200)
      json = JSON.parse(response.body)
      expect(json['brand_config']['js_overrides']).to be_present
    end
  end

  describe '#destroy' do
    it "should allow authorized admin to create" do
      admin = account_admin_user(account: @account)
      user_session(admin)
      session[:brand_config_md5] = @bc.md5
      delete 'destroy', account_id: @account.id
      assert_status(302)
      expect(session[:brand_config_md5]).to be_nil
      expect { @bc.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'should not allow non admin access' do
      user = user_with_pseudonym(active_all: true)
      user_session(user)
      delete 'destroy', account_id: @account.id
      assert_status(401)
    end
  end

  describe '#save_to_account' do
    it "should allow authorized admin to create" do
      admin = account_admin_user(account: @account)
      user_session(admin)
      post 'save_to_account', account_id: @account.id
      assert_status(200)
    end

    it 'should regenerate sub accounts' do
      subbc = BrandConfig.create(variables: {"ic-brand-primary" => "#111"})
      @account.sub_accounts.create!(name: "Sub", brand_config_md5: subbc.md5)

      admin = account_admin_user(account: @account)
      user_session(admin)
      session[:brand_config_md5] = @bc.md5
      post 'save_to_account', account_id: @account.id
      assert_status(200)
      json = JSON.parse(response.body)
      expect(json['subAccountProgresses']).to be_present
    end

    it 'should not allow non admin access' do
      user = user_with_pseudonym(active_all: true)
      user_session(user)
      post 'save_to_account', account_id: @account.id
      assert_status(401)
    end
  end

  describe '#save_to_user_session' do
    it "should allow authorized admin to create" do
      admin = account_admin_user(account: @account)
      user_session(admin)
      post 'save_to_user_session', account_id: @account.id, brand_config_md5: @bc.md5
      assert_status(302)
      expect(session[:brand_config_md5]).to eq @bc.md5
    end

    it "should allow authorized admin to remove" do
      admin = account_admin_user(account: @account)
      user_session(admin)
      session[:brand_config_md5] = @bc.md5
      post 'save_to_user_session', account_id: @account.id, brand_config_md5: ''
      assert_status(302)
      expect(session[:brand_config_md5]).to eq false
      expect { @bc.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'should not allow non admin access' do
      user = user_with_pseudonym(active_all: true)
      user_session(user)
      post 'save_to_user_session', account_id: @account.id, brand_config_md5: @bc.md5
      assert_status(401)
      expect(session[:brand_config_md5]).to be_nil
    end
  end
end
