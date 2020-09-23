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

  def inject_apm_settings(yaml_string)
    Canvas::DynamicSettings.fallback_data = {
        "private": {
          "canvas": {
            "datadog_apm.yml": yaml_string
          }
        }
      }
  end

  describe "settings parsing" do
    describe "analytics setting" do
      it "is true for bool string" do
        inject_apm_settings("sample_rate: 0.5\nhost_sample_rate: 1.0\napp_analytics_enabled: true")
        expect(Canvas::Apm.config['app_analytics_enabled']).to eq(true)
        expect(Canvas::Apm).to be_analytics_enabled
      end

      it "is false if missing or set to false" do
        inject_apm_settings("sample_rate: 0.5\nhost_sample_rate: 1.0")
        expect(Canvas::Apm).to_not be_analytics_enabled
        Canvas::Apm.reset!
        Canvas::DynamicSettings.reset_cache!
        inject_apm_settings("sample_rate: 0.5\nhost_sample_rate: 1.0\napp_analytics_enabled: false")
        expect(Canvas::Apm).to_not be_analytics_enabled
      end
    end
  end

  describe ".configured?" do
    it "is false for empty config" do
      Canvas::DynamicSettings.fallback_data = {}
      expect(Canvas::Apm.configured?).to eq(false)
    end

    it "is false for 0 sampling rate" do
      inject_apm_settings("sample_rate: 0.0\nhost_sample_rate: 1.0")
      Canvas::Apm.hostname = "testbox"
      expect(Canvas::Apm.configured?).to eq(false)
    end

    it "is true for >0 sampling rate" do
      Canvas::Apm.reset!
      inject_apm_settings("sample_rate: 0.5\nhost_sample_rate: 1.0")
      Canvas::Apm.hostname = "testbox"
      expect(Canvas::Apm.config.fetch('sample_rate')).to eq(0.5)
      expect(Canvas::Apm.sample_rate).to eq(0.5)
      expect(Canvas::Apm.host_sample_rate).to eq(1.0)
      expect(Canvas::Apm.configured?).to eq(true)
    end

    it "is false when no hosts are sampled" do
      Canvas::Apm.reset!
      inject_apm_settings("sample_rate: 0.5\nhost_sample_rate: 0.0")
      Canvas::Apm.hostname = "testbox"
      expect(Canvas::Apm.config.fetch('sample_rate')).to eq(0.5)
      expect(Canvas::Apm.host_sample_rate).to eq(0.0)
      expect(Canvas::Apm.configured?).to eq(false)
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

  describe "general tracing" do
    class FakeSpan
      attr_reader :tags
      attr_accessor :resource, :span_type
      def initialize
        self.reset!
      end

      def reset!
        @tags = {}
      end

      def set_tag(key, val)
        @tags[key] = val
      end

      def get_tag(key)
        @tags[key]
      end
    end

    class FakeTracer
      attr_reader :span
      def initialize
        @span = FakeSpan.new
      end

      def trace(_name, opts = {})
        span.resource = opts.fetch(:resource, nil)
        yield span
      end

      def active_root_span
        @span
      end

      def enabled
        true
      end
    end

    let(:tracer){ FakeTracer.new }
    let(:span){ tracer.span }

    around do |example|
      Canvas::Apm.reset!
      Canvas::DynamicSettings.fallback_data = {
        "private": {
          "canvas": {
            "datadog_apm.yml": "sample_rate: 1.0\nhost_sample_rate: 1.0"
          }
        }
      }
      Canvas::Apm.hostname = "testbox"
      Canvas::Apm.tracer = tracer
      example.run
      span.reset!
      Canvas::Apm.reset!
    end

    it "adds shard and account tags to active span" do
      Canvas::Apm.hostname = "testbox"
      Canvas::Apm.tracer.trace("TESTING") do |span|
        shard = OpenStruct.new({id: 42})
        account = OpenStruct.new({global_id: 420000042})
        user = OpenStruct.new({global_id: 42100000421})
        generate_request_id = "1234567890"
        expect(tracer.active_root_span).to eq(span)
        Canvas::Apm.annotate_trace(shard, account, generate_request_id, user)
        expect(span.get_tag('shard')).to eq('42')
        expect(span.get_tag('root_account')).to eq('420000042')
        expect(span.get_tag('request_context_id')).to eq('1234567890')
        expect(span.get_tag('current_user')).to eq('42100000421')
      end
    end

    it "provides a hook to the dd tracer" do
      expect(Canvas::Apm.sample_rate).to eq(1.0)
      expect(Canvas::Apm).to be_configured
      expect(Canvas::Apm.tracer).to eq(tracer)
      Canvas::Apm.reset!
      Canvas::Apm.hostname = "testbox"
      expect(Canvas::Apm).to be_configured
      expect(Canvas::Apm.tracer).to eq(Datadog.tracer)
    end

    it "traces arbitrary code" do
      expect(Canvas::Apm.sample_rate).to eq(1.0)
      expect(Canvas::Apm).to be_configured
      Canvas::Apm.trace("test") do |span|
        span.set_tag("TEST", "VALUE")
        # arbitrary other code
      end
      expect(span.resource).to eq("test")
    end

    it 'still yields if there is no configuration' do
      Canvas::Apm.reset!
      Canvas::DynamicSettings.fallback_data = {
        "private": {
          "canvas": {
            "datadog_apm.yml": "sample_rate: 0.0\nhost_sample_rate: 0.0"
          }
        }
      }
      expect(Canvas::Apm).to_not be_configured
      Canvas::Apm.trace("test") do |span|
        expect(span.class).to eq(Canvas::Apm::StubTracer::StubSpan)
      end
    end
  end
end