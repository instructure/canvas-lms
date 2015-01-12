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
  before(:once) do
    course_model
    @root_account = @course.root_account
    @account = account_model(:root_account => @root_account, :parent_account => @root_account)
    @course.update_attribute(:account, @account)
    expect(@course.account).to eql(@account)
    expect(@course.root_account).to eql(@root_account)
    expect(@account.parent_account).to eql(@root_account)
    expect(@account.root_account).to eql(@root_account)
  end
  describe "url or domain validation" do
    it "should validate with a domain setting" do
      @tool = @course.context_external_tools.create(:name => "a", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      expect(@tool).not_to be_new_record
      expect(@tool.errors).to be_empty
    end
    
    it "should validate with a url setting" do
      @tool = @course.context_external_tools.create(:name => "a", :url => "http://google.com", :consumer_key => '12345', :shared_secret => 'secret')
      expect(@tool).not_to be_new_record
      expect(@tool.errors).to be_empty
    end
    
    it "should validate with a canvas lti extension url setting" do
      @tool = @course.context_external_tools.new(:name => "a", :consumer_key => '12345', :shared_secret => 'secret')
      @tool.editor_button = {
        "icon_url"=>"http://www.example.com/favicon.ico", 
        "text"=>"Example",
        "url"=>"http://www.example.com",
        "selection_height"=>400, 
        "selection_width"=>600
      }
      @tool.save
      expect(@tool).not_to be_new_record
      expect(@tool.errors).to be_empty
    end

    def url_test(nav_url=nil)
      course_with_teacher(:active_all => true)
      @tool = @course.context_external_tools.new(:name => "a", :consumer_key => '12345', :shared_secret => 'secret', :url => "http://www.example.com")
      ContextExternalTool::EXTENSION_TYPES.each do |type|
        @tool.send "#{type}=", {
                :url => nav_url,
                :text => "Example",
                :icon_url => "http://www.example.com/image.ico",
                :selection_width => 50,
                :selection_height => 50
        }

        launch_url = @tool.extension_setting(type, :url)

        if nav_url
          expect(launch_url).to eq nav_url
        else
          expect(launch_url).to eq @tool.url
        end
      end
    end

    it "should allow extension to not have a url if the main config has a url" do
      url_test
    end

    it "should prefer the extension url to the main config url" do
      url_test(nav_url="https://example.com/special_launch_of_death")
    end

    it "should not allow extension with no custom url and a domain match" do
      @tool = @course.context_external_tools.create!(:name => "a", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tool.course_navigation = {
                :text => "Example"
      }
      @tool.save!
      expect(@tool.has_placement?(:course_navigation)).to eq false
    end

    it "should not validate with no domain or url setting" do
      @tool = @course.context_external_tools.create(:name => "a", :consumer_key => '12345', :shared_secret => 'secret')
      expect(@tool).to be_new_record
      expect(@tool.errors['url']).to eq ["Either the url or domain should be set."]
      expect(@tool.errors['domain']).to eq ["Either the url or domain should be set."]
    end

    it "should accept both a domain and a url" do
      @tool = @course.context_external_tools.create(:name => "a", :domain => "google.com", :url => "http://google.com", :consumer_key => '12345', :shared_secret => 'secret')
      expect(@tool).not_to be_new_record
      expect(@tool.errors).to be_empty
    end
  end

  it "should allow extension with only 'enabled' key" do
    @tool = @course.context_external_tools.create!(:name => "a", :url => "http://google.com", :consumer_key => '12345', :shared_secret => 'secret')
    @tool.course_navigation = {
              :enabled => "true"
    }
    @tool.save!
    expect(@tool.has_placement?(:course_navigation)).to eq true
  end

  it "should allow accept_media_types setting exclusively for file_menu extension" do
    @tool = @course.context_external_tools.create!(:name => "a", :url => "http://google.com", :consumer_key => '12345', :shared_secret => 'secret')
    @tool.course_navigation = {
        :accept_media_types => "types"
    }
    @tool.file_menu = {
        :accept_media_types => "types"
    }
    @tool.save!
    expect(@tool.extension_setting(:course_navigation, :accept_media_types)).to be_blank
    expect(@tool.extension_setting(:file_menu, :accept_media_types)).to eq "types"
  end

  it "should clear disabled extensions" do
    @tool = @course.context_external_tools.create!(:name => "a", :url => "http://google.com", :consumer_key => '12345', :shared_secret => 'secret')
    @tool.course_navigation = {
              :enabled => "false"
    }
    @tool.save!
    expect(@tool.has_placement?(:course_navigation)).to eq false
  end

  describe "find_external_tool" do
    it "should match on the same domain" do
      @tool = @course.context_external_tools.create!(:name => "a", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://google.com/is/cool", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
    end
    
    it "should match on a subdomain" do
      @tool = @course.context_external_tools.create!(:name => "a", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com/is/cool", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
    end
    
    it "should not match on non-matching domains" do
      @tool = @course.context_external_tools.create!(:name => "a", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tool2 = @course.context_external_tools.create!(:name => "a", :domain => "www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://mgoogle.com/is/cool", Course.find(@course.id))
      expect(@found_tool).to eql(nil)
      @found_tool = ContextExternalTool.find_external_tool("http://sgoogle.com/is/cool", Course.find(@course.id))
      expect(@found_tool).to eql(nil)
    end
    
    it "should not match on the closest matching domain" do
      @tool = @course.context_external_tools.create!(:name => "a", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tool2 = @course.context_external_tools.create!(:name => "a", :domain => "www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://www.www.google.com/is/cool", Course.find(@course.id))
      expect(@found_tool).to eql(@tool2)
    end
    
    it "should match on exact url" do
      @tool = @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com/coolness", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com/coolness", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
    end

    it "should match on url ignoring query parameters" do
      @tool = @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com/coolness", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com/coolness?a=1", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com/coolness?a=1&b=2", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
    end

    it "should match on url even when tool url contains query parameters" do
      @tool = @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com/coolness?a=1&b=2", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com/coolness?b=2&a=1", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com/coolness?c=3&b=2&d=4&a=1", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
    end

    it "should not match on url if the tool url contains query parameters that the search url doesn't" do
      @tool = @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com/coolness?a=1", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com/coolness?a=2", Course.find(@course.id))
      expect(@found_tool).to be_nil
    end

    it "should not match on url before matching on domain" do
      @tool = @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com/coolness", :consumer_key => '12345', :shared_secret => 'secret')
      @tool2 = @course.context_external_tools.create!(:name => "a", :domain => "www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com/coolness", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
    end

    it "should match on url or domain for a tool that has both" do
      @tool = @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com/coolness", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      expect(ContextExternalTool.find_external_tool("http://google.com/is/cool", Course.find(@course.id))).to eql(@tool)
      expect(ContextExternalTool.find_external_tool("http://www.google.com/coolness", Course.find(@course.id))).to eql(@tool)
    end
    
    it "should find the context's tool matching on url first" do
      @tool = @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @course.context_external_tools.create!(:name => "b", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @account.context_external_tools.create!(:name => "c", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @account.context_external_tools.create!(:name => "d", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @root_account.context_external_tools.create!(:name => "e", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @root_account.context_external_tools.create!(:name => "f", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
    end
    
    it "should find the nearest account's tool matching on url if there are no url-matching context tools" do
      @course.context_external_tools.create!(:name => "b", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tool = @account.context_external_tools.create!(:name => "c", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @account.context_external_tools.create!(:name => "d", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @root_account.context_external_tools.create!(:name => "e", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @root_account.context_external_tools.create!(:name => "f", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
    end
    
    it "should find the root account's tool matching on url before matching by domain on the course" do
      @course.context_external_tools.create!(:name => "b", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @account.context_external_tools.create!(:name => "d", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tool = @root_account.context_external_tools.create!(:name => "e", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @root_account.context_external_tools.create!(:name => "f", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
    end
    
    it "should find the context's tool matching on domain if no url-matching tools are found" do
      @tool = @course.context_external_tools.create!(:name => "b", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @account.context_external_tools.create!(:name => "d", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @root_account.context_external_tools.create!(:name => "f", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
    end
    
    it "should find the nearest account's tool matching on domain if no url-matching tools are found" do
      @tool = @account.context_external_tools.create!(:name => "c", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @root_account.context_external_tools.create!(:name => "e", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
    end
    
    it "should find the root account's tool matching on domain if no url-matching tools are found" do
      @tool = @root_account.context_external_tools.create!(:name => "e", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com/", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
    end
    
    it "should find the preferred tool if there are two matching-priority tools" do
      @tool1 = @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tool2 = @course.context_external_tools.create!(:name => "b", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id), @tool1.id)
      expect(@found_tool).to eql(@tool1)
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id), @tool2.id)
      expect(@found_tool).to eql(@tool2)
      @tool1.destroy
      @tool2.destroy
      
      @tool1 = @course.context_external_tools.create!(:name => "a", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tool2 = @course.context_external_tools.create!(:name => "b", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id), @tool1.id)
      expect(@found_tool).to eql(@tool1)
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id), @tool2.id)
      expect(@found_tool).to eql(@tool2)
    end
    
    it "should find the preferred tool even if there is a higher priority tool configured" do
      @tool = @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @preferred = @root_account.context_external_tools.create!(:name => "f", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')

      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id), @preferred.id)
      expect(@found_tool).to eql(@preferred)
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
      expect(@found_tool).to eql(@tool)
    end

    it "should not return preferred tool outside of context chain" do
      preferred = @root_account.context_external_tools.create!(:name => "a", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      expect(ContextExternalTool.find_external_tool("http://www.google.com", @course, preferred.id)).to eq preferred
    end

    it "should not return preferred tool if url doesn't match" do
      c1 = @course
      c2 = course_model
      preferred = c1.context_external_tools.create!(:name => "a", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      expect(ContextExternalTool.find_external_tool("http://example.com", c2, preferred.id)).to be_nil
    end

  end
  
  describe "custom fields" do
    it "should parse custom_fields_string from a text field" do
      tool = @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      tool.custom_fields_string=("a=1\nbT^@!#n_40=123\n\nc=")
      expect(tool.custom_fields).not_to be_nil
      expect(tool.custom_fields.keys.length).to eq 2
      expect(tool.custom_fields['a']).to eq '1'
      expect(tool.custom_fields['bT^@!#n_40']).to eq '123'
      expect(tool.custom_fields['c']).to eq nil
    end
    
    it "should return custom_fields_string as a text-formatted field" do
      tool = @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret', :custom_fields => {'a' => '123', 'b' => '456'})
      fields_string = tool.custom_fields_string
      expect(fields_string).to eq "a=123\nb=456"
    end

    it "should merge custom fields for extension launches" do
      course_with_teacher(:active_all => true)
      @tool = @course.context_external_tools.new(:name => "a", :consumer_key => '12345', :shared_secret => 'secret', :custom_fields => {'a' => "1", 'b' => "2"}, :url =>"http://www.example.com")
      ContextExternalTool::EXTENSION_TYPES.each do |type|
        @tool.send "#{type}=",  {
          :text =>"Example",
          :url =>"http://www.example.com",
          :icon_url => "http://www.example.com/image.ico",
          :custom_fields => {"b" => "5", "c" => "3"},
          :selection_width => 50,
          :selection_height => 50
        }
        @tool.save!

        hash = {}
        @tool.set_custom_fields(hash, type)
        expect(hash["custom_a"]).to eq "1"
        expect(hash["custom_b"]).to eq "5"
        expect(hash["custom_c"]).to eq "3"

        hash = {}
        @tool.settings[type.to_sym][:custom_fields] = nil
        @tool.set_custom_fields(hash, type)

        expect(hash["custom_a"]).to eq "1"
        expect(hash["custom_b"]).to eq "2"
        expect(hash.has_key?("custom_c")).to eq false
      end
    end
  end

  describe "#substituted_custom_fields" do
    it "substitutes custom fields for a placement" do
      subject.user_navigation = {custom_fields: {'custom_a' => '$Custom.substitution'}}

      custom_params = subject.substituted_custom_fields(:user_navigation, {'$Custom.substitution' => 'substituted_value'})
      expect(custom_params).to eq({'custom_a' => 'substituted_value'})

    end

    it "executes procs" do
      subject.course_navigation = {custom_fields: {'custom_b' => '$Custom.substitution'}}
      custom_params = subject.substituted_custom_fields(:course_navigation, {'$Custom.substitution' => -> {'substituted_value'}})

      expect(custom_params).to eq({'custom_b' => 'substituted_value'})
    end

    it "ignores constants" do
      subject.account_navigation = {custom_fields: {'custom_c' => 'constant'}}
      custom_params = subject.substituted_custom_fields(:account_navigation, {'$Custom.substitution' => 'substituted_value'})

      expect(custom_params).to eq({'custom_c' => 'constant'})
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
      expect(ContextExternalTool.all_tools_for(@course).to_a).to eql(@tools.sort_by(&:name))
    end

    it "returns all tools that are selectable" do
      @tools = []
      @tools << @root_account.context_external_tools.create!(:name => "f", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tools << @root_account.context_external_tools.create!(:name => "e", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret', not_selectable: true)
      @tools << @account.context_external_tools.create!(:name => "d", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tools << @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret', not_selectable: true)
      tools = ContextExternalTool.all_tools_for(@course, selectable: true)
      expect(tools.count).to eq 2
    end

    it 'returns multiple requested placements' do
      tool1 = @course.context_external_tools.create!(:name => "First Tool", :url => "http://www.example.com", :consumer_key => "key", :shared_secret => "secret")
      tool2 = @course.context_external_tools.new(:name => "Another Tool", :consumer_key => "key", :shared_secret => "secret")
      tool2.settings[:editor_button] = {:url => "http://www.example.com", :icon_url => "http://www.example.com", :selection_width => 100, :selection_height => 100}.with_indifferent_access
      tool2.save!
      tool3 = @course.context_external_tools.new(:name => "Third Tool", :consumer_key => "key", :shared_secret => "secret")
      tool3.settings[:resource_selection] = {:url => "http://www.example.com", :icon_url => "http://www.example.com", :selection_width => 100, :selection_height => 100}.with_indifferent_access
      tool3.save!
      placements = Lti::ResourcePlacement::DEFAULT_PLACEMENTS + ['resource_selection']
      expect(ContextExternalTool.all_tools_for(@course, placements: placements).to_a).to eql([tool1, tool3].sort_by(&:name))
    end
  end

  describe "placements" do

    it 'returns multiple requested placements' do
      tool1 = @course.context_external_tools.create!(:name => "First Tool", :url => "http://www.example.com", :consumer_key => "key", :shared_secret => "secret")
      tool2 = @course.context_external_tools.new(:name => "Another Tool", :consumer_key => "key", :shared_secret => "secret")
      tool2.settings[:editor_button] = {:url => "http://www.example.com", :icon_url => "http://www.example.com", :selection_width => 100, :selection_height => 100}.with_indifferent_access
      tool2.save!
      tool3 = @course.context_external_tools.new(:name => "Third Tool", :consumer_key => "key", :shared_secret => "secret")
      tool3.settings[:resource_selection] = {:url => "http://www.example.com", :icon_url => "http://www.example.com", :selection_width => 100, :selection_height => 100}.with_indifferent_access
      tool3.save!
      placements = Lti::ResourcePlacement::DEFAULT_PLACEMENTS + ['resource_selection']
      expect(ContextExternalTool.all_tools_for(@course).placements(*placements).to_a).to eql([tool1, tool3].sort_by(&:name))
    end

    it 'it only returns a single requested placements' do
      tool1 = @course.context_external_tools.create!(:name => "First Tool", :url => "http://www.example.com", :consumer_key => "key", :shared_secret => "secret")
      tool2 = @course.context_external_tools.new(:name => "Another Tool", :consumer_key => "key", :shared_secret => "secret")
      tool2.settings[:editor_button] = {:url => "http://www.example.com", :icon_url => "http://www.example.com", :selection_width => 100, :selection_height => 100}.with_indifferent_access
      tool2.save!
      tool3 = @course.context_external_tools.new(:name => "Third Tool", :consumer_key => "key", :shared_secret => "secret")
      tool3.settings[:resource_selection] = {:url => "http://www.example.com", :icon_url => "http://www.example.com", :selection_width => 100, :selection_height => 100}.with_indifferent_access
      tool3.save!
      expect(ContextExternalTool.all_tools_for(@course).placements('resource_selection').to_a).to eql([tool3])
    end

    it "doesn't return not selectable tools placements for moudle_item" do
      tool1 = @course.context_external_tools.create!(:name => "First Tool", :url => "http://www.example.com", :consumer_key => "key", :shared_secret => "secret")
      tool2 = @course.context_external_tools.new(:name => "Another Tool", :consumer_key => "key", :shared_secret => "secret")
      tool2.settings[:editor_button] = {:url => "http://www.example.com", :icon_url => "http://www.example.com", :selection_width => 100, :selection_height => 100}.with_indifferent_access
      tool2.save!
      tool3 = @course.context_external_tools.new(:name => "Third Tool", :consumer_key => "key", :shared_secret => "secret")
      tool3.settings[:resource_selection] = {:url => "http://www.example.com", :icon_url => "http://www.example.com", :selection_width => 100, :selection_height => 100}.with_indifferent_access
      tool3.not_selectable = true
      tool3.save!
      expect(ContextExternalTool.all_tools_for(@course).placements(*Lti::ResourcePlacement::DEFAULT_PLACEMENTS).to_a).to eql([tool1])
    end

  end

  describe "find_integration_for" do
    it "should return nil if there are no matching integrations" do
      at  = @account.context_external_tools.create!(name: 'at', url: 'http://example.com', consumer_key: '12345', shared_secret: 'secret')
      ait = @account.context_external_tools.create!(name: 'ait', integration_type: 'other', url: 'http://example.com', consumer_key: '12345', shared_secret: 'secret')
      ct  = @course.context_external_tools.create!(name: 'ct', url: 'http://example.com', consumer_key: '12345', shared_secret: 'secret')
      cit = @course.context_external_tools.create!(name: 'cit', integration_type: 'other', url: 'http://example.com', consumer_key: '12345', shared_secret: 'secret')
      integration = ContextExternalTool.find_integration_for(@course, 'testing')
      expect(integration).to be_nil
    end

    it "should find the integration in the specified context" do
      at  = @account.context_external_tools.create!(name: 'at', url: 'http://example.com', consumer_key: '12345', shared_secret: 'secret')
      ait = @account.context_external_tools.create!(name: 'ait', integration_type: 'testing', url: 'http://example.com', consumer_key: '12345', shared_secret: 'secret')
      ct  = @course.context_external_tools.create!(name: 'ct', url: 'http://example.com', consumer_key: '12345', shared_secret: 'secret')
      cit = @course.context_external_tools.create!(name: 'cit', integration_type: 'testing', url: 'http://example.com', consumer_key: '12345', shared_secret: 'secret')
      integration = ContextExternalTool.find_integration_for(@course, 'testing')
      expect(integration.id).to eq cit.id
    end

    it "should find the integration in the nearest context" do
      at  = @account.context_external_tools.create!(name: 'at', url: 'http://example.com', consumer_key: '12345', shared_secret: 'secret')
      ait = @account.context_external_tools.create!(name: 'ait', integration_type: 'testing', url: 'http://example.com', consumer_key: '12345', shared_secret: 'secret')
      rt  = @root_account.context_external_tools.create!(name: 'rt', url: 'http://example.com', consumer_key: '12345', shared_secret: 'secret')
      rit = @root_account.context_external_tools.create!(name: 'rit', integration_type: 'testing', url: 'http://example.com', consumer_key: '12345', shared_secret: 'secret')
      integration = ContextExternalTool.find_integration_for(@course, 'testing')
      expect(integration.id).to eq ait.id
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
      expect(tool.user_navigation).to be_nil
      tool.settings = {:user_navigation => {:url => "http://www.example.com"}}
      tool.save
      expect(tool.user_navigation).not_to be_nil
    end
    
    it "should require valid configuration for course navigation settings" do
      tool = new_external_tool
      tool.settings = {:course_navigation => {:bob => 'asfd'}}
      tool.save
      expect(tool.course_navigation).to be_nil
      tool.settings = {:course_navigation => {:url => "http://www.example.com"}}
      tool.save
      expect(tool.course_navigation).not_to be_nil
    end
    
    it "should require valid configuration for account navigation settings" do
      tool = new_external_tool
      tool.settings = {:account_navigation => {:bob => 'asfd'}}
      tool.save
      expect(tool.account_navigation).to be_nil
      tool.settings = {:account_navigation => {:url => "http://www.example.com"}}
      tool.save
      expect(tool.account_navigation).not_to be_nil
    end
    
    it "should require valid configuration for resource selection settings" do
      tool = new_external_tool
      tool.settings = {:resource_selection => {:bob => 'asfd'}}
      tool.save
      expect(tool.resource_selection).to be_nil
      tool.settings = {:resource_selection => {:url => "http://www.example.com", :selection_width => 100, :selection_height => 100}}
      tool.save
      expect(tool.resource_selection).not_to be_nil
    end
    
    it "should require valid configuration for editor button settings" do
      tool = new_external_tool
      tool.settings = {:editor_button => {:bob => 'asfd'}}
      tool.save
      expect(tool.editor_button).to be_nil
      tool.settings = {:editor_button => {:url => "http://www.example.com"}}
      tool.save
      expect(tool.editor_button).to be_nil
      tool.settings = {:editor_button => {:url => "http://www.example.com", :icon_url => "http://www.example.com", :selection_width => 100, :selection_height => 100}}
      tool.save
      expect(tool.editor_button).not_to be_nil
    end
    
    it "should set user_navigation if navigation configured" do
      tool = new_external_tool
      tool.settings = {:user_navigation => {:url => "http://www.example.com"}}
      expect(tool.has_placement?(:user_navigation)).to be_falsey
      tool.save
      expect(tool.has_placement?(:user_navigation)).to be_truthy
    end
    
    it "should set course_navigation if navigation configured" do
      tool = new_external_tool
      tool.settings = {:course_navigation => {:url => "http://www.example.com"}}
      expect(tool.has_placement?(:course_navigation)).to be_falsey
      tool.save
      expect(tool.has_placement?(:course_navigation)).to be_truthy
    end

    it "should set account_navigation if navigation configured" do
      tool = new_external_tool
      tool.settings = {:account_navigation => {:url => "http://www.example.com"}}
      expect(tool.has_placement?(:account_navigation)).to be_falsey
      tool.save
      expect(tool.has_placement?(:account_navigation)).to be_truthy
    end

    it "should set resource_selection if selection configured" do
      tool = new_external_tool
      tool.settings = {:resource_selection => {:url => "http://www.example.com", :selection_width => 100, :selection_height => 100}}
      expect(tool.has_placement?(:resource_selection)).to be_falsey
      tool.save
      expect(tool.has_placement?(:resource_selection)).to be_truthy
    end

    it "should set editor_button if button configured" do
      tool = new_external_tool
      tool.settings = {:editor_button => {:url => "http://www.example.com", :icon_url => "http://www.example.com", :selection_width => 100, :selection_height => 100}}
      expect(tool.has_placement?(:editor_button)).to be_falsey
      tool.save
      expect(tool.has_placement?(:editor_button)).to be_truthy
    end

    it "should remove and add placements according to configuration" do
      tool = new_external_tool
      tool.settings = {
          :editor_button => {:url => "http://www.example.com", :icon_url => "http://www.example.com", :selection_width => 100, :selection_height => 100},
          :resource_selection => {:url => "http://www.example.com", :selection_width => 100, :selection_height => 100}
      }
      tool.save!
      expect(tool.context_external_tool_placements.pluck(:placement_type)).to match_array(['editor_button', 'resource_selection'])
      tool.settings.delete(:editor_button)
      tool.settings[:account_navigation] = {:url => "http://www.example.com"}
      tool.save!
      expect(tool.context_external_tool_placements.pluck(:placement_type)).to match_array(['resource_selection', 'account_navigation'])
    end

    it "should allow setting tool_id and icon_url" do
      tool = new_external_tool
      tool.tool_id = "new_tool"
      tool.icon_url = "http://www.example.com/favicon.ico"
      tool.save
      expect(tool.tool_id).to eq "new_tool"
      expect(tool.icon_url).to eq "http://www.example.com/favicon.ico"
    end
  end

  describe "extension settings" do
    let(:tool) do
      tool = @root_account.context_external_tools.new({:name => "t", :consumer_key => '12345', :shared_secret => 'secret', :url => "http://google.com/launch_url"})
      tool.settings = {:selection_width => 100, :selection_height => 100, :icon_url => "http://www.example.com/favicon.ico"}
      tool.save
      tool
    end

    it "should get the tools launch url if no extension urls are configured" do
      tool.editor_button = {:enabled => true}
      tool.save
      expect(tool.editor_button(:url)).to eq "http://google.com/launch_url"
    end

    it "should fall back to tool defaults" do
      tool.editor_button = {:url => "http://www.example.com"}
      tool.save
      expect(tool.editor_button).not_to eq nil
      expect(tool.editor_button(:url)).to eq "http://www.example.com"
      expect(tool.editor_button(:icon_url)).to eq "http://www.example.com/favicon.ico"
      expect(tool.editor_button(:selection_width)).to eq 100
    end

    it "should return nil if the tool is not enabled" do
      expect(tool.resource_selection).to eq nil
      expect(tool.resource_selection(:url)).to eq nil
    end

    it "should get properties for each tool extension" do
      tool.course_navigation = {:enabled => true}
      tool.account_navigation = {:enabled => true}
      tool.user_navigation = {:enabled => true}
      tool.resource_selection = {:enabled => true}
      tool.editor_button = {:enabled => true}
      tool.save
      expect(tool.course_navigation).not_to eq nil
      expect(tool.account_navigation).not_to eq nil
      expect(tool.user_navigation).not_to eq nil
      expect(tool.resource_selection).not_to eq nil
      expect(tool.editor_button).not_to eq nil
    end

    describe "display_type" do
      it "should be 'in_context' by default" do
        expect(tool.display_type(:course_navigation)).to eq 'in_context'
        tool.course_navigation = {enabled: true}
        tool.save!
        expect(tool.display_type(:course_navigation)).to eq 'in_context'
      end

      it "should be configurable by a property" do
        tool.course_navigation = { enabled: true }
        tool.settings[:display_type] = "custom_display_type"
        tool.save!
        expect(tool.display_type(:course_navigation)).to eq 'custom_display_type'
      end

      it "should be configurable in extension" do
        tool.course_navigation = {display_type: 'other_display_type'}
        tool.save!
        expect(tool.display_type(:course_navigation)).to eq 'other_display_type'
      end

    end
  end

  describe "#extension_default_value" do

    it "returns resource_selection when the type is 'resource_slection'" do
      expect(subject.extension_default_value(:resource_selection, :message_type)).to eq 'resource_selection'
    end

  end

  describe "change_domain" do
    let(:prod_base_url) {'http://www.example.com'}
    let(:new_host) {'test.example.com'}

    let(:tool) do
      tool = @root_account.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob", :domain => "www.example.com", :url => prod_base_url)
      tool.settings = {:url => prod_base_url, :icon_url => "#{prod_base_url}/icon.ico"}
      tool.account_navigation = {:url => "#{prod_base_url}/launch?my_var=1"}
      tool.editor_button = {:url => "#{prod_base_url}/resource_selection", :icon_url => "#{prod_base_url}/resource_selection.ico"}
      tool
    end

    it "should update the domain" do
      tool.change_domain! new_host
      expect(tool.domain).to eq new_host
      expect(URI.parse(tool.url).host).to eq new_host
      expect(URI.parse(tool.settings[:url]).host).to eq new_host
      expect(URI.parse(tool.icon_url).host).to eq new_host
      expect(URI.parse(tool.account_navigation[:url]).host).to eq new_host
      expect(URI.parse(tool.editor_button[:url]).host).to eq new_host
      expect(URI.parse(tool.editor_button[:icon_url]).host).to eq new_host
    end

    it "should ignore domain if it is nil" do
      tool.domain = nil
      tool.change_domain! new_host
      expect(tool.domain).to be_nil
    end

    it "should ignore launch url if it is nil" do
      tool.url = nil
      tool.change_domain! new_host
      expect(tool.url).to be_nil
    end

    it "should ignore custom fields" do
      tool.custom_fields = {:url => 'http://www.google.com/'}
      tool.change_domain! new_host
      expect(tool.custom_fields[:url]).to eq 'http://www.google.com/'
    end

    it "should ignore environments fields" do
      tool.settings["environments"] = {:launch_url => 'http://www.google.com/'}
      tool.change_domain! new_host
      expect(tool.settings["environments"]).to eq({:launch_url => 'http://www.google.com/'})
    end
  end

  describe "standardize_url" do
    it "should standardize urls" do
      url = ContextExternalTool.standardize_url("http://www.google.com?a=1&b=2")
      expect(url).to eql(ContextExternalTool.standardize_url("http://www.google.com?b=2&a=1"))
      expect(url).to eql(ContextExternalTool.standardize_url("http://www.google.com/?b=2&a=1"))
      expect(url).to eql(ContextExternalTool.standardize_url("www.google.com/?b=2&a=1"))
    end
  end
  
  describe "label_for" do
    append_before(:each) do
      @tool = @root_account.context_external_tools.new(:name => 'tool', :consumer_key => '12345', :shared_secret => 'secret', :url => "http://example.com")
    end

    it "should return the tool name if nothing else is configured and no key is sent" do
      @tool.save!
      expect(@tool.label_for(nil)).to eq 'tool'
    end
    
    it "should return the tool name if nothing is configured on the sent key" do
      @tool.settings = {:course_navigation => {:bob => 'asfd'}}
      @tool.save!
      expect(@tool.label_for(:course_navigation)).to eq 'tool'
    end
    
    it "should return the tool's 'text' value if no key is sent" do
      @tool.settings = {:text => 'tool label', :course_navigation => {:url => "http://example.com", :text => 'course nav'}}
      @tool.save!
      expect(@tool.label_for(nil)).to eq 'tool label'
    end
    
    it "should return the tool's 'text' value if no 'text' value is set for the sent key" do
      @tool.settings = {:text => 'tool label', :course_navigation => {:bob => 'asdf'}}
      @tool.save!
      expect(@tool.label_for(:course_navigation)).to eq 'tool label'
    end

    it "should return the tool's locale-specific 'text' value if no 'text' value is set for the sent key" do
      @tool.settings = {:text => 'tool label', :labels => {'en' => 'translated tool label'}, :course_navigation => {:bob => 'asdf'}}
      @tool.save!
      expect(@tool.label_for(:course_navigation, 'en')).to eq 'translated tool label'
    end
    
    it "should return the setting's 'text' value for the sent key if available" do
      @tool.settings = {:text => 'tool label', :course_navigation => {:url => "http://example.com", :text => 'course nav'}}
      @tool.save!
      expect(@tool.label_for(:course_navigation)).to eq 'course nav'
    end
    
    it "should return the locale-specific label if specified and matching exactly" do
      @tool.settings = {:text => 'tool label', :course_navigation => {:url => "http://example.com", :text => 'course nav', :labels => {'en-US' => 'english nav'}}}
      @tool.save!
      expect(@tool.label_for(:course_navigation, 'en-US')).to eq 'english nav'
      expect(@tool.label_for(:course_navigation, 'es')).to eq 'course nav'
    end
    
    it "should return the locale-specific label if specified and matching based on general locale" do
      @tool.settings = {:text => 'tool label', :course_navigation => {:url => "http://example.com", :text => 'course nav', :labels => {'en' => 'english nav'}}}
      @tool.save!
      expect(@tool.label_for(:course_navigation, 'en-US')).to eq 'english nav'
    end
  end
  
  describe "find_for" do
    before :once do
      course_model
    end

    def new_external_tool(context)
      context.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob", :domain => "google.com")
    end
    
    it "should find the tool if it's attached to the course" do
      tool = new_external_tool @course
      tool.course_navigation = {:url => "http://www.example.com", :text => "Example URL"}
      tool.save!
      expect(ContextExternalTool.find_for(tool.id, @course, :course_navigation)).to eq tool
      expect { ContextExternalTool.find_for(tool.id, @course, :user_navigation) }.to raise_error(ActiveRecord::RecordNotFound)
    end
    
    it "should find the tool if it's attached to the course's account" do
      tool = new_external_tool @course.account
      tool.course_navigation = {:url => "http://www.example.com", :text => "Example URL"}
      tool.save!
      expect(ContextExternalTool.find_for(tool.id, @course, :course_navigation)).to eq tool
      expect { ContextExternalTool.find_for(tool.id, @course, :user_navigation) }.to raise_error(ActiveRecord::RecordNotFound)
    end
    
    it "should find the tool if it's attached to the course's root account" do
      tool = new_external_tool @course.root_account
      tool.course_navigation = {:url => "http://www.example.com", :text => "Example URL"}
      tool.save!
      expect(ContextExternalTool.find_for(tool.id, @course, :course_navigation)).to eq tool
      expect { ContextExternalTool.find_for(tool.id, @course, :user_navigation) }.to raise_error(ActiveRecord::RecordNotFound)
    end
    
    it "should not find the tool if it's attached to a sub-account" do
      @account = @course.account.sub_accounts.create!(:name => "sub-account")
      tool = new_external_tool @account
      tool.course_navigation = {:url => "http://www.example.com", :text => "Example URL"}
      tool.save!
      expect { ContextExternalTool.find_for(tool.id, @course, :course_navigation) }.to raise_error(ActiveRecord::RecordNotFound)
    end
    
    it "should not find the tool if it's attached to another course" do
      @course2 = @course
      @course = course_model
      tool = new_external_tool @course2
      tool.course_navigation = {:url => "http://www.example.com", :text => "Example URL"}
      tool.save!
      expect { ContextExternalTool.find_for(tool.id, @course, :course_navigation) }.to raise_error(ActiveRecord::RecordNotFound)
    end
    
    it "should not find the tool if it's not enabled for the correct navigation type" do
      tool = new_external_tool @course
      tool.course_navigation = {:url => "http://www.example.com", :text => "Example URL"}
      tool.save!
      expect { ContextExternalTool.find_for(tool.id, @course, :user_navigation) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should raise RecordNotFound if the id is invalid" do
      expect { ContextExternalTool.find_for("horseshoes", @course, :course_navigation) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "opaque_identifier_for" do
    it "should create lti_context_id for asset" do
      expect(@course.lti_context_id).to eq nil
      @tool = @course.context_external_tools.create!(:name => "a", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      context_id = @tool.opaque_identifier_for(@course)
      @course.reload
      expect(@course.lti_context_id).to eq context_id
    end

    it "should not create new lti_context for asset if exists" do
      @course.lti_context_id =  'dummy_context_id'
      @course.save!
      @tool = @course.context_external_tools.create!(:name => "a", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      context_id = @tool.opaque_identifier_for(@course)
      @course.reload
      expect(@course.lti_context_id).to eq 'dummy_context_id'
    end
  end

  describe "global navigation" do
    before(:once) do
      @account = account_model
    end

    it "should let account admins see admin tools" do
      account_admin_user(:account => @account, :active_all => true)
      expect(ContextExternalTool.global_navigation_visibility_for_user(@account, @user)).to eq 'admins'
    end

    it "should let teachers see admin tools" do
      course_with_teacher(:account => @account, :active_all => true)
      expect(ContextExternalTool.global_navigation_visibility_for_user(@account, @user)).to eq 'admins'
    end

    it "should not let students see admin tools" do
      course_with_student(:account => @account, :active_all => true)
      expect(ContextExternalTool.global_navigation_visibility_for_user(@account, @user)).to eq 'members'
    end

    it "should update the visibility cache if enrollments are updated or user is touched" do
      time = Time.now
      enable_cache do
        Timecop.freeze(time) do
          course_with_student(:account => @account, :active_all => true)
          expect(ContextExternalTool.global_navigation_visibility_for_user(@account, @user)).to eq 'members'
        end

        Timecop.freeze(time + 1.second) do
          course_with_teacher(:account => @account, :active_all => true, :user => @user)
          expect(ContextExternalTool.global_navigation_visibility_for_user(@account, @user)).to eq 'admins'
        end

        Timecop.freeze(time + 2.second) do
          @user.teacher_enrollments.update_all(:workflow_state => 'deleted')
          # should not have affected the earlier cache
          expect(ContextExternalTool.global_navigation_visibility_for_user(@account, @user)).to eq 'admins'

          @user.touch
          expect(ContextExternalTool.global_navigation_visibility_for_user(@account, @user)).to eq 'members'
        end
      end
    end

    it "should update the global navigation menu cache key when the global navigation tools are updated (or removed)" do
      time = Time.now
      enable_cache do
        Timecop.freeze(time) do
          @admin_tool = @account.context_external_tools.new(:name => "a", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
          @admin_tool.global_navigation = {:visibility => 'admins', :url => "http://www.example.com", :text => "Example URL"}
          @admin_tool.save!
          @member_tool = @account.context_external_tools.new(:name => "b", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
          @member_tool.global_navigation = {:url => "http://www.example.com", :text => "Example URL"}
          @member_tool.save!
          @other_tool = @account.context_external_tools.create!(:name => "c", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')

          @admin_cache_key = ContextExternalTool.global_navigation_menu_cache_key(@account, 'admins')
          @member_cache_key = ContextExternalTool.global_navigation_menu_cache_key(@account, 'members')
        end

        Timecop.freeze(time + 1.second) do
          @other_tool.save!
          # cache keys should remain the same
          expect(ContextExternalTool.global_navigation_menu_cache_key(@account, 'admins')).to eq @admin_cache_key
          expect(ContextExternalTool.global_navigation_menu_cache_key(@account, 'members')).to eq @member_cache_key
        end

        Timecop.freeze(time + 2.second) do
          @admin_tool.global_navigation = nil
          @admin_tool.save!
          # should update the admin key
          expect(ContextExternalTool.global_navigation_menu_cache_key(@account, 'admins')).not_to eq @admin_cache_key
          # should not update the members key
          expect(ContextExternalTool.global_navigation_menu_cache_key(@account, 'members')).to eq @member_cache_key
        end
      end
    end

    describe "#has_placement?" do

      it 'returns true for module item if it has selectable, and a url' do
        tool = @course.context_external_tools.create!(:name => "a", :url => "http://google.com", :consumer_key => '12345', :shared_secret => 'secret')
        expect(tool.has_placement?(:link_selection)).to eq true
      end

      it 'returns true for module item if it has selectable, and a domain' do
        tool = @course.context_external_tools.create!(:name => "a", :domain => "http://google.com", :consumer_key => '12345', :shared_secret => 'secret')
        expect(tool.has_placement?(:link_selection)).to eq true
      end

      it 'returns false for module item if it is not selectable' do
        tool = @course.context_external_tools.create!(:name => "a", not_selectable: true, :url => "http://google.com", :consumer_key => '12345', :shared_secret => 'secret')
        expect(tool.has_placement?(:link_selection)).to eq false
      end

       it 'returns false for module item if it has selectable, and no domain or url' do
        tool = @course.context_external_tools.new(:name => "a", :consumer_key => '12345', :shared_secret => 'secret')
        tool.settings[:resource_selection] = {:url => "http://www.example.com", :icon_url => "http://www.example.com", :selection_width => 100, :selection_height => 100}.with_indifferent_access
        tool.save!
        expect(tool.has_placement?(:link_selection)).to eq false
      end

    end


  end
end
