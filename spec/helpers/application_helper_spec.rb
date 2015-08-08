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
  include ApplicationHelper
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
    user
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
    before do
      @zone = Time.zone
      Time.zone = "Alaska"
      Timecop.freeze(Time.utc(2013,3,13,9,12))
    end

    after do
      Timecop.return
      Time.zone = @zone
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

  context "include_account_css" do
    before do
      helper.stubs(:use_new_styles?).returns(false)
    end

    before :once do
      @site_admin = Account.site_admin
      @domain_root_account = Account.default
    end

    context "with no custom css" do
      it "should be empty" do
        expect(helper.include_account_css).to be_nil
      end
    end

    context "with custom css" do
      it "should include account css" do
        @domain_root_account.settings = @domain_root_account.settings.merge({ :global_includes => true })
        @domain_root_account.settings = @domain_root_account.settings.merge({ :global_stylesheet => '/path/to/css' })
        @domain_root_account.save!

        output = helper.include_account_css
        expect(output).to have_tag 'link'
        expect(output).to match %r{/path/to/css}
      end

      it "should include site admin css" do
        @site_admin.settings = @site_admin.settings.merge({ :global_includes => true })
        @site_admin.settings = @site_admin.settings.merge({ :global_stylesheet => '/path/to/css' })
        @site_admin.save!

        output = helper.include_account_css
        expect(output).to have_tag 'link'
        expect(output).to match %r{/path/to/css}
      end

      it "should include site admin css once" do
        @site_admin.settings = @site_admin.settings.merge({ :global_includes => true })
        @site_admin.settings = @site_admin.settings.merge({ :global_stylesheet => '/path/to/css' })
        @site_admin.save!

        output = helper.include_account_css
        expect(output).to have_tag 'link'
        expect(output.scan(%r{/path/to/css}).length).to eql 1
      end

      it "should include site admin css first" do
        @site_admin.settings = @site_admin.settings.merge({ :global_includes => true })
        @site_admin.settings = @site_admin.settings.merge({ :global_stylesheet => '/path/to/admin/css' })
        @site_admin.save!

        @domain_root_account.settings = @domain_root_account.settings.merge({ :global_includes => true })
        @domain_root_account.settings = @domain_root_account.settings.merge({ :global_stylesheet => '/path/to/root/css' })
        @domain_root_account.save!

        output = helper.include_account_css
        expect(output).to have_tag 'link'
        expect(output.scan(%r{/path/to/(root/|admin/)?css})).to eql [['admin/'], ['root/']]
      end

      it "should not include anything if param is set to 0" do
        @domain_root_account.settings = @domain_root_account.settings.merge({ :global_includes => true })
        @domain_root_account.settings = @domain_root_account.settings.merge({ :global_stylesheet => '/path/to/css' })
        @domain_root_account.save!

        params[:global_includes] = '0'
        output = helper.include_account_css
        expect(output).to be_nil
      end
    end

    context "sub-accounts" do
      before :once do
        @site_admin.settings = @site_admin.settings.merge({ :global_includes => true })
        @site_admin.settings = @site_admin.settings.merge({ :global_stylesheet => '/path/to/admin/css' })
        @site_admin.save!

        @domain_root_account.settings = @domain_root_account.settings.merge({ :global_includes => true })
        @domain_root_account.settings = @domain_root_account.settings.merge({ :sub_account_includes => true })
        @domain_root_account.settings = @domain_root_account.settings.merge({ :global_stylesheet => '/path/to/root/css' })
        @domain_root_account.save!

        @sub_account1 = account_model(:root_account => @domain_root_account)
        @sub_account1.settings = @sub_account1.settings.merge({ :global_stylesheet => '/path/to/sub1/css' })
        @sub_account1.settings = @sub_account1.settings.merge({ :sub_account_includes => true })
        @sub_account1.save!

        @sub_account2 = account_model(:root_account => @domain_root_account)
        @sub_account2.settings = @sub_account2.settings.merge({ :global_stylesheet => '/path/to/sub2/css' })
        @sub_account2.save!
      end

      it "should include sub-account css" do
        @context = @sub_account1
        output = helper.include_account_css
        expect(output).to have_tag 'link'
        expect(output.scan(%r{/path/to/(sub1/|sub2/|root/|admin/)?css})).to eql [['admin/'], ['root/'], ['sub1/']]
      end

      it "should not include sub-account css when root account is context" do
        @context = @domain_root_account
        output = helper.include_account_css
        expect(output).to have_tag 'link'
        expect(output.scan(%r{/path/to/(sub1/|sub2/|root/|admin/)?css})).to eql [['admin/'], ['root/']]
      end

      it "should include sub-account css for course context" do
        @context = @sub_account1.courses.create!
        output = helper.include_account_css
        expect(output).to have_tag 'link'
        expect(output.scan(%r{/path/to/(sub1/|sub2/|root/|admin/)?css})).to eql [['admin/'], ['root/'], ['sub1/']]
      end

      it "should include sub-account css for group context" do
        @course = @sub_account1.courses.create!
        @context = @course.groups.create!
        output = helper.include_account_css
        expect(output).to have_tag 'link'
        expect(output.scan(%r{/path/to/(sub1/|sub2/|root/|admin/)?css})).to eql [['admin/'], ['root/'], ['sub1/']]
      end

      it "should use include sub-account css, if sub-account is lowest common account context" do
        @course = @sub_account1.courses.create!
        @course.offer!
        student_in_course(:active_all => true)
        @context = @user
        @current_user = @user
        output = helper.include_account_css
        expect(output).to have_tag 'link'
        expect(output.scan(%r{/path/to/(sub1/|sub2/|root/|admin/)?css})).to eql [['admin/'], ['root/'], ['sub1/']]
      end

      it "should not use include sub-account css, if sub-account is not lowest common account context" do
        @course1 = @sub_account1.courses.create!
        @course1.offer!
        @course2 = @sub_account2.courses.create!
        @course2.offer!
        student_in_course(:active_all => true, :course => @course1)
        student_in_course(:active_all => true, :course => @course2, :user => @user)
        @context = @user
        @current_user = @user
        output = helper.include_account_css
        expect(output).to have_tag 'link'
        expect(output.scan(%r{/path/to/(sub1/|sub2/|root/|admin/)?css})).to eql [['admin/'], ['root/']]
      end

      it "should include multiple levesl of sub-account css in the right order for course page" do
        @sub_sub_account1 = account_model(:parent_account => @sub_account1, :root_account => @domain_root_account)
        @sub_sub_account1.settings = @sub_sub_account1.settings.merge({ :global_stylesheet => '/path/to/subsub1/css' })
        @sub_sub_account1.save!

        @context = @sub_sub_account1.courses.create!
        output = helper.include_account_css
        expect(output).to have_tag 'link'
        expect(output.scan(%r{/path/to/(subsub1/|sub1/|sub2/|root/|admin/)?css})).to eql [['admin/'], ['root/'], ['sub1/'], ['subsub1/']]
      end

      it "should include multiple levesl of sub-account css in the right order" do
        @sub_sub_account1 = account_model(:parent_account => @sub_account1, :root_account => @domain_root_account)
        @sub_sub_account1.settings = @sub_sub_account1.settings.merge({ :global_stylesheet => '/path/to/subsub1/css' })
        @sub_sub_account1.save!

        @course = @sub_sub_account1.courses.create!
        @course.offer!
        student_in_course(:active_all => true)
        @context = @user
        @current_user = @user
        output = helper.include_account_css
        expect(output).to have_tag 'link'
        expect(output.scan(%r{/path/to/(subsub1/|sub1/|sub2/|root/|admin/)?css})).to eql [['admin/'], ['root/'], ['sub1/'], ['subsub1/']]
      end
    end
  end

  describe "include_account_js" do
    before do
      helper.stubs(:use_new_styles?).returns(false)
    end

    before :once do
      @site_admin = Account.site_admin
      @domain_root_account = Account.default
    end

    context "with no custom js" do
      it "should be empty" do
        expect(helper.include_account_js).to be_nil
      end
    end

    context "with custom js" do
      it "should include account javascript" do
        @domain_root_account.settings = @domain_root_account.settings.merge({ :global_includes => true })
        @domain_root_account.settings = @domain_root_account.settings.merge({ :global_javascript => '/path/to/js' })
        @domain_root_account.save!

        output = helper.include_account_js
        expect(output).to have_tag 'script'
        expect(output).to match %r{\\?/path\\?/to\\?/js}
      end

      it "should include site admin javascript" do
        @site_admin.settings = @site_admin.settings.merge({ :global_includes => true })
        @site_admin.settings = @site_admin.settings.merge({ :global_javascript => '/path/to/js' })
        @site_admin.save!

        output = helper.include_account_js
        expect(output).to have_tag 'script'
        expect(output).to match %r{\\?/path\\?/to\\?/js}
      end

      it "should include both site admin and root account javascript, site admin first" do
        @domain_root_account.settings = @domain_root_account.settings.merge({ :global_includes => true })
        @domain_root_account.settings = @domain_root_account.settings.merge({ :global_javascript => '/path/to/root/js' })
        @domain_root_account.save!

        @site_admin.settings = @site_admin.settings.merge({ :global_includes => true })
        @site_admin.settings = @site_admin.settings.merge({ :global_javascript => '/path/to/admin/js' })
        @site_admin.save!

        output = helper.include_account_js
        expect(output).to have_tag 'script'
        expect(output.scan(%r{\\?/path\\?/to\\?/(admin|root)?\\?/?js})).to eql [['admin'], ['root']]
      end
    end
  end

  context "global_includes" do
    before do
      helper.stubs(:use_new_styles?).returns(false)
    end

    it "should only compute includes once, with includes" do
      @site_admin = Account.site_admin
      @site_admin.expects(:global_includes_hash).once.returns({:css => "/path/to/css", :js => "/path/to/js"})
      expect(helper.include_account_css).to match %r{/path/to/css}
      expect(helper.include_account_js).to match %r{\\?/path\\?/to\\?/js}
    end

    it "should only compute includes once, with includes" do
      @site_admin = Account.site_admin
      @site_admin.expects(:global_includes_hash).once.returns(nil)
      expect(helper.include_account_css).to be_nil
      expect(helper.include_account_js).to be_nil
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
      collection = [user, user, user]
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
          @current_user = user
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
      tool.editor_button = {:url => "http://example.com", :icon_url => "http://example.com"}
      tool.save!
      @context = @group

      expect(editor_buttons).to eq([{:name=>"bob", :id=>tool.id, :url=>"http://example.com", :icon_url=>"http://example.com", :width=>800, :height=>400}])
    end

    it "should return hash of tools if in course" do
      @course = course_model
      tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "test", :shared_secret => "secret", :url => "http://example.com")
      tool.editor_button = {:url => "http://example.com", :icon_url => "http://example.com"}
      tool.save!
      controller.stubs(:group_external_tool_path).returns('http://dummy')
      @context = @course

      expect(editor_buttons).to eq([{:name=>"bob", :id=>tool.id, :url=>"http://example.com", :icon_url=>"http://example.com", :width=>800, :height=>400}])
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
      let(:request){ stub('request', :fullpath => '/courses/2')}

      it "recognizes the active path" do
        expect(active_path?('courses')).to be_truthy
      end

      it "rejects paths that don't match" do
        expect(active_path?('grades')).to be_falsey
      end
    end

    describe "#account_external_tool_path?" do
      account_ext_tool_path = "/accounts/2/external_tools/27"
      course_ext_tool_path = "/courses/2/external_tools/27"

      it "recognizes the account external tool path" do
        expect(account_external_tool_path?(account_ext_tool_path)).to be_truthy
      end

      it "rejects paths that don't match" do
        expect(account_external_tool_path?(course_ext_tool_path)).to be_falsey
      end
    end
  end
end
