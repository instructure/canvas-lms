# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

describe "Canvadoc" do
  def stub_upload
    expectation = receive(:upload).and_return "id" => 123_456, "status" => "pending"
    allow_any_instance_of(Canvadocs::API).to expectation
    expectation
  end

  before do
    PluginSetting.create! name: "canvadocs",
                          settings: { "api_key" => "blahblahblahblahblah",
                                      "base_url" => "http://example.com",
                                      "annotations_supported" => true }
    stub_upload
    allow_any_instance_of(Canvadocs::API).to receive(:session).and_return "id" => "blah",
                                                                          "status" => "pending"
    @user = user_model
    @attachment = attachment_model(user: @user, content_type: "application/pdf")
    @doc = @attachment.create_canvadoc
  end

  def disable_canvadocs
    allow(Canvadocs).to receive(:enabled?).and_return false
  end

  describe "#jwt_secret" do
    it "returns the secret stored in DynamicSettings, base64 decoded" do
      allow(DynamicSettings).to receive(:find).with(service: "canvadoc", default_ttl: 5.minutes).and_return(
        { "secret" => "c2Vrcml0" }
      )
      expect(Canvadoc.jwt_secret).to eq "sekrit"
    end

    it "returns nil if no secret found in DynamicSettings" do
      allow(DynamicSettings).to receive(:find).with(service: "canvadoc", default_ttl: 5.minutes).and_return({})
      expect(Canvadoc.jwt_secret).to be_nil
    end
  end

  describe "#upload" do
    it "uploads" do
      @doc.upload
      expect(@doc.document_id.to_s).to eq "123456"
    end

    it "doesn't upload again" do
      @doc.update_attribute :document_id, 999_999
      @doc.upload
      expect(@doc.document_id.to_s).to eq "999999" # not 123456
    end

    it "doesn't upload when canvadocs isn't configured" do
      disable_canvadocs
      expect do
        @doc.upload
      end.to raise_error("Canvadocs isn't enabled")
    end

    it "ignores annotatable if unavailable" do
      stub_upload.with(@doc.attachment.public_url, {})
      @doc.upload annotatable: true
    end

    it "uses targeted exception for timeouts" do
      allow(Canvas).to receive(:timeout_protection).and_return(nil)
      expect { @doc.upload }.to raise_error(Canvadoc::UploadTimeout)
    end
  end

  describe "#session_url" do
    it "returns a session_url" do
      @doc.upload
      expect(@doc.session_url).to eq "http://example.com/sessions/blah/view?theme=dark"
    end

    it "Creates context for annotation session" do
      @doc.upload
      @doc.has_annotations = true
      canvadocs_api = @doc.send(:canvadocs_api)
      expect(canvadocs_api).to receive(:session).with(anything, hash_including(annotation_context: "default")).and_return({})
      @doc.session_url(user: @attachment.user, enable_annotations: true)
    end

    it "Creates test context for annotation session" do
      allow(ApplicationController).to receive_messages(test_cluster?: true, test_cluster_name: "super-secret-testing")

      @doc.upload
      @doc.has_annotations = true

      canvadocs_api = @doc.send(:canvadocs_api)

      expect(canvadocs_api).to receive(:session).with(anything, hash_including(annotation_context: "default-super-secret-testing")).and_return({})
      @doc.session_url(user: @attachment.user, enable_annotations: true)
    end

    context "if enhanced_docviewer_url_security feature flag set" do
      before do
        Account.site_admin.enable_feature!(:enhanced_docviewer_url_security)
      end

      after do
        Account.site_admin.disable_feature!(:enhanced_docviewer_url_security)
      end

      it "passes is_launch_token=true to canvadocs_api" do
        @doc.upload
        canvadocs_api = @doc.send(:canvadocs_api)
        expect(canvadocs_api).to receive(:session).with(anything, hash_including(is_launch_token: true)).and_return({})
        @doc.session_url(user: @attachment.user, enable_annotations: false)
      end
    end
  end

  describe "#available?" do
    before { @doc.upload }

    it "is available for documents that didn't fail" do
      expect(@doc).to be_available

      @doc.update_attribute :process_state, "error"
      expect(@doc).not_to be_available
    end

    it "... unless canvadocs isn't configured" do
      disable_canvadocs
      expect(@doc).not_to be_available
    end
  end

  describe "#document_id" do
    before { @doc.upload }

    describe "when not on test cluster" do
      it "returns document_id" do
        expect(@doc.document_id.to_s).to eq "123456"
      end
    end

    describe "when on test cluster" do
      before do
        allow(ApplicationController).to receive_messages(test_cluster?: true, region: "foo")
      end

      it "returns nil if last updated before last data refresh timestamp setting" do
        last_data_refresh_time = @doc.updated_at + 10 # document was updated 10 seconds before the last data refresh
        allow(Setting).to receive(:get).with("last_data_refresh_time_foo", nil).and_return last_data_refresh_time.to_s
        expect(@doc.document_id).to be_nil
      end

      it "returns document_id if last updated after last data refresh timestamp setting" do
        last_data_refresh_time = @doc.updated_at - 10 # document was updated 10 seconds after the last data refresh
        allow(Setting).to receive(:get).with("last_data_refresh_time_foo", nil).and_return last_data_refresh_time.to_s
        expect(@doc.document_id.to_s).to eq "123456"
      end
    end
  end

  describe "#has_annotations?" do
    it "has annotations when true" do
      @doc.has_annotations = true
      expect(@doc).to have_annotations
    end
  end

  describe "mime types" do
    before do
      Account.current_domain_root_account = Account.default
      Account.default.external_integration_keys.create!(key_type: "salesforce_billing_country_code", key_value: "US")
      allow(Shard.current.database_server.config).to receive(:[]).and_call_original
      allow(Shard.current.database_server.config).to receive(:[]).with(:region).and_return("us-east-1")
    end

    after do
      Account.current_domain_root_account = nil
    end

    it "returns default mime types" do
      expect(Canvadoc.mime_types).to eq(Canvadoc::DEFAULT_MIME_TYPES)
    end

    it "returns iWork files in mime_types when feature is enabled" do
      acct = Account.default.root_account
      acct.enable_feature! :docviewer_enable_iwork_files

      full_set = Canvadoc::DEFAULT_MIME_TYPES.dup.concat(Canvadoc::IWORK_MIME_TYPES)

      expect(Canvadoc.mime_types).to eq(full_set)
    end

    it "returns default submission mime types" do
      expect(Canvadoc.submission_mime_types).to eq(Canvadoc::DEFAULT_SUBMISSION_MIME_TYPES)
    end

    it "returns iWork files in submission_mime_types when feature is enabled" do
      acct = Account.default.root_account
      acct.enable_feature! :docviewer_enable_iwork_files

      full_set = Canvadoc::DEFAULT_SUBMISSION_MIME_TYPES.dup.concat(Canvadoc::IWORK_MIME_TYPES)

      expect(Canvadoc.submission_mime_types).to eq(full_set)
    end
  end
end
