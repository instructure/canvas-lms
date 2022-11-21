# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

describe FeatureFlags::UsageMetricsPredicate do
  let(:settings) { nil }
  let(:external_integration_keys) { nil }
  let(:root_account) { double(settings: settings, external_integration_keys: external_integration_keys) }
  let(:context) { double(root_account: root_account) }
  let(:predicate) { FeatureFlags::UsageMetricsPredicate.new context }

  it "defaults to false" do
    expect(predicate.call).to be_falsey
  end

  describe "when overridden" do
    let(:settings) { { enable_usage_metrics: true } }

    it "returns true" do
      expect(predicate.call).to be_truthy
    end
  end

  describe "when in domestic territory and us billing" do
    let(:external_integration_keys) do
      keys = double
      allow(keys).to receive(:find_by).with({ key_type: "salesforce_billing_country_code" }) { double(key_value: "US") }
      allow(keys).to receive(:find_by).with({ key_type: "salesforce_territory_region" }) { double(key_value: "domestic") }
      keys
    end

    it "returns true" do
      expect(predicate.call).to be_truthy
    end
  end
end
