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

require 'spec_helper'

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
            "datadog_apm.yml": "sample_rate: 0.0\nhost_sample_rate: 1.0"
          }
        }
      }
      Canvas::Apm.hostname = "testbox"
      expect(Canvas::Apm.configured?).to eq(false)
    end

    it "is true for >0 sampling rate" do
      Canvas::Apm.reset!
      Canvas::DynamicSettings.fallback_data = {
        "private": {
          "canvas": {
            "datadog_apm.yml": "sample_rate: 0.5\nhost_sample_rate: 1.0"
          }
        }
      }
      Canvas::Apm.hostname = "testbox"
      expect(Canvas::Apm.config.fetch('sample_rate')).to eq(0.5)
      expect(Canvas::Apm.sample_rate).to eq(0.5)
      expect(Canvas::Apm.host_sample_rate).to eq(1.0)
      expect(Canvas::Apm.configured?).to eq(true)
    end

    it "is false when no hosts are sampled" do
      Canvas::Apm.reset!
      Canvas::DynamicSettings.fallback_data = {
        "private": {
          "canvas": {
            "datadog_apm.yml": "sample_rate: 0.5\nhost_sample_rate: 0.0"
          }
        }
      }
      Canvas::Apm.hostname = "testbox"
      expect(Canvas::Apm.config.fetch('sample_rate')).to eq(0.5)
      expect(Canvas::Apm.host_sample_rate).to eq(0.0)
      expect(Canvas::Apm.configured?).to eq(false)
    end
  end

  describe "annotating with standard tags" do
    it "adds shard and account tags to active span" do
      Canvas::Apm.reset!
      Canvas::DynamicSettings.fallback_data = {
        "private": {
          "canvas": {
            "datadog_apm.yml": "sample_rate: 0.5\nhost_sample_rate: 1.0"
          }
        }
      }
      Canvas::Apm.hostname = "testbox"
      Datadog.tracer.trace("TESTING") do |span|
        shard = OpenStruct.new({id: 42})
        account = OpenStruct.new({global_id: 420000042})
        user = OpenStruct.new({global_id: 42100000421})
        generate_request_id = "1234567890"
        expect(Datadog.tracer.active_root_span).to eq(span)
        Canvas::Apm.annotate_trace(shard, account, generate_request_id, user)
        expect(span.get_tag('shard')).to eq('42')
        expect(span.get_tag('root_account')).to eq('420000042')
        expect(span.get_tag('request_context_id')).to eq('1234567890')
        expect(span.get_tag('current_user')).to eq('42100000421')
      end
    end
  end

  describe "sampling at the host level" do
    def generate_hostname
      hosttype = ["app","job"].sample
      tup1 = rand(256).to_s.rjust(3, '0')
      tup2 = rand(256).to_s.rjust(3, '0')
      "#{hosttype}010002#{tup1}#{tup2}"
    end

    it "produces approximately correct sampling ratios" do
      hostnames = ([true] * 1000).collect{ generate_hostname }
      sample_rate = 0.25
      interval = Canvas::Apm::HOST_SAMPLING_INTERVAL
      decisions = hostnames.collect{|hn| Canvas::Apm.get_sampling_decision(hn,sample_rate, interval) }
      samples = decisions.select{|x| x}
      expect(samples.size > 50).to be_truthy
      expect(samples.size < 500).to be_truthy
    end
  end
end