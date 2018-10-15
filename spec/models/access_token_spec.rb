#
# Copyright (C) 2012 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper')

describe AccessToken do

  context "Authenticate" do
    shared_examples "#authenticate" do

      it "new access tokens shouldnt have an expiration" do
        at = AccessToken.create!(:user => user_model, :developer_key => DeveloperKey.default)
        expect(at.expires_at).to eq nil
      end

      it "should authenticate valid token" do
        at = AccessToken.create!(:user => user_model, :developer_key => DeveloperKey.default)
        expect(AccessToken.authenticate(at.full_token)).to eq at
      end

      it "shouldn't authenticate expired tokens" do
        at = AccessToken.create!(
            :user => user_model,
            :developer_key => DeveloperKey.default,
            :expires_at => 2.hours.ago
        )
        expect(AccessToken.authenticate(at.full_token)).to be nil
      end
    end

    context "With auto expire" do
      before :once do
        DeveloperKey.default.auto_expire_tokens = true
        DeveloperKey.default.save!
      end

      it "shouldn't have auto expire tokens" do
        expect(DeveloperKey.default.auto_expire_tokens).to be true
      end

      include_examples "#authenticate"
    end

    context "Without auto expire" do
      before :once do
        d = DeveloperKey.default
        d.auto_expire_tokens = false
        d.save!
      end

      it "shouldn't have auto expire tokens" do

        expect(DeveloperKey.default.auto_expire_tokens).to be false
      end

      include_examples "#authenticate"
    end
  end

  context "hashed tokens" do
    before :once do
      @at = AccessToken.create!(:user => user_model, :developer_key => DeveloperKey.default)
      @token_string = @at.full_token
      @refresh_token_string = @at.plaintext_refresh_token
    end

    it "should only store the encrypted token" do
      expect(@token_string).to be_present
      expect(@token_string).not_to eq @at.crypted_token
      expect(AccessToken.find(@at.id).full_token).to be_nil
    end

    it "should authenticate via crypted_token" do
      expect(AccessToken.authenticate(@token_string)).to eq @at
    end

    it "shouldn't auth old tokens after regeneration" do
      expect(AccessToken.authenticate(@token_string)).to eq @at
      @at.regenerate_access_token
      new_token_string = @at.full_token

      expect(new_token_string).to_not eq @token_string
      expect(AccessToken.authenticate(new_token_string)).to eq @at

      expect(AccessToken.authenticate(@token_string)).to_not eq @at
    end

    it "should not authenticate expired tokens" do
      @at.update_attribute(:expires_at, 2.hours.ago)
      expect(AccessToken.authenticate(@token_string)).to be_nil
    end

    it "should authenticate via crypted_refresh_token" do
      expect(AccessToken.authenticate_refresh_token(@refresh_token_string)).to eq @at
    end

    it "should authenticate expired tokens by the refresh token" do
      @at.update_attribute(:expires_at, 2.hours.ago)
      expect(AccessToken.authenticate_refresh_token(@refresh_token_string)).to eq @at
    end
  end

  describe "usable?" do
    before :once do
      @at = AccessToken.create!(:user => user_model, :developer_key => DeveloperKey.default)
      @token_string = @at.full_token
      @refresh_token_string = @at.plaintext_refresh_token
    end

    it "shouldn't be usable without proper fields" do
      token = AccessToken.new
      expect(token.usable?).to eq false
    end

    it "Should be usable" do
      expect(@at.usable?).to eq true
    end

    it "Should be usable without dev key" do
      @at.developer_key_id = nil
      expect(@at.usable?).to eq true
    end

    it "Shouldn't be usable if expired" do
      @at.update_attribute(:expires_at, 2.hours.ago)
      expect(@at.usable?).to eq false
    end

    it "Should be usable if expired, but requesting with a refresh_token" do
      @at.update_attribute(:expires_at, 2.hours.ago)
      expect(@at.usable?(:crypted_refresh_token)).to eq true
    end

    it "Shouldn't be usable if dev key isn't active" do

      dk = DeveloperKey.create!(account: account_model)
      dk.deactivate
      @at.developer_key = dk
      @at.save

      expect(@at.usable?).to eq false
    end

    it "Shouldn't be usable if dev key isn't active, even if we request with a refresh token" do

      dk = DeveloperKey.create!(account: account_model)
      dk.deactivate
      @at.developer_key = dk
      @at.save

      expect(@at.usable?(:crypted_refresh_token)).to eq false
    end
  end

  describe "visible tokens" do
    specs_require_sharding
    it "only displays integrations from non-internal developer keys" do
      user = User.create!
      trustedkey = DeveloperKey.create!(internal_service: true)
      trusted_access_token = user.access_tokens.create!({developer_key: trustedkey})

      untrustedkey = DeveloperKey.create!()
      third_party_access_token = user.access_tokens.create!({developer_key: untrustedkey})

      expect(AccessToken.visible_tokens(user.access_tokens).length).to eq 1
      expect(AccessToken.visible_tokens(user.access_tokens).first.id).to eq third_party_access_token.id
    end

    it "access token and developer key scoping work cross-shard" do
      trustedkey = DeveloperKey.new(internal_service: true)
      untrustedkey = DeveloperKey.new()

      @shard1.activate do
        trustedkey.save!
        untrustedkey.save!
      end

      @shard2.activate do
        user = User.create!
        trusted_access_token = user.access_tokens.create!({developer_key: trustedkey})
        third_party_access_token = user.access_tokens.create!({developer_key: untrustedkey})
        user.save!

        expect(AccessToken.visible_tokens(user.access_tokens).length).to eq 1
        expect(AccessToken.visible_tokens(user.access_tokens).first.id).to eq third_party_access_token.id
      end
    end
  end

  describe "token scopes" do
    let_once(:token) do
      token = AccessToken.new
      token.scopes = %w{https://canvas.instructure.com/login/oauth2/auth/user_profile https://canvas.instructure.com/login/oauth2/auth/accounts}
      token
    end

    it "should match named scopes" do
      expect(token.scoped_to?(['https://canvas.instructure.com/login/oauth2/auth/user_profile', 'accounts'])).to eq true
    end

    it "should not partially match scopes" do
      expect(token.scoped_to?(['user', 'accounts'])).to eq false
      expect(token.scoped_to?(['profile', 'accounts'])).to eq false
    end

    it "should not match if token has more scopes then requested" do
      expect(token.scoped_to?(['user_profile', 'accounts', 'courses'])).to eq false
    end

    it "should not match if token has less scopes then requested" do
      expect(token.scoped_to?(['user_profile'])).to eq false
    end

    it "doesn't expire /auth/userinfo scope, even for auto expiring developer key" do
      dk = DeveloperKey.create!
      expect(dk.auto_expire_tokens).to eq true
      token = AccessToken.create!(developer_key: dk, scopes: ['/auth/userinfo'])
      expect(token.expires_at).to eq nil
    end

    it "does not validate scopes if the workflow state is deleted" do
      dk_scopes = ["url:POST|/api/v1/accounts/:account_id/admins", "url:DELETE|/api/v1/accounts/:account_id/admins/:user_id",  "url:GET|/api/v1/accounts/:account_id/admins"]
      dk = DeveloperKey.create!(scopes: dk_scopes, require_scopes: true)
      token = AccessToken.new(developer_key: dk, scopes: dk_scopes)
      dk.update!(scopes: [])
      expect { token.destroy! }.not_to raise_error
    end
  end

  context "url scopes" do
    let(:token) do
      token = AccessToken.new
      token.scopes = %w{
        blah/scope
        url:GET|/api/v1/accounts
        url:POST|/api/v1/courses
        url:PUT|/api/v1/courses/:id
        url:DELETE|/api/v1/courses/:course_id/assignments/:id
      }
      token
    end

    it "returns regexes that correspond to the http method" do
      expect(token.url_scopes_for_method('GET')).to match_array [/^\/api\/v1\/accounts(?:\.[^\/]+|)$/]
    end

    it "accounts for format segments" do
      token = AccessToken.new(scopes: %w{url:GET|/blah})
      expect(token.url_scopes_for_method('GET')).to match_array [/^\/blah(?:\.[^\/]+|)$/]
    end

    it "accounts for glob segments" do
      token = AccessToken.new(scopes: %w{url:GET|/*blah})
      expect(token.url_scopes_for_method('GET')).to match_array [/^\/.+(?:\.[^\/]+|)$/]
    end

    it "accounts for dynamic segments" do
      token = AccessToken.new(scopes: %w{url:GET|/courses/:id})
      expect(token.url_scopes_for_method('GET')).to match_array [/^\/courses\/[^\/]+(?:\.[^\/]+|)$/]
    end

    it "accounts for optional segments" do
      token = AccessToken.new(scopes: %w{url:GET|/courses(/:course_id)(/*blah)})
      expect(token.url_scopes_for_method('GET')).to match_array [/^\/courses(?:\/[^\/]+|)(?:\/.+|)(?:\.[^\/]+|)$/]
    end
  end

  describe "account scoped access" do

    before :once do
      @ac = account_model
      @sub_ac = @ac.sub_accounts.create!
      @foreign_ac = Account.create!

      @dk = DeveloperKey.create!(account: @ac)
      enable_developer_key_account_binding! @dk
      @at = AccessToken.create!(:user => user_model, :developer_key => @dk)

      @dk_without_account = DeveloperKey.create!
      @at_without_account = AccessToken.create!(:user => user_model, :developer_key => @dk2)
    end

    it "account should be set" do
      expect(@at.account.id).to be @ac.id
    end

    it "account should be authorized" do
      expect(@at.authorized_for_account?(@ac)).to be true
    end

    it "account should be the account from the developer key" do
      expect(@at.account.id).to be @dk.account.id
    end

    it "account should be nil" do
      expect(@at_without_account.account).to be nil
    end

    it "foreign account should not be authorized" do
      expect(@at.authorized_for_account?(@foreign_ac)).to be false
    end

    it "foreign account should not be authorized if there is no account" do
      expect(@at_without_account.authorized_for_account?(@foreign_ac)).to be false
    end

    context 'when the developer key new feature flags are on' do
      let(:root_account) { account_model }
      let(:root_account_key) { DeveloperKey.create!(account: root_account) }
      let(:site_admin_key) { DeveloperKey.create! }
      let(:sub_account) do
        account = account_model
        account.update!(root_account: root_account)
        account
      end

      shared_examples_for 'an access token that honors developer key bindings' do
        let(:access_token) { raise 'set in example' }
        let(:binding) { raise 'set in example' }
        let(:account) { raise 'set in example' }

        it 'authorizes if the binding state is on' do
          binding.update!(workflow_state: 'on')
          expect(access_token.authorized_for_account?(account)).to eq true
        end

        it 'does not authorize if the binding state is off' do
          binding.update!(workflow_state: 'off')
          expect(access_token.authorized_for_account?(account)).to eq false
        end

        it 'does not authorize if the binding state is allow' do
          binding.update!(workflow_state: 'allow')
          expect(access_token.authorized_for_account?(account)).to eq false
        end
      end

      describe 'site admin key' do
        context 'when target account is site admin' do
          it_behaves_like 'an access token that honors developer key bindings' do
            let(:access_token) { AccessToken.create!(user: user_model, developer_key: site_admin_key) }
            let(:binding) { site_admin_key.developer_key_account_bindings.find_by(account: Account.site_admin) }
            let(:account) { Account.site_admin }
          end
        end

        context 'when target account is root account' do
          let(:access_token) { AccessToken.create!(user: user_model, developer_key: site_admin_key) }
          let(:binding) { site_admin_key.developer_key_account_bindings.create!(account: root_account) }

          before do
            site_admin_key.developer_key_account_bindings.find_by(account: Account.site_admin).update!(
              workflow_state: 'allow'
            )
          end

          it_behaves_like 'an access token that honors developer key bindings' do
            let(:access_token) { AccessToken.create!(user: user_model, developer_key: site_admin_key) }
            let(:binding) { site_admin_key.developer_key_account_bindings.create!(account: root_account) }
            let(:account) { root_account }
          end

          it 'does not authorize if the root account binding state is on but site admin off' do
            binding.update!(workflow_state: 'on')
            site_admin_key.developer_key_account_bindings.find_by(account: Account.site_admin).update!(
              workflow_state: 'off'
            )
            expect(access_token.authorized_for_account?(root_account)).to eq false
          end
        end

        context 'when target is a sub account' do
          let(:access_token) { AccessToken.create!(user: user_model, developer_key: site_admin_key) }
          let(:binding) { site_admin_key.developer_key_account_bindings.create!(account: root_account) }

          before do
            site_admin_key.developer_key_account_bindings.find_by(account: Account.site_admin).update!(
              workflow_state: 'allow'
            )
          end

          it_behaves_like 'an access token that honors developer key bindings' do
            let(:access_token) { AccessToken.create!(user: user_model, developer_key: site_admin_key) }
            let(:binding) { site_admin_key.developer_key_account_bindings.create!(account: root_account) }
            let(:account) { sub_account }
          end

          it 'does not authorize if the root account binding state is on but site admin off' do
            binding.update!(workflow_state: 'on')
            site_admin_key.developer_key_account_bindings.find_by(account: Account.site_admin).update!(
              workflow_state: 'off'
            )
            expect(access_token.authorized_for_account?(sub_account)).to eq false
          end
        end
      end

      describe 'root acount key' do
        it_behaves_like 'an access token that honors developer key bindings' do
          let(:access_token) { AccessToken.create!(user: user_model, developer_key: root_account_key) }
          let(:binding) { root_account_key.developer_key_account_bindings.find_by!(account: root_account) }
          let(:account) { root_account }
        end
      end
    end

    describe 'adding scopes' do
      let(:dev_key) { DeveloperKey.create! require_scopes: true, scopes: TokenScopes.all_scopes.slice(0,10)}

      before do
        allow_any_instance_of(Account).to receive(:feature_enabled?).and_return(false)
      end

      it 'is invalid when scopes requested are not included on dev key' do
        access_token = AccessToken.new(user: user_model, developer_key: dev_key, scopes: [TokenScopes.all_scopes[12]])
        expect(access_token).not_to be_valid
      end

      it 'is valid when scopes requested are included on dev key' do
        access_token = AccessToken.new(user: user_model, developer_key: dev_key, scopes: [TokenScopes.all_scopes[8], TokenScopes.all_scopes[7]])
        expect(access_token).to be_valid
      end
    end
  end

  describe "regenerate_access_token" do
    before :once do
      # default developer keys no lponger regenerate expirations
      key = DeveloperKey.create!(:redirect_uri => "http://example.com/a/b")
      @at = AccessToken.create!(:user => user_model, :developer_key => key)
      @token_string = @at.full_token
      @refresh_token_string = @at.plaintext_refresh_token
    end

    it "should regenerate the token" do
      allow(DateTime).to receive(:now).and_return(Time.zone.parse('2015-06-29T23:01:00+00:00'))

      @at.update_attribute(:expires_at, 2.hours.ago)
      @at.regenerate_access_token
      expect(@at.expires_at.to_i).to be((DateTime.now.utc + 1.hour).to_i)
    end
  end

  describe "#dev_key_account_id" do

    it "returns the developer_key account_id" do
      account = Account.create!
      dev_key = DeveloperKey.create!(account: account)
      at = AccessToken.create!(developer_key: dev_key)
      expect(at.dev_key_account_id).to eq account.id
    end

  end

end
