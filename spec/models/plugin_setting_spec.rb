# frozen_string_literal: true

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

describe PluginSetting do
  before(:all) do
    Canvas::Plugin.register("plugin_setting_test", nil, { encrypted_settings: [:foo], settings: { bar: "asdf" } })
  end

  it "encrypt/decrypts transparently" do
    s = PluginSetting.create!(name: "plugin_setting_test", settings: { bar: "qwerty", foo: "asdf" })
    s.reload
    expect(s.valid_settings?).to be_truthy
    expect(s.settings.keys.sort_by(&:to_s)).to eql(%i[bar foo foo_dec foo_enc foo_salt])
    expect(s.settings[:bar]).to eql("qwerty")
    expect(s.settings[:foo_dec]).to eql("asdf")
  end

  context "dirty_checking" do
    it "considers a new object to be dirty" do
      s = PluginSetting.new(name: "plugin_setting_test", settings: { bar: "qwerty", foo: "asdf" })
      expect(s.changed?).to be_truthy
    end

    it "considers a freshly loaded encrypted object to be clean" do
      PluginSetting.create!(name: "plugin_setting_test", settings: { bar: "qwerty", foo: "asdf" })
      settings = PluginSetting.find_by(name: "plugin_setting_test")
      expect(settings.changed?).to_not be_truthy
    end
  end

  it "is not valid if there are decrypt errors" do
    s = PluginSetting.new(name: "plugin_setting_test", settings: { bar: "qwerty", foo_enc: "invalid", foo_salt: "invalid" })
    expect(s.valid_settings?).to be_falsey
    expect(s.settings).to eql({ bar: "qwerty", foo_enc: "invalid", foo_salt: "invalid", foo: PluginSetting::DUMMY_STRING })
  end

  it "returns default content if no setting is set" do
    settings = PluginSetting.settings_for_plugin("plugin_setting_test")
    expect(settings).not_to be_nil
    expect(settings[:bar]).to eq "asdf"
  end

  it "returns updated content if created" do
    PluginSetting.create!(name: "plugin_setting_test", settings: { bar: "qwerty" })
    settings = PluginSetting.settings_for_plugin("plugin_setting_test")
    expect(settings).not_to be_nil
    expect(settings[:bar]).to eq "qwerty"
  end

  it "returns default content if the setting is disabled" do
    s = PluginSetting.create!(name: "plugin_setting_test", settings: { bar: "qwerty" })
    settings = PluginSetting.settings_for_plugin("plugin_setting_test")
    expect(settings).not_to be_nil
    expect(settings[:bar]).to eq "qwerty"

    s.update_attribute(:disabled, true)
    settings = PluginSetting.settings_for_plugin("plugin_setting_test")
    expect(settings).not_to be_nil
    expect(settings[:bar]).to eq "asdf"
  end

  it "immediately uncaches on save" do
    enable_cache do
      s = PluginSetting.create!(name: "plugin_setting_test", settings: { bar: "qwerty" })
      # cache it
      settings = PluginSetting.settings_for_plugin("plugin_setting_test")
      expect(settings).to eq({ bar: "qwerty" })
      s.settings = { food: "bar" }
      s.save!
      # new settings
      settings = PluginSetting.settings_for_plugin("plugin_setting_test")
      expect(settings).to eq({ food: "bar" })
    end
  end

  it "caches in-process" do
    RequestCache.enable do
      enable_cache do
        name = "plugin_setting_test"
        s = PluginSetting.create!(name:, settings: { bar: "qwerty" })
        expect(MultiCache.cache).to receive(:fetch_multi).once.and_return(s)
        PluginSetting.cached_plugin_setting(name) # sets the cache
        PluginSetting.cached_plugin_setting(name) # 2nd lookup
      end
    end
  end
end
