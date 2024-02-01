# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require_relative "../spec_helper"

describe DatadogRumHelper do
  include ApplicationHelper

  let(:datadog_rum_config) do
    DynamicSettings::FallbackProxy.new({
                                         application_id: "27627d1e-8a4f-4645-b390-bb396fc83c81",
                                         client_token: "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r",
                                         sample_rate_percentage: 100.0
                                       })
  end

  describe "#include_datadog_rum_js?" do
    before :once do
      Account.site_admin.enable_feature!(:datadog_rum_js)
    end

    before do
      allow(DynamicSettings).to receive(:find).and_call_original
      allow(DynamicSettings).to(
        receive(:find).with("datadog-rum", tree: "config", service: "canvas").and_return(datadog_rum_config)
      )
      allow(self).to receive(:random).and_return(0.5)
    end

    context "when opted in to using datadog rum js" do
      before do
        opt_in_datadog_rum_js
      end

      it "returns true when the random value is below the sample rate" do
        datadog_rum_config.data[:sample_rate_percentage] = 50.0001
        expect(include_datadog_rum_js?).to be(true)
      end

      it "returns true when the random value matches the sample rate" do
        datadog_rum_config.data[:sample_rate_percentage] = 50.0
        expect(include_datadog_rum_js?).to be(true)
      end

      it "returns false when the random value is above the sample rate" do
        datadog_rum_config.data[:sample_rate_percentage] = 49.9999
        expect(include_datadog_rum_js?).to be(false)
      end

      it "returns true when the sample rate percentage is 100%" do
        datadog_rum_config.data[:sample_rate_percentage] = 100.0
        expect(include_datadog_rum_js?).to be(true)
      end

      it "returns false when the sample rate percentage is 0%" do
        allow(self).to receive(:random).and_return(0.0)
        datadog_rum_config.data[:sample_rate_percentage] = 0.0
        expect(include_datadog_rum_js?).to be(false)
      end

      it "returns false consistently when called multiple times" do
        datadog_rum_config.data[:sample_rate_percentage] = 50.0
        allow(self).to receive(:random).and_return(0.6)
        expect(include_datadog_rum_js?).to be(false)
        allow(self).to receive(:random).and_return(0.4)
        expect(include_datadog_rum_js?).to be(false)
      end

      it "returns true consistently when called multiple times" do
        datadog_rum_config.data[:sample_rate_percentage] = 50.0
        allow(self).to receive(:random).and_return(0.4)
        expect(include_datadog_rum_js?).to be(true)
        allow(self).to receive(:random).and_return(0.6)
        expect(include_datadog_rum_js?).to be(true)
      end

      it "returns false when the feature is not enabled" do
        Account.site_admin.disable_feature!(:datadog_rum_js)
        expect(include_datadog_rum_js?).to be(false)
      end
    end

    context "when explicitly requesting the feature" do
      it "returns true when the feature is enabled" do
        request_datadog_rum_js
        expect(include_datadog_rum_js?).to be(true)
      end

      it "returns false when the sample rate percentage is 0.0" do
        request_datadog_rum_js
        datadog_rum_config.data[:sample_rate_percentage] = 0.0
        expect(include_datadog_rum_js?).to be(false)
      end

      it "returns false when the feature is not enabled" do
        request_datadog_rum_js
        Account.site_admin.disable_feature!(:datadog_rum_js)
        expect(include_datadog_rum_js?).to be(false)
      end
    end

    it "returns false when not opted in" do
      expect(include_datadog_rum_js?).to be(false)
    end

    it "returns false when the configuration is missing :application_id" do
      opt_in_datadog_rum_js
      datadog_rum_config.data.delete(:application_id)
      expect(include_datadog_rum_js?).to be(false)
    end

    it "returns false when the configuration is missing :client_token" do
      opt_in_datadog_rum_js
      datadog_rum_config.data.delete(:client_token)
      expect(include_datadog_rum_js?).to be(false)
    end

    it "returns false when the configuration is missing :sample_rate_percentage" do
      opt_in_datadog_rum_js
      datadog_rum_config.data.delete(:sample_rate_percentage)
      expect(include_datadog_rum_js?).to be(false)
    end

    it "renders the datadog rum js partial when it will be included" do
      expect(self).to receive(:include_datadog_rum_js?).and_return(true)
      expect(self).to receive(:render).with(partial: "shared/datadog_rum_js")
      render_datadog_rum_js
    end

    it "does not render the datadog rum js partial when it will not be included" do
      expect(self).to receive(:include_datadog_rum_js?).and_return(false)
      expect(self).not_to receive(:render)
      render_datadog_rum_js
    end
  end
end
