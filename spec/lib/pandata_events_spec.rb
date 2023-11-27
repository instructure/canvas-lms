# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

describe PandataEvents do
  describe ".credentials" do
    subject { described_class.credentials }

    before { described_class.instance_variable_set(:@credentials, nil) }

    context "when creds are configured" do
      let(:fake_secrets) do
        {
          canvas_key: "canvas_key",
          canvas_secret: "canvas_secret",
        }.with_indifferent_access
      end

      before do
        allow(Rails.application.credentials).to receive(:pandata_creds).and_return(fake_secrets)
      end

      it "reads from Vault" do
        expect(subject).to eq(fake_secrets)
      end
    end

    context "when creds are not configured" do
      before do
        allow(Rails.application.credentials).to receive(:pandata_creds).and_return(nil)
      end

      it "returns empty hash" do
        expect(subject).to eq({})
      end
    end
  end

  describe ".config" do
    subject { described_class.config }

    let(:config_values) { raise "configure in examples" }
    let(:fake_config) { DynamicSettings::FallbackProxy.new(config_values) }

    before do
      described_class.instance_variable_set(:@config, nil)
      allow(DynamicSettings).to receive(:find).with("pandata/events", service: "canvas").and_return(fake_config)
    end

    context "when Consul is populated" do
      let(:config_values) do
        {
          url: "https://example.com",
          enabled: true,
        }
      end

      it "reads from Consul" do
        expect(subject).to eq(fake_config)
      end
    end

    context "when Consul is not populated" do
      let(:config_values) { {} }

      it "returns empty DynamicSettings hash" do
        expect(subject).to eq(fake_config)
      end
    end
  end

  describe ".endpoint" do
    subject { described_class.endpoint }

    let(:url) { "https://example.com" }

    before do
      described_class.instance_variable_set(:@config, nil)
      described_class.instance_variable_set(:@endpoint, nil)
    end

    context "when endpoint is configured" do
      before do
        allow(DynamicSettings).to receive(:find).with("pandata/events", service: "canvas").and_return({ url: })
      end

      it "reads from Consul" do
        expect(subject).to eq(url)
      end
    end

    context "when endpoint is not configured" do
      before do
        allow(DynamicSettings).to receive(:find).with("pandata/events", service: "canvas").and_return({})
      end

      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end

  describe ".enabled?" do
    subject { described_class.enabled? }

    before do
      described_class.instance_variable_set(:@config, nil)
    end

    context "when enabled is set in Consul" do
      before do
        allow(DynamicSettings).to receive(:find).with("pandata/events", service: "canvas").and_return({ enabled_for_canvas: true })
      end

      it { is_expected.to be_truthy }
    end

    context "when Consul is not configured" do
      before do
        allow(DynamicSettings).to receive(:find).with("pandata/events", service: "canvas").and_return({})
      end

      it { is_expected.to be_falsy }
    end
  end
end
