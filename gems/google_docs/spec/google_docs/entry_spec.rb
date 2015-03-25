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

DOCS_FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures/google_docs/'

def load_fixture(filename)
  File.read(DOCS_FIXTURES_PATH + filename)
end

describe GoogleDocs::Entry do
  let(:entry_feed) { load_fixture("create_doc_response.xml") }

  describe "#extension" do
    context "with an extension looker upper" do
      before do
        extension_looker_upper = mock
        extension_mock = mock
        extension_looker_upper.expects(:find_by_name).with('text/html').returns(extension_mock)
        extension_mock.expects(:extension).returns("whatever")
        GoogleDocs::Entry.extension_looker_upper = extension_looker_upper
      end

      after do
        GoogleDocs::Entry.extension_looker_upper = nil
      end

      it "checks the extension_looker_upper first" do
        entry = GoogleDocs::Entry.new(entry_feed)
        entry.extension.should == "whatever"
      end
    end

    it "is 'doc' when document id matches 'document'" do
      entry = GoogleDocs::Entry.new(entry_feed)
      entry.extension.should == "doc"
    end

    it "can be reset/forced to 'xlsx'" do
      entry = GoogleDocs::Entry.new(entry_feed)
      entry.extension.should == "doc"
      entry.reset_extension_as_xlsx
      entry.extension.should == "xlsx"
    end
  end

  describe '#download_url' do
    it 'should add exportFormat and format parameters when applicable' do
      entry = GoogleDocs::Entry.new(entry_feed)
      entry.stubs(:extension).returns("xls")

      url = URI.parse(entry.download_url)

      url.scheme.should == "https"
      url.host.should == "docs.google.com"
      url.path.should == "/feeds/download/documents/export/Export"

      params = url.query.split("&")
      params.should include("id=1HJoN38KHlnu32B5z_THgchnTMUbj7dgs8P-Twrm38cA")
      params.should include("exportFormat=xls")
      params.should include("format=xls")

      entry.stubs(:extension).returns(nil)
      entry.download_url.should == "https://docs.google.com/feeds/download/documents/export/Export?id=1HJoN38KHlnu32B5z_THgchnTMUbj7dgs8P-Twrm38cA"
    end
  end
end
