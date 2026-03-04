# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "../../spec_helper"

module Services
  describe Athena do
    before do
      Athena.instance_variable_set(:@config, nil)

      allow(DynamicSettings).to receive(:find).with(any_args).and_call_original
      allow(DynamicSettings).to receive(:find)
        .with(tree: :private)
        .and_return(DynamicSettings::FallbackProxy.new({
                                                         "athena.yml" => {
                                                           "oauth_client_id" => "10000000000001"
                                                         }.to_yaml
                                                       }))
    end

    describe ".developer_key" do
      it "returns nil when settings are unavailable" do
        Athena.instance_variable_set(:@config, nil)
        allow(DynamicSettings).to receive(:find)
          .with(tree: :private)
          .and_return(DynamicSettings::FallbackProxy.new({ "athena.yml" => nil }))

        expect(Athena.developer_key).to be_nil
      end

      it "returns nil when client_id is blank" do
        Athena.instance_variable_set(:@config, nil)
        allow(DynamicSettings).to receive(:find)
          .with(tree: :private)
          .and_return(DynamicSettings::FallbackProxy.new({
                                                           "athena.yml" => { "oauth_client_id" => "" }.to_yaml
                                                         }))

        expect(Athena.developer_key).to be_nil
      end

      it "returns nil when the key is not found" do
        allow(DeveloperKey).to receive(:find_cached).and_raise(ActiveRecord::RecordNotFound)
        expect(Athena.developer_key).to be_nil
      end

      it "returns the developer key when configured" do
        key = DeveloperKey.create!
        allow(DeveloperKey).to receive(:find_cached).with("10000000000001").and_return(key)
        expect(Athena.developer_key).to eq(key)
      end
    end

    describe ".public_app_config" do
      it "returns a hash with authenticated, launch_domain, and launch_path" do
        allow(Athena).to receive(:user_authenticated?).with(nil).and_return(false)
        allow(Athena).to receive_messages(launch_domain: "athena.example.com", launch_path: "/agent")

        expect(Athena.public_app_config(nil)).to eq({
                                                      authenticated: false,
                                                      launch_domain: "athena.example.com",
                                                      launch_path: "/agent"
                                                    })
      end
    end

    describe ".user_authenticated?" do
      it "returns false when user is nil" do
        expect(Athena.user_authenticated?(nil)).to be false
      end

      it "returns false when no developer key is configured" do
        allow(Athena).to receive(:developer_key).and_return(nil)
        user = instance_double(User)
        expect(Athena.user_authenticated?(user)).to be false
      end

      it "returns false when user has no active token for the key" do
        key = DeveloperKey.create!
        allow(Athena).to receive(:developer_key).and_return(key)
        user = user_model
        expect(Athena.user_authenticated?(user)).to be false
      end

      it "returns true when user has an active token for the key" do
        key = DeveloperKey.create!
        allow(Athena).to receive(:developer_key).and_return(key)
        user = user_model
        user.access_tokens.create!(developer_key: key, purpose: "test")
        expect(Athena.user_authenticated?(user)).to be true
      end
    end
  end
end
