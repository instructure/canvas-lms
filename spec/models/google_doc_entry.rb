#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
DOCS_FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures/google_docs/'
def load_fixture_entry(filename)
  GoogleDocEntry.new(File.read(DOCS_FIXTURES_PATH + filename))
end

describe GoogleDocEntry do
  context "to_hash" do
    let(:entry) { load_fixture_entry("spreadsheet_document_id_only_entry.xml") }
    let(:hash) { entry.to_hash }
    it "should use the display name" do
      expect(hash['name']).to eq entry.display_name
    end

    it "should have document_id, extension" do
      expect(hash['document_id']).not_to be_empty
      expect(hash['extension']).not_to be_empty
    end

    it "should have alternate_url" do
      expect(hash['alternate_url']).to eq 'http://docs.google.com'
    end
  end

  context "extension" do
    it "should be nil if no document_id or content type" do
      entry = load_fixture_entry("blank_entry.xml")
      expect(entry.document_id).to be_empty
      expect(entry.content_type).to be_nil
      expect(entry.extension).to be_nil
    end

    it "should be nil if no content type and unknown document_id prefix" do
      entry = load_fixture_entry("unknown_document_id_only_entry.xml")
      expect(entry.document_id).not_to be_empty
      expect(entry.content_type).to be_nil
      expect(entry.extension).to be_nil
    end

    it "should detect correctly if no content type and known document_id prefix" do
      entry = load_fixture_entry("spreadsheet_document_id_only_entry.xml")
      expect(entry.document_id).to be_present
      expect(entry.content_type).to be_nil
      expect(entry.extension).to eq 'xls'
    end

    it "should be nil if no document_id and unknown content type" do
      scribd_mime_type_model(:name => 'application/pdf', :extension => 'pdf')
      entry = load_fixture_entry("unknown_content_type_only_entry.xml")
      expect(entry.document_id).to be_empty
      expect(entry.content_type).to be_present
      expect(entry.extension).to be_nil
    end

    it "should detect correctly if no document_id and known content type" do
      scribd_mime_type_model(:name => 'application/pdf', :extension => 'pdf')
      entry = load_fixture_entry("pdf_content_type_only_entry.xml")
      expect(entry.document_id).to be_empty
      expect(entry.content_type).to be_present
      expect(entry.extension).to eq 'pdf'
    end

    it "should prefer content type over document_id for detection" do
      scribd_mime_type_model(:name => 'application/pdf', :extension => 'pdf')
      entry = load_fixture_entry("conflicting_document_id_and_content_type_entry.xml")
      expect(entry.document_id).to be_present
      expect(entry.content_type).to be_present
      expect(entry.extension).to eq 'pdf'
    end
  end
end
