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
  let(:test_domain_root_account) { Account.create! }

  context "Site admin" do
    before :once do
      account_admin_user(:account => Account.site_admin)
    end

    describe "GET 'index'" do
      context 'with no session' do
        it 'should require authorization' do
          get 'index', params: {account_id: Account.site_admin.id}
          expect(response).to be_redirect
        end
      end

      context 'with a session' do
        before do
          user_session(@admin)
        end

        it 'should return the list of developer keys' do
          dk = DeveloperKey.create!
          get 'index', params: {account_id: Account.site_admin.id}
          expect(response).to be_success
          expect(assigns[:keys]).to be_include(dk)
        end

        describe "js bundles" do
          render_views

          it 'includes developer_keys' do
            get 'index', params: {account_id: Account.site_admin.id}
            expect(response).to render_template(:index)
            expect(response).to be_success
          end
        end

        it 'should not include deleted keys' do
          dk = DeveloperKey.create!
          dk.destroy
          get 'index', params: {account_id: Account.site_admin.id}
          expect(response).to be_success
          expect(assigns[:keys]).not_to be_include(dk)
        end

        it 'should include inactive keys' do
          dk = DeveloperKey.create!
          dk.deactivate!
          get 'index', params: {account_id: Account.site_admin.id}
          expect(response).to be_success
          expect(assigns[:keys]).to be_include(dk)
        end

        it "should include the key's 'vendor_code'" do
          DeveloperKey.create!(vendor_code: 'test_vendor_code')
          get 'index', params: {account_id: Account.site_admin.id}
          expect(assigns[:keys].first.vendor_code).to eq 'test_vendor_code'
        end

        it "should include the key's 'visibility'" do
          key = DeveloperKey.create!
          get 'index', params: {account_id: Account.site_admin.id}, format: :json
          developer_key = json_parse(response.body).first
          expect(developer_key['visible']).to eq(key.visible)
        end

        it 'includes non-visible keys created in site admin' do
          site_admin_key = DeveloperKey.create!(name: 'Site Admin Key', visible: false)
          get 'index', params: {account_id: 'site_admin'}
          expect(assigns[:keys]).to eq [site_admin_key]
        end

        context 'with inherited param' do
          before do
            site_admin_key
            root_account_key
            allow_any_instance_of(Account).to receive(:feature_enabled?).and_return(true)
            allow_any_instance_of(Account).to receive(:feature_enabled?).with(:api_token_scoping).and_return(false)
          end

          context 'on site_admin account' do
            it 'returns empty array' do
              get 'index', params: {inherited: true, account_id: 'site_admin', format: 'json'}
              developer_keys = json_parse(response.body)
              expect(developer_keys.size).to eq 0
            end
          end

          context 'on root account' do
            context 'with site_admin key visible' do
              before do
                dev_key = DeveloperKey.create!(name: 'Site Admin Key 2')
                dev_key.update!(visible: true)
              end

              it 'returns only the keys from site_admin' do
                get 'index', params: {inherited: true, account_id: test_domain_root_account.id, format: 'json'}
                developer_keys = json_parse(response.body)
                expect(developer_keys.size).to eq 1
                expect(developer_keys.first['name']).to eq 'Site Admin Key 2'
              end
            end

            context 'with site_admin key not visible' do
              it 'returns empty array' do
                get 'index', params: {inherited: true, account_id: test_domain_root_account.id, format: 'json'}
                developer_keys = json_parse(response.body)
                expect(developer_keys.size).to eq 0
              end
            end
          end

          context 'on sub account'
        end
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

      describe 'scopes' do
        let(:valid_scopes) do
          %w(url:POST|/api/v1/courses/:course_id/quizzes/:id/validate_access_code
             url:GET|/api/v1/audit/grade_change/courses/:course_id/assignments/:assignment_id/graders/:grader_id)
        end
        let(:invalid_scopes) { ['url:POST/banana', 'url:POST/invalid/scope'] }
        let(:root_account) { account_model }

        before do
          Account.site_admin.allow_feature!(:api_token_scoping)
          allow_any_instance_of(Account).to receive(:feature_enabled?).with(:api_token_scoping).and_return(true)
          allow_any_instance_of(Account).to receive(:feature_enabled?).with(:developer_key_management_ui_rewrite).and_return(true)
          user_session(@admin)
        end

        it 'allows setting scopes' do
          post 'create', params: { account_id: root_account.id, developer_key: { scopes: valid_scopes } }
          expect(DeveloperKey.find(json_parse['id']).scopes).to match_array valid_scopes
        end

        it 'returns an error if an invalid scope is used' do
          post 'create', params: { account_id: root_account.id, developer_key: { scopes: invalid_scopes } }
          expect(json_parse.dig('errors', 'scopes').first['attribute']).to eq 'scopes'
        end

        it 'does not create the key if any scopes are invalid' do
          expect do
            post 'create', params: { account_id: root_account.id, developer_key: { scopes: invalid_scopes.concat(valid_scopes) } }
          end.not_to change(DeveloperKey, :count)
        end

        it 'does not set scopes if the "developer_key_management_ui_rewrite" flag is disabled' do
          allow_any_instance_of(Account).to receive(:feature_enabled?).with(:developer_key_management_ui_rewrite).and_return(false)
          post 'create', params: { account_id: root_account.id, developer_key: { scopes: valid_scopes } }
          expect(DeveloperKey.find(json_parse['id']).scopes).to be_blank
        end
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

      describe 'scopes' do
        let(:valid_scopes) do
          %w(url:POST|/api/v1/courses/:course_id/quizzes/:id/validate_access_code
             url:GET|/api/v1/audit/grade_change/courses/:course_id/assignments/:assignment_id/graders/:grader_id)
        end
        let(:invalid_scopes) { ['url:POST|/api/v1/banana', 'not_a_scope'] }
        let(:root_account) { account_model }
        let(:developer_key) { DeveloperKey.create!(account: account_model) }

        before do
          allow_any_instance_of(Account).to receive(:feature_enabled?).with(:api_token_scoping).and_return(true)
          allow_any_instance_of(Account).to receive(:feature_enabled?).with(:developer_key_management_ui_rewrite).and_return(true)
          user_session(@admin)
        end

        it 'allows setting scopes' do
          put 'update', params: { id: developer_key.id, developer_key: { scopes: valid_scopes } }
          expect(developer_key.reload.scopes).to match_array valid_scopes
        end

        it 'returns an error if an invalid scope is used' do
          put 'update', params: { id: developer_key.id, developer_key: { scopes: invalid_scopes } }
          expect(json_parse.dig('errors', 'scopes').first['attribute']).to eq 'scopes'
        end

        it 'does not persist scopes if any are invalid' do
          put 'update', params: { id: developer_key.id, developer_key: { scopes: invalid_scopes.concat(valid_scopes) } }
          expect(developer_key.reload.scopes).to be_blank
        end

        it 'does not set scopes if the "developer_key_management_ui_rewrite" flag is disabled' do
          allow_any_instance_of(Account).to receive(:feature_enabled?).with(:developer_key_management_ui_rewrite).and_return(false)
          put 'update', params: { id: developer_key.id, developer_key: { scopes: valid_scopes } }
          expect(developer_key.reload.scopes).to be_blank
        end
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
    let(:test_domain_root_account_admin) { account_admin_user(account: test_domain_root_account) }
    let(:sub_account) { test_domain_root_account.sub_accounts.create!(parent_account: test_domain_root_account, root_account: test_domain_root_account) }

    before :each do
      user_session(test_domain_root_account_admin)
      allow(LoadAccount).to receive(:default_domain_root_account).and_return(test_domain_root_account)
    end

    describe '#index' do
      before do
        site_admin_key
        root_account_key

        allow_any_instance_of(Account).to receive(:feature_enabled?).and_return(false)
        allow_any_instance_of(Account).to receive(:feature_enabled?).with(:developer_key_management_ui_rewrite).and_return(true)
      end

      it 'does not inherit site admin keys if feature flag is off' do
        site_admin_key.update!(visible: true)
        get 'index', params: {account_id: test_domain_root_account.id}
        expect(assigns[:keys]).to match_array [root_account_key]
      end

      it 'does not include non-visible keys from site admin' do
        get 'index', params: {account_id: test_domain_root_account.id}
        expect(assigns[:keys]).to match_array [root_account_key]
      end

      it 'does not include visible keys from site admin' do
        site_admin_key.update!(visible: true)
        get 'index', params: {account_id: test_domain_root_account.id}
        expect(assigns[:keys]).to match_array [root_account_key]
      end

      it 'includes non-visible keys created in the current context' do
        root_account_key.update!(visible: false)
        get 'index', params: {account_id: test_domain_root_account.id}
        expect(assigns[:keys]).to match_array [root_account_key]
      end

      context 'with "inherited" parameter' do
        it 'does not include account developer keys' do
          root_account_key
          get 'index', params: {account_id: test_domain_root_account.id, inherited: true}
          expect(assigns[:keys]).to be_blank
        end
      end

      context 'with sharding' do
        specs_require_sharding

        let(:root_account_admin) { root_account_shard.activate { account_admin_user(account: root_account) } }
        let(:site_admin_shard) { Account.site_admin.shard }
        let(:site_admin_key) do
          site_admin_shard.activate do
            key = DeveloperKey.create!
            key.update!(visible: true)
            key
          end
        end
        let(:root_account_shard) { Shard.create! }
        let(:root_account) { root_account_shard.activate { account_model } }
        let(:root_account_key) { root_account_shard.activate { DeveloperKey.create!(account: root_account) } }

        before do
          site_admin_key
          root_account_key

          allow(controller).to receive(:account_context) do
            controller.send(:require_account_context)
            controller.send(:context)
          end
        end

        it 'includes visible site admin keys from the site admin shard' do
          user_session(root_account_admin)

          root_account_shard.activate do
            get 'index', params: {account_id: root_account.id, inherited: true}
          end

          expect(assigns[:keys]).to match_array [site_admin_key]
        end
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
