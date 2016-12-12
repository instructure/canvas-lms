# coding: utf-8
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

require 'nokogiri'

describe ApplicationHelper do
  include ERB::Util

  alias_method :content_tag_without_nil_return, :content_tag

  context "folders_as_options" do
    before(:once) do
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
      expect(html.css('option').count).to eq 5
      expect(html.css('option')[0].text).to eq @f.name
      expect(html.css('option')[1].text).to match /^\xC2\xA0\xC2\xA0\xC2\xA0- #{@f_1.name}/
      expect(html.css('option')[4].text).to match /^\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0- #{@f_2_1_1.name}/
    end

    it "should limit depth" do
      option_string = folders_as_options([@f], :all_folders => @all_folders, :max_depth => 1)

      html = Nokogiri::HTML::DocumentFragment.parse("<select>#{option_string}</select>")
      expect(html.css('option').count).to eq 3
      expect(html.css('option')[0].text).to eq @f.name
      expect(html.css('option')[1].text).to match /^\xC2\xA0\xC2\xA0\xC2\xA0- #{@f_1.name}/
      expect(html.css('option')[2].text).to match /^\xC2\xA0\xC2\xA0\xC2\xA0- #{@f_2.name}/
    end

    it "should work without supplying all folders" do
      option_string = folders_as_options([@f])

      html = Nokogiri::HTML::DocumentFragment.parse("<select>#{option_string}</select>")
      expect(html.css('option').count).to eq 5
      expect(html.css('option')[0].text).to eq @f.name
      expect(html.css('option')[1].text).to match /^\xC2\xA0\xC2\xA0\xC2\xA0- #{@f_1.name}/
      expect(html.css('option')[4].text).to match /^\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0- #{@f_2_1_1.name}/
    end
  end

  it "show_user_create_course_button should work" do
    Account.default.update_attribute(:settings, { :teachers_can_create_courses => true, :students_can_create_courses => true })
    @domain_root_account = Account.default
    expect(show_user_create_course_button(nil)).to be_falsey
    user_factory
    expect(show_user_create_course_button(@user)).to be_falsey
    course_with_teacher
    expect(show_user_create_course_button(@teacher)).to be_truthy
    account_admin_user
    expect(show_user_create_course_button(@admin)).to be_truthy
  end

  describe "tomorrow_at_midnight" do
    it "should always return a time in the future" do
      now = 1.day.from_now.midnight - 5.seconds
      expect(tomorrow_at_midnight).to be > now
    end
  end

  describe "Time Display Helpers" do
    before :each do
      @zone = Time.zone
      Time.zone = "Alaska"
    end

    after :each do
      Time.zone = @zone
    end

    around do |example|
      Timecop.freeze(Time.zone.local(2013,3,13,9,12), &example)
    end

    describe '#context_sensitive_datetime_title' do
      it "produces a string showing the local time and the course time" do
        context = stub(time_zone: ActiveSupport::TimeZone["America/Denver"])
        expect(context_sensitive_datetime_title(Time.now, context)).to eq "data-tooltip data-html-tooltip-title=\"Local: Mar 13 at  1:12am<br>Course: Mar 13 at  3:12am\""
      end

      it "only prints the text if just_text option passed" do
        context = stub(time_zone: ActiveSupport::TimeZone["America/Denver"])
        expect(context_sensitive_datetime_title(Time.now, context, just_text: true)).to eq "Local: Mar 13 at  1:12am<br>Course: Mar 13 at  3:12am"
      end

      it "uses the simple title if theres no timezone difference" do
        context = stub(time_zone: ActiveSupport::TimeZone["America/Anchorage"])
        expect(context_sensitive_datetime_title(Time.now, context, just_text: true)).to eq "Mar 13 at  1:12am"
        expect(context_sensitive_datetime_title(Time.now, context)).to eq "data-tooltip data-html-tooltip-title=\"Mar 13 at  1:12am\""
      end

      it 'uses the simple title for nil context' do
        expect(context_sensitive_datetime_title(Time.now, nil, just_text: true)).to eq "Mar 13 at  1:12am"
      end

      it 'crosses date boundaries appropriately' do
        Timecop.freeze(Time.utc(2013,3,13,7,12)) do
          context = stub(time_zone: ActiveSupport::TimeZone["America/Denver"])
          expect(context_sensitive_datetime_title(Time.now, context)).to eq "data-tooltip data-html-tooltip-title=\"Local: Mar 12 at 11:12pm<br>Course: Mar 13 at  1:12am\""
        end
      end
    end

    describe '#friendly_datetime' do
      let(:context) { stub(time_zone: ActiveSupport::TimeZone["America/Denver"]) }

      it 'spits out a friendly time tag' do
        tag = friendly_datetime(Time.now)
        expect(tag).to eq "<time data-html-tooltip-title=\"Mar 13 at  1:12am\" data-tooltip=\"top\">Mar 13 at  1:12am</time>"
      end

      it 'builds a whole time tag with a useful title showing the timezone offset if theres a context' do
        tag = friendly_datetime(Time.now, context: context)
        expect(tag).to match /^<time.*<\/time>$/
        expect(tag).to match /data-html-tooltip-title=/
        expect(tag).to match /Local: Mar 13 at  1:12am/
        expect(tag).to match /Course: Mar 13 at  3:12am/
      end

      it 'can produce an alternate tag type' do
        tag = friendly_datetime(Time.now, context: context, tag_type: :span)
        expect(tag).to match /^<span.*<\/span>$/
        expect(tag).to match /data-html-tooltip-title=/
        expect(tag).to match /Local: Mar 13 at  1:12am/
        expect(tag).to match /Course: Mar 13 at  3:12am/
      end

      it 'produces no tooltip for a nil datetime' do
        tag = friendly_datetime(nil, context: context)
        expect(tag).to eq "<time></time>"
      end
    end
  end

  describe "accessible date formats" do
    it "generates a date format for use throughout the app" do
      expect(accessible_date_format).to match(/YYYY/)
      expect(accessible_date_format).to match(/hh:mm/)
    end

    it "wraps a prompt around the format for Screenreader users" do
      expect(datepicker_screenreader_prompt).to include(accessible_date_format)
    end

    it "produces a date-only format" do
      format = accessible_date_format('date')
      expect(format).to match(/YYYY/)
      expect(format).to_not match(/hh:mm/)
    end

    it "produces a time-only format" do
      format = accessible_date_format('time')
      expect(format).to_not match(/YYYY/)
      expect(format).to match(/hh:mm/)
    end

    it "throws an argument error for a foolish format" do
      expect{ accessible_date_format('nonsense') }.to raise_error(ArgumentError)
    end
  end

  describe "cache_if" do
    it "should cache the fragment if the condition is true" do
      enable_cache do
        cache_if(true, "t1", :expires_in => 15.minutes, :no_locale => true) { output_buffer.concat "blargh" }
        expect(@controller.read_fragment("t1")).to eq "blargh"
      end
    end

    it "should not cache if the condition is false" do
      enable_cache do
        cache_if(false, "t1", :expires_in => 15.minutes, :no_locale => true) { output_buffer.concat "blargh" }
        expect(@controller.read_fragment("t1")).to be_nil
      end
    end
  end

  describe "custom css/js includes" do

    def set_up_subaccounts
      @domain_root_account.settings[:global_includes] = true
      @domain_root_account.settings[:sub_account_includes] = true
      @domain_root_account.create_brand_config!({
        css_overrides: 'https://example.com/root/account.css',
        js_overrides: 'https://example.com/root/account.js'
      })
      @domain_root_account.save!

      @child_account = account_model(root_account: @domain_root_account, name: 'child account')
      bc = @child_account.build_brand_config({
        css_overrides: 'https://example.com/child/account.css',
        js_overrides: 'https://example.com/child/account.js'
      })
      bc.parent = @domain_root_account.brand_config
      bc.save!
      @child_account.save!

      @grandchild_account = @child_account.sub_accounts.create!(name: 'grandchild account')
      bc = @grandchild_account.build_brand_config({
        css_overrides: 'https://example.com/grandchild/account.css',
        js_overrides: 'https://example.com/grandchild/account.js'
      })
      bc.parent = @child_account.brand_config
      bc.save!
      @grandchild_account.save!
    end

    describe "include_account_css" do

      before :once do
        @site_admin = Account.site_admin
        @domain_root_account = Account.default
        @domain_root_account.settings = @domain_root_account.settings.merge(global_includes: true)
        @domain_root_account.save!
      end

      context "with no custom css" do
        it "should be empty" do
          helper.stubs(:active_brand_config).returns(nil)
          expect(helper.include_account_css).to be_nil
        end
      end

      context "with custom css" do
        it "should include account css" do
          helper.stubs(:active_brand_config).returns BrandConfig.create!(css_overrides: 'https://example.com/path/to/overrides.css')
          output = helper.include_account_css
          expect(output).to have_tag 'link'
          expect(output).to match %r{https://example.com/path/to/overrides.css}
        end

        it "should include site_admin css even if there is no active brand" do
          helper.stubs(:active_brand_config).returns nil
          Account.site_admin.create_brand_config!({
            css_overrides: 'https://example.com/site_admin/account.css',
            js_overrides: 'https://example.com/site_admin/account.js'
          })
          output = helper.include_account_css
          expect(output).to have_tag 'link'
          expect(output).to match %r{https://example.com/site_admin/account.css}
        end


        it "should not include anything if param is set to 0" do
          helper.stubs(:active_brand_config).returns BrandConfig.create!(css_overrides: 'https://example.com/path/to/overrides.css')
          params[:global_includes] = '0'

          output = helper.include_account_css
          expect(output).to be_nil
        end
      end

      context "sub-accounts" do
        before { set_up_subaccounts }

        it "should include sub-account css when viewing the subaccount or any course or group in it" do
          course = @grandchild_account.courses.create!
          group = course.groups.create!
          [@grandchild_account, course, group].each do |context|
            @context = context
            output = helper.include_account_css
            expect(output).to have_tag 'link'
            expect(output.scan(%r{https://example.com/(root|child|grandchild)?/account.css})).to eql [['root'], ['child'], ['grandchild']]
          end
        end

        it "should not include sub-account css when root account is context" do
          @context = @domain_root_account
          output = helper.include_account_css
          expect(output).to have_tag 'link'
          expect(output.scan(%r{https://example.com/(root|child|grandchild)?/account.css})).to eql [['root']]
        end

        it "should use include sub-account css, if sub-account is lowest common account context" do
          @course = @grandchild_account.courses.create!
          @course.offer!
          student_in_course(active_all: true)
          @context = @user
          @current_user = @user
          output = helper.include_account_css
          expect(output).to have_tag 'link'
          expect(output.scan(%r{https://example.com/(root|child|grandchild)?/account.css})).to eql [['root'], ['child'], ['grandchild']]
        end

        it "should work using common_account_chain starting from lowest common account context with enrollments" do
          course1 = @child_account.courses.create!
          course1.offer!
          course2 = @grandchild_account.courses.create!
          course2.offer!
          student_in_course(active_all: true, course: course1, user: @user)
          student_in_course(active_all: true, course: course2, user: @user)
          @context = @user
          @current_user = @user
          output = helper.include_account_css
          expect(output).to have_tag 'link'
          expect(output.scan(%r{https://example.com/(root|child|grandchild)?/account.css})).to eql [['root'], ['child']]
        end

        it "should fall-back to @domain_root_account's branding if I'm logged in but not enrolled in anything" do
          @current_user = user_factory
          output = helper.include_account_css
          expect(output).to have_tag 'link'
          expect(output.scan(%r{https://example.com/(root|child|grandchild)?/account.css})).to eql [['root']]
        end

        it "should load custom css even for high contrast users" do
          @current_user = user_factory
          user_factory.enable_feature!(:high_contrast)
          @context = @grandchild_account
          output = helper.include_account_css
          expect(output).to have_tag 'link'
          expect(output.scan(%r{https://example.com/(root|child|grandchild)?/account.css})).to eql [["root"], ["child"], ["grandchild"]]
        end

      end
    end

    describe "include_account_js" do
      before :once do
        @site_admin = Account.site_admin
        @domain_root_account = Account.default
        @domain_root_account.settings = @domain_root_account.settings.merge(global_includes: true)
        @domain_root_account.save!
      end

      context "with no custom js" do
        it "should be empty" do
          helper.stubs(:active_brand_config).returns(nil)
          expect(helper.include_account_js).to be_nil
        end
      end

      context "with custom js" do
        it "should include account javascript" do
          helper.stubs(:active_brand_config).returns BrandConfig.create!(js_overrides: 'https://example.com/path/to/overrides.js')
          output = helper.include_account_js
          expect(output).to have_tag 'script', text: %r{https:\\/\\/example.com\\/path\\/to\\/overrides.js}
        end

        it "should include site_admin javascript even if there is no active brand" do
          helper.stubs(:active_brand_config).returns nil
          Account.site_admin.create_brand_config!({
            css_overrides: 'https://example.com/site_admin/account.css',
            js_overrides: 'https://example.com/site_admin/account.js'
          })

          output = helper.include_account_js
          expect(output).to have_tag 'script', text: %r{https:\\/\\/example.com\\/site_admin\\/account.js}
        end

        context "sub-accounts" do
          before { set_up_subaccounts }

          it "should just include domain root account's when there is no context or @current_user" do
            output = helper.include_account_js
            expect(output).to have_tag 'script'
            expect(output).to match(/#{Regexp.quote('["https:\/\/example.com\/root\/account.js"].forEach')}/)
          end

          it "should load custom js even for high contrast users" do
            @current_user = user_factory
            user_factory.enable_feature!(:high_contrast)
            output = helper.include_account_js
            expect(output).to have_tag 'script'
            expect(output).to match(/#{Regexp.quote('["https:\/\/example.com\/root\/account.js"].forEach')}/)
          end

          it "should include granchild, child, and root when viewing the grandchild or any course or group in it" do
            course = @grandchild_account.courses.create!
            group = course.groups.create!
            [@grandchild_account, course, group].each do |context|
              @context = context
              output = helper.include_account_js
            expect(output).to have_tag 'script'
            expected = '["https:\/\/example.com\/root\/account.js","https:\/\/example.com\/child\/account.js","https:\/\/example.com\/grandchild\/account.js"].forEach'
            expect(output).to match(/#{Regexp.quote(expected)}/)
            end
          end
        end
      end
    end
  end

  describe "help link" do
    before :once do
      Setting.set('show_feedback_link', 'true')
    end

    it "should configure the help link to display the dialog by default" do
      expect(helper.show_help_link?).to eq true
      expect(helper.help_link_url).to eq '#'
      expect(helper.help_link_classes).to eq 'help_dialog_trigger'
    end

    it "should override default help link with the configured support url" do
      support_url = 'http://instructure.com'
      Account.default.update_attribute(:settings, { :support_url => support_url })
      helper.instance_variable_set(:@domain_root_account, Account.default)
      Setting.set('show_feedback_link', 'false')

      expect(helper.support_url).to eq support_url
      expect(helper.show_help_link?).to eq true
      expect(helper.help_link_url).to eq support_url
      expect(helper.help_link_icon).to eq 'help'
      expect(helper.help_link_classes).to eq 'support_url'
    end

    it "should return the configured icon" do
      icon = 'inbox'
      Account.default.update_attribute(:settings, { :help_link_icon => icon })
      helper.instance_variable_set(:@domain_root_account, Account.default)

      expect(helper.help_link_icon).to eq icon
    end

    it "should return the configured help link name" do
      link_name = 'Links'
      Account.default.update_attribute(:settings, { :help_link_name => link_name })
      helper.instance_variable_set(:@domain_root_account, Account.default)

      expect(helper.help_link_name).to eq link_name
    end
  end

  describe "hidden dialogs" do
    before do
      expect(hidden_dialogs).to be_empty
    end

    it "should generate empty string when there are no dialogs" do
      str = render_hidden_dialogs
      expect(str).to eq ''
    end

    it "should work with one hidden_dialog" do
      hidden_dialog('my_test_dialog') { "Hello there!" }
      str = render_hidden_dialogs
      expect(str).to eq "<div id='my_test_dialog' style='display: none;''>Hello there!</div>"
    end

    it "should work with more than one hidden dialog" do
      hidden_dialog('first_dialog') { "first" }
      hidden_dialog('second_dialog') { "second" }
      str = render_hidden_dialogs
      expect(str).to eq "<div id='first_dialog' style='display: none;''>first</div><div id='second_dialog' style='display: none;''>second</div>"
    end

    it "should raise an error when a dialog with conflicting content is added" do
      hidden_dialog('dialog_id') { 'content' }
      expect { hidden_dialog('dialog_id') { 'different content' } }.to raise_error
    end

    it "should only render a dialog once when it has been added multiple times" do
      hidden_dialog('dialog_id') { 'content' }
      hidden_dialog('dialog_id') { 'content' }
      str = render_hidden_dialogs
      expect(str).to eq "<div id='dialog_id' style='display: none;''>content</div>"
    end
  end

  describe "collection_cache_key" do
    it "should generate a cache key, changing when an element cache_key changes" do
      collection = [user_factory, user_factory, user_factory]
      key1 = collection_cache_key(collection)
      key2 = collection_cache_key(collection)
      expect(key1).to eq key2
      # verify it's not overly long
      expect(key1.length).to be <= 40

      User.where(:id => collection[1]).update_all(:updated_at => 1.hour.ago)
      collection[1].reload
      key3 = collection_cache_key(collection)
      expect(key1).not_to eq key3
    end
  end

  context "dashboard_url" do
    before :once do
      @domain_root_account = Account.default
    end

    it "returns a regular canvas dashboard url" do
      expect(dashboard_url).to eq "http://test.host/"
    end

    context "with a custom dashboard_url on the account" do
      before :each do
        @domain_root_account.settings[:dashboard_url] = "http://foo.bar"
      end

      it "returns the custom dashboard_url" do
        expect(dashboard_url).to eq "http://foo.bar"
      end

      context "with login_success=1" do
        it "returns a regular canvas dashboard url" do
          expect(dashboard_url(:login_success => '1')).to eq "http://test.host/?login_success=1"
        end
      end

      context "with become_user_id=1" do
        it "returns a regular canvas dashboard url for masquerading" do
          expect(dashboard_url(:become_user_id => '1')).to eq "http://test.host/?become_user_id=1"
        end
      end

      context "with a user logged in" do
        before :each do
          @current_user = user_factory
        end

        it "returns the custom dashboard_url with the current user's id" do
          expect(dashboard_url).to eq "http://foo.bar?current_user_id=#{@current_user.id}"
        end
      end
    end
  end

  context "include_custom_meta_tags" do
    it "should be nil if @meta_tags is not defined" do
      expect(include_custom_meta_tags).to be_nil
    end

    it "should include tags if present" do
      @meta_tags = [{ :name => "hi", :content => "there" }]
      result = include_custom_meta_tags
      expect(result).to match(/meta/)
      expect(result).to match(/name="hi"/)
      expect(result).to match(/content="there"/)
    end

    it "should html_safe-ify them" do
      @meta_tags = [{ :name => "hi", :content => "there" }]
      expect(include_custom_meta_tags).to be_html_safe
    end
  end

  describe "editor_buttons" do
    it "should return hash of tools if in group" do
      @course = course_model
      @group = @course.groups.create!(:name => "some group")
      tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "test", :shared_secret => "secret", :url => "http://example.com")
      tool.editor_button = {:url => "http://example.com", :icon_url => "http://example.com", :canvas_icon_class => 'icon-commons'}
      tool.save!
      @context = @group

      expect(editor_buttons).to eq([{:name=>"bob", :id=>tool.id, :url=>"http://example.com", :icon_url=>"http://example.com", :canvas_icon_class => 'icon-commons', :width=>800, :height=>400}])
    end

    it "should return hash of tools if in course" do
      @course = course_model
      tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "test", :shared_secret => "secret", :url => "http://example.com")
      tool.editor_button = {:url => "http://example.com", :icon_url => "http://example.com", :canvas_icon_class => 'icon-commons'}
      tool.save!
      controller.stubs(:group_external_tool_path).returns('http://dummy')
      @context = @course

      expect(editor_buttons).to eq([{:name=>"bob", :id=>tool.id, :url=>"http://example.com", :icon_url=>"http://example.com", :canvas_icon_class => 'icon-commons', :width=>800, :height=>400}])
    end

    it "should not include tools from the domain_root_account for users" do
      @domain_root_account = Account.default
      account_admin_user
      tool = @domain_root_account.context_external_tools.new(
        :name => "bob",
        :consumer_key => "test",
        :shared_secret => "secret",
        :url => "http://example.com"
      )
      tool.editor_button = {:url => "http://example.com", :icon_url => "http://example.com"}
      tool.save!
      @context = @admin

      expect(editor_buttons).to be_empty
    end
  end

  describe "UI path checking" do
    describe "#active_path?" do
      context "when the request path is the course show page" do
        let(:request){ stub('request', :fullpath => '/courses/2')}

        it "returns true for paths that match" do
          expect(active_path?('/courses')).to be_truthy
        end

        it "returns false for paths that don't match" do
          expect(active_path?('/grades')).to be_falsey
        end

        it "returns false for paths that don't start the same" do
          expect(active_path?('/accounts/courses')).to be_falsey
        end
      end

      context "when the request path is the account external tools path" do
        let(:request){ stub('request', :fullpath => '/accounts/2/external_tools/27')}

        before :each do
          @context = Account.default
          controller.stubs(:controller_name).returns('external_tools')
        end

        it "it doesn't return true for '/accounts'" do
          expect(active_path?('/accounts')).to be_falsey
        end
      end

      context "when the request path is the course external tools path" do
        let(:request){ stub('request', :fullpath => '/courses/2/external_tools/27')}

        before :each do
          @context = Account.default.courses.create!
          controller.stubs(:controller_name).returns('external_tools')
        end

        it "returns true for '/courses'" do
          expect(active_path?('/courses')).to be_truthy
        end
      end
    end
  end

  describe "js_base_url" do
    it "returns an immutable string" do
      expect(js_base_url).to be_frozen
    end
  end

  describe 'brand_config_for_account' do
    it "handles not having @domain_root_account set" do
      expect(helper.send(:brand_config_for_account)).to be_nil
    end
  end

  describe "active_brand_config" do

    it "returns nil if user prefers high contrast" do
      @current_user = user_factory
      @current_user.enable_feature!(:high_contrast)
      expect(helper.send(:active_brand_config)).to be_nil
    end

    it "returns 'K12 Theme' by default for a k12 school" do
      helper.stubs(:k12?).returns(true)
      BrandConfig.stubs(:k12_config)
      expect(helper.send(:active_brand_config)).to eq BrandConfig.k12_config
    end

    it "returns 'K12 Theme' if a k12 school has chosen 'canvas default' in Theme Editor" do
      helper.stubs(:k12?).returns(true)
      BrandConfig.stubs(:k12_config)

      # this is what happens if you pick "Canvas Default" from the theme picker
      session[:brand_config_md5] = false

      expect(helper.send(:active_brand_config)).to eq BrandConfig.k12_config
    end

  end


  describe "include_js_bundles" do
    before :each do
      helper.stubs(:js_bundles).returns([[:some_bundle], [:some_plugin_bundle, :some_plugin], [:another_bundle, nil]])
    end
    it "creates the correct javascript tags" do
      helper.stubs(:use_webpack?).returns(false)
      base_url = helper.use_optimized_js? ? '/optimized' : '/javascripts'
      expect(helper.include_js_bundles).to eq %{
<script src="#{base_url}/compiled/bundles/some_bundle.js"></script>
<script src="#{base_url}/plugins/some_plugin/compiled/bundles/some_plugin_bundle.js"></script>
<script src="#{base_url}/compiled/bundles/another_bundle.js"></script>
      }.strip
    end

    it "creates the correct javascript tags with webpack enabled" do
      helper.stubs(:use_webpack?).returns(true)
      helper.stubs(:js_env).returns({
        BIGEASY_LOCALE: 'nb_NO',
        MOMENT_LOCALE: 'nb',
        TIMEZONE: 'America/La_Paz',
        CONTEXT_TIMEZONE: 'America/Denver'
      })
      base_url = helper.use_optimized_js? ? 'dist/webpack-production' : 'dist/webpack-dev'
      Canvas::Cdn::RevManifest.stubs(:webpack_url_for).with(base_url + '/vendor.js').returns('vendor_url')
      Canvas::Cdn::RevManifest.stubs(:webpack_url_for).with(base_url + '/vendor/timezone/America/La_Paz.js').returns('La_Paz_url')
      Canvas::Cdn::RevManifest.stubs(:webpack_url_for).with(base_url + '/vendor/timezone/America/Denver.js').returns('Denver_url')
      Canvas::Cdn::RevManifest.stubs(:webpack_url_for).with(base_url + '/vendor/timezone/nb_NO.js').returns('nb_NO_url')
      Canvas::Cdn::RevManifest.stubs(:webpack_url_for).with(base_url + '/moment/locale/nb.js').returns('nb_url')
      Canvas::Cdn::RevManifest.stubs(:webpack_url_for).with(base_url + '/appBootstrap.js').returns('app_bootstrap_url')
      Canvas::Cdn::RevManifest.stubs(:webpack_url_for).with(base_url + '/common.js').returns('common_url')
      Canvas::Cdn::RevManifest.stubs(:webpack_url_for).with(base_url + '/some_bundle.js').returns('some_bundle_url')
      Canvas::Cdn::RevManifest.stubs(:webpack_url_for).with(base_url + '/some_plugin-some_plugin_bundle.js').returns('plugin_url')
      Canvas::Cdn::RevManifest.stubs(:webpack_url_for).with(base_url + '/another_bundle.js').returns('another_bundle_url')

      expect(helper.include_js_bundles).to eq %{
<script src="/vendor_url"></script>
<script src="/La_Paz_url"></script>
<script src="/Denver_url"></script>
<script src="/nb_NO_url"></script>
<script src="/nb_url"></script>
<script src="/app_bootstrap_url"></script>
<script src="/common_url"></script>
<script src="/some_bundle_url"></script>
<script src="/plugin_url"></script>
<script src="/another_bundle_url"></script>
      }.strip
    end
  end

  describe "map_courses_for_menu" do
    context "with Dashcard Reordering feature enabled" do
      before(:each) do
        @account = Account.default
        @account.enable_feature! :dashcard_reordering
        @domain_root_account = @account
      end

      it "returns the list of courses sorted by position" do
        course1 = @account.courses.create!
        course2 = @account.courses.create!
        course3 = @account.courses.create!
        user = user_model
        course1.enroll_student(user)
        course2.enroll_student(user)
        course3.enroll_student(user)
        courses = [course1, course2, course3]
        user.dashboard_positions[course1.asset_string] = 3
        user.dashboard_positions[course2.asset_string] = 2
        user.dashboard_positions[course3.asset_string] = 1
        user.save!
        @current_user = user
        mapped_courses = map_courses_for_menu(courses)
        expect(mapped_courses.map {|h| h[:id]}).to eq [course3.id, course2.id, course1.id]
      end
    end
  end

end
