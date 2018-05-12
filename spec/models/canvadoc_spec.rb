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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe 'Canvadoc' do

  def stub_upload
    expectation = receive(:upload).and_return "id" => 123456, "status" => "pending"
    allow_any_instance_of(Canvadocs::API).to expectation
    expectation
  end

  before do
    PluginSetting.create! :name => 'canvadocs',
                          :settings => {"api_key" => "blahblahblahblahblah",
                                        "base_url" => "http://example.com",
                                        "annotations_supported" => true}
    stub_upload
    allow_any_instance_of(Canvadocs::API).to receive(:session).and_return "id" => "blah",
      "status" => "pending"
    @user = user_model
    @attachment = attachment_model(user: @user, content_type: "application/pdf")
    @doc = @attachment.create_canvadoc()
  end

  def disable_canvadocs
    allow(Canvadocs).to receive(:enabled?).and_return false
  end

  describe "#upload" do
    it "uploads" do
      @doc.upload
      expect(@doc.document_id.to_s).to eq "123456"
    end

    it "doesn't upload again" do
      @doc.update_attribute :document_id, 999999
      @doc.upload
      expect(@doc.document_id.to_s).to eq "999999"  # not 123456
    end

    it "doesn't upload when canvadocs isn't configured" do
      disable_canvadocs
      expect {
        @doc.upload
      }.to raise_error("Canvadocs isn't enabled")
    end

    it "ignores annotatable if unavailable" do
      stub_upload.with(@doc.attachment.public_url, {})
      @doc.upload annotatable: true
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
      expect(canvadocs_api).to receive(:session).with(anything, hash_including(annotation_context: 'default')).and_return({})
      @doc.session_url(user: @attachment.user, enable_annotations: true)
    end

    it "Creates test context for annotation session" do
      allow(ApplicationController).to receive(:test_cluster?).and_return(true)
      allow(ApplicationController).to receive(:test_cluster_name).and_return('super-secret-testing')

      @doc.upload
      @doc.has_annotations = true

      canvadocs_api = @doc.send(:canvadocs_api)

      expect(canvadocs_api).to receive(:session).with(anything, hash_including(annotation_context: 'default-super-secret-testing')).and_return({})
      @doc.session_url(user: @attachment.user, enable_annotations: true)
    end

    it "Session creation sends users crocodoc id" do
      @doc.upload
      @doc.has_annotations = true
      @attachment.user.crocodoc_id = 6
      canvadocs_api = @doc.send(:canvadocs_api)

      expect(canvadocs_api).to receive(:session).with(anything, hash_including(user_crocodoc_id: @attachment.user.crocodoc_id)).and_return({})
      @doc.session_url(user: @attachment.user, enable_annotations: true)
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

  describe "#has_annotations?" do
    it "has annotations when true" do
      @doc.has_annotations = true
      expect(@doc).to have_annotations
    end
  end
end
