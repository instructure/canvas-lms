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

require 'gradebook_csv_parser'

describe CSVParser do
  context "initialize" do
    it "should require contents" do
      expect{CSVParser.new}.to raise_error
      expect{CSVParser.new('some contents')}.not_to raise_error
    end
    
    it "should make contents accessible" do
      expect(CSVParser.new('some contents').contents).to eql('some contents')
    end
  end
  
  context "gradebook" do
    before(:each) do
      @cp = CSVParser.new(valid_gradebook_csv_content)
    end
    
    it "should offer an array of arrays" do
      expect(@cp.gradebook).to be_is_a(Array)
    end
    
    it "should offer a series of open structs to contain the gradebook details" do
      @cp.gradebook.each {|row| row.each {|cell| expect(cell).to be_is_a(OpenStruct)}}
    end
    
    it "should be able to use run as an alias for gradebook" do
      expect(@cp.gradebook).to eql(@cp.run)
    end
    
  end
end
