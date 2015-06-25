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

  fake_client = Class.new do
    attr_reader :token
    attr_writer :responses

    def initialize(input=nil)
      @input = input
      @calls = 0
      @token = 0
      @responses = []
    end

    def insert
      self
    end

    def request_schema
      self.class
    end

    def discovered_api(_endpoint, _version)
      self
    end

    def files
      self
    end

    def authorization
      self
    end

    def update_token!
      @token += 1
    end

    def get
      "/api_method"
    end

    def execute!(*_args)
      response = @responses[@calls]
      @calls += 1
      response
    end

    def execute(*args)
      execute!(*args)
    end

  end

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

  describe "API interaction" do
    let(:connection){ GoogleDocs::DriveConnection.new(token, secret) }
    let(:client){ fake_client.new }

    before do
      connection.send(:set_api_client, client)
    end

    describe "#download" do
      before do
        client.responses = [
          stub(status: 200, data:
                {
                  'parents' => [],
                  'title' => "SomeFile.txt"
                }
              ),
          stub(status: 200, data: {})
        ]
      end

      it "requests a download from the api client" do
        output = connection.download("42", nil)
        expect(output[1]).to eq("SomeFile.txt")
        expect(output[2]).to eq("txt")
      end

      it "wraps a timeout in a drive connection exception" do
        Timeout.stubs(:timeout).raises(Timeout::Error)
        expect{ connection.download("42", nil) }.to(
          raise_error(GoogleDocs::DriveConnectionException) do |e|
            expect(e.message).to eq("Google Drive connection timed out")
          end
        )
      end
    end

    describe "#create_doc" do

      before do
        client.responses = [
          stub(status: 200, data: {})
        ]
      end

      it "forces a new refresh token" do
        connection.create_doc("DocName")
        expect(client.token).to eq(1)
      end

      it "wraps a timeout in a drive connection exception" do
        Timeout.stubs(:timeout).raises(Timeout::Error)
        expect{ connection.create_doc("Docname") }.to(
          raise_error(GoogleDocs::DriveConnectionException) do |e|
            expect(e.message).to eq("Google Drive connection timed out")
          end
        )
      end
    end
  end
end
