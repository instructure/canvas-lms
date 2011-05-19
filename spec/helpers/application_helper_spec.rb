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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ApplicationHelper do
  include ApplicationHelper
  
  context "folders_as_options" do
    before(:each) do
      course_model
      @f = Folder.create!(:name => 'f', :context => @course)
      @f_1 = Folder.create!(:name => 'f_1', :parent_folder => @f, :context => @course)
      @f_2 = Folder.create!(:name => 'f_2', :parent_folder => @f, :context => @course)
      @f_2_1 = Folder.create!(:name => 'f_2_1', :parent_folder => @f_2, :context => @course)
      @f_2_1_1 = Folder.create!(:name => 'f_2_1_1', :parent_folder => @f_2_1, :context => @course)
      @all_folders = [ @f, @f_1, @f_2, @f_2_1, @f_2_1_1 ]
    end
    
    it "should work work recursively" do
      option_string = folders_as_options([@f], :all_folders => @all_folders)
      
      html = Nokogiri::HTML::DocumentFragment.parse("<select>#{option_string}</select>")
      html.css('option').count.should == 5
      html.css('option')[0].text.should == @f.name
      html.css('option')[1].text.should match /^\xC2\xA0\xC2\xA0\xC2\xA0- #{@f_1.name}/
      html.css('option')[4].text.should match /^\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0- #{@f_2_1_1.name}/
    end
    
    it "should limit depth" do
      option_string = folders_as_options([@f], :all_folders => @all_folders, :max_depth => 1)
      
      html = Nokogiri::HTML::DocumentFragment.parse("<select>#{option_string}</select>")
      html.css('option').count.should == 3
      html.css('option')[0].text.should == @f.name
      html.css('option')[1].text.should match /^\xC2\xA0\xC2\xA0\xC2\xA0- #{@f_1.name}/
      html.css('option')[2].text.should match /^\xC2\xA0\xC2\xA0\xC2\xA0- #{@f_2.name}/
    end
    
    it "should work without supplying all folders" do
      option_string = folders_as_options([@f])
      
      html = Nokogiri::HTML::DocumentFragment.parse("<select>#{option_string}</select>")
      html.css('option').count.should == 5
      html.css('option')[0].text.should == @f.name
      html.css('option')[1].text.should match /^\xC2\xA0\xC2\xA0\xC2\xA0- #{@f_1.name}/
      html.css('option')[4].text.should match /^\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0- #{@f_2_1_1.name}/
    end
  end
end
