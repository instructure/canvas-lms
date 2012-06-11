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
  describe "url or domain validation" do
    it "should validate with a domain setting" do
      @tool = @course.context_external_tools.create(:name => "a", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tool.should_not be_new_record
      @tool.errors.should be_empty
    end
    
    it "should validate with a url setting" do
      @tool = @course.context_external_tools.create(:name => "a", :url => "http://google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tool.should_not be_new_record
      @tool.errors.should be_empty
    end
    
    it "should validate with a canvas lti extension url setting" do
      @tool = @course.context_external_tools.new(:name => "a", :consumer_key => '12345', :shared_secret => 'secret')
      @tool.settings[:editor_button] = {
        "icon_url"=>"http://www.example.com/favicon.ico", 
        "text"=>"Example",
        "url"=>"http://www.example.com", 
        "selection_height"=>400, 
        "selection_width"=>600
      }
      @tool.save
      @tool.should_not be_new_record
      @tool.errors.should be_empty
    end
    
    it "should not validate with no domain or url setting" do
      @tool = @course.context_external_tools.create(:name => "a", :consumer_key => '12345', :shared_secret => 'secret')
      @tool.should be_new_record
      @tool.errors['url'].should == "Either the url or domain should be set."
      @tool.errors['domain'].should == "Either the url or domain should be set."
    end
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
    
    it "should not match on url before matching on domain" do
      @tool = @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com/coolness", :consumer_key => '12345', :shared_secret => 'secret')
      @tool2 = @course.context_external_tools.create!(:name => "a", :domain => "www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com/coolness", Course.find(@course.id))
      @found_tool.should eql(@tool)
    end
    
    it "should find the context's tool matching on url first" do
      @tool = @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @course.context_external_tools.create!(:name => "b", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @account.context_external_tools.create!(:name => "c", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @account.context_external_tools.create!(:name => "d", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @root_account.context_external_tools.create!(:name => "e", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @root_account.context_external_tools.create!(:name => "f", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id))
      @found_tool.should eql(@tool)
    end
    
    it "should find the nearest account's tool matching on url if there are no url-matching context tools" do
      @course.context_external_tools.create!(:name => "b", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tool = @account.context_external_tools.create!(:name => "c", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @account.context_external_tools.create!(:name => "d", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @root_account.context_external_tools.create!(:name => "e", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @root_account.context_external_tools.create!(:name => "f", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id))
      @found_tool.should eql(@tool)
    end
    
    it "should find the root account's tool matching on url before matching by domain on the course" do
      @course.context_external_tools.create!(:name => "b", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @account.context_external_tools.create!(:name => "d", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tool = @root_account.context_external_tools.create!(:name => "e", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @root_account.context_external_tools.create!(:name => "f", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id))
      @found_tool.should eql(@tool)
    end
    
    it "should find the context's tool matching on domain if no url-matching tools are found" do
      @tool = @course.context_external_tools.create!(:name => "b", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @account.context_external_tools.create!(:name => "d", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @root_account.context_external_tools.create!(:name => "f", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id))
      @found_tool.should eql(@tool)
    end
    
    it "should find the nearest account's tool matching on domain if no url-matching tools are found" do
      @tool = @account.context_external_tools.create!(:name => "c", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @root_account.context_external_tools.create!(:name => "e", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id))
      @found_tool.should eql(@tool)
    end
    
    it "should find the root account's tool matching on domain if no url-matching tools are found" do
      @tool = @root_account.context_external_tools.create!(:name => "e", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com/", Course.find(@course.id))
      @found_tool.should eql(@tool)
    end
    
    it "should find the preferred tool if there are two matching-priority tools" do
      @tool1 = @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tool2 = @course.context_external_tools.create!(:name => "b", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id), @tool1.id)
      @found_tool.should eql(@tool1)
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id), @tool2.id)
      @found_tool.should eql(@tool2)
      @tool1.destroy
      @tool2.destroy
      
      @tool1 = @course.context_external_tools.create!(:name => "a", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tool2 = @course.context_external_tools.create!(:name => "b", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id), @tool1.id)
      @found_tool.should eql(@tool1)
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id), @tool2.id)
      @found_tool.should eql(@tool2)
    end
    
    it "should find the preferred tool even if there is a higher priority tool configured, provided the preferred tool has resource_selection set" do
      @tool = @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @course.context_external_tools.create!(:name => "b", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @account.context_external_tools.create!(:name => "c", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @account.context_external_tools.create!(:name => "d", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @root_account.context_external_tools.create!(:name => "e", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @preferred = @root_account.context_external_tools.create!(:name => "f", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id), @preferred.id)
      @found_tool.should eql(@tool)
      @preferred.settings[:resource_selection] = {:url => "http://www.example.com", :selection_width => 400, :selection_height => 400}
      @preferred.save!
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id), @preferred.id)
      @found_tool.should eql(@preferred)
    end
    
    it "should not find the preferred tool if it is deleted" do
      @preferred = @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @preferred.destroy
      @course.context_external_tools.create!(:name => "b", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tool = @account.context_external_tools.create!(:name => "c", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @account.context_external_tools.create!(:name => "d", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @root_account.context_external_tools.create!(:name => "e", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @root_account.context_external_tools.create!(:name => "f", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id), @preferred.id)
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
  
  describe "infer_defaults" do
    def new_external_tool
      @root_account.context_external_tools.new(:name => "t", :consumer_key => '12345', :shared_secret => 'secret', :domain => "google.com")
    end
    
    it "should require valid configuration for user navigation settings" do
      tool = new_external_tool
      tool.settings = {:user_navigation => {:bob => 'asfd'}}
      tool.save
      tool.settings[:user_navigation].should be_nil
      tool.settings = {:user_navigation => {:url => "http://www.example.com"}}
      tool.save
      tool.settings[:user_navigation].should_not be_nil
    end
    
    it "should require valid configuration for course navigation settings" do
      tool = new_external_tool
      tool.settings = {:course_navigation => {:bob => 'asfd'}}
      tool.save
      tool.settings[:course_navigation].should be_nil
      tool.settings = {:course_navigation => {:url => "http://www.example.com"}}
      tool.save
      tool.settings[:course_navigation].should_not be_nil
    end
    
    it "should require valid configuration for account navigation settings" do
      tool = new_external_tool
      tool.settings = {:account_navigation => {:bob => 'asfd'}}
      tool.save
      tool.settings[:account_navigation].should be_nil
      tool.settings = {:account_navigation => {:url => "http://www.example.com"}}
      tool.save
      tool.settings[:account_navigation].should_not be_nil
    end
    
    it "should require valid configuration for resource selection settings" do
      tool = new_external_tool
      tool.settings = {:resource_selection => {:bob => 'asfd'}}
      tool.save
      tool.settings[:resource_selection].should be_nil
      tool.settings = {:resource_selection => {:url => "http://www.example.com"}}
      tool.save
      tool.settings[:resource_selection].should be_nil
      tool.settings = {:resource_selection => {:url => "http://www.example.com", :selection_width => 100, :selection_height => 100}}
      tool.save
      tool.settings[:resource_selection].should_not be_nil
    end
    
    it "should require valid configuration for editor button settings" do
      tool = new_external_tool
      tool.settings = {:editor_button => {:bob => 'asfd'}}
      tool.save
      tool.settings[:editor_button].should be_nil
      tool.settings = {:editor_button => {:url => "http://www.example.com"}}
      tool.save
      tool.settings[:editor_button].should be_nil
      tool.settings = {:editor_button => {:url => "http://www.example.com", :icon_url => "http://www.example.com", :selection_width => 100, :selection_height => 100}}
      tool.save
      tool.settings[:editor_button].should_not be_nil
    end
    
    it "should set has_user_navigation if navigation configured" do
      tool = new_external_tool
      tool.settings = {:user_navigation => {:url => "http://www.example.com"}}
      tool.has_user_navigation.should be_false
      tool.save
      tool.has_user_navigation.should be_true
    end
    
    it "should set has_course_navigation if navigation configured" do
      tool = new_external_tool
      tool.settings = {:course_navigation => {:url => "http://www.example.com"}}
      tool.has_course_navigation.should be_false
      tool.save
      tool.has_course_navigation.should be_true
    end

    it "should set has_account_navigation if navigation configured" do
      tool = new_external_tool
      tool.settings = {:account_navigation => {:url => "http://www.example.com"}}
      tool.has_account_navigation.should be_false
      tool.save
      tool.has_account_navigation.should be_true
    end

    it "should set has_resource_selection if selection configured" do
      tool = new_external_tool
      tool.settings = {:resource_selection => {:url => "http://www.example.com", :selection_width => 100, :selection_height => 100}}
      tool.has_resource_selection.should be_false
      tool.save
      tool.has_resource_selection.should be_true
    end

    it "should set has_editor_button if button configured" do
      tool = new_external_tool
      tool.settings = {:editor_button => {:url => "http://www.example.com", :icon_url => "http://www.example.com", :selection_width => 100, :selection_height => 100}}
      tool.has_editor_button.should be_false
      tool.save
      tool.has_editor_button.should be_true
    end

    it "should allow setting tool_id and icon_url" do
      tool = new_external_tool
      tool.tool_id = "new_tool"
      tool.settings[:icon_url] = "http://www.example.com/favicon.ico"
      tool.save
      tool.tool_id.should == "new_tool"
      tool.settings[:icon_url].should == "http://www.example.com/favicon.ico"
    end
    
    it "should use editor button's icon_url if none is set on the tool" do
      tool = new_external_tool
      tool.settings = {:editor_button => {:url => "http://www.example.com", :icon_url => "http://www.example.com/favicon.ico", :selection_width => 100, :selection_height => 100}}
      tool.save
      tool.settings[:icon_url].should == "http://www.example.com/favicon.ico"
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
  
  describe "label_for" do
    it "should return the tool name if nothing else is configured and no key is sent" do
      tool = @root_account.context_external_tools.new(:name => 'tool', :consumer_key => '12345', :shared_secret => 'secret', :url => "http://example.com")
      tool.save!
      tool.label_for(nil).should == 'tool'
    end
    
    it "should return the tool name if nothing is configured on the sent key" do
      tool = @root_account.context_external_tools.new(:name => 'tool', :consumer_key => '12345', :shared_secret => 'secret', :url => "http://example.com")
      tool.settings = {:course_navigation => {:bob => 'asfd'}}
      tool.save!
      tool.label_for(:course_navigation).should == 'tool'
    end
    
    it "should return the tool's 'text' value if no key is sent" do
      tool = @root_account.context_external_tools.new(:name => 'tool', :consumer_key => '12345', :shared_secret => 'secret', :url => "http://example.com")
      tool.settings = {:text => 'tool label', :course_navigation => {:url => "http://example.com", :text => 'course nav'}}
      tool.save!
      tool.label_for(nil).should == 'tool label'
    end
    
    it "should return the tool's 'text' value if no 'text' value is set for the sent key" do
      tool = @root_account.context_external_tools.new(:name => 'tool', :consumer_key => '12345', :shared_secret => 'secret', :url => "http://example.com")
      tool.settings = {:text => 'tool label', :course_navigation => {:bob => 'asdf'}}
      tool.save!
      tool.label_for(:course_navigation).should == 'tool label'
    end
    
    it "should return the setting's 'text' value for the sent key if available" do
      tool = @root_account.context_external_tools.new(:name => 'tool', :consumer_key => '12345', :shared_secret => 'secret', :url => "http://example.com")
      tool.settings = {:text => 'tool label', :course_navigation => {:url => "http://example.com", :text => 'course nav'}}
      tool.save!
      tool.label_for(:course_navigation).should == 'course nav'
    end
    
    it "should return the locale-specific label if specified and matching exactly" do
      tool = @root_account.context_external_tools.new(:name => 'tool', :consumer_key => '12345', :shared_secret => 'secret', :url => "http://example.com")
      tool.settings = {:text => 'tool label', :course_navigation => {:url => "http://example.com", :text => 'course nav', :labels => {'en-US' => 'english nav'}}}
      tool.save!
      tool.label_for(:course_navigation, 'en-US').should == 'english nav'
      tool.label_for(:course_navigation, 'es').should == 'course nav'
    end
    
    it "should return the locale-specific label if specified and matching based on general locale" do
      tool = @root_account.context_external_tools.new(:name => 'tool', :consumer_key => '12345', :shared_secret => 'secret', :url => "http://example.com")
      tool.settings = {:text => 'tool label', :course_navigation => {:url => "http://example.com", :text => 'course nav', :labels => {'en' => 'english nav'}}}
      tool.save!
      tool.label_for(:course_navigation, 'en-US').should == 'english nav'
    end
  end
  
  describe "find_for" do
    def new_external_tool(context)
      context.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob", :domain => "google.com")
    end
    
    it "should find the tool if it's attached to the course" do
      course_model
      tool = new_external_tool @course
      tool.settings[:course_navigation] = {:url => "http://www.example.com", :text => "Example URL"}
      tool.save!
      ContextExternalTool.find_for(tool.id, @course, :course_navigation).should == tool
      (ContextExternalTool.find_for(tool.id, @course, :user_navigation) rescue nil).should be_nil
    end
    
    it "should find the tool if it's attached to the account" do
    end
    
    it "should find the tool if it's attached to the course's account" do
      course_model
      tool = new_external_tool @course.account
      tool.settings[:course_navigation] = {:url => "http://www.example.com", :text => "Example URL"}
      tool.save!
      ContextExternalTool.find_for(tool.id, @course, :course_navigation).should == tool
      (ContextExternalTool.find_for(tool.id, @course, :user_navigation) rescue nil).should be_nil
    end
    
    it "should find the tool if it's attached to the course's root account" do
      course_model
      tool = new_external_tool @course.root_account
      tool.settings[:course_navigation] = {:url => "http://www.example.com", :text => "Example URL"}
      tool.save!
      ContextExternalTool.find_for(tool.id, @course, :course_navigation).should == tool
      (ContextExternalTool.find_for(tool.id, @course, :user_navigation) rescue nil).should be_nil
    end
    
    it "should not find the tool if it's attached to a sub-account" do
      course_model
      @account = @course.account.sub_accounts.create!(:name => "sub-account")
      tool = new_external_tool @account
      tool.settings[:course_navigation] = {:url => "http://www.example.com", :text => "Example URL"}
      tool.save!
      (ContextExternalTool.find_for(tool.id, @course, :course_navigation) rescue nil).should be_nil
    end
    
    it "should not find the tool if it's attached to another course" do
      @course2 = course_model
      @course = course_model
      tool = new_external_tool @course2
      tool.settings[:course_navigation] = {:url => "http://www.example.com", :text => "Example URL"}
      tool.save!
      (ContextExternalTool.find_for(tool.id, @course, :course_navigation) rescue nil).should be_nil
    end
    
    it "should not find the tool if it's not enabled for the correct navigation type" do
      course_model
      tool = new_external_tool @course
      tool.settings[:course_navigation] = {:url => "http://www.example.com", :text => "Example URL"}
      tool.save!
      (ContextExternalTool.find_for(tool.id, @course, :user_navigation) rescue nil).should be_nil
    end
  end
  
  describe "import_from_migration" do
    it "should work for course-level tools" do
      course_model
      tool = ContextExternalTool.import_from_migration({:title => 'tool', :url => 'http://example.com'}, @course)
      tool.should_not be_nil
      tool.context.should == @course
    end
    
    it "should work for account-level tools" do
      course_model
      tool = ContextExternalTool.import_from_migration({:title => 'tool', :url => 'http://example.com'}, @course.account)
      tool.should_not be_nil
      tool.context.should == @course.account
    end
  end
end
