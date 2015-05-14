#
# Copyright (C) 2011-2014 Instructure, Inc.
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

describe GoogleDocs::DriveConnection do

  let(:token) { "token" }
  let(:secret) { "secret" }

  before do
    config = {
      "api_key" => "key",
      "secret_key" => "secret",
    }
    GoogleDocs::DriveConnection.config = proc do
      config
    end
  end

  describe "#file_extension from headers" do
    it "should pull the file extension from the response header" do
      google_docs = GoogleDocs::DriveConnection.new(token, secret)

      headers = {
        'content-disposition' => 'attachment;filename="Testing.docx"'
      }

      entry = stub('DriveEntry', extension: "not")
      file_extension  = google_docs.send(:file_extension_from_header, headers, entry)

      expect(file_extension).to eq("docx")
    end

    it "should pull the file extension from the entry if its not in the response header" do
      google_docs = GoogleDocs::DriveConnection.new(token, secret)

      headers = {
        'content-disposition' => 'attachment"'
      }

      entry = stub('DriveEntry', extension: "not")
      file_extension  = google_docs.send(:file_extension_from_header, headers, entry)
      expect(file_extension).to eq("not")
    end

    it "should use unknown as a last resort file extension" do
      google_docs = GoogleDocs::DriveConnection.new(token, secret)

      headers = {
        'content-disposition' => 'attachment"'
      }

      entry = stub('DriveEntry', extension: "")
      file_extension  = google_docs.send(:file_extension_from_header, headers, entry)
      expect(file_extension).to eq("unknown")
    end

    it "should use unknown as file extension when extension is nil" do
      google_docs = GoogleDocs::DriveConnection.new(token, secret)

      headers = {}
      entry = stub('DriveEntry', extension: nil)

      file_extension  = google_docs.send(:file_extension_from_header, headers, entry)
      expect(file_extension).to eq("unknown")
    end
  end

  describe "#normalize_document_id" do
    it "should remove prefixes" do
      google_docs = GoogleDocs::DriveConnection.new(token, secret)

      spreadsheet_id = google_docs.send(:normalize_document_id, "spreadsheet:awesome-spreadsheet-id")
      expect(spreadsheet_id).to eq("awesome-spreadsheet-id")

      doc_id = google_docs.send(:normalize_document_id, "document:awesome-document-id")
      expect(doc_id).to eq("awesome-document-id")
    end

    it "shouldnt do anything to normalized ids" do
      google_docs = GoogleDocs::DriveConnection.new(token, secret)


      spreadsheet_id = google_docs.send(:normalize_document_id, "awesome-spreadsheet-id")
      expect(spreadsheet_id).to eq("awesome-spreadsheet-id")

      doc_id = google_docs.send(:normalize_document_id, "awesome-document-id")
      expect(doc_id).to eq("awesome-document-id")

    end
  end
end
