#
# Copyright (C) 2015 - present Instructure, Inc.
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

describe GoogleDrive::Connection do

  let(:connection) { GoogleDrive::Connection.new(token, secret, retries: 1) }
  let(:token) { "token" }
  let(:secret) { "secret" }
  let(:config) do
    {
      "api_key" => "key",
      "secret_key" => "secret",
    }
  end

  before do
    GoogleDrive::Connection.config = proc { config }
  end

  describe "#file_extension from headers" do
    it "should pull the file extension from the response header" do
      headers = {
        'content-disposition' => 'attachment;filename="Testing.docx"'
      }

      entry = double('Entry', extension: "not")
      file_extension = connection.send(:file_extension_from_header, headers, entry)

      expect(file_extension).to eq("docx")
    end

    it "should pull the file extension from the entry if its not in the response header" do
      headers = {
        'content-disposition' => 'attachment"'
      }

      entry = double('Entry', extension: "not")
      file_extension = connection.send(:file_extension_from_header, headers, entry)
      expect(file_extension).to eq("not")
    end

    it "should use unknown as a last resort file extension" do
      headers = {
        'content-disposition' => 'attachment"'
      }

      entry = double('Entry', extension: "")
      file_extension = connection.send(:file_extension_from_header, headers, entry)
      expect(file_extension).to eq("unknown")
    end

    it "should use unknown as file extension when extension is nil" do
      headers = {}
      entry = double('Entry', extension: nil)

      file_extension = connection.send(:file_extension_from_header, headers, entry)
      expect(file_extension).to eq("unknown")
    end
  end

  describe "#normalize_document_id" do
    it "should remove prefixes" do
      spreadsheet_id = connection.send(:normalize_document_id, "spreadsheet:awesome-spreadsheet-id")
      expect(spreadsheet_id).to eq("awesome-spreadsheet-id")

      doc_id = connection.send(:normalize_document_id, "document:awesome-document-id")
      expect(doc_id).to eq("awesome-document-id")
    end

    it "shouldnt do anything to normalized ids" do
      spreadsheet_id = connection.send(:normalize_document_id, "awesome-spreadsheet-id")
      expect(spreadsheet_id).to eq("awesome-spreadsheet-id")

      doc_id = connection.send(:normalize_document_id, "awesome-document-id")
      expect(doc_id).to eq("awesome-document-id")
    end
  end

  describe "API interaction" do
    before do
      stub_request(:get, "https://www.googleapis.com/discovery/v1/apis/drive/v2/rest").
        to_return(
          :status => 200,
          :body => load_fixture('discovered_api.json'),
          :headers => {'Content-Type' => 'application/json'}
        )
    end

    describe "#list_with_extension_filter" do
      let(:http_status) { 200 }
      let(:body) { load_fixture('list.json') }
      let(:url) { 'https://www.googleapis.com/drive/v2/files?maxResults=0&q=trashed=false' }
      let(:request) do
        stub_request(:get, url).
          to_return(
            status: http_status,
            body: body,
            headers: {'Content-Type' => 'application/json'}
          )
      end

      before { request }

      context 'with 200 success response' do
        it "should submit `trashed = false` parameter" do
          connection.list_with_extension_filter('txt')
          expect(WebMock).to have_requested(:get, url)
        end

        it "should return allowed extension" do
          returned_list = connection.list_with_extension_filter('png')
          expect(returned_list.files.select { |a| a.entry["fileExtension"] == 'png' }).not_to be_empty
        end

        it "should not return other extension" do
          returned_list = connection.list_with_extension_filter('txt')
          expect(returned_list.files).to be_empty
        end

        it "should return all extensions if no extension filter provided" do
          returned_list = connection.list_with_extension_filter('')
          expect(returned_list.files.select { |a| a.entry["fileExtension"] == 'png' }).not_to be_empty
        end
      end

      context 'with 429 throttling response' do
        let(:http_status) { 429 }
        let(:body) { '' }

        it 'will retry on ClientError' do
          expect { connection.list_with_extension_filter('txt') }.to raise_error Google::APIClient::ClientError

          expect(WebMock).to(have_requested(:get, url).times(2))
        end
      end

      context 'with 503 gateway error response' do
        let(:http_status) { 503 }
        let(:body) { '' }

        it 'will retry on ServerError' do
          expect { connection.list_with_extension_filter('txt') }.to raise_error Google::APIClient::ServerError

          expect(WebMock).to(have_requested(:get, url).times(2))
        end
      end
    end

    describe "#download" do
      let(:export_url) { 'https://docs.google.com/feeds/download/documents/export/Export?exportFormat=docx&id=**file_id**' }
      let(:files_url) { 'https://www.googleapis.com/drive/v2/files/42' }
      let(:http_status) { 200 }

      before do
        stub_request(:get, files_url).to_return(
          :status => http_status,
          body: load_fixture('file_data.json'),
          headers: {'Content-Type' => 'application/json'}
        )

        stub_request(:get, export_url).to_return(
          status: 200,
          body: '',
          headers: {
            'Content-Type' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
          }
        )
      end

      it "requests a download from the api client" do
        output = connection.download("42", nil)
        expect(output[1]).to eq("Biology 100 Collaboration.docx")
        expect(output[2]).to eq("docx")
      end

      it "wraps a timeout in a drive connection exception" do
        allow(Timeout).to receive(:timeout).and_raise(Timeout::Error)
        expect{ connection.download("42", nil) }.to(
          raise_error(GoogleDrive::ConnectionException) do |e|
            expect(e.message).to eq("Google Drive connection timed out")
          end
        )
      end

      context 'with 429 throttling response' do
        let(:http_status) { 429 }

        it 'will retry on ClientError' do
          expect { connection.download("42", nil) }.to raise_error Google::APIClient::ClientError

          expect(WebMock).to(have_requested(:get, files_url).times(2))
        end
      end

      context 'with 503 gateway error response' do
        let(:http_status) { 503 }
        let(:body) { '' }

        it 'will retry on ServerError' do
          expect { connection.download("42", nil) }.to raise_error Google::APIClient::ServerError

          expect(WebMock).to(have_requested(:get, files_url).times(2))
        end
      end
    end

    describe "#create_doc" do
      it "wraps a timeout in a drive connection exception" do

        allow(Timeout).to receive(:timeout).and_raise(Timeout::Error)
        expect{ connection.create_doc("Docname") }.to(
          raise_error(GoogleDrive::ConnectionException) do |e|
            expect(e.message).to eq("Google Drive connection timed out")
          end
        )
      end
    end

    describe "#authorized?" do
      it "returns false when there ConnectionException" do
        GoogleDrive::Connection.config = GoogleDrive::Connection.config = proc do
          nil
        end

        expect(connection.authorized?).to be false
      end

      it "returns false when there NoTokenError" do
        my_connection = GoogleDrive::Connection.new(nil, nil)

        expect(my_connection.authorized?).to be false
      end

      it "returns false when there NoTokenError" do

        stub_request(:get, "https://www.googleapis.com/drive/v2/about").
          to_return(:status => 200, :body => "", :headers => {})

        expect(connection.authorized?).to be true
      end
    end
  end
end
