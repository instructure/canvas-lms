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

require_relative '../../sharding_spec_helper'

describe Canvas::Apm do
  after(:each) do
    Canvas::DynamicSettings.config = nil
    Canvas::DynamicSettings.reset_cache!
    Canvas::DynamicSettings.fallback_data = nil
    Canvas::Apm.reset!
  end

  describe ".configured?" do
    it "is false for empty config" do
      Canvas::DynamicSettings.fallback_data = {}
      expect(Canvas::Apm.configured?).to eq(false)
    end

    it "is false for 0 sampling rate" do
      Canvas::DynamicSettings.fallback_data = {
        "private": {
          "canvas": {
            "datadog_apm.yml": "sample_rate: 0.0"
          }
        }
      }
      expect(Canvas::Apm.configured?).to eq(false)
    end

    it "is true for >0 sampling rate" do
      Canvas::Apm.reset!
      Canvas::DynamicSettings.fallback_data = {
        "private": {
          "canvas": {
            "datadog_apm.yml": "sample_rate: 0.5"
          }
        }
      }
      expect(Canvas::Apm.config.fetch('sample_rate')).to eq(0.5)
      expect(Canvas::Apm.sample_rate).to eq(0.5)
      expect(Canvas::Apm.configured?).to eq(true)
    end
  end

  describe "annotating with standard tags" do
    it "adds shard and account tags to active span" do
      Canvas::Apm.reset!
      Canvas::DynamicSettings.fallback_data = {
        "private": {
          "canvas": {
            "datadog_apm.yml": "sample_rate: 0.5"
          }
        }
      }
      Datadog.tracer.trace("TESTING") do |span|
        shard = OpenStruct.new({id: 42})
        account = OpenStruct.new({global_id: 420000042})
        expect(Datadog.tracer.active_root_span).to eq(span)
        Canvas::Apm.annotate_trace(shard, account)
        expect(span.get_tag('shard')).to eq('42')
        expect(span.get_tag('root_account')).to eq('420000042')
      end
    end
  end
end