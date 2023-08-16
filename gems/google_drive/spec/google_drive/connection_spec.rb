# frozen_string_literal: true

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

require "spec_helper"

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

  describe "#normalize_document_id" do
    it "removes prefixes" do
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
    describe "#create_doc" do
      it "wraps a timeout in a drive connection exception" do
        allow(connection).to receive(:force_token_update)
        stub_request(:post, "https://www.googleapis.com/drive/v3/files?fields=id,webViewLink")
          .to_return do
            raise HTTPClient::ReceiveTimeoutError
          end
        expect { connection.create_doc("Docname") }.to(
          raise_error(GoogleDrive::ConnectionException) do |e|
            expect(e.message).to eq("Google Drive connection timed out")
          end
        )
      end
    end

    describe "#authorized?" do
      it "returns false when there ConnectionException" do
        stub_request(:get, "https://www.googleapis.com/drive/v3/about?fields=user")
          .to_return(status: 500, body: "", headers: {})

        expect(connection.authorized?).to be false
      end

      it "returns false when there NoTokenError" do
        my_connection = GoogleDrive::Connection.new(nil, nil)

        expect(my_connection.authorized?).to be false
      end

      it "returns true when response is 200" do
        stub_request(:get, "https://www.googleapis.com/drive/v3/about?fields=user")
          .to_return(status: 200, body: "", headers: {})

        expect(connection.authorized?).to be true
      end
    end
  end
end
