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

module Canvas::OAuth
  describe Token do
    let(:code) { "code123code" }
    let(:key) { DeveloperKey.create! }
    let(:user) { User.create! }
    let(:token) { Token.new(key, code) }

    def stub_out_cache(client_id = nil, scopes = nil)
      if client_id
        allow(token).to receive_messages(cached_code_entry: '{"client_id": ' + client_id.to_s +
                        ', "user": ' + user.id.to_s +
                        (scopes ? ', "scopes": ' + scopes.to_json : "") + "}")
      else
        allow(token).to receive_messages(cached_code_entry: "{}")
      end
    end

    before { stub_out_cache key.id }

    describe "initialization" do
      it "retains the key" do
        expect(token.key).to eq key
      end

      it "retains the code" do
        expect(token.code).to eq code
      end
    end

    describe "#is_for_valid_code?" do
      it "is false when there is no code data" do
        stub_out_cache
        expect(token.is_for_valid_code?).to be_falsey
      end

      it "is true otherwise" do
        expect(token.is_for_valid_code?).to be_truthy
      end
    end

    describe "#client_id" do
      it "delegates to the parsed json" do
        expect(token.client_id).to eq key.id
      end

      it "is nil when there is no cached entry" do
        stub_out_cache
        expect(token.client_id).to be_nil
      end
    end

    describe "#user" do
      it "uses the user_id from the redis entry to load a user" do
        expect(token.user).to eq user
      end
    end

    describe "#code_data" do
      it "parses the json from the cache" do
        hash = token.code_data
        expect(hash["client_id"]).to eq key.id
        expect(hash["user"]).to eq user.id
      end
    end

    describe "#access_token" do
      let(:scopes) { ["#{TokenScopes::OAUTH2_SCOPE_NAMESPACE}userinfo"] }

      it "creates a new token if none exists" do
        expect(user.access_tokens).to be_empty
        expect(token.access_token).to be_a AccessToken
        expect(user.access_tokens.reload.size).to eq 1
        expect(token.access_token.full_token).not_to be_empty
        expect(token.access_token.permanent_expires_at).to be_nil
      end

      it "creates a scoped access token" do
        stub_out_cache key.id, scopes
        expect(token.access_token).to be_scoped_to scopes
      end

      it "creates a new token if the scopes do not match" do
        access_token = user.access_tokens.create!(developer_key: key, scopes:)
        expect(token.access_token).to be_a AccessToken
        expect(token.access_token).not_to eq access_token
      end

      it "will not return the full token for a userinfo scope" do
        scope = "#{TokenScopes::OAUTH2_SCOPE_NAMESPACE}userinfo"
        stub_out_cache key.id, [scope]
        expect(token.access_token.full_token).to be_nil
      end

      it "finds an existing userinfo token if one exists" do
        scope = "#{TokenScopes::OAUTH2_SCOPE_NAMESPACE}userinfo"
        stub_out_cache key.id, [scope]
        access_token = user.access_tokens.create!(developer_key: key, scopes: [scope], remember_access: true)
        expect(token.access_token).to eq access_token
        expect(token.access_token.full_token).to be_nil
      end

      it "ignores existing token if user did not remember access" do
        scope = "#{TokenScopes::OAUTH2_SCOPE_NAMESPACE}userinfo"
        stub_out_cache key.id, [scope]
        access_token = user.access_tokens.create!(developer_key: key, scopes: [scope])
        expect(token.access_token).not_to eq access_token
        expect(token.access_token.full_token).to be_nil
      end

      it "ignores existing tokens by default" do
        stub_out_cache key.id, scopes
        access_token = user.access_tokens.create!(developer_key: key, scopes:)
        expect(token.access_token).to be_a AccessToken
        expect(token.access_token).not_to eq access_token
      end

      it "sets token to expire if the key is set to expire" do
        allow(key).to receive(:mobile_app?).and_return(true)
        allow(Canvas::Plugin).to receive(:find).with("sessions").and_return(double(settings: { mobile_timeout: 30 }))
        expect(token.access_token.permanent_expires_at).not_to be_nil
      end
    end

    describe "#create_access_token_if_needed" do
      it "deletes existing tokens for the same key when requested" do
        old_token = user.access_tokens.create! developer_key: key
        token.create_access_token_if_needed(true)
        expect(AccessToken.not_deleted.where(id: old_token.id).exists?).to be(false)
      end

      it "does not delete existing tokens for the same key when not requested" do
        old_token = user.access_tokens.create! developer_key: key
        token.create_access_token_if_needed
        expect(AccessToken.not_deleted.where(id: old_token.id).exists?).to be(true)
      end
    end

    describe ".find_access_token" do
      specs_require_sharding
      let_once(:scopes) { ["url:POST|/api/v1/inst_access_tokens"] }
      let_once(:purpose) { "inst_access_tokens" }

      before do
        Shard.default.activate do
          @dev_key = DeveloperKey.create!(scopes:)
        end
        @shard1.activate do
          @user = User.create!
          Shard.default.activate { user.save_shadow_record }
          @user.access_tokens.create!(developer_key_id: @dev_key.global_id, scopes:, purpose:)
        end
      end

      it "finds the user's access token" do
        access_token = token.class.find_access_token(@user, @dev_key, scopes, purpose)
        expect(access_token).to be_a AccessToken
      end

      it "returns nil if token isn't found" do
        @user.access_tokens.destroy_all
        access_token = token.class.find_access_token(@user, @dev_key.reload, scopes, purpose)
        expect(access_token).to be_nil
      end
    end

    describe "#as_json" do
      let(:json) { token.as_json }

      it "includes the access token" do
        expect(json["access_token"]).to be_a String
        expect(json["access_token"]).not_to be_empty
      end

      it "includes the refresh token" do
        expect(json["refresh_token"]).to be_a String
        expect(json["refresh_token"]).not_to be_empty
      end

      it "ignores refresh token if its not there" do
        # need to re-fetch the access token so refresh token wont be set
        access_token = AccessToken.authenticate(json["access_token"])
        # setup new token with existing access token
        new_token = Token.new(token.key, token.code, access_token)
        expect(new_token.as_json.keys).to_not include "refresh_token"
      end

      it "grabs the user json as well" do
        expect(json["user"]).to eq({
                                     "id" => user.id,
                                     "name" => user.name,
                                     "global_id" => user.global_id.to_s,
                                     "effective_locale" => "en"
                                   })
      end

      it "returns the expires_in parameter" do
        allow(Time).to receive(:now).and_return(DateTime.parse("2015-07-10T09:29:00Z").utc.to_time)
        access_token = token.access_token
        access_token.expires_at = DateTime.parse("2015-07-10T10:29:00Z")
        access_token.save!
        expect(json["expires_in"]).to eq 3600
      end

      it "does not put anything else into the json" do
        expect(json.keys.sort).to match_array(%w[access_token refresh_token user expires_in token_type canvas_region])
      end

      it "does not put expires_in in the json when auto_expire_tokens is false" do
        key = token.key
        key.auto_expire_tokens = false
        key.save!
        expect(json.keys.sort).to match_array(%w[access_token refresh_token user token_type canvas_region])
      end

      it "puts real_user in the json when masquerading" do
        real_user = User.create!
        allow(token).to receive(:real_user).and_return(real_user)
        expect(json["real_user"]).to eq({
                                          "id" => real_user.id,
                                          "name" => real_user.name,
                                          "global_id" => real_user.global_id.to_s
                                        })
        expect(user.access_tokens.where(real_user:).count).to eq 1
      end

      it "does not put real_user in the json when not masquerading" do
        expect(json["real_user"]).to be_nil
      end

      context "when region is configured" do
        let(:region) { "us-east-1" }

        before do
          allow(Shard.current.database_server).to receive(:config).and_return({ region: })
        end

        it "includes aws region" do
          expect(json["canvas_region"]).to eq region
        end
      end

      context "when region is absent" do
        it "uses default value" do
          expect(json["canvas_region"]).to eq "unknown"
        end
      end
    end

    describe ".generate_code_for" do
      let(:code) { "brand_new_code" }

      before { allow(SecureRandom).to receive_messages(hex: code) }

      it "returns the new code" do
        allow(Canvas).to receive_messages(redis: double(setex: true))
        expect(Token.generate_code_for(1, 2, 3)).to eq code
      end

      it "sets the new data hash into redis with 10 min ttl" do
        redis = Object.new
        code_data = { user: 1, real_user: 2, client_id: 3, scopes: nil, purpose: nil, remember_access: nil }
        # should have 10 min (in seconds) ttl passed as second param
        expect(redis).to receive(:setex).with("oauth2:brand_new_code", 600, code_data.to_json)
        allow(Canvas).to receive_messages(redis:)
        Token.generate_code_for(1, 2, 3)
      end
    end

    context "token expiration" do
      it "starts expiring tokens in 1 hour" do
        allow(Time).to receive(:now).and_return(Time.zone.parse("2016-06-29T23:01:00Z"))
        expect(token.access_token.expires_at.utc).to eq(Time.zone.parse("2016-06-30T00:01:00Z"))
      end

      it "doesn't set an expiration if the dev key has auto_expire_tokens set to false" do
        key = token.key
        key.auto_expire_tokens = false
        key.save!
        expect(token.access_token.expires_at).to be_nil
      end

      it "gives short expiration for real_users" do
        real_user = User.create!
        token2 = Token.new(key, "real_user_code")
        allow(token2).to receive(:real_user).and_return(real_user)
        expect(token.access_token.expires_at).to be <= 1.hour.from_now
      end

      it "Tokens wont expire if the dev key has auto_expire_tokens set to false" do
        allow(Time).to receive(:now).and_return(Time.zone.parse("2015-06-29T23:01:00Z"))
        key = token.key
        key.auto_expire_tokens = false
        key.save!
        expect(token.access_token.expires_at).to be_nil
        expect(token.access_token.expired?).to be false
      end
    end
  end
end
