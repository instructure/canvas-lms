#
# Copyright (C) 2019 - present Instructure, Inc.
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

require_relative '../spec_helper'

describe "a mock static site" do

  it "should throw exception if static site directory doesn't exist" do
    expect {
      MockStaticSite.new('asdf.test', 'non_existant_location')
    }.to raise_error(NonexistentMockSiteError)
  end

  it "should create a MockStaticSite if the directory does exist" do
    expect {
      MockStaticSite.new('asdf.test', 'sample_site')
    }.not_to raise_error
  end

  context "when created" do

    it "finds the index file" do
      MockStaticSite.new('google.com', 'sample_site')
      response = Net::HTTP.get('google.com', '/')
      expect(response).to include('sample page')
    end
    
    it "finds a specific file" do
      MockStaticSite.new('google.com', 'sample_site')
      response = Net::HTTP.get('google.com', '/file.txt')
      expect(response).to include('This is a sample file.')
    end

    it "only blocks the specified host" do
      MockStaticSite.new('google.com', 'sample_site')
      google_response = Net::HTTP.get('google.com', '/')
      other_response = Net::HTTP.get('canvaslms.com', '/')

      expect(google_response).to include('This is a sample page')
      expect(other_response).not_to include('This is a sample page')
    end
  end
end
