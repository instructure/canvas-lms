#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe DeveloperKeysController do
  context "Site admin" do
    before :once do
      account_admin_user(:account => Account.site_admin)
    end

    describe "GET 'index'" do
      it 'should require authorization' do
        get 'index', params: {account_id: Account.site_admin.id}
        expect(response).to be_redirect
      end

      it 'should return the list of developer keys' do
        user_session(@admin)
        dk = DeveloperKey.create!
        get 'index', params: {account_id: Account.site_admin.id}
        expect(response).to be_success
        expect(assigns[:keys]).to be_include(dk)
      end

      describe "js bundles" do
        render_views

        it 'includes developer_keys_react' do
          allow_any_instance_of(Account).to receive(:feature_allowed?).with(:developer_key_management_ui_rewrite).and_return(true)
          user_session(@admin)
          get 'index', params: {account_id: Account.site_admin.id}
          expect(response).to render_template(:index_react)
          expect(response).to be_success
        end

        it 'includes developer_keys' do
          user_session(@admin)
          get 'index', params: {account_id: Account.site_admin.id}
          expect(response).to render_template(:index)
          expect(response).to be_success
        end
      end

      it 'should not include deleted keys' do
        user_session(@admin)
        dk = DeveloperKey.create!
        dk.destroy
        get 'index', params: {account_id: Account.site_admin.id}
        expect(response).to be_success
        expect(assigns[:keys]).to_not be_include(dk)
      end

      it 'should include inactive keys' do
        user_session(@admin)
        dk = DeveloperKey.create!
        dk.deactivate!
        get 'index', params: {account_id: Account.site_admin.id}
        expect(response).to be_success
        expect(assigns[:keys]).to be_include(dk)
      end

      it "should include the key's 'vendor_code'" do
        user_session(@admin)
        DeveloperKey.create!(vendor_code: 'test_vendor_code')
        get 'index', params: {account_id: Account.site_admin.id}
        expect(assigns[:keys].first.vendor_code).to eq 'test_vendor_code'
      end

      it "should include the key's 'visibility'" do
        user_session(@admin)
        key = DeveloperKey.create!
        get 'index', params: {account_id: Account.site_admin.id}, format: :json
        developer_key = json_parse(response.body).first
        expect(developer_key['visible']).to eq(key.visible)
      end

      it 'includes non-visible keys created in site admin' do
        user_session(@admin)
        site_admin_key = DeveloperKey.create!(name: 'Site Admin Key', visible: false)
        get 'index', params: {account_id: 'site_admin'}
        expect(assigns[:keys]).to eq [site_admin_key]
      end
    end

    describe "POST 'create'" do
      it 'should return the list of developer keys' do
        user_session(@admin)

        post "create", params: {account_id: Account.site_admin.id, developer_key: {
                       redirect_uri: "http://example.com/sdf"
                     }}

        expect(response).to be_success

        json_data = JSON.parse(response.body)

        key = DeveloperKey.find(json_data['id'])
        expect(key.account).to be nil
      end
    end

    describe "PUT 'update'" do
      it "should deactivate a key" do
        user_session(@admin)

        dk = DeveloperKey.create!
        put 'update', params: {id: dk.id, developer_key: { event: :deactivate }, account_id: Account.site_admin.id}
        expect(response).to be_success
        expect(dk.reload.state).to eq :inactive
      end

      it "should reactivate a key" do
        user_session(@admin)

        dk = DeveloperKey.create!
        dk.deactivate!
        put 'update', params: {id: dk.id, developer_key: { event: :activate }, account_id: Account.site_admin.id}
        expect(response).to be_success
        expect(dk.reload.state).to eq :active
      end
    end

    describe "DELETE 'destroy'" do
      it "should soft delete a key" do
        user_session(@admin)

        dk = DeveloperKey.create!
        delete 'destroy', params: {id: dk.id, account_id: Account.site_admin.id}
        expect(response).to be_success
        expect(dk.reload.state).to eq :deleted
      end
    end
  end

  context "Account admin (not site admin)" do
    let(:test_domain_root_account) { Account.create! }
    let(:test_domain_root_account_admin) { account_admin_user(account: test_domain_root_account) }
    let(:sub_account) { test_domain_root_account.sub_accounts.create!(parent_account: test_domain_root_account, root_account: test_domain_root_account) }

    before :each do
      user_session(test_domain_root_account_admin)
      allow(LoadAccount).to receive(:default_domain_root_account).and_return(test_domain_root_account)
    end

    describe '#index' do
      let(:site_admin_key) do
        DeveloperKey.create!(
          name: 'Site Admin Key',
          visible: false
        )
      end

      let(:root_account_key) do
        DeveloperKey.create!(
          name: 'Root Account Key',
          account: test_domain_root_account,
          visible: true
        )
      end

      before do
        site_admin_key
        root_account_key

        allow_any_instance_of(Account).to receive(:feature_allowed?).with(:developer_key_management_ui_rewrite).and_return(true)
        allow_any_instance_of(Account).to receive(:feature_enabled?).with(:developer_key_management_ui_rewrite).and_return(true)
      end

      it 'does not inherit site admin keys if feature flag is off' do
        allow_any_instance_of(Account).to receive(:feature_allowed?).with(:developer_key_management_ui_rewrite).and_return(false)
        site_admin_key.update!(visible: true)
        get 'index', params: {account_id: test_domain_root_account.id}
        expect(assigns[:keys]).to match_array [root_account_key]
      end

      it 'does not include non-visible keys from site admin' do
        get 'index', params: {account_id: test_domain_root_account.id}
        expect(assigns[:keys]).to match_array [root_account_key]
      end

      it 'does include visible keys from site admin' do
        site_admin_key.update!(visible: true)
        get 'index', params: {account_id: test_domain_root_account.id}
        expect(assigns[:keys]).to match_array [site_admin_key, root_account_key]
      end

      it 'includes non-visible keys created in the current context' do
        root_account_key.update!(visible: false)
        get 'index', params: {account_id: test_domain_root_account.id}
        expect(assigns[:keys]).to match_array [root_account_key]
      end
    end

    it 'Should be allowed to access their dev keys' do
      get 'index', params: {account_id: test_domain_root_account.id}
      expect(response).to be_success
    end

    it "An account admin shouldn't be able to access site admin dev keys" do
      user_session(test_domain_root_account_admin)
      get 'index', params: {account_id: Account.site_admin.id}
      expect(response).to be_redirect
      expect(flash[:error]).to eq "You don't have permission to access that page"
    end

    it "An account admin shouldn't be able to access site admin dev keys explicitly" do
      user_session(test_domain_root_account_admin)
      get 'index', params: {account_id: Account.site_admin.id}
      expect(response).to be_redirect
      expect(flash[:error]).to eq "You don't have permission to access that page"
    end

    describe "Should be able to create developer key" do
      before :each do
        post "create", params: {account_id: test_domain_root_account.id, developer_key: {
                       redirect_uri: "http://example.com/sdf"
                     }}
      end

      it 'should be allowed to create a dev key' do
        expect(response).to be_success
      end

      it 'should be dev keys plus 1 key' do
        expect(test_domain_root_account.developer_keys.all.count).to be 1
      end
    end

    it 'should be allowed update a dev key' do
      dk = test_domain_root_account.developer_keys.create!(redirect_uri: 'http://asd.com/')
      put 'update', params: {id: dk.id, developer_key: {
          redirect_uri: "http://example.com/sdf"
        }}
      expect(response).to be_success
      dk.reload
      expect(dk.redirect_uri).to eq("http://example.com/sdf")

    end

    it "Shouldn't be allowed access dev keys for a sub account" do
      get 'index', params: {account_id: sub_account.id}
      expect(response).to be_redirect
      expect(flash[:error]).to eq "You don't have permission to access that page"
    end

    it "Shouldn't be allowed to create dev keys for a sub account" do
      post 'create', params: {account_id: sub_account.id}
      expect(response).to be_redirect
      expect(flash[:error]).to eq "You don't have permission to access that page"
    end

    describe "Shouldn't be able to access other accounts" do
      before :once do
        @other_root_account = Account.create!
        @other_sub_account = @other_root_account.sub_accounts.create!(parent_account: @other_root_account, root_account: @other_root_account)
      end

      it "Shouldn't be allowed access dev keys for a foreign account" do
        get 'index', params: {account_id: @other_root_account.id}
        expect(response).to be_redirect
        expect(flash[:error]).to eq "You don't have permission to access that page"
      end

      it "Shouldn't be allowed to create dev keys for a foreign account" do
        post 'create', params: {account_id: @other_root_account.id}
        expect(response).to be_redirect
        expect(flash[:error]).to eq "You don't have permission to access that page"
      end

      it "Shouldn't be allowed to update dev keys for a foreign account" do
        dk = @other_root_account.developer_keys.create!
        post 'update', params: {id: dk.id, account_id: test_domain_root_account_admin.id, developer_key: { event: :deactivate }}
        expect(response).to be_redirect
        expect(flash[:error]).to eq "You don't have permission to access that page"
      end

      it "Shouldn't be allowed to update global dev keys" do
        dk = DeveloperKey.create!
        post 'update', params: {id: dk.id, account_id: test_domain_root_account_admin.id, developer_key: { event: :deactivate }}
        expect(response).to be_redirect
        expect(flash[:error]).to eq "You don't have permission to access that page"
      end

      it "Shouldn't be allowed to view foreign accounts dev_key" do
        dk = @other_root_account.developer_keys.create!(redirect_uri: 'http://asd.com/')

        post 'update', params: {id: dk.id}
        expect(response).to be_redirect
        expect(flash[:error]).to eq "You don't have permission to access that page"
      end
    end
  end
end
