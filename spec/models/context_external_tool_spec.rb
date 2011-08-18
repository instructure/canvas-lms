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

describe ContextExternalTool do
  before(:each) do
    course_model
    @root_account = @course.root_account
    @account = account_model(:root_account => @root_account, :parent_account => @root_account)
    @course.update_attribute(:account, @account)
    @course.account.should eql(@account)
    @course.root_account.should eql(@root_account)
    @account.parent_account.should eql(@root_account)
    @account.root_account.should eql(@root_account)
  end
  describe "find_external_tool" do
    it "should match on the same domain" do
      @tool = @course.context_external_tools.create!(:name => "a", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://google.com/is/cool", Course.find(@course.id))
      @found_tool.should eql(@tool)
    end
    
    it "should match on a subdomain" do
      @tool = @course.context_external_tools.create!(:name => "a", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com/is/cool", Course.find(@course.id))
      @found_tool.should eql(@tool)
    end
    
    it "should not match on non-matching domains" do
      @tool = @course.context_external_tools.create!(:name => "a", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tool2 = @course.context_external_tools.create!(:name => "a", :domain => "www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://mgoogle.com/is/cool", Course.find(@course.id))
      @found_tool.should eql(nil)
      @found_tool = ContextExternalTool.find_external_tool("http://sgoogle.com/is/cool", Course.find(@course.id))
      @found_tool.should eql(nil)
    end
    
    it "should not match on the closest matching domain" do
      @tool = @course.context_external_tools.create!(:name => "a", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tool2 = @course.context_external_tools.create!(:name => "a", :domain => "www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://www.www.google.com/is/cool", Course.find(@course.id))
      @found_tool.should eql(@tool2)
    end
    
    it "should match on exact url" do
      @tool = @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com/coolness", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com/coolness", Course.find(@course.id))
      @found_tool.should eql(@tool)
    end
    
    it "should not match on domain before matching on url" do
      @tool = @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com/coolness", :consumer_key => '12345', :shared_secret => 'secret')
      @tool2 = @course.context_external_tools.create!(:name => "a", :domain => "www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com/coolness", Course.find(@course.id))
      @found_tool.should eql(@tool2)
    end
    
    it "should find the nearest account's tool matching on domain first" do
      @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @course.context_external_tools.create!(:name => "b", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @account.context_external_tools.create!(:name => "c", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tool = @account.context_external_tools.create!(:name => "d", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @root_account.context_external_tools.create!(:name => "e", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @root_account.context_external_tools.create!(:name => "f", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://something.google.com/is/cool", Course.find(@course.id))
      @found_tool.should eql(@tool)
    end
    
    it "should find the root account's tool matching on domain before matching by url or on the course" do
      @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @course.context_external_tools.create!(:name => "b", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @account.context_external_tools.create!(:name => "c", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @root_account.context_external_tools.create!(:name => "e", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tool = @root_account.context_external_tools.create!(:name => "f", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://something.google.com/is/cool", Course.find(@course.id))
      @found_tool.should eql(@tool)
    end
    
    it "should find the nearest account's tool matching on url if no domain-tools are found" do
      @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tool = @account.context_external_tools.create!(:name => "c", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @root_account.context_external_tools.create!(:name => "e", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id))
      @found_tool.should eql(@tool)
    end
    
    it "should find the root account's tool matching on url if no domain-tools are found before matching on the course" do
      @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tool = @root_account.context_external_tools.create!(:name => "e", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com/", Course.find(@course.id))
      @found_tool.should eql(@tool)
    end
  end
  
  describe "custom fields" do
    it "should parse custom_fields_string from a text field" do
      tool = @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      tool.custom_fields_string=("a=1\nbT^@!#n_40=123\n\nc=")
      tool.settings[:custom_fields].should_not be_nil
      tool.settings[:custom_fields].keys.length.should == 2
      tool.settings[:custom_fields]['a'].should == '1'
      tool.settings[:custom_fields]['bT^@!#n_40'].should == '123'
      tool.settings[:custom_fields]['c'].should == nil
    end
    
    it "should return custom_fields_string as a text-formatted field" do
      tool = @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret', :custom_fields => {'a' => '123', 'b' => '456'})
      tool.custom_fields_string.should == "a=123\nb=456"
    end
    
    
  end
  
  describe "all_tools_for" do
    it "should retrieve all tools in alphabetical order" do
      @tools = []
      @tools << @root_account.context_external_tools.create!(:name => "f", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tools << @root_account.context_external_tools.create!(:name => "e", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tools << @account.context_external_tools.create!(:name => "d", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tools << @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tools << @course.context_external_tools.create!(:name => "b", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tools << @account.context_external_tools.create!(:name => "c", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      ContextExternalTool.all_tools_for(@course).should eql(@tools.sort_by(&:name))
    end
  end

  describe "standardize_url" do
    it "should standardize urls" do
      url = ContextExternalTool.standardize_url("http://www.google.com?a=1&b=2")
      url.should eql(ContextExternalTool.standardize_url("http://www.google.com?b=2&a=1"))
      url.should eql(ContextExternalTool.standardize_url("http://www.google.com/?b=2&a=1"))
      url.should eql(ContextExternalTool.standardize_url("www.google.com/?b=2&a=1"))
    end
  end
  
  describe "find_for" do
    it "should find the tool if it's attached to the course" do
      course_model
      tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob")
      tool.settings[:course_navigation] = {:url => "http://www.example.com", :text => "Example URL"}
      tool.save!
      ContextExternalTool.find_for(tool.id, @course, :course_navigation).should == tool
      (ContextExternalTool.find_for(tool.id, @course, :user_navigation) rescue nil).should be_nil
    end
    
    it "should find the tool if it's attached to the account" do
    end
    
    it "should find the tool if it's attached to the course's account" do
      course_model
      tool = @course.account.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob")
      tool.settings[:course_navigation] = {:url => "http://www.example.com", :text => "Example URL"}
      tool.save!
      ContextExternalTool.find_for(tool.id, @course, :course_navigation).should == tool
      (ContextExternalTool.find_for(tool.id, @course, :user_navigation) rescue nil).should be_nil
    end
    
    it "should find the tool if it's attached to the course's root account" do
      course_model
      tool = @course.root_account.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob")
      tool.settings[:course_navigation] = {:url => "http://www.example.com", :text => "Example URL"}
      tool.save!
      ContextExternalTool.find_for(tool.id, @course, :course_navigation).should == tool
      (ContextExternalTool.find_for(tool.id, @course, :user_navigation) rescue nil).should be_nil
    end
    
    it "should not find the tool if it's attached to a sub-account" do
      course_model
      @account = @course.account.sub_accounts.create!(:name => "sub-account")
      tool = @account.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob")
      tool.settings[:course_navigation] = {:url => "http://www.example.com", :text => "Example URL"}
      tool.save!
      (ContextExternalTool.find_for(tool.id, @course, :course_navigation) rescue nil).should be_nil
    end
    
    it "should not find the tool if it's attached to another course" do
      @course2 = course_model
      @course = course_model
      tool = @course2.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob")
      tool.settings[:course_navigation] = {:url => "http://www.example.com", :text => "Example URL"}
      tool.save!
      (ContextExternalTool.find_for(tool.id, @course, :course_navigation) rescue nil).should be_nil
    end
    
    it "should not find the tool if it's not enabled for the correct navigation type" do
      course_model
      tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob")
      tool.settings[:course_navigation] = {:url => "http://www.example.com", :text => "Example URL"}
      tool.save!
      (ContextExternalTool.find_for(tool.id, @course, :user_navigation) rescue nil).should be_nil
    end
  end
end
