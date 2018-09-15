#
# Copyright (C) 2012 - present Instructure, Inc.
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

describe "User Content" do
  describe "ContextController#object_snippet" do
    it "should reject object_snippet on non-safefiles domain" do
      allow(HostUrl).to receive(:is_file_host?).with("files.example.com").and_return(true)
      allow(HostUrl).to receive(:is_file_host?).with("canvas.example.com").and_return(false)
      allow(HostUrl).to receive(:has_file_host?).and_return(true)

      obj_data = "<div>test</div>"
      snippet = Base64.encode64 obj_data
      sig = Canvas::Security.hmac_sha1(snippet)
      post "http://files.example.com/object_snippet", params: {:object_data => snippet, :s => sig}
      expect(response).to be_successful
      expect(response.body).to be_include(obj_data)

      post "http://canvas.example.com/object_snippet", params: {:object_data => snippet, :s => sig}
      assert_status(400)
      expect(response.body).to be_blank
    end

    it "should allow object_snippet if there is no safefiles domain configured" do
      allow(HostUrl).to receive(:default_host).and_return("canvas.example.com")
      allow(HostUrl).to receive(:file_host).and_return("canvas.example.com")

      obj_data = "<div>test</div>"
      snippet = Base64.encode64 obj_data
      sig = Canvas::Security.hmac_sha1(snippet)
      post "http://files.example.com/object_snippet", params: {:object_data => snippet, :s => sig}
      expect(response).to be_successful
      expect(response.body).to be_include(obj_data)
    end
  end
end
