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

describe FeatureFlags::DocviewerIworkPredicate do
  let(:settings) { nil }
  let(:external_integration_keys) { nil }
  let(:root_account) { double(settings:, external_integration_keys:) }
  let(:context) { double(root_account:) }
  let(:region) { nil }
  let(:predicate) { FeatureFlags::DocviewerIworkPredicate.new context, region }

  it "defaults to false" do
    expect(predicate.call).to be_falsey
  end

  describe "when overridden" do
    let(:settings) { { docviewer_enable_iwork_files: true } }

    it "returns true" do
      expect(predicate.call).to be_truthy
    end
  end

  describe "when US billing country and approved US aws region" do
    let(:external_integration_keys) do
      keys = double
      allow(keys).to receive(:find_by).with({ key_type: "salesforce_billing_country_code" }) { double(key_value: "US") }
      keys
    end
    let(:region) { "us-east-1" }

    it "returns true" do
      expect(predicate.call).to be_truthy
    end
  end
end
