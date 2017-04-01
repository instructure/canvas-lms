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

describe DeveloperKeysController do

  context "Site admin" do
    before :once do
      account_admin_user(:account => Account.site_admin)
    end

    describe "GET 'index'" do
      it 'should require authorization' do
        get 'index', account_id: Account.site_admin.id
        expect(response).to be_redirect
      end

      it 'should return the list of developer keys' do
        user_session(@admin)
        dk = DeveloperKey.create!
        get 'index', account_id: Account.site_admin.id
        expect(response).to be_success
        expect(assigns[:keys]).to be_include(dk)
      end

      it 'should not include deleted keys' do
        user_session(@admin)
        dk = DeveloperKey.create!
        dk.destroy
        get 'index', account_id: Account.site_admin.id
        expect(response).to be_success
        expect(assigns[:keys]).to_not be_include(dk)
      end

      it 'should include inactive keys' do
        user_session(@admin)
        dk = DeveloperKey.create!
        dk.deactivate!
        get 'index', account_id: Account.site_admin.id
        expect(response).to be_success
        expect(assigns[:keys]).to be_include(dk)
      end
    end

    describe "POST 'create'" do
      it 'should return the list of developer keys' do
        user_session(@admin)

        post "create", account_id: Account.site_admin.id, developer_key: {
                       redirect_uri: "http://example.com/sdf"
                     }
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
        put 'update', id: dk.id, developer_key: { event: :deactivate }, account_id: Account.site_admin.id
        expect(response).to be_success
        expect(dk.reload.state).to eq :inactive
      end

      it "should reactivate a key" do
        user_session(@admin)

        dk = DeveloperKey.create!
        dk.deactivate!
        put 'update', id: dk.id, developer_key: { event: :activate }, account_id: Account.site_admin.id
        expect(response).to be_success
        expect(dk.reload.state).to eq :active
      end
    end

    describe "DELETE 'destroy'" do
      it "should soft delete a key" do
        user_session(@admin)

        dk = DeveloperKey.create!
        delete 'destroy', id: dk.id, account_id: Account.site_admin.id
        expect(response).to be_success
        expect(dk.reload.state).to eq :deleted
      end
    end
  end

  context "Account admin (not site admin)" do
    before :once do
      @test_domain_root_account = Account.create!
      @test_domain_root_account_admin= account_admin_user(account: @test_domain_root_account)
      @sub_account = @test_domain_root_account.sub_accounts.create!(parent_account: @test_domain_root_account, root_account: @test_domain_root_account)
    end

    before :each do
      user_session(@test_domain_root_account_admin)
      LoadAccount.stubs(:default_domain_root_account).returns(@test_domain_root_account)
    end

    it 'Should be allowed to access their dev keys' do
      get 'index', account_id: @test_domain_root_account.id
      expect(response).to be_success
    end

    it "An account admin shouldn't be able to access site admin dev keys" do
      user_session(@test_domain_root_account_admin)
      get 'index', account_id: Account.site_admin.id
      expect(response).to be_redirect
      expect(flash[:error]).to eq "You don't have permission to access that page"
    end

    it "An account admin shouldn't be able to access site admin dev keys explicitly" do
      user_session(@test_domain_root_account_admin)
      get 'index', account_id: Account.site_admin.id
      expect(response).to be_redirect
      expect(flash[:error]).to eq "You don't have permission to access that page"
    end

    describe "Should be able to create developer key" do
      before :each do
        post "create", account_id: @test_domain_root_account.id, developer_key: {
                       redirect_uri: "http://example.com/sdf"
                     }
      end

      it 'should be allowed to create a dev key' do
        expect(response).to be_success
      end

      it 'should be dev keys plus 1 key' do
        expect(@test_domain_root_account.developer_keys.all.count).to be 1
      end
    end

    it 'should be allowed update a dev key' do
      dk = @test_domain_root_account.developer_keys.create!(redirect_uri: 'http://asd.com/')
      put 'update', id: dk.id, developer_key: {
          redirect_uri: "http://example.com/sdf"
        }
      expect(response).to be_success
      dk.reload
      expect(dk.redirect_uri).to eq("http://example.com/sdf")

    end

    it "Shouldn't be allowed access dev keys for a sub account" do
      get 'index', account_id: @sub_account.id
      expect(response).to be_redirect
      expect(flash[:error]).to eq "You don't have permission to access that page"
    end

    it "Shouldn't be allowed to create dev keys for a sub account" do
      post 'create', account_id: @sub_account.id
      expect(response).to be_redirect
      expect(flash[:error]).to eq "You don't have permission to access that page"
    end

    describe "Shouldn't be able to access other accounts" do
      before :once do
        @other_root_account = Account.create!
        @other_sub_account = @other_root_account.sub_accounts.create!(parent_account: @other_root_account, root_account: @other_root_account)
      end

      it "Shouldn't be allowed access dev keys for a foreign account" do
        get 'index', account_id: @other_root_account.id
        expect(response).to be_redirect
        expect(flash[:error]).to eq "You don't have permission to access that page"
      end

      it "Shouldn't be allowed to create dev keys for a foreign account" do
        post 'create', account_id: @other_root_account.id
        expect(response).to be_redirect
        expect(flash[:error]).to eq "You don't have permission to access that page"
      end

      it "Shouldn't be allowed to update dev keys for a foreign account" do
        dk = @other_root_account.developer_keys.create!
        post 'update', id: dk.id, account_id: @test_domain_root_account_admin.id, developer_key: { event: :deactivate }
        expect(response).to be_redirect
        expect(flash[:error]).to eq "You don't have permission to access that page"
      end

      it "Shouldn't be allowed to update global dev keys" do
        dk = DeveloperKey.create!
        post 'update', id: dk.id, account_id: @test_domain_root_account_admin.id, developer_key: { event: :deactivate }
        expect(response).to be_redirect
        expect(flash[:error]).to eq "You don't have permission to access that page"
      end

      it "Shouldn't be allowed to view foreign accounts dev_key" do
        dk = @other_root_account.developer_keys.create!(redirect_uri: 'http://asd.com/')

        post 'update', id: dk.id
        expect(response).to be_redirect
        expect(flash[:error]).to eq "You don't have permission to access that page"
      end

    end
  end
end
