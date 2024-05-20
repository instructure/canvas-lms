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

require_relative "../../spec_helper"

describe AuthenticationProvider::PluginSettings do
  let(:klass) do
    Class.new(AuthenticationProvider) do
      include AuthenticationProvider::PluginSettings
      self.plugin = :custom_plugin

      def noninherited_method
        "noninherited"
      end

      plugin_settings :auth_host, noninherited_method: :renamed_setting
    end
  end

  let(:plugin) { double }

  before do
    allow(Canvas::Plugin).to receive(:find).with(:custom_plugin).and_return(plugin)
  end

  describe ".globally_configured?" do
    it "chains to the plugin being enabled" do
      allow(plugin).to receive(:enabled?).and_return(false)
      expect(klass.globally_configured?).to be false

      allow(plugin).to receive(:enabled?).and_return(true)
      expect(klass.globally_configured?).to be true
    end
  end

  describe ".recognized_params" do
    context "with plugin config" do
      it "returns nothing" do
        allow(plugin).to receive(:enabled?).and_return(true)
        expect(klass.recognized_params).to eq %i[mfa_required skip_internal_mfa otp_via_sms]
      end
    end

    context "without plugin config" do
      it "returns plugin params" do
        allow(plugin).to receive(:enabled?).and_return(false)
        expect(klass.recognized_params).to eq %i[auth_host noninherited_method mfa_required skip_internal_mfa otp_via_sms]
      end
    end
  end

  context "settings methods" do
    let(:aac) do
      aac = klass.new
      aac.auth_host = "host"
      aac
    end

    before do
      allow(plugin).to receive(:settings).and_return(auth_host: "ps",
                                                     noninherited_method: "hidden",
                                                     renamed_setting: "renamed")
    end

    context "with plugin config" do
      before do
        allow(plugin).to receive(:enabled?).and_return(true)
      end

      it "uses settings from plugin" do
        expect(aac.auth_host).to eq "ps"
      end

      it "uses renamed settings from plugin" do
        expect(aac.noninherited_method).to eq "renamed"
      end
    end

    context "without plugin config" do
      before do
        allow(plugin).to receive(:enabled?).and_return(false)
      end

      it "uses settings from plugin" do
        expect(aac.auth_host).to eq "host"
      end
    end
  end
end
