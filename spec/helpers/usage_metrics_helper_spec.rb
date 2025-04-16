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

  before :once do
    @domain_root_account = Account.default
  end

  before do
    allow(@domain_root_account).to receive(:feature_enabled?).with(:send_usage_metrics).and_return(true)
    allow_any_instance_of(UsageMetricsHelper).to receive(:usage_metrics_api_key).and_return("some_api_key")
    allow(self).to receive(:js_env)
  end

  it "returns true if the feature is enabled and usage_metrics_api_key is present" do
    expect(load_usage_metrics?).to be_truthy
  end

  it "returns false when domain_root_account doesn't have the feature enabled" do
    allow(@domain_root_account).to receive(:feature_enabled?).with(:send_usage_metrics).and_return(false)
    expect(load_usage_metrics?).to be_falsey
  end

  it "returns false if there is no usage_metrics_api_key" do
    allow_any_instance_of(UsageMetricsHelper).to receive(:usage_metrics_api_key).and_return(nil)
    expect(load_usage_metrics?).to be_falsey
  end

  it "calls js_env with the correct parameters" do
    expect(self).to receive(:js_env).with(PENDO_APP_ID: "some_api_key")
    load_usage_metrics?
  end
end
