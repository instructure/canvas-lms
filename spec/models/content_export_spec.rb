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

describe ContentExport do

  context "export_object?" do
    before do
      @ce = ContentExport.new
    end

    it "should return true for everything if there are no copy options" do
      @ce.export_object?(@ce).should == true
    end

    it "should return true for everything if 'everything' is selected" do
      @ce.selected_content = {:everything => "1"}
      @ce.export_object?(@ce).should == true
    end

    it "should return false for nil objects" do
      @ce.export_object?(nil).should == false
    end

    it "should return true for all object types if the all_ option is true" do
      @ce.selected_content = {:all_content_exports => "1"}
      @ce.export_object?(@ce).should == true
    end

    it "should return false for objects not selected" do
      @ce.save!
      @ce.selected_content = {:all_content_exports => "0"}
      @ce.export_object?(@ce).should == false
      @ce.selected_content = {:content_exports => {}}
      @ce.export_object?(@ce).should == false
      @ce.selected_content = {:content_exports => {CC::CCHelper.create_key(@ce) => "0"}}
      @ce.export_object?(@ce).should == false
    end

    it "should return true for selected objects" do
      @ce.save!
      @ce.selected_content = {:content_exports => {CC::CCHelper.create_key(@ce) => "1"}}
      @ce.export_object?(@ce).should == true
    end

  end

end