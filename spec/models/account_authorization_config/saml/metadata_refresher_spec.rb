#
# Copyright (C) 2016 Instructure, Inc.
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

require_relative '../../../spec_helper'

describe AccountAuthorizationConfig::SAML::MetadataRefresher do
  let(:subject) { AccountAuthorizationConfig::SAML::MetadataRefresher }

  describe ".refresh_providers" do
    before do
      AccountAuthorizationConfig::SAML.any_instance.stubs(:download_metadata).returns(nil)
    end

    let (:saml1) { Account.default.authentication_providers.create!(auth_type: 'saml', metadata_uri: '1') }

    it "keeps going even if one fails" do
      saml2 = Account.default.authentication_providers.create!(auth_type: 'saml', metadata_uri: '2')

      subject.expects(:refresh_if_necessary).with(saml1.global_id, '1').raises('die')
      subject.expects(:refresh_if_necessary).with(saml2.global_id, '2').returns(false)
      ::Canvas::Errors.expects(:capture_exception).once

      subject.refresh_providers
    end

    it "doesn't populate if nothing changed" do
      subject.expects(:refresh_if_necessary).with(saml1.global_id, '1').returns(false)
      saml1.expects(:populate_from_metadata_xml).never

      subject.refresh_providers
    end

    it "does populate, but doesn't save, if the XML changed, but nothing changes on the model" do
      subject.expects(:refresh_if_necessary).with(saml1.global_id, '1').returns('xml')
      saml1.any_instantiation.expects(:populate_from_metadata_xml).with('xml')
      saml1.any_instantiation.expects(:save!).never

      subject.refresh_providers
    end

    it "populates and saves" do
      subject.expects(:refresh_if_necessary).with(saml1.global_id, '1').returns('xml')
      saml1.any_instantiation.expects(:populate_from_metadata_xml).with('xml')
      saml1.any_instantiation.expects(:changed?).returns(true)
      saml1.any_instantiation.expects(:save!).once

      subject.refresh_providers
    end
  end

  describe ".refresh_if_necessary" do
    let(:redis) { stub("redis") }

    before do
      Canvas.stubs(:redis_enabled?).returns(true)
      Canvas.stubs(:redis).returns(redis)
    end

    it "passes ETag if we know it" do
      redis.expects(:get).returns("MyETag")
      CanvasHttp.expects(:get).with("url", "If-None-Match" => "MyETag")

      subject.send(:refresh_if_necessary, 1, 'url')
    end

    it "doesn't pass ETag if force_fetch: true" do
      redis.expects(:get).never
      CanvasHttp.expects(:get).with("url", {})

      subject.send(:refresh_if_necessary, 1, 'url', force_fetch: true)
    end

    it "returns false if not modified" do
      redis.expects(:get).returns("MyETag")
      response = stub("response")
      response.expects(:is_a?).with(Net::HTTPNotModified).returns(true)

      CanvasHttp.expects(:get).with("url", "If-None-Match" => "MyETag").yields(response)

      expect(subject.send(:refresh_if_necessary, 1, 'url')).to eq false
    end

    it "sets the ETag if provided" do
      redis.expects(:get).returns(nil)
      response = stub("response")
      response.expects(:is_a?).with(Net::HTTPNotModified).returns(false)
      response.expects(:value)
      response.stubs(:[]).with('ETag').returns("NewETag")
      redis.expects(:set).with("saml_1_etag", "NewETag")
      response.expects(:body).returns("xml")

      CanvasHttp.expects(:get).with("url", {}).yields(response)

      expect(subject.send(:refresh_if_necessary, 1, 'url')).to eq "xml"
    end
  end
end
