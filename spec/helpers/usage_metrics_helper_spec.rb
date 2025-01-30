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

describe "usage_metrics_helper" do
  include UsageMetricsHelper

  before do
    Account.site_admin.enable_feature!(:send_usage_metrics)
    @domain_root_account = Account.new
    @domain_root_account.settings[:enable_usage_metrics] = true
    @domain_root_account.save!
  end

  context "with feature enabled" do
    it "returns false if there is no pendo_app_id" do
      allow_any_instance_of(UsageMetricsHelper).to receive(:find_usage_metrics_application_id).and_return(nil)

      expect(load_usage_metrics?).to be_falsey
    end

    it "returns false if the feature is not eanbled" do
      Account.site_admin.disable_feature!(:send_usage_metrics)

      expect(load_usage_metrics?).to be_falsey
    end

    it "is disabled if the dynamic settings are missing" do
      allow_any_instance_of(UsageMetricsHelper).to receive(:find_usage_metrics_application_id).and_return(nil)

      override_dynamic_settings(config: { canvas: nil }) do
        expect(load_usage_metrics?).to be_falsey
      end
    end
  end

  context "with feature disabled" do
    before do
      Account.site_admin.disable_feature!(:send_usage_metrics)
    end

    it "returns false if the feature is disabled" do
      allow_any_instance_of(UsageMetricsHelper).to receive(:find_usage_metrics_application_id).and_return("some_app_id")

      expect(load_usage_metrics?).to be_falsey
    end
  end

  context "with pendo_app_id present" do
    before do
      allow_any_instance_of(UsageMetricsHelper).to receive(:find_usage_metrics_application_id).and_return("some_app_id")
    end

    it "returns true if the feature is enabled and pendo_app_id is present" do
      expect(load_usage_metrics?).to be_truthy
    end
  end
end
