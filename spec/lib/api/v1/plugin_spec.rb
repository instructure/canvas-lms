# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe Api::V1::Plugin do
  describe "#plugin_json" do
    subject(:fake_controller) do
      Class.new do
        include Api::V1::Plugin
      end.new
    end

    let_once(:user) { account_admin_user(account: Account.site_admin, active_all: true) }

    let_once(:encrypted_settings) { %w[shhh tell_no_one keep_it_secret] }

    let_once(:plugin) { Canvas::Plugin.register("test_plugin", nil, { encrypted_settings: }) }

    let(:session) { {} }

    let(:created_at) { Time.new(2024, 5, 15, 20, 0, 0).utc }

    let(:updated_at) { Time.new(2024, 5, 15, 20, 0, 0).utc }

    let_once(:plugin_setting) do
      PluginSetting.new(name: plugin.id,
                        disabled: false,
                        created_at:,
                        updated_at:,
                        settings: {
                          domain: "example.com",
                          rando: "setting",
                          taco: "mcgibblets",
                          shhh: "secret",
                          shhh_dec: "decrypted",
                          shhh_salt: "salted",
                          tell_no_one: "another secret",
                          keep_it_secret: "keep it safe",
                        })
    end

    it "returns a valid json result" do
      expect(fake_controller.plugin_json(plugin, plugin_setting, user, session)).to eq(
        {
          "id" => "test_plugin",
          "settings" => { "domain" => "example.com", "rando" => "setting", "taco" => "mcgibblets" },
          "plugin_setting" => { "disabled" => false },
          "created_at" => created_at.iso8601,
          "updated_at" => updated_at.iso8601
        }
      )
    end

    it "does not include encrypted settings" do
      result = fake_controller.plugin_json(plugin, plugin_setting, user, session)
      expect(result).not_to include(encrypted_settings + %w[shhh_dec shhh_salt])
    end
  end
end
