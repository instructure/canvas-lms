# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

describe AuthenticationProvider::SAML::MetadataRefresher do
  let(:subject) { AuthenticationProvider::SAML::MetadataRefresher }

  describe ".refresh_providers" do
    before do
      allow_any_instance_of(AuthenticationProvider::SAML).to receive(:download_metadata).and_return(nil)
    end

    let(:saml1) { Account.default.authentication_providers.create!(auth_type: "saml", metadata_uri: "1") }

    it "keeps going even if one fails" do
      saml2 = Account.default.authentication_providers.create!(auth_type: "saml", metadata_uri: "2")

      expect(subject).to receive(:refresh_if_necessary).with(saml1.global_id, "1").and_raise("die")
      expect(subject).to receive(:refresh_if_necessary).with(saml2.global_id, "2").and_return(false)
      expect(Canvas::Errors).to receive(:capture).once

      subject.refresh_providers
    end

    it "doesn't populate if nothing changed" do
      expect(subject).to receive(:refresh_if_necessary).with(saml1.global_id, "1").and_return(false)
      expect(saml1).not_to receive(:populate_from_metadata_xml)

      subject.refresh_providers
    end

    it "does populate, but doesn't save, if the XML changed, but nothing changes on the model" do
      expect(subject).to receive(:refresh_if_necessary).with(saml1.global_id, "1").and_return("xml")
      expect_any_instantiation_of(saml1).to receive(:populate_from_metadata_xml).with("xml")
      expect_any_instantiation_of(saml1).not_to receive(:save!)

      subject.refresh_providers
    end

    it "populates and saves" do
      expect(subject).to receive(:refresh_if_necessary).with(saml1.global_id, "1").and_return("xml")
      expect_any_instantiation_of(saml1).to receive(:populate_from_metadata_xml).with("xml")
      expect_any_instantiation_of(saml1).to receive(:changed?).and_return(true)
      expect_any_instantiation_of(saml1).to receive(:save!).once

      subject.refresh_providers
    end

    it "ignores nil/blank metadata_uris" do
      AuthenticationProvider::SAML.where(id: saml1.id).update_all(metadata_uri: nil)
      Account.default.authentication_providers.create!(auth_type: "saml", metadata_uri: "")
      expect(subject).not_to receive(:refresh_if_necessary)

      subject.refresh_providers
    end
  end

  describe ".refresh_if_necessary" do
    let(:redis) { double("redis") }

    before do
      allow(Canvas).to receive_messages(redis_enabled?: true, redis:)
    end

    it "passes ETag if we know it" do
      expect(redis).to receive(:get).and_return("MyETag")
      expect(CanvasHttp).to receive(:get).with("url", { "If-None-Match" => "MyETag" })

      subject.send(:refresh_if_necessary, 1, "url")
    end

    it "doesn't pass ETag if force_fetch: true" do
      expect(redis).not_to receive(:get)
      expect(CanvasHttp).to receive(:get).with("url", {})

      subject.send(:refresh_if_necessary, 1, "url", force_fetch: true)
    end

    it "returns false if not modified" do
      expect(redis).to receive(:get).and_return("MyETag")
      response = double("response")
      expect(response).to receive(:is_a?).with(Net::HTTPNotModified).and_return(true)

      expect(CanvasHttp).to receive(:get).with("url", { "If-None-Match" => "MyETag" }).and_yield(response)

      expect(subject.send(:refresh_if_necessary, 1, "url")).to be false
    end

    it "sets the ETag if provided" do
      expect(redis).to receive(:get).and_return(nil)
      response = double("response")
      expect(response).to receive(:is_a?).with(Net::HTTPNotModified).and_return(false)
      expect(response).to receive(:value)
      allow(response).to receive(:[]).with("ETag").and_return("NewETag")
      expect(redis).to receive(:set).with("saml_1_etag", "NewETag")
      expect(response).to receive(:body).and_return("xml")

      expect(CanvasHttp).to receive(:get).with("url", {}).and_yield(response)

      expect(subject.send(:refresh_if_necessary, 1, "url")).to eq "xml"
    end
  end
end
