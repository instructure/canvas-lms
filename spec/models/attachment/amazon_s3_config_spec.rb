# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

describe "amazon_s3 config" do
  describe "Attachment.s3_config" do
    around do |example|
      Attachment.remove_instance_variable(:@s3_config) if Attachment.instance_variable_defined?(:@s3_config)
      example.run
      Attachment.remove_instance_variable(:@s3_config) if Attachment.instance_variable_defined?(:@s3_config)
    end

    context "when the filesystem config is available" do
      before do
        allow(ConfigFile).to receive(:load).and_call_original
        allow(ConfigFile).to receive(:load).with("amazon_s3").and_return(
          "bucket_name" => "fs-bucket",
          "region" => "us-east-1"
        )
      end

      it "returns the filesystem config" do
        config = Attachment.s3_config
        expect(config["bucket_name"]).to eq("fs-bucket")
      end
    end

    context "when the filesystem config is missing" do
      before do
        allow(ConfigFile).to receive(:load).and_call_original
        allow(ConfigFile).to receive(:load).with("amazon_s3").and_return(nil)
        stub_consul_config("amazon_s3", {
                             "bucket_name" => "consul-bucket",
                             "region" => "us-west-2"
                           })
      end

      it "falls back to Consul" do
        config = Attachment.s3_config
        expect(config["bucket_name"]).to eq("consul-bucket")
      end
    end

    context "when neither filesystem nor Consul has the config" do
      before do
        allow(ConfigFile).to receive(:load).and_call_original
        allow(ConfigFile).to receive(:load).with("amazon_s3").and_return(nil)
        stub_consul_unavailable("amazon_s3")
      end

      it "returns nil" do
        expect(Attachment.s3_config).to be_nil
      end
    end
  end
end
