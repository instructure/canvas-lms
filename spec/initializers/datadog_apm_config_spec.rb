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

require_relative '../spec_helper'
require_relative '../../config/initializers/datadog_apm'

describe DatadogApmConfig do
  after(:each) do
    Canvas::DynamicSettings.config = nil
    Canvas::DynamicSettings.reset_cache!
    Canvas::DynamicSettings.fallback_data = nil
  end

  describe ".configured?" do
    it "i sfalse for empty config" do
      Canvas::DynamicSettings.fallback_data = {}
      expect(DatadogApmConfig.configured?).to eq(false)
    end

    it "is false for 0 sampling rate" do
      Canvas::DynamicSettings.fallback_data = {
        "private": {
          "canvas": {
            "datadog_apm.yml": "sample_rate: 0.0"
          }
        }
      }
      expect(DatadogApmConfig.configured?).to eq(false)
    end

    it "is true for >0 sampling rate" do
      Canvas::DynamicSettings.fallback_data = {
        "private": {
          "canvas": {
            "datadog_apm.yml": "sample_rate: 0.5"
          }
        }
      }
      expect(DatadogApmConfig.configured?).to eq(true)
    end
  end
end