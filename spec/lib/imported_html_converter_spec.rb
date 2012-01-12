#
# Copyright (C) 2012 Instructure, Inc.
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

describe ImportedHtmlConverter do
  
  context ".convert" do
    before(:each) do
      course
      @path = "/courses/#{@course.id}/"
    end
    
    it "should convert a wiki reference" do
      test_string = %{<a href="%24WIKI_REFERENCE%24/wiki/test-wiki-page">Test Wiki Page</a>}
      @course.wiki.wiki_pages.create!(:title => "Test Wiki Page", :body => "stuff")
  
      ImportedHtmlConverter.convert(test_string, @course).should == %{<a href="#{@path}wiki/test-wiki-page">Test Wiki Page</a>}
    end
    
    it "should convert a wiki reference without $ escaped" do
      test_string = %{<a href="$WIKI_REFERENCE$/wiki/test-wiki-page">Test Wiki Page</a>}
      @course.wiki.wiki_pages.create!(:title => "Test Wiki Page", :body => "stuff")
  
      ImportedHtmlConverter.convert(test_string, @course).should == %{<a href="#{@path}wiki/test-wiki-page">Test Wiki Page</a>}
    end
    
    it "should convert a wiki reference by migration id" do
      test_string = %{<a href="wiki_page_migration_id=123456677788">Test Wiki Page</a>}
      wiki = @course.wiki.wiki_pages.create(:title => "Test Wiki Page", :body => "stuff")
      wiki.migration_id = "123456677788"
      wiki.save!
  
      ImportedHtmlConverter.convert(test_string, @course).should == %{<a href="#{@path}wiki/test-wiki-page">Test Wiki Page</a>}
    end
    
    it "should convert a discussion reference by migration id" do
      test_string = %{<a href="discussion_topic_migration_id=123456677788">Test topic</a>}
      topic = @course.discussion_topics.create(:title => "Test discussion")
      topic.migration_id = "123456677788"
      topic.save!
  
      ImportedHtmlConverter.convert(test_string, @course).should == %{<a href="#{@path}discussion_topics/#{topic.id}">Test topic</a>}
    end
    
    it "should find an attachment by migration id" do
      att = Attachment.create(:filename => 'test.png', :display_name => "test.png", :uploaded_data => StringIO.new('psych!'), :folder => Folder.unfiled_folder(@course), :context => @course)
      att.migration_id = "1768525836051"
      att.save!
      
      test_string = %{<p>This is an image: <br /><img src="%24CANVAS_OBJECT_REFERENCE%24/attachments/1768525836051" alt=":(" /></p>}
      ImportedHtmlConverter.convert(test_string, @course).should == %{<p>This is an image: <br><img src="#{@path}files/#{att.id}/preview" alt=":("></p>}
    end
    
    it "should find an attachment by path" do
      att = Attachment.create(:filename => 'test.png', :display_name => "test.png", :uploaded_data => StringIO.new('psych!'), :folder => Folder.unfiled_folder(@course), :context => @course)
      att.migration_id = "1768525836051"
      att.save!
      
      test_string = %{<p>This is an image: <br /><img src="%24IMS_CC_FILEBASE%24/test.png" alt=":(" /></p>}
      
      # if there isn't a path->migration id map it'll be a relative course file path
      ImportedHtmlConverter.convert(test_string, @course).should == %{<p>This is an image: <br><img src="#{@path}file_contents/course%20files/test.png" alt=":("></p>}
  
      @course.attachment_path_id_lookup = {"test.png" => att.migration_id}
      ImportedHtmlConverter.convert(test_string, @course).should == %{<p>This is an image: <br><img src="#{@path}files/#{att.id}/preview" alt=":("></p>}
    end
  
    it "should convert course section urls" do
      test_string = %{<a href="%24CANVAS_COURSE_REFERENCE%24/discussion_topics">discussions</a>}
      ImportedHtmlConverter.convert(test_string, @course).should == %{<a href="#{@path}discussion_topics">discussions</a>}
    end
  
    it "should leave invalid and absolute urls alone" do
      test_string = %{<a href="stupid &^%$ url">Linkage</a><br><a href="http://www.example.com/poop">Linkage</a>}
      ImportedHtmlConverter.convert(test_string, @course).should == %{<a href="stupid%20&amp;%5E%%24%20url">Linkage</a><br><a href="http://www.example.com/poop">Linkage</a>}
    end
  
    it "should prepend course files for unrecognized relative urls" do
      test_string = %{<a href="/relative/path/to/file">Linkage</a>}
      ImportedHtmlConverter.convert(test_string, @course).should == %{<a href="#{@path}file_contents/course%20files/relative/path/to/file">Linkage</a>}
      test_string = %{<a href="relative/path/to/file">Linkage</a>}
      ImportedHtmlConverter.convert(test_string, @course).should == %{<a href="#{@path}file_contents/course%20files/relative/path/to/file">Linkage</a>}
      test_string = %{<a href="relative/path/to/file%20with%20space.html">Linkage</a>}
      ImportedHtmlConverter.convert(test_string, @course).should == %{<a href="#{@path}file_contents/course%20files/relative/path/to/file%20with%20space.html">Linkage</a>}
    end
  end
  
  context ".relative_url?" do
    it "should recognize an absolute url" do
      ImportedHtmlConverter.relative_url?("http://example.com").should == false
    end
    
    it "should recognize relative urls" do
      ImportedHtmlConverter.relative_url?("/relative/eh").should == true
      ImportedHtmlConverter.relative_url?("also/relative").should == true
      ImportedHtmlConverter.relative_url?("watup/nothing.html#anchoritbaby").should == true
      ImportedHtmlConverter.relative_url?("watup/nothing?absolutely=1").should == true
    end
    
    it "should error on invalid urls" do
      expect { ImportedHtmlConverter.relative_url?("stupid &^%$ url") }.to raise_error(URI::InvalidURIError)
    end
  end

end
