#
# Copyright (C) 2014 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under the
# terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe 'Canvadoc' do

  def stub_upload
    Canvadocs::API.any_instance.stubs(:upload).returns "id" => 123456,
      "status" => "pending"
  end

  before do
    PluginSetting.create! :name => 'canvadocs',
                          :settings => {"api_key" => "blahblahblahblahblah",
                                        "base_url" => "http://example.com"}
    stub_upload
    Canvadocs::API.any_instance.stubs(:session).returns "id" => "blah",
      "status" => "pending"
    @attachment = attachment_model(content_type: "application/pdf")
    @doc = @attachment.create_canvadoc
  end

  def disable_canvadocs
    Canvadocs.stubs(:enabled?).returns false
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
      stub_upload.with(@doc.attachment.authenticated_s3_url, {})
      @doc.upload annotatable: true
    end
  end

  describe "#session_url" do
    it "returns a session_url" do
      @doc.upload
      expect(@doc.session_url).to eq "http://example.com/sessions/blah/view?theme=dark"
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
end
