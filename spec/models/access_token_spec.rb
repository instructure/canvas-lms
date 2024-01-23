# frozen_string_literal: true

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

describe AccessToken do
  context "Authenticate" do
    shared_examples "#authenticate" do
      it "new access tokens shouldnt have an expiration" do
        at = AccessToken.create!(user: user_model, developer_key: @dk)
        expect(at.permanent_expires_at).to be_nil
      end

      it "authenticates valid token" do
        at = AccessToken.create!(user: user_model, developer_key: @dk)
        expect(AccessToken.authenticate(at.full_token)).to eq at
      end

      it "does not authenticate expired tokens" do
        at = AccessToken.create!(
          user: user_model,
          developer_key: @dk,
          permanent_expires_at: 2.hours.ago
        )
        expect(AccessToken.authenticate(at.full_token)).to be_nil
      end
    end

    context "With auto expire" do
      before :once do
        @dk = DeveloperKey.create!
      end

      it "does not have auto expire tokens" do
        expect(DeveloperKey.default.auto_expire_tokens).to be true
      end

      include_examples "#authenticate"
    end

    context "Without auto expire" do
      before :once do
        @dk = DeveloperKey.create!
        @dk.auto_expire_tokens = false
        @dk.save!
      end

      it "does not have auto expire tokens" do
        expect(@dk.auto_expire_tokens).to be false
      end

      include_examples "#authenticate"
    end

    context "when an access token argument is provided" do
      subject { AccessToken.authenticate(token.full_token, AccessToken::TOKEN_TYPES.crypted_token, token) }

      let(:token) { AccessToken.create!(user: user_model) }
      let(:user) { user_model }

      shared_examples_for "contexts with a provided access token" do
        it "does not query the DB for an access token" do
          expect(AccessToken).not_to receive(:not_deleted)
          subject
        end
      end

      context "and the token is valid" do
        it_behaves_like "contexts with a provided access token"

        it { is_expected.to eq token }
      end

      context "and the token is invalid" do
        before { token.update!(permanent_expires_at: 1.hour.ago) }

        it_behaves_like "contexts with a provided access token"

        it { is_expected.to be_nil }
      end

      context "and the token is using an old hash" do
        before { token.update_columns(crypted_token: "old-hashed-token") }

        it_behaves_like "contexts with a provided access token"

        it "persists the re-hashed token" do
          expect { subject }.to change { token.reload.crypted_token }.from(
            "old-hashed-token"
          ).to(
            CanvasSecurity.hmac_sha1(token.full_token.split("~").last)
          )
        end
      end
    end
  end

  context "hashed tokens" do
    before :once do
      @at = AccessToken.create!(user: user_model, developer_key: DeveloperKey.default)
      @token_string = @at.full_token
      @refresh_token_string = @at.plaintext_refresh_token
    end

    it "only stores the encrypted token" do
      expect(@token_string).to be_present
      expect(@token_string).not_to eq @at.crypted_token
      expect(AccessToken.find(@at.id).full_token).to be_nil
    end

    it "authenticates via crypted_token" do
      expect(AccessToken.authenticate(@token_string)).to eq @at
    end

    it "does not auth old tokens after regeneration" do
      expect(AccessToken.authenticate(@token_string)).to eq @at
      @at.regenerate_access_token
      new_token_string = @at.full_token

      expect(new_token_string).to_not eq @token_string
      expect(AccessToken.authenticate(new_token_string)).to eq @at

      expect(AccessToken.authenticate(@token_string)).to_not eq @at
    end

    it "does not authenticate expired tokens" do
      @at.update!(permanent_expires_at: 2.hours.ago)
      expect(AccessToken.authenticate(@token_string)).to be_nil
    end

    it "authenticates via crypted_refresh_token" do
      expect(AccessToken.authenticate_refresh_token(@refresh_token_string)).to eq @at
    end

    it "authenticates expired tokens by the refresh token" do
      @at.update!(expires_at: 2.hours.ago)
      expect(AccessToken.authenticate_refresh_token(@refresh_token_string)).to eq @at
    end
  end

  describe "usable?" do
    before :once do
      @at = AccessToken.create!(user: user_model, developer_key: DeveloperKey.default)
      @token_string = @at.full_token
      @refresh_token_string = @at.plaintext_refresh_token
    end

    it "is not usable without proper fields" do
      token = AccessToken.new
      expect(token.usable?).to be false
    end

    it "is usable" do
      expect(@at.usable?).to be true
    end

    it "is usable without dev key" do
      @at.developer_key_id = nil
      expect(@at.usable?).to be true
    end

    it "is not usable if expired" do
      @at.update!(permanent_expires_at: 2.hours.ago)
      expect(@at.usable?).to be false
    end

    it "is not usable if it needs refreshed" do
      @at.update!(expires_at: 2.hours.ago)
      expect(@at.usable?).to be false
    end

    it "is usable if it needs refreshed but dev key doesn't require it" do
      dk = DeveloperKey.create!
      dk.update!(auto_expire_tokens: false)
      @at.update!(developer_key: dk, expires_at: 2.hours.ago)
      expect(@at.usable?).to be true
    end

    it "is usable if it needs refreshed, but requesting with a refresh_token" do
      @at.update!(expires_at: 2.hours.ago)
      expect(@at.usable?(:crypted_refresh_token)).to be true
    end

    it "is not usable if dev key isn't active" do
      dk = DeveloperKey.create!(account: account_model)
      dk.deactivate
      @at.developer_key = dk
      @at.save

      expect(@at.reload.usable?).to be false
    end

    it "is not usable if dev key isn't active, even if we request with a refresh token" do
      dk = DeveloperKey.create!(account: account_model)
      dk.deactivate
      @at.developer_key = dk
      @at.save

      expect(@at.reload.usable?(:crypted_refresh_token)).to be false
    end
  end

  describe "visible tokens" do
    specs_require_sharding
    it "only displays integrations from non-internal developer keys" do
      user = User.create!
      trustedkey = DeveloperKey.create!(internal_service: true)
      user.access_tokens.create!({ developer_key: trustedkey })

      untrustedkey = DeveloperKey.create!
      third_party_access_token = user.access_tokens.create!({ developer_key: untrustedkey })

      expect(AccessToken.visible_tokens(user.access_tokens).length).to eq 1
      expect(AccessToken.visible_tokens(user.access_tokens).first.id).to eq third_party_access_token.id
    end

    it "access token and developer key scoping work cross-shard" do
      trustedkey = DeveloperKey.new(internal_service: true)
      untrustedkey = DeveloperKey.new

      @shard1.activate do
        trustedkey.save!
        untrustedkey.save!
      end

      @shard2.activate do
        user = User.create!
        user.access_tokens.create!({ developer_key: trustedkey })
        third_party_access_token = user.access_tokens.create!({ developer_key: untrustedkey })
        user.save!

        expect(AccessToken.visible_tokens(user.access_tokens).length).to eq 1
        expect(AccessToken.visible_tokens(user.access_tokens).first.id).to eq third_party_access_token.id
      end
    end

    it "does not display duplicate tokens" do
      token = user_model.access_tokens.create!({ developer_key: @dk })
      visible_tokens = AccessToken.visible_tokens([token, token])

      expect(visible_tokens).to be_one
      expect(visible_tokens.first).to eq token
    end
  end

  describe "token scopes" do
    let_once(:token) do
      token = AccessToken.new
      token.scopes = %w[https://canvas.instructure.com/login/oauth2/auth/user_profile https://canvas.instructure.com/login/oauth2/auth/accounts]
      token
    end

    it "matches named scopes" do
      expect(token.scoped_to?(["https://canvas.instructure.com/login/oauth2/auth/user_profile", "accounts"])).to be true
    end

    it "does not partially match scopes" do
      expect(token.scoped_to?(["user", "accounts"])).to be false
      expect(token.scoped_to?(["profile", "accounts"])).to be false
    end

    it "does not match if token has more scopes then requested" do
      expect(token.scoped_to?(%w[user_profile accounts courses])).to be false
    end

    it "does not match if token has less scopes then requested" do
      expect(token.scoped_to?(["user_profile"])).to be false
    end

    it "does not validate scopes if the workflow state is deleted" do
      dk_scopes = ["url:POST|/api/v1/accounts/:account_id/admins", "url:DELETE|/api/v1/accounts/:account_id/admins/:user_id", "url:GET|/api/v1/accounts/:account_id/admins"]
      dk = DeveloperKey.create!(scopes: dk_scopes, require_scopes: true)
      token = AccessToken.new(developer_key: dk, scopes: dk_scopes)
      dk.update!(scopes: [])
      expect { token.destroy! }.not_to raise_error
    end
  end

  context "url scopes" do
    let(:token) do
      token = AccessToken.new
      token.scopes = %w[
        blah/scope
        url:GET|/api/v1/accounts
        url:POST|/api/v1/courses
        url:PUT|/api/v1/courses/:id
        url:DELETE|/api/v1/courses/:course_id/assignments/:id
      ]
      token
    end

    it "returns regexes that correspond to the http method" do
      expect(token.url_scopes_for_method("GET")).to match_array [%r{^/api/v1/accounts(?:\.[^/]+|)$}]
    end

    it "accounts for format segments" do
      token = AccessToken.new(scopes: %w[url:GET|/blah])
      expect(token.url_scopes_for_method("GET")).to match_array [%r{^/blah(?:\.[^/]+|)$}]
    end

    it "accounts for glob segments" do
      token = AccessToken.new(scopes: %w[url:GET|/*blah])
      expect(token.url_scopes_for_method("GET")).to match_array [%r{^/.+(?:\.[^/]+|)$}]
    end

    it "accounts for dynamic segments" do
      token = AccessToken.new(scopes: %w[url:GET|/courses/:id])
      expect(token.url_scopes_for_method("GET")).to match_array [%r{^/courses/[^/]+(?:\.[^/]+|)$}]
    end

    it "accounts for optional segments" do
      token = AccessToken.new(scopes: %w[url:GET|/courses(/:course_id)(/*blah)])
      expect(token.url_scopes_for_method("GET")).to match_array [%r{^/courses(?:/[^/]+|)(?:/.+|)(?:\.[^/]+|)$}]
    end
  end

  describe "account scoped access" do
    before :once do
      @ac = account_model
      @sub_ac = @ac.sub_accounts.create!
      @foreign_ac = Account.create!

      @dk = DeveloperKey.create!(account: @ac)
      enable_developer_key_account_binding! @dk
      @at = AccessToken.create!(user: user_model, developer_key: @dk)

      @dk_without_account = DeveloperKey.create!
      @at_without_account = AccessToken.create!(user: user_model, developer_key: @dk2)
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
      expect(@at_without_account.account).to be_nil
    end

    it "foreign account should not be authorized" do
      expect(@at.authorized_for_account?(@foreign_ac)).to be false
    end

    it "foreign account should not be authorized if there is no account" do
      expect(@at_without_account.authorized_for_account?(@foreign_ac)).to be false
    end

    context "when the developer key new feature flags are on" do
      let(:root_account) { account_model }
      let(:root_account_key) { DeveloperKey.create!(account: root_account) }
      let(:site_admin_key) { DeveloperKey.create! }
      let(:sub_account) do
        account = account_model(root_account:)
        account
      end

      shared_examples_for "an access token that honors developer key bindings" do
        let(:access_token) { raise "set in example" }
        let(:binding) { raise "set in example" }
        let(:account) { raise "set in example" }

        it "authorizes if the binding state is on" do
          binding.update!(workflow_state: "on")
          expect(access_token.authorized_for_account?(account)).to be true
        end

        it "does not authorize if the binding state is off" do
          binding.update!(workflow_state: "off")
          expect(access_token.authorized_for_account?(account)).to be false
        end

        it "does not authorize if the binding state is allow" do
          binding.update!(workflow_state: "allow")
          expect(access_token.authorized_for_account?(account)).to be false
        end
      end

      describe "site admin key" do
        context "when target account is site admin" do
          it_behaves_like "an access token that honors developer key bindings" do
            let(:access_token) { AccessToken.create!(user: user_model, developer_key: site_admin_key) }
            let(:binding) { site_admin_key.developer_key_account_bindings.find_by(account: Account.site_admin) }
            let(:account) { Account.site_admin }
          end
        end

        context "when target account is root account" do
          let(:access_token) { AccessToken.create!(user: user_model, developer_key: site_admin_key) }
          let(:binding) { site_admin_key.developer_key_account_bindings.create!(account: root_account) }

          before do
            site_admin_key.developer_key_account_bindings.find_by(account: Account.site_admin).update!(
              workflow_state: "allow"
            )
          end

          it_behaves_like "an access token that honors developer key bindings" do
            let(:access_token) { AccessToken.create!(user: user_model, developer_key: site_admin_key) }
            let(:binding) { site_admin_key.developer_key_account_bindings.create!(account: root_account) }
            let(:account) { root_account }
          end

          it "does not authorize if the root account binding state is on but site admin off" do
            binding.update!(workflow_state: "on")
            site_admin_key.developer_key_account_bindings.find_by(account: Account.site_admin).update!(
              workflow_state: "off"
            )
            expect(access_token.authorized_for_account?(root_account)).to be false
          end
        end

        context "when target is a sub account" do
          let(:access_token) { AccessToken.create!(user: user_model, developer_key: site_admin_key) }
          let(:binding) { site_admin_key.developer_key_account_bindings.create!(account: root_account) }

          before do
            site_admin_key.developer_key_account_bindings.find_by(account: Account.site_admin).update!(
              workflow_state: "allow"
            )
          end

          it_behaves_like "an access token that honors developer key bindings" do
            let(:access_token) { AccessToken.create!(user: user_model, developer_key: site_admin_key) }
            let(:binding) { site_admin_key.developer_key_account_bindings.create!(account: root_account) }
            let(:account) { sub_account }
          end

          it "does not authorize if the root account binding state is on but site admin off" do
            binding.update!(workflow_state: "on")
            site_admin_key.developer_key_account_bindings.find_by(account: Account.site_admin).update!(
              workflow_state: "off"
            )
            expect(access_token.authorized_for_account?(sub_account)).to be false
          end
        end
      end

      describe "root acount key" do
        it_behaves_like "an access token that honors developer key bindings" do
          let(:access_token) { AccessToken.create!(user: user_model, developer_key: root_account_key) }
          let(:binding) { root_account_key.developer_key_account_bindings.find_by!(account: root_account) }
          let(:account) { root_account }
        end
      end
    end

    describe "adding scopes" do
      let(:dev_key) { DeveloperKey.create! require_scopes: true, scopes: TokenScopes.all_scopes.slice(0, 10) }
      let(:access_token) { AccessToken.new(user: user_model, developer_key: dev_key, scopes:) }
      let(:scopes) { [TokenScopes.all_scopes[12]] }

      before do
        allow_any_instance_of(Account).to receive(:feature_enabled?).and_return(false)
      end

      it "is invalid when scopes requested are not included on dev key" do
        expect(access_token).not_to be_valid
      end

      context do
        let(:scopes) { [TokenScopes.all_scopes[8], TokenScopes.all_scopes[7]] }

        it "is valid when scopes requested are included on dev key" do
          expect(access_token).to be_valid
        end
      end

      context "with bad scopes" do
        let(:scopes) { ["bad/scope"] }

        it "is invalid" do
          expect(access_token).not_to be_valid
        end

        context "with require_scopes off" do
          before do
            dev_key.update! require_scopes: false
          end

          it "is valid" do
            expect(access_token).to be_valid
          end
        end
      end
    end
  end

  describe "regenerate_access_token" do
    before :once do
      # default developer keys no longer regenerate expirations
      key = DeveloperKey.create!(redirect_uri: "http://example.com/a/b")
      @at = AccessToken.create!(user: user_model, developer_key: key)
      @token_string = @at.full_token
      @refresh_token_string = @at.plaintext_refresh_token
    end

    it "regenerates the token" do
      allow(Time).to receive(:now).and_return(Time.zone.parse("2015-06-29T23:01:00+00:00"))

      @at.update!(expires_at: 2.hours.ago)
      @at.regenerate_access_token
      expect(@at.expires_at.to_i).to be((Time.now.utc + 1.hour).to_i)
    end
  end

  describe "#dev_key_account_id" do
    it "returns the developer_key account_id" do
      account = Account.create!
      dev_key = DeveloperKey.create!(account:)
      at = AccessToken.create!(developer_key: dev_key)
      expect(at.dev_key_account_id).to eq account.id
    end
  end

  context "broadcast policy" do
    before(:once) do
      Notification.create!(name: "Manually Created Access Token Created")
      user_model
    end

    it "sends a notification when a new manually created access token is created" do
      access_token = AccessToken.create!(user: @user)
      expect(access_token.messages_sent).to include("Manually Created Access Token Created")
    end

    it "sends a notification when a manually created access token is regenerated" do
      AccessToken.create!(user: @user)
      access_token = AccessToken.last
      access_token.regenerate_access_token
      expect(access_token.messages_sent).to include("Manually Created Access Token Created")
    end

    it "does not send a notification when a manually created access token is touched" do
      AccessToken.create!(user: @user)
      access_token = AccessToken.last
      access_token.touch
      expect(access_token.messages_sent).not_to include("Manually Created Access Token Created")
    end

    it "does not send a notification when a new non-manually created access token is created" do
      developer_key = DeveloperKey.create!
      access_token = AccessToken.create!(user: @user, developer_key:)
      expect(access_token.messages_sent).not_to include("Manually Created Access Token Created")
    end
  end

  describe "root_account_id" do
    let(:root_account) { account_model }
    let(:sub_account) { root_account.sub_accounts.create! name: "sub" }
    let(:root_account_key) { DeveloperKey.create!(account: root_account) }
    let(:site_admin_key) { DeveloperKey.create! }

    it "uses root_account value from developer key association" do
      at = AccessToken.create!(user: user_model, developer_key: root_account_key)
      expect(at.root_account_id).to eq(root_account_key.root_account_id)
    end

    it "inherits root_account value from siteadmin context" do
      at = AccessToken.create!(user: user_model, developer_key: site_admin_key)
      expect(at.root_account_id).to eq Account.site_admin.id
    end

    it "keeps set value if it already exists" do
      at = AccessToken.create!(
        user: user_model,
        developer_key: root_account_key,
        root_account_id: sub_account.id
      )
      expect(at.root_account_id).to eq(sub_account.id)
    end
  end

  describe "valid?" do
    it "validates character length maximum (255) for purpose column" do
      lorem_ipsum = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod
      tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud
      exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure
      dolor in reprehenderit."
      at = AccessToken.new user: user_model, developer_key: DeveloperKey.default
      expect(at.save).to be true
      expect(at.update(purpose: lorem_ipsum)).to be false
    end
  end

  describe "#site_admin?" do
    specs_require_sharding
    let(:account) { account_model }
    let(:access_token) { AccessToken.create!(user: user_model, developer_key: DeveloperKey.create!(account:)) }

    it "authenticates access token and calls #site_admin?" do
      expect(AccessToken).to receive(:authenticate).and_return(access_token)
      expect(access_token).to receive(:site_admin?)

      AccessToken.site_admin?("token-string")
    end

    it "normally returns false" do
      @shard2.activate do
        expect(access_token.site_admin?).to be false
      end
    end

    context "when access token is for site admin" do
      let(:account) { Account.site_admin }

      it "returns true" do
        expect(access_token.site_admin?).to be true
      end
    end
  end

  describe "#used!" do
    let_once(:access_token) { AccessToken.create!(user: user_model, developer_key: DeveloperKey.default) }

    it "updates last_used_at when not set yet" do
      access_token.used!
      expect(access_token.last_used_at).not_to be_nil
      expect(access_token).not_to be_changed
    end

    it "does not update last_used_at within the threshold" do
      access_token.used!
      last_used = access_token.last_used_at
      access_token.used!
      expect(access_token.last_used_at).to eq last_used
    end

    it "updates last used after the threshold" do
      access_token.used!
      last_used = access_token.last_used_at
      Timecop.travel(20.minutes) { access_token.used! }
      expect(access_token.last_used_at).not_to eq last_used
    end

    context "when out-of-region" do
      before do
        allow(access_token.shard).to receive(:in_current_region?).and_return(false)
        allow(Rails.env).to receive(:production?).and_return(true)
      end

      it "simply queues a job" do
        expect(access_token).to receive(:delay).and_call_original
        access_token.used!
        expect(access_token.last_used_at).to be_nil
      end

      it "updates immediately if already in a job" do
        allow(Delayed::Job).to receive(:in_delayed_job?).and_return(true)
        expect(access_token).not_to receive(:delay)
        access_token.used!
        expect(access_token.last_used_at).not_to be_nil
      end
    end

    it "uses save! if there are other changes" do
      access_token.created_at = 1.day.ago
      expect(access_token).to receive(:save!).and_call_original
      access_token.used!
      expect(access_token.last_used_at).not_to be_nil
      expect(access_token).not_to be_changed
    end

    it "skips the update if someone else has changed it" do
      access_token.used!
      Timecop.travel(20.minutes) do
        AccessToken.where(id: access_token).update_all(last_used_at: 1.day.ago)
        expect(access_token).not_to receive(:save!)
        expect(AccessToken).to receive(:where).twice.and_call_original
        access_token.used!
        expect(access_token).to be_changed
      end
    end

    it "normally uses a custom query to skip locks" do
      expect(access_token).not_to receive(:save!)
      expect(AccessToken).to receive(:where).twice.and_call_original
      access_token.used!
      expect(access_token).not_to be_changed
    end
  end

  describe "#queue_developer_key_token_count_increment" do
    let(:dk) { DeveloperKey.create!(account: account_model) }
    let(:access_token) { AccessToken.create!(user: user_model, developer_key: dk) }

    it "increments the developer key token count" do
      access_token = AccessToken.new(user: user_model, developer_key: dk)
      expect { access_token.queue_developer_key_token_count_increment }.to change { dk.reload.access_token_count }.by(1)
    end

    it "is called as an after create hook" do
      access_token = AccessToken.new(user: user_model, developer_key: dk)
      expect(access_token).to receive(:queue_developer_key_token_count_increment).and_call_original
      expect do
        access_token.save!
      end.to change { dk.reload.access_token_count }.by(1)
    end

    it "enqueues using a strand that depends on global developer key id" do
      expect(DeveloperKey).to \
        receive(:delay_if_production)
        .with(strand: "developer_key_token_count_increment_#{dk.id}")
        .and_call_original
      access_token
    end

    describe "in a sharded environment" do
      specs_require_sharding

      let(:dk) { @shard1.activate { DeveloperKey.create!(account: account_model) } }

      it "increments the developer key token count in the correct shard" do
        @shard2.activate do
          expect { AccessToken.create!(user: user_model, developer_key: dk) }.to \
            change { dk.reload.access_token_count }.by(1)
        end
      end
    end
  end
end
