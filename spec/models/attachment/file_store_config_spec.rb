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

describe "file_store config" do
  describe "Attachment.file_store_config" do
    around do |example|
      Attachment.instance_variable_set(:@file_store_config, nil)
      example.run
      Attachment.instance_variable_set(:@file_store_config, nil)
    end

    context "when the filesystem config is available" do
      before do
        allow(ConfigFile).to receive(:load).and_call_original
        allow(ConfigFile).to receive(:load).with("file_store").and_return(
          "storage" => "s3",
          "path_prefix" => "custom/path"
        )
      end

      it "returns the filesystem config" do
        config = Attachment.file_store_config
        expect(config["storage"]).to eq("s3")
        expect(config["path_prefix"]).to eq("custom/path")
      end
    end

    context "when the filesystem config is missing" do
      before do
        allow(ConfigFile).to receive(:load).and_call_original
        allow(ConfigFile).to receive(:load).with("file_store").and_return(nil)
        stub_consul_config("file_store", {
                             "storage" => "s3",
                             "path_prefix" => "consul/path"
                           })
      end

      it "falls back to Consul" do
        config = Attachment.file_store_config
        expect(config["storage"]).to eq("s3")
      end
    end

    context "when neither filesystem nor Consul has the config" do
      before do
        allow(ConfigFile).to receive(:load).and_call_original
        allow(ConfigFile).to receive(:load).with("file_store").and_return(nil)
        stub_consul_unavailable("file_store")
      end

      it "defaults to local storage" do
        config = Attachment.file_store_config
        expect(config["storage"]).to eq("local")
        expect(config["path_prefix"]).to eq("tmp/files")
      end
    end
  end
end
