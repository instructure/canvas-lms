# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

describe Setting do
  context "getting" do
    it "gets the default value as a string" do
      expect(Setting.get("my_new_setting", true)).to eq "true"
    end

    it "gets the default value as a string for dates" do
      time = Time.now.utc
      expect(Setting.get("my_new_setting", time)).to eq time.to_s
    end

    it "returns set values" do
      Setting.set("my_new_setting", "1")
      expect(Setting.get("my_new_setting", "0")).to eq "1"
    end

    it "allows passing a cache expiration" do
      # cache 0 in process
      expect(Setting.get("my_new_setting", "0", expires_in: 1.minute)).to eq "0"
      # some other process sets the value out from under us
      Setting.create!(name: "my_new_setting", value: "1")
      MultiCache.delete("all_settings")
      # but we still see the cached value for now
      expect(Setting.get("my_new_setting", "0", expires_in: 1.minute)).to eq "0"
      # until the expiration has passed
      Timecop.travel(2.minutes.from_now) do
        expect(Setting.get("my_new_setting", "0", expires_in: 1.minute)).to eq "1"
      end
    end

    it "doesn't need to query if all settings are already cached" do
      Setting.reset_cache!
      Setting.get("setting1", nil)
      expect(Setting).not_to receive(:find_by)
      expect(Setting).not_to receive(:pluck)
      expect(MultiCache).not_to receive(:fetch)
      Setting.get("setting2", nil)
    end

    it "doesn't touch MultiCache if skip_cache is true" do
      Setting.reset_cache!
      expect(MultiCache).not_to receive(:fetch)
      expect(Setting).to receive(:pluck).and_call_original
      Setting.get("setting1", nil, skip_cache: true)
    end
  end

  context "setting" do
    it "sets boolean values as strings" do
      Setting.set("my_new_setting", true)
      expect(Setting.get("my_new_setting", "1")).to eq "true"
    end

    it "sets time values as strings" do
      time = Time.now.utc
      Setting.set("my_new_setting", time)
      expect(Setting.get("my_new_setting", "1")).to eq time.to_s
    end

    it "sets the secret flag on create" do
      Setting.set("new_nonsecret_setting", "value")
      expect(Setting.find_by(name: "new_nonsecret_setting").secret).to be_falsey

      Setting.set("new_secret_setting", "value", secret: true)
      expect(Setting.find_by(name: "new_secret_setting").secret).to be_truthy
    end

    it "changes the secret flag when modifying" do
      Setting.set("new_nonsecret_setting", "value")
      Setting.set("new_nonsecret_setting", "secret_value", secret: true)

      expect(Setting.find_by(name: "new_nonsecret_setting").secret).to be_truthy
    end

    context "when in a Rails console" do
      before do
        stub_const("Console", {})
      end

      it "logs a notice about SIGHUP" do
        expect(Rails.logger).to receive(:info).with(a_string_including("SIGHUP"))
        Setting.set("test_setting", "test_value")
      end

      it "logs a customized notice about SIGHUP" do
        Setting.set("setting_set_sighup_required_message", "Custom message 🍕")

        expect(Rails.logger).to receive(:info).with("Custom message 🍕")
        Setting.set("test_setting", "test_value")
      end
    end

    context "when not in a Rails console" do
      before do
        hide_const("Console")
      end

      it "does not log a notice about SIGHUP" do
        expect(Rails.logger).not_to receive(:info).with(a_string_including("SIGHUP"))
        Setting.set("test_setting", "test_value")
      end
    end
  end
end
