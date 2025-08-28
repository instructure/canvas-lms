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
#

require_relative "../../../spec_helper"

describe Utils::InstStatsdUtils::Timing do
  let(:metric_name) { "test.metric" }

  describe ".track" do
    before do
      allow(InstStatsd::Statsd).to receive(:timing)
    end

    context "basic timing functionality" do
      it "yields a TimingMeta object" do
        expect { |b| described_class.track(metric_name, &b) }
          .to yield_with_args(Utils::InstStatsdUtils::TimingMeta)
      end

      it "sends timing stats by default" do
        described_class.track(metric_name) { nil }

        expect(InstStatsd::Statsd).to have_received(:timing)
          .with(metric_name, be_a(Float), tags: {})
      end

      it "measures elapsed time accurately" do
        expected_time = 0.01
        allow(Process).to receive(:clock_gettime).and_return(0.0, expected_time)

        described_class.track(metric_name) { nil }

        expect(InstStatsd::Statsd).to have_received(:timing)
          .with(metric_name, expected_time, tags: {})
      end
    end

    context "conditional stats sending" do
      it "does not send stats when send_stats is false" do
        described_class.track(metric_name) do |meta|
          meta.send_stats = false
        end

        expect(InstStatsd::Statsd).not_to have_received(:timing)
      end

      it "sends stats when send_stats is true" do
        described_class.track(metric_name) do |meta|
          meta.send_stats = true
        end

        expect(InstStatsd::Statsd).to have_received(:timing)
          .with(metric_name, be_a(Float), tags: {})
      end

      it "does not calculate timing when send_stats is false" do
        allow(Process).to receive(:clock_gettime).and_call_original

        described_class.track(metric_name) do |meta|
          meta.send_stats = false
        end

        # Should only be called once (for timing_start)
        expect(Process).to have_received(:clock_gettime)
          .with(Process::CLOCK_MONOTONIC).once
      end
    end

    context "tags functionality" do
      it "sends empty tags by default" do
        described_class.track(metric_name) { nil }

        expect(InstStatsd::Statsd).to have_received(:timing)
          .with(metric_name, be_a(Float), tags: {})
      end

      it "sends custom tags when provided" do
        tags = { foo: "bar", baz: "qux" }

        described_class.track(metric_name) do |meta|
          meta.tags = tags
        end

        expect(InstStatsd::Statsd).to have_received(:timing)
          .with(metric_name, be_a(Float), tags:)
      end

      it "handles nil tags gracefully" do
        described_class.track(metric_name) do |meta|
          meta.tags = nil
        end

        expect(InstStatsd::Statsd).to have_received(:timing)
          .with(metric_name, be_a(Float), tags: {})
      end
    end

    context "exception handling" do
      it "still sends timing stats when block raises exception" do
        expect do
          described_class.track(metric_name) do
            raise StandardError, "test error"
          end
        end.to raise_error(StandardError, "test error")

        expect(InstStatsd::Statsd).to have_received(:timing)
          .with(metric_name, be_a(Float), tags: {})
      end

      it "respects send_stats=false even when exception occurs" do
        expect do
          described_class.track(metric_name) do |meta|
            meta.send_stats = false
            raise StandardError, "test error"
          end
        end.to raise_error(StandardError, "test error")

        expect(InstStatsd::Statsd).not_to have_received(:timing)
      end
    end
  end

  describe Utils::InstStatsdUtils::TimingMeta do
    describe "#initialize" do
      it "sets tags to the provided value" do
        tags = { foo: "bar" }
        meta = described_class.new(tags)

        expect(meta.tags).to eq(tags)
      end

      it "sets send_stats to true by default" do
        meta = described_class.new({})

        expect(meta.send_stats).to be true
      end
    end

    describe "attribute accessors" do
      let(:meta) { described_class.new({}) }

      it "allows reading and writing tags" do
        tags = { test: "value" }
        meta.tags = tags

        expect(meta.tags).to eq(tags)
      end

      it "allows reading and writing send_stats" do
        meta.send_stats = false

        expect(meta.send_stats).to be false
      end
    end
  end
end
