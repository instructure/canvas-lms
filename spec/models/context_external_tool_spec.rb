#
# Copyright (C) 2011 - present Instructure, Inc.
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
  end

  describe 'associations' do
    let_once(:developer_key) { DeveloperKey.create! }
    let_once(:tool) do
      ContextExternalTool.create!(
        context: @course,
        consumer_key: 'key',
        shared_secret: 'secret',
        name: 'test tool',
        url: 'http://www.tool.com/launch',
        developer_key: developer_key
      )
    end

    it 'allows setting the developer key' do
      expect(tool.developer_key).to eq developer_key
    end
  end

  describe '#deployment_id' do
    let_once(:tool) do
      ContextExternalTool.create!(
        id: 1,
        context: @course,
        consumer_key: 'key',
        shared_secret: 'secret',
        name: 'test tool',
        url: 'http://www.tool.com/launch'
      )
    end

    it 'returns the correct deployment_id' do
      expect(tool.deployment_id).to eq "#{tool.id}:#{Lti::Asset.opaque_identifier_for(tool.context)}"
    end
  end

  describe '#duplicated_in_context?' do
    shared_examples_for 'detects duplication in contexts' do
      subject { second_tool.duplicated_in_context? }
      let(:context) { raise 'Override in spec' }
      let(:second_tool) { tool.dup }
      let(:settings) do
        {
          "editor_button" => {
            "icon_url"=>"http://www.example.com/favicon.ico",
            "text"=>"Example",
            "url"=>"http://www.example.com",
            "selection_height"=>400,
            "selection_width"=>600
          }
        }
      end
      let(:tool) do
        ContextExternalTool.create!(
          settings: settings,
          context: context,
          name: 'first tool',
          consumer_key: 'key',
          shared_secret: 'secret',
          url: 'http://www.tool.com/launch'
        )
      end

      context 'when url is not set' do
        let(:domain) { 'instructure.com' }

        before { tool.update!(url: nil, domain: domain) }

        context 'when no other tools are installed in the context' do
          it 'does not count as duplicate' do
            expect(tool.duplicated_in_context?).to eq false
          end
        end

        context 'when a tool with matching domain is found' do
          it { is_expected.to eq true }
        end

        context 'when a tool with matching domain is found in different context' do
          before { second_tool.update!(context: course_model) }

          it { is_expected.to eq false }
        end

        context 'when a tool with matching domain is not found' do
          before { second_tool.domain = 'different-domain.com' }

          it { is_expected.to eq false }
        end
      end

      context 'when no other tools are installed in the context' do
        it 'does not count as duplicate' do
          expect(tool.duplicated_in_context?).to eq false
        end
      end

      context 'when a tool with matching settings and different URL is found' do
        before { second_tool.url << '/different/url' }

        it { is_expected.to eq false }
      end

      context 'when a tool with different settings and matching URL is found' do
        before { second_tool.settings[:different_key] = 'different value' }

        it { is_expected.to eq true }
      end

      context 'when a tool with different settings and different URL is found' do
        before do
          second_tool.url << '/different/url'
          second_tool.settings[:different_key] = 'different value'
        end

        it { is_expected.to eq false }
      end

      context 'when a tool with matching settings and matching URL is found' do
        it { is_expected.to eq true }
      end
    end

    context 'duplicated in account chain' do
      it_behaves_like 'detects duplication in contexts' do
        let(:context) { account_model }
      end
    end

    context 'duplicated in course' do
      it_behaves_like 'detects duplication in contexts' do
        let(:context) { course_model }
      end
    end
  end

  describe '#content_migration_configured?' do
    let(:tool) do
      ContextExternalTool.new.tap do |t|
        t.settings = {
          'content_migration' => {
            'export_start_url' => 'https://lti.example.com/begin_export',
            'import_start_url' => 'https://lti.example.com/begin_import',
          }
        }
      end
    end

    it 'must return false when the content_migration key is missing from the settings hash' do
      tool.settings.delete('content_migration')
      expect(tool.content_migration_configured?).to eq false
    end

    it 'must return false when the content_migration key is present in the settings hash but the export_start_url sub key is missing' do
      tool.settings['content_migration'].delete('export_start_url')
      expect(tool.content_migration_configured?).to eq false
    end

    it 'must return false when the content_migration key is present in the settings hash but the import_start_url sub key is missing' do
      tool.settings['content_migration'].delete('import_start_url')
      expect(tool.content_migration_configured?).to eq false
    end

    it 'must return true when the content_migration key and all relevant sub-keys are present' do
      expect(tool.content_migration_configured?).to eq true
    end
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
      Lti::ResourcePlacement::PLACEMENTS.each do |type|
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

    it "should be case insensitive when matching on the same domain" do
      @tool = @course.context_external_tools.create!(:name => "a", :domain => "Google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://google.com/is/cool", Course.find(@course.id), @tool.id)
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

    it "should not match on domain if domain is nil" do
      @tool = @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com/coolness", :consumer_key => '12345', :shared_secret => 'secret')
      @found_tool = ContextExternalTool.find_external_tool("http://malicious.domain./hahaha", Course.find(@course.id))
      expect(@found_tool).to be_nil
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

    context 'when exclude_tool_id is set' do
      subject { ContextExternalTool.find_external_tool("http://www.google.com", Course.find(course.id), nil, exclude_tool.id) }

      let(:course) { @course }
      let(:exclude_tool) do
        course.context_external_tools.create!(:name => "a", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      end

      it 'should not return the excluded tool' do
        expect(subject).to be_nil
      end
    end

    context 'preferred_tool_id' do
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
        preferred = c1.context_external_tools.create!(:name => "a", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
        expect(ContextExternalTool.find_external_tool("http://example.com", c1, preferred.id)).to be_nil
      end

      it "should return the preferred tool if the url is nil" do
        c1 = @course
        preferred = c1.context_external_tools.create!(:name => "a", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
        expect(ContextExternalTool.find_external_tool(nil, c1, preferred.id)).to eq preferred
      end
    end
  end

  describe "#extension_setting" do

    it "returns the top level extension setting if no placement is given" do
      tool = @course.context_external_tools.new(:name => "bob",
                                                :consumer_key => "bob",
                                                :shared_secret => "bob")
      tool.url = "http://www.example.com/basic_lti"
      tool.settings[:windowTarget] = "_blank"
      tool.save!
      expect(tool.extension_setting(nil, :windowTarget)).to eq '_blank'
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
      Lti::ResourcePlacement::PLACEMENTS.each do |type|
        @tool.send "#{type}=",  {
          :text =>"Example",
          :url =>"http://www.example.com",
          :icon_url => "http://www.example.com/image.ico",
          :custom_fields => {"b" => "5", "c" => "3"},
          :selection_width => 50,
          :selection_height => 50
        }
        @tool.save!

        hash = @tool.set_custom_fields(type)
        expect(hash["custom_a"]).to eq "1"
        expect(hash["custom_b"]).to eq "5"
        expect(hash["custom_c"]).to eq "3"

        @tool.settings[type.to_sym][:custom_fields] = nil
        hash = @tool.set_custom_fields(type)

        expect(hash["custom_a"]).to eq "1"
        expect(hash["custom_b"]).to eq "2"
        expect(hash.has_key?("custom_c")).to eq false
      end
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

    it 'honors only_visible option' do
      course_with_student(active_all: true, user: user_with_pseudonym, account: @account)
      @tools = []
      @tools << @root_account.context_external_tools.create!(:name => "f", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tools << @course.context_external_tools.create!(:name => "d", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret',
                                                        :settings => {:assignment_view => {:visibility => 'admins'}})
      @tools << @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret',
                                                        :settings => {:assignment_view => {:visibility => 'members'}})
      tools = ContextExternalTool.all_tools_for(@course)
      expect(tools.count).to eq 3
      tools = ContextExternalTool.all_tools_for(@course, only_visible: true, current_user: @user, visibility_placements: ["assignment_view"])
      expect(tools.count).to eq 1
      expect(tools[0].name).to eq 'a'
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

  describe "visible" do

    it "returns all tools to admins" do
      course_with_teacher(active_all: true, user: user_with_pseudonym, account: @account)
      tool1 = @course.context_external_tools.create!(:name => "1", :url => "http://www.example.com", :consumer_key => "key", :shared_secret => "secret")
      tool2 = @course.context_external_tools.new(:name => "2", :consumer_key => "key", :shared_secret => "secret")
      tool2.settings[:assignment_view] = {:url => "http://www.example.com"}.with_indifferent_access
      tool2.save!
      expect(ContextExternalTool.all_tools_for(@course).visible(@user, @course, nil, []).to_a).to eql([tool1, tool2].sort_by(&:name))
    end

    it "returns nothing if a non-admin requests without specifying placement" do
      course_with_student(active_all: true, user: user_with_pseudonym, account: @account)
      tool1 = @course.context_external_tools.create!(:name => "1", :url => "http://www.example.com", :consumer_key => "key", :shared_secret => "secret")
      tool2 = @course.context_external_tools.new(:name => "2", :consumer_key => "key", :shared_secret => "secret")
      tool2.settings[:assignment_view] = {:url => "http://www.example.com"}.with_indifferent_access
      tool2.save!
      expect(ContextExternalTool.all_tools_for(@course).visible(@user, @course, nil, []).to_a).to eql([])
    end

    it "returns only tools with placements matching the requested placement" do
      course_with_student(active_all: true, user: user_with_pseudonym, account: @account)
      tool1 = @course.context_external_tools.create!(:name => "1", :url => "http://www.example.com", :consumer_key => "key", :shared_secret => "secret")
      tool2 = @course.context_external_tools.new(:name => "2", :consumer_key => "key", :shared_secret => "secret")
      tool2.settings[:assignment_view] = {:url => "http://www.example.com"}.with_indifferent_access
      tool2.save!
      expect(ContextExternalTool.all_tools_for(@course).visible(@user, @course, nil, ["assignment_view"]).to_a).to eql([tool2])
    end

    it "does not return admin tools to students" do
      course_with_student(active_all: true, user: user_with_pseudonym, account: @account)
      tool = @course.context_external_tools.create!(:name => "1", :url => "http://www.example.com", :consumer_key => "key", :shared_secret => "secret")
      tool.settings[:assignment_view] = {:url => "http://www.example.com", :visibility => 'admins'}.with_indifferent_access
      tool.save!
      expect(ContextExternalTool.all_tools_for(@course).visible(@user, @course, nil, ["assignment_view"]).to_a).to eql([])
    end

    it "does return member tools to students" do
      course_with_student(active_all: true, user: user_with_pseudonym, account: @account)
      tool = @course.context_external_tools.create!(:name => "1", :url => "http://www.example.com", :consumer_key => "key", :shared_secret => "secret")
      tool.settings[:assignment_view] = {:url => "http://www.example.com", :visibility => 'members'}.with_indifferent_access
      tool.save!
      expect(ContextExternalTool.all_tools_for(@course).visible(@user, @course, nil, ["assignment_view"]).to_a).to eql([tool])
    end

    it "does not return member tools to public" do
      tool = @course.context_external_tools.create!(:name => "1", :url => "http://www.example.com", :consumer_key => "key", :shared_secret => "secret")
      tool.settings[:assignment_view] = {:url => "http://www.example.com", :visibility => 'members'}.with_indifferent_access
      tool.save!
      expect(ContextExternalTool.all_tools_for(@course).visible(nil, @course, nil, ["assignment_view"]).to_a).to eql([])
    end

    it "does return public tools to public" do
      tool = @course.context_external_tools.create!(:name => "1", :url => "http://www.example.com", :consumer_key => "key", :shared_secret => "secret")
      tool.settings[:assignment_view] = {:url => "http://www.example.com", :visibility => 'public'}.with_indifferent_access
      tool.save!
      expect(ContextExternalTool.all_tools_for(@course).visible(nil, @course, nil, ["assignment_view"]).to_a).to eql([tool])
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

    it "should ignore an existing invalid url" do
      tool.url = "null"
      tool.change_domain! new_host
      expect(tool.url).to eq "null"
    end
  end

  describe "standardize_url" do
    it "should standardize urls" do
      url = ContextExternalTool.standardize_url("http://www.google.com?a=1&b=2")
      expect(url).to eql(ContextExternalTool.standardize_url("http://www.google.com?b=2&a=1"))
      expect(url).to eql(ContextExternalTool.standardize_url("http://www.google.com/?b=2&a=1"))
      expect(url).to eql(ContextExternalTool.standardize_url("www.google.com/?b=2&a=1"))
    end

    it 'should handle spaces in front of url' do
      url = ContextExternalTool.standardize_url(" http://sub_underscore.google.com?a=1&b=2")
      expect(url).to eql('http://sub_underscore.google.com/?a=1&b=2')
    end

    it 'should handle tabs in front of url' do
      url = ContextExternalTool.standardize_url("\thttp://sub_underscore.google.com?a=1&b=2")
      expect(url).to eql('http://sub_underscore.google.com/?a=1&b=2')
    end

    it 'should handle unicode whitespace' do
      url = ContextExternalTool.standardize_url("\u00A0http://sub_underscore.go\u2005ogle.com?a=1\u2002&b=2")
      expect(url).to eql('http://sub_underscore.google.com/?a=1&b=2')
    end

    it 'handles underscores in the domain' do
      url = ContextExternalTool.standardize_url("http://sub_underscore.google.com?a=1&b=2")
      expect(url).to eql('http://sub_underscore.google.com/?a=1&b=2')
    end

  end

  describe "default_label" do
    append_before(:each) do
      @tool = @root_account.context_external_tools.new(:consumer_key => '12345', :shared_secret => 'secret', :url => "http://example.com", :name => "tool name")
    end

    it "returns the default label if no language or name is specified" do
      expect(@tool.default_label).to eq 'tool name'
    end

    it "returns the localized label if a locale is specified" do
      @tool.settings = {:url => "http://example.com", :text => 'course nav', :labels => {'en-US' => 'english nav'}}
      @tool.save!
      expect(@tool.default_label('en-US')).to eq 'english nav'
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

    it "should not find a course tool with workflow_state deleted" do
      tool = new_external_tool @course
      tool.course_navigation = {:url => "http://www.example.com", :text => "Example URL"}
      tool.workflow_state = 'deleted'
      tool.save!
      expect { ContextExternalTool.find_for(tool.id, @course, :course_navigation) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should not find an account tool with workflow_state deleted" do
      tool = new_external_tool @account
      tool.account_navigation = {:url => "http://www.example.com", :text => "Example URL"}
      tool.workflow_state = 'deleted'
      tool.save!
      expect { ContextExternalTool.find_for(tool.id, @account, :account_navigation) }.to raise_error(ActiveRecord::RecordNotFound)
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

    it 'should use the global_asset_id for new assets that are stored in the db' do
      expect(@course.lti_context_id).to eq nil
      @tool = @course.context_external_tools.create!(:name => "a", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      context_id = Lti::Asset.global_context_id_for(@course)
      @tool.opaque_identifier_for(@course)
      @course.reload
      expect(@course.lti_context_id).to eq context_id
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

    describe ".find_tool_for_assignment" do

      let(:tool) do
        @course.context_external_tools.create(
            name: "a",
            consumer_key: '12345',
            shared_secret: 'secret',
            url: 'http://example.com/launch'
        )
      end

      it 'finds the tool from an assignment' do
        a = @course.assignments.create!(title: "test",
                                        submission_types: 'external_tool',
                                        external_tool_tag_attributes: {url: tool.url})
        expect(described_class.tool_for_assignment(a)).to eq tool
      end

      it 'returns nil if there is no content tag' do
        a = @course.assignments.create!(title: "test",
                                        submission_types: 'external_tool')
        expect(described_class.tool_for_assignment(a)).to be_nil
      end

    end

    describe ".visible?" do
      let(:u) {user_factory}
      let(:admin) {account_admin_user(account:c.root_account)}
      let(:c) {course_factory(active_course:true)}
      let(:student) do
        student = factory_with_protected_attributes(User, valid_user_attributes)
        e = c.enroll_student(student)
        e.invite
        e.accept
        student
      end
      let(:teacher) do
        teacher = factory_with_protected_attributes(User, valid_user_attributes)
        e = c.enroll_teacher(teacher)
        e.invite
        e.accept
        teacher
      end

      it 'returns true for public visibility' do
        expect(described_class.visible?('public', u, c)).to be true
      end

      it 'returns false for non members if visibility is members' do
        expect(described_class.visible?('members', u, c)).to be false
      end

      it 'returns true for members visibility if a student in the course' do
        expect(described_class.visible?('members', student, c)).to be true
      end

      it 'returns true for members visibility if a teacher in the course' do
        expect(described_class.visible?('members', teacher, c)).to be true
      end

      it 'returns true for admins visibility if a teacher' do
        expect(described_class.visible?('admins', teacher, c)).to be true
      end

      it 'returns true for admins visibility if an admin' do
        expect(described_class.visible?('admins', admin, c)).to be true
      end

      it 'returns false for admins visibility if a student' do
        expect(described_class.visible?('admins', student, c)).to be false
      end

      it 'returns false for admins visibility if a non member user' do
        expect(described_class.visible?('admins', u, c)).to be false
      end

      it 'returns true if visibility is invalid' do
        expect(described_class.visible?('true', u, c)).to be true
      end

      it 'returns true if visibility is nil' do
        expect(described_class.visible?(nil, u, c)).to be true
      end

    end

    describe 'set_policy' do
      let(:tool) do
        @course.context_external_tools.create(
          name: "a",
          consumer_key: '12345',
          shared_secret: 'secret',
          url: 'http://example.com/launch'
        )
      end

      it 'should grant update_manually to the proper individuals' do
        @admin = account_admin_user()

        course_with_teacher(:active_all => true, :account => Account.default)
        @teacher = user_factory(active_all: true)
        @course.enroll_teacher(@teacher).accept!

        @designer = user_factory(active_all: true)
        @course.enroll_designer(@designer).accept!

        @ta = user_factory(active_all: true)
        @course.enroll_ta(@ta).accept!

        @student = user_factory(active_all: true)
        @course.enroll_student(@student).accept!

        expect(tool.grants_right?(@admin, :update_manually)).to be_truthy
        expect(tool.grants_right?(@teacher, :update_manually)).to be_truthy
        expect(tool.grants_right?(@designer, :update_manually)).to be_truthy
        expect(tool.grants_right?(@ta, :update_manually)).to be_truthy
        expect(tool.grants_right?(@student, :update_manually)).to be_falsey
      end
    end
  end
end
