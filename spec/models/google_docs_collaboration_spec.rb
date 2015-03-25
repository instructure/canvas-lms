#
# Copyright (C) 2014 Instructure, Inc.
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

require 'spec_helper'

describe GoogleDocsCollaboration do
  describe "#initialize_document" do
    let(:user) { User.new }
    it "creates a google doc" do
      google_docs_collaboration = GoogleDocsCollaboration.new
      google_docs_collaboration.title = "title"
      google_docs_collaboration.user = user
      google_doc_connection = stub(retrieve_access_token: "asdf123")

      Canvas::Plugin.stubs(:find).with(:google_drive).returns(nil)
      GoogleDocs::Connection.expects(:new).returns(google_doc_connection)
      file = stub(document_id: 1, entry: stub(to_xml: "<xml></xml>"), alternate_url: "http://google.com")
      google_doc_connection.expects(:create_doc).with("title").returns(file)
      Rails.cache.expects(:fetch).returns(["token", "secret"])

      google_docs_collaboration.initialize_document
    end
  end
end