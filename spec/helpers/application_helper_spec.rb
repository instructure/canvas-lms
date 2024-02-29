# frozen_string_literal: true

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

require "nokogiri"

describe ApplicationHelper do
  include ERB::Util

  alias_method :content_tag_without_nil_return, :content_tag

  context "folders_as_options" do
    before(:once) do
      course_model
      @f = Folder.create!(name: "f", context: @course)
      @f_1 = Folder.create!(name: "f_1", parent_folder: @f, context: @course)
      @f_2 = Folder.create!(name: "f_2", parent_folder: @f, context: @course)
      @f_2_1 = Folder.create!(name: "f_2_1", parent_folder: @f_2, context: @course)
      @f_2_1_1 = Folder.create!(name: "f_2_1_1", parent_folder: @f_2_1, context: @course)
      @all_folders = [@f, @f_1, @f_2, @f_2_1, @f_2_1_1]
    end

    it "works work recursively" do
      option_string = folders_as_options([@f], all_folders: @all_folders)

      html = Nokogiri::HTML5.fragment("<select>#{option_string}</select>")
      expect(html.css("option").count).to eq 5
      expect(html.css("option")[0].text).to eq @f.name
      expect(html.css("option")[1].text).to match(/^\xC2\xA0\xC2\xA0\xC2\xA0- #{@f_1.name}/)
      expect(html.css("option")[4].text).to match(/^\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0- #{@f_2_1_1.name}/)
    end

    it "limits depth" do
      option_string = folders_as_options([@f], all_folders: @all_folders, max_depth: 1)

      html = Nokogiri::HTML5.fragment("<select>#{option_string}</select>")
      expect(html.css("option").count).to eq 3
      expect(html.css("option")[0].text).to eq @f.name
      expect(html.css("option")[1].text).to match(/^\xC2\xA0\xC2\xA0\xC2\xA0- #{@f_1.name}/)
      expect(html.css("option")[2].text).to match(/^\xC2\xA0\xC2\xA0\xC2\xA0- #{@f_2.name}/)
    end

    it "works without supplying all folders" do
      option_string = folders_as_options([@f])

      html = Nokogiri::HTML5.fragment("<select>#{option_string}</select>")
      expect(html.css("option").count).to eq 5
      expect(html.css("option")[0].text).to eq @f.name
      expect(html.css("option")[1].text).to match(/^\xC2\xA0\xC2\xA0\xC2\xA0- #{@f_1.name}/)
      expect(html.css("option")[4].text).to match(/^\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0- #{@f_2_1_1.name}/)
    end
  end

  context "show_user_create_course_button" do
    before(:once) { @domain_root_account = Account.default }

    it "works (non-granular)" do
      @domain_root_account.disable_feature!(:granular_permissions_manage_courses)
      @domain_root_account.update_attribute(
        :settings,
        { teachers_can_create_courses: true, students_can_create_courses: true }
      )
      expect(show_user_create_course_button(nil)).to be_falsey
      user_factory
      expect(show_user_create_course_button(@user)).to be_falsey
      course_with_teacher
      expect(show_user_create_course_button(@teacher)).to be_truthy
      account_admin_user
      expect(show_user_create_course_button(@admin)).to be_truthy
    end

    it "works for no enrollments setting (granular permissions)" do
      @domain_root_account.enable_feature!(:granular_permissions_manage_courses)
      @domain_root_account.update(settings: { no_enrollments_can_create_courses: true })
      expect(show_user_create_course_button(nil)).to be_falsey
      user_factory
      expect(show_user_create_course_button(@user)).to be_truthy
      course_with_teacher
      expect(show_user_create_course_button(@teacher)).to be_falsey
      account_admin_user
      expect(show_user_create_course_button(@admin)).to be_truthy
    end
  end

  describe "tomorrow_at_midnight" do
    it "always returns a time in the future" do
      now = 1.day.from_now.midnight - 5.seconds
      expect(tomorrow_at_midnight).to be > now
    end
  end

  describe "Time Display Helpers" do
    before do
      @zone = Time.zone
      Time.zone = "Alaska"
    end

    after do
      Time.zone = @zone
    end

    around do |example|
      Timecop.freeze(Time.zone.local(2013, 3, 13, 9, 12), &example)
    end

    describe "#context_sensitive_datetime_title" do
      it "produces a string showing the local time and the course time" do
        context = double(time_zone: ActiveSupport::TimeZone["America/Denver"])
        expect(context_sensitive_datetime_title(Time.now, context)).to eq "data-tooltip data-html-tooltip-title=\"Local: Mar 13 at 1:12am<br>Course: Mar 13 at 3:12am\""
      end

      it "only prints the text if just_text option passed" do
        context = double(time_zone: ActiveSupport::TimeZone["America/Denver"])
        expect(context_sensitive_datetime_title(Time.now, context, just_text: true)).to eq "Local: Mar 13 at 1:12am<br>Course: Mar 13 at 3:12am"
      end

      it "uses the simple title if theres no timezone difference" do
        context = double(time_zone: ActiveSupport::TimeZone["America/Anchorage"])
        expect(context_sensitive_datetime_title(Time.now, context, just_text: true)).to eq "Mar 13 at 1:12am"
        expect(context_sensitive_datetime_title(Time.now, context)).to eq "data-tooltip data-html-tooltip-title=\"Mar 13 at 1:12am\""
      end

      it "uses the simple title for nil context" do
        expect(context_sensitive_datetime_title(Time.now, nil, just_text: true)).to eq "Mar 13 at 1:12am"
      end

      it "crosses date boundaries appropriately" do
        Timecop.freeze(Time.utc(2013, 3, 13, 7, 12)) do
          context = double(time_zone: ActiveSupport::TimeZone["America/Denver"])
          expect(context_sensitive_datetime_title(Time.now, context)).to eq "data-tooltip data-html-tooltip-title=\"Local: Mar 12 at 11:12pm<br>Course: Mar 13 at 1:12am\""
        end
      end
    end

    describe "#friendly_datetime" do
      let(:context) { double(time_zone: ActiveSupport::TimeZone["America/Denver"]) }

      it "spits out a friendly time tag" do
        tag = friendly_datetime(Time.now)
        expect(tag).to eq "<time data-html-tooltip-title=\"Mar 13 at 1:12am\" data-tooltip=\"top\">Mar 13 at 1:12am</time>"
      end

      it "builds a whole time tag with a useful title showing the timezone offset if theres a context" do
        tag = friendly_datetime(Time.now, context:)
        expect(tag).to match(%r{^<time.*</time>$})
        expect(tag).to match(/data-html-tooltip-title=/)
        expect(tag).to match(/Local: Mar 13 at 1:12am/)
        expect(tag).to match(/Course: Mar 13 at 3:12am/)
      end

      it "can produce an alternate tag type" do
        tag = friendly_datetime(Time.now, context:, tag_type: :span)
        expect(tag).to match(%r{^<span.*</span>$})
        expect(tag).to match(/data-html-tooltip-title=/)
        expect(tag).to match(/Local: Mar 13 at 1:12am/)
        expect(tag).to match(/Course: Mar 13 at 3:12am/)
      end

      it "produces no tooltip for a nil datetime" do
        tag = friendly_datetime(nil, context:)
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
      format = accessible_date_format("date")
      expect(format).to match(/YYYY/)
      expect(format).to_not match(/hh:mm/)
    end

    it "produces a time-only format" do
      format = accessible_date_format("time")
      expect(format).to_not match(/YYYY/)
      expect(format).to match(/hh:mm/)
    end

    it "throws an argument error for a foolish format" do
      expect { accessible_date_format("nonsense") }.to raise_error(ArgumentError)
    end
  end

  describe "custom css/js includes" do
    def set_up_subaccounts
      @domain_root_account.settings[:global_includes] = true
      @domain_root_account.settings[:sub_account_includes] = true
      @domain_root_account.create_brand_config!({
                                                  css_overrides: "https://example.com/root/account.css",
                                                  js_overrides: "https://example.com/root/account.js"
                                                })
      @domain_root_account.save!

      @child_account = account_model(root_account: @domain_root_account, name: "child account")
      bc = @child_account.build_brand_config({
                                               css_overrides: "https://example.com/child/account.css",
                                               js_overrides: "https://example.com/child/account.js"
                                             })
      bc.parent_md5 = @domain_root_account.brand_config.md5
      bc.save!
      @child_account.save!

      @grandchild_account = @child_account.sub_accounts.create!(name: "grandchild account")
      bc = @grandchild_account.build_brand_config({
                                                    css_overrides: "https://example.com/grandchild/account.css",
                                                    js_overrides: "https://example.com/grandchild/account.js"
                                                  })
      bc.parent_md5 = @child_account.brand_config.md5
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
        it "is empty" do
          allow(helper).to receive(:active_brand_config).and_return(nil)
          expect(helper.include_account_css).to be_nil
        end
      end

      context "with custom css" do
        it "includes account css" do
          allow(helper).to receive(:active_brand_config).and_return BrandConfig.create!(css_overrides: "https://example.com/path/to/overrides.css")
          output = helper.include_account_css
          expect(output).to have_tag "link"
          expect(output).to match %r{https://example.com/path/to/overrides.css}
        end

        it "includes site_admin css even if there is no active brand" do
          allow(helper).to receive(:active_brand_config).and_return nil
          Account.site_admin.create_brand_config!({
                                                    css_overrides: "https://example.com/site_admin/account.css",
                                                    js_overrides: "https://example.com/site_admin/account.js"
                                                  })
          output = helper.include_account_css
          expect(output).to have_tag "link"
          expect(output).to match %r{https://example.com/site_admin/account.css}
        end

        it "does not include anything if param is set to 0" do
          allow(helper).to receive(:active_brand_config).and_return BrandConfig.create!(css_overrides: "https://example.com/path/to/overrides.css")
          params[:global_includes] = "0"

          output = helper.include_account_css
          expect(output).to be_nil
        end

        context "with user that doesn't work for that account" do
          before do
            @current_pseudonym = pseudonym_model
            allow(@current_pseudonym).to receive(:works_for_account?).and_return(false)
          end

          it "won't render only JS" do
            allow(helper).to receive(:active_brand_config).and_return BrandConfig.create!(css_overrides: "https://example.com/path/to/overrides.css")
            expect(helper.include_account_css).to be_nil
          end

          it "will not render if there's javacscript" do
            allow(helper).to receive(:active_brand_config).and_return BrandConfig.create!(
              css_overrides: "https://example.com/root/account.css",
              js_overrides: "https://example.com/root/account.js"
            )
            expect(helper.include_account_css).to be_nil
          end
        end
      end

      context "sub-accounts" do
        before { set_up_subaccounts }

        it "includes sub-account css when viewing the subaccount or any course or group in it" do
          course = @grandchild_account.courses.create!
          group = course.groups.create!
          [@grandchild_account, course, group].each do |context|
            @context = context
            output = helper.include_account_css
            expect(output).to have_tag "link"
            expect(output.scan(%r{https://example.com/(root|child|grandchild)?/account.css})).to eql [["root"], ["child"], ["grandchild"]]
          end
        end

        it "does not include sub-account css when root account is context" do
          @context = @domain_root_account
          output = helper.include_account_css
          expect(output).to have_tag "link"
          expect(output.scan(%r{https://example.com/(root|child|grandchild)?/account.css})).to eql [["root"]]
        end

        it "uses include sub-account css, if sub-account is lowest common account context" do
          @course = @grandchild_account.courses.create!
          @course.offer!
          student_in_course(active_all: true)
          @context = @user
          @current_user = @user
          output = helper.include_account_css
          expect(output).to have_tag "link"
          expect(output.scan(%r{https://example.com/(root|child|grandchild)?/account.css})).to eql [["root"], ["child"], ["grandchild"]]
        end

        it "works using common_account_chain starting from lowest common account context with enrollments" do
          course1 = @child_account.courses.create!
          course1.offer!
          course2 = @grandchild_account.courses.create!
          course2.offer!
          student_in_course(active_all: true, course: course1, user: @user)
          student_in_course(active_all: true, course: course2, user: @user)
          @context = @user
          @current_user = @user
          output = helper.include_account_css
          expect(output).to have_tag "link"
          expect(output.scan(%r{https://example.com/(root|child|grandchild)?/account.css})).to eql [["root"], ["child"]]
        end

        it "fall-backs to @domain_root_account's branding if I'm logged in but not enrolled in anything" do
          @current_user = user_factory
          output = helper.include_account_css
          expect(output).to have_tag "link"
          expect(output.scan(%r{https://example.com/(root|child|grandchild)?/account.css})).to eql [["root"]]
        end

        it "loads custom css even for high contrast users" do
          @current_user = user_factory
          user_factory.enable_feature!(:high_contrast)
          @context = @grandchild_account
          output = helper.include_account_css
          expect(output).to have_tag "link"
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
        it "is empty" do
          allow(helper).to receive(:active_brand_config).and_return(nil)
          expect(helper.include_account_js).to be_nil
        end
      end

      context "with custom js" do
        it "includes account javascript" do
          allow(helper).to receive(:active_brand_config).and_return BrandConfig.create!(js_overrides: "https://example.com/path/to/overrides.js")
          output = helper.include_account_js
          expect(output).to have_tag "script", text: %r{https:\\/\\/example.com\\/path\\/to\\/overrides.js}
        end

        it "includes site_admin javascript even if there is no active brand" do
          allow(helper).to receive(:active_brand_config).and_return nil
          Account.site_admin.create_brand_config!({
                                                    css_overrides: "https://example.com/site_admin/account.css",
                                                    js_overrides: "https://example.com/site_admin/account.js"
                                                  })

          output = helper.include_account_js
          expect(output).to have_tag "script", text: %r{https:\\/\\/example.com\\/site_admin\\/account.js}
        end

        it "will not render for user that doesn't work with that account" do
          @current_pseudonym = pseudonym_model
          allow(@current_pseudonym).to receive(:works_for_account?).and_return(false)
          allow(helper).to receive(:active_brand_config).and_return BrandConfig.create!(js_overrides: "https://example.com/path/to/overrides.js")
          expect(helper.include_account_js).to be_nil
        end

        it "renders for consortium admins in subaccounts" do
          consortium_parent = account_model
          root = account_model
          sub = account_model(parent_account: root, root_account: root)

          consortium_parent.settings[:consortium_parent_account] = true
          consortium_parent.save!
          consortium_parent.add_consortium_child(root)

          @current_pseudonym = pseudonym_model(account: consortium_parent)
          @brand_account = sub

          allow(helper).to receive(:active_brand_config).and_return BrandConfig.create!(js_overrides: "https://example.com/path/to/overrides.js")
          output = helper.include_account_js
          expect(output).to have_tag "script", text: %r{https:\\/\\/example.com\\/path\\/to\\/overrides.js}
        end

        context "sub-accounts" do
          before { set_up_subaccounts }

          it "justs include domain root account's when there is no context or @current_user" do
            output = helper.include_account_js
            expect(output).to have_tag "script"
            expect(output).to eq("<script src=\"https://example.com/root/account.js\" defer=\"defer\"></script>")
          end

          it "loads custom js even for high contrast users" do
            @current_user = user_factory
            user_factory.enable_feature!(:high_contrast)
            output = helper.include_account_js
            expect(output).to eq("<script src=\"https://example.com/root/account.js\" defer=\"defer\"></script>")
          end

          it "includes granchild, child, and root when viewing the grandchild or any course or group in it" do
            course = @grandchild_account.courses.create!
            group = course.groups.create!
            [@grandchild_account, course, group].each do |context|
              @context = context
              expect(helper.include_account_js).to eq("<script src=\"https://example.com/root/account.js\" defer=\"defer\"></script>\n  <script src=\"https://example.com/child/account.js\" defer=\"defer\"></script>\n  <script src=\"https://example.com/grandchild/account.js\" defer=\"defer\"></script>")
            end
          end
        end
      end
    end
  end

  describe "help link" do
    it "configures the help link to display the dialog by default" do
      expect(helper.help_link_url).to eq "#"
      expect(helper.help_link_classes).to eq "help_dialog_trigger"
    end

    it "returns the default_support_url setting if set" do
      Setting.set("default_support_url", "http://help.example.com")
      expect(helper.help_link_url).to eq "http://help.example.com"
    end

    it "overrides default help link with the configured support url" do
      support_url = "http://instructure.com"
      Account.default.update_attribute(:settings, { support_url: })
      helper.instance_variable_set(:@domain_root_account, Account.default)

      expect(helper.support_url).to eq support_url
      expect(helper.help_link_url).to eq support_url
      expect(helper.help_link_icon).to eq "help"
      expect(helper.help_link_classes).to eq "support_url help_dialog_trigger"
    end

    it "returns the configured icon" do
      icon = "inbox"
      Account.default.update_attribute(:settings, { help_link_icon: icon })
      helper.instance_variable_set(:@domain_root_account, Account.default)

      expect(helper.help_link_icon).to eq icon
    end

    it "returns the configured help link name" do
      link_name = "Links"
      Account.default.update_attribute(:settings, { help_link_name: link_name })
      helper.instance_variable_set(:@domain_root_account, Account.default)

      expect(helper.help_link_name).to eq link_name
    end
  end

  describe "collection_cache_key" do
    it "generates a cache key, changing when an element cache_key changes" do
      collection = [user_factory, user_factory, user_factory]
      key1 = collection_cache_key(collection)
      key2 = collection_cache_key(collection)
      expect(key1).to eq key2
      # verify it's not overly long
      expect(key1.length).to be <= 128

      User.where(id: collection[1]).update_all(updated_at: 1.hour.ago)
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
      before do
        @domain_root_account.settings[:dashboard_url] = "http://foo.bar"
      end

      it "returns the custom dashboard_url" do
        expect(dashboard_url).to eq "http://foo.bar"
      end

      context "with login_success=1" do
        it "returns a regular canvas dashboard url" do
          expect(dashboard_url(login_success: "1")).to eq "http://test.host/?login_success=1"
        end
      end

      context "with become_user_id=1" do
        it "returns a regular canvas dashboard url for masquerading" do
          expect(dashboard_url(become_user_id: "1")).to eq "http://test.host/?become_user_id=1"
        end
      end

      context "with a user logged in" do
        before do
          @current_user = user_factory
        end

        it "returns the custom dashboard_url with the current user's id" do
          expect(dashboard_url).to eq "http://foo.bar?current_user_id=#{@current_user.id}"
        end
      end
    end
  end

  context "include_custom_meta_tags" do
    it "is nil if @meta_tags is not defined" do
      expect(include_custom_meta_tags).to be_nil
    end

    it "includes tags if present" do
      @meta_tags = [{ name: "hi", content: "there" }]
      result = include_custom_meta_tags
      expect(result).to match(/meta/)
      expect(result).to match(/name="hi"/)
      expect(result).to match(/content="there"/)
    end

    it "html_safe-ifies them" do
      @meta_tags = [{ name: "hi", content: "there" }]
      expect(include_custom_meta_tags).to be_html_safe
    end
  end

  describe "editor_buttons" do
    it "returns hash of tools if in group" do
      @course = course_model
      @group = @course.groups.create!(name: "some group")
      tool = @course.context_external_tools.new(
        name: "bob",
        consumer_key: "test",
        shared_secret: "secret",
        url: "http://example.com",
        description: "the description."
      )
      tool.editor_button = { url: "http://example.com", icon_url: "http://example.com", canvas_icon_class: "icon-commons" }
      tool.save!
      @context = @group

      expect(editor_buttons).to eq([{
                                     name: "bob",
                                     id: tool.id,
                                     url: "http://example.com",
                                     icon_url: "http://example.com",
                                     canvas_icon_class: "icon-commons",
                                     width: 800,
                                     height: 400,
                                     use_tray: false,
                                     always_on: false,
                                     description: "<p>the description.</p>\n",
                                     favorite: false
                                   }])
    end

    it "returns hash of tools if in course" do
      @course = course_model
      tool = @course.context_external_tools.new(name: "bob", consumer_key: "test", shared_secret: "secret", url: "http://example.com")
      tool.editor_button = { url: "http://example.com", icon_url: "http://example.com", canvas_icon_class: "icon-commons" }
      tool.save!
      allow(controller).to receive(:group_external_tool_path).and_return("http://dummy")
      @context = @course

      expect(editor_buttons).to eq([{
                                     name: "bob",
                                     id: tool.id,
                                     url: "http://example.com",
                                     icon_url: "http://example.com",
                                     canvas_icon_class: "icon-commons",
                                     width: 800,
                                     height: 400,
                                     use_tray: false,
                                     always_on: false,
                                     description: "",
                                     favorite: false
                                   }])
    end

    it "does not include tools from the domain_root_account for users" do
      @domain_root_account = Account.default
      account_admin_user
      tool = @domain_root_account.context_external_tools.new(
        name: "bob",
        consumer_key: "test",
        shared_secret: "secret",
        url: "http://example.com"
      )
      tool.editor_button = { url: "http://example.com", icon_url: "http://example.com" }
      tool.save!
      @context = @admin

      expect(editor_buttons).to be_empty
    end

    it "passes in the base url for use with default tool icons" do
      @course = course_model
      @context = @course

      expect(ContextExternalTool).to receive(:editor_button_json).with(
        an_instance_of(Array),
        anything,
        anything,
        anything,
        "http://test.host"
      )
      editor_buttons
    end
  end

  describe "UI path checking" do
    describe "#active_path?" do
      context "when the request path is the course show page" do
        let(:request) { double("request", fullpath: "/courses/2") }

        it "returns true for paths that match" do
          expect(active_path?("/courses")).to be_truthy
        end

        it "returns false for paths that don't match" do
          expect(active_path?("/grades")).to be_falsey
        end

        it "returns false for paths that don't start the same" do
          expect(active_path?("/accounts/courses")).to be_falsey
        end
      end

      context "when the request path is the account external tools path" do
        let(:request) { double("request", fullpath: "/accounts/2/external_tools/27") }

        before do
          @context = Account.default
          allow(controller).to receive(:controller_name).and_return("external_tools")
        end

        it "doesn't return true for '/accounts'" do
          expect(active_path?("/accounts")).to be_falsey
        end
      end

      context "when the request path is the course external tools path" do
        let(:request) { double("request", fullpath: "/courses/2/external_tools/27") }

        before do
          @context = Account.default.courses.create!
          allow(controller).to receive(:controller_name).and_return("external_tools")
        end

        it "returns true for '/courses'" do
          expect(active_path?("/courses")).to be_truthy
        end
      end
    end
  end

  describe "brand_config_account" do
    it "handles not having @domain_root_account set" do
      expect(helper.send(:brand_config_account)).to be_nil
    end
  end

  describe "active_brand_config" do
    it "returns nil if user prefers high contrast" do
      @current_user = user_factory
      @current_user.enable_feature!(:high_contrast)
      expect(helper.send(:active_brand_config)).to be_nil
    end

    it "returns 'K12 Theme' by default for a k12 school" do
      allow(helper).to receive(:k12?).and_return(true)
      allow(BrandConfig).to receive(:k12_config)
      expect(helper.send(:active_brand_config)).to eq BrandConfig.k12_config
    end

    it "returns 'K12 Theme' if a k12 school has chosen 'canvas default' in Theme Editor" do
      @domain_root_account = Account.default
      allow(helper).to receive(:k12?).and_return(true)
      allow(BrandConfig).to receive(:k12_config)

      # this is what happens if you pick "Canvas Default" from the theme picker
      session[:brand_config] = { md5: nil, type: :default }

      expect(helper.send(:active_brand_config)).to eq BrandConfig.k12_config
    end
  end

  describe "map_groups_for_planner" do
    context "with planner enabled" do
      before do
        @account = Account.default
      end

      it "returns the list of groups the user belongs to" do
        user = user_model
        group1 = @account.groups.create! name: "Account group"
        course1 = @account.courses.create!
        group2 = course1.groups.create! name: "Course group"
        group3 = @account.groups.create! name: "Another account group"
        groups = [group1, group2, group3]

        @current_user = user
        course1.enroll_student(@current_user)
        groups.each { |g| g.add_user(user, "accepted", true) }
        user_account_groups = map_groups_for_planner(groups)
        expect(user_account_groups.pluck(:id)).to eq [group1.id, group2.id, group3.id]
      end
    end
  end

  describe "tutorials_enabled?" do
    before do
      @domain_root_account = Account.default
    end

    context "with new_users_tutorial feature flag enabled" do
      before do
        @domain_root_account.enable_feature! :new_user_tutorial
        @current_user = User.create!
      end

      it "returns true if the user has the flag enabled" do
        @current_user.enable_feature!(:new_user_tutorial_on_off)
        expect(tutorials_enabled?).to be true
      end

      it "returns false if the user has the flag disabled" do
        @current_user.disable_feature!(:new_user_tutorial_on_off)
        expect(tutorials_enabled?).to be false
      end
    end
  end

  describe "planner_enabled?" do
    before do
      @domain_root_account = Account.default
    end

    it "returns false when a user has no student enrollments" do
      course_with_teacher(active_all: true)
      @current_user = @user
      expect(planner_enabled?).to be false
    end

    it "returns true when there is at least one student enrollment" do
      course_with_student(active_all: true)
      @current_user = @user
      expect(planner_enabled?).to be true
    end

    it "returns true for past student enrollments" do
      enrollment = course_with_student
      enrollment.workflow_state = "completed"
      enrollment.save!
      @current_user = @user
      expect(planner_enabled?).to be true
    end

    it "returns true for invited student enrollments" do
      enrollment = course_with_student
      enrollment.workflow_state = "invited"
      enrollment.save!
      @current_user = @user
      expect(planner_enabled?).to be true
    end

    it "returns true for future student enrollments" do
      enrollment = course_with_student
      enrollment.start_at = 2.months.from_now
      enrollment.end_at = 3.months.from_now
      enrollment.workflow_state = "active"
      enrollment.save!
      @course.restrict_student_future_view = true
      @course.restrict_enrollments_to_course_dates = true
      @course.save!
      @current_user = @user
      expect(planner_enabled?).to be true
    end

    it "returns false with no user" do
      expect(planner_enabled?).to be false
    end

    context "for observers" do
      before :once do
        @course1 = course_factory(active_all: true)
        @student1 = user_factory(active_all: true)
        @observer = user_factory(active_all: true)
        @course1.enroll_student(@student1)
        @course1.enroll_user(@observer, "ObserverEnrollment", { associated_user_id: @student1.id })
      end

      it "still returns true for the observed student" do
        @current_user = @student1
        expect(planner_enabled?).to be true
      end

      it "returns true for the observer if k5_user" do
        allow(helper).to receive(:k5_user?).and_return(true)
        @current_user = @observer
        expect(helper.planner_enabled?).to be true
      end

      it "still returns false for a teacher" do
        teacher = user_factory(active_all: true)
        @course1.enroll_teacher(teacher)
        @current_user = teacher
        expect(planner_enabled?).to be false
      end

      it "returns true for a normal observer" do
        allow(helper).to receive(:k5_user?).and_return(false)
        @current_user = @observer
        expect(helper.planner_enabled?).to be true
      end
    end
  end

  describe "file_access_user" do
    it "returns access user from session" do
      access_user = user_model
      session["file_access_user_id"] = access_user.id
      expect(file_access_user).to eql access_user
    end

    it "returns the current user" do
      @current_user = user_model
      expect(file_access_user).to eql @current_user
    end

    it "returns nil if not set" do
      expect(file_access_user).to be_nil
    end
  end

  describe "file_access_real_user" do
    context "not on the files domain" do
      before do
        @files_domain = false
      end

      let(:logged_in_user) { user_model }

      it "returns logged_in_user" do
        expect(file_access_real_user).to be logged_in_user
      end
    end

    context "on the files domain" do
      before do
        @files_domain = true
      end

      it "returns real access user from session" do
        real_access_user = user_model
        session["file_access_real_user_id"] = real_access_user.id
        expect(file_access_real_user).to eql real_access_user
      end

      it "returns access user from session if real access user not set" do
        access_user = user_model
        session["file_access_user_id"] = access_user.id
        session["file_access_real_user_id"] = nil
        expect(file_access_real_user).to eql access_user
      end

      it "returns real access user over access user if both set" do
        access_user = user_model
        real_access_user = user_model
        session["file_access_user_id"] = access_user.id
        session["file_access_real_user_id"] = real_access_user.id
        expect(file_access_real_user).to eql real_access_user
      end

      it "returns nil if neither set" do
        expect(file_access_real_user).to be_nil
      end
    end
  end

  describe "file_access_developer_key" do
    context "not on the files domain" do
      before do
        @files_domain = false
      end

      it "returns token's developer_key with @access_token set" do
        user = user_model
        developer_key = DeveloperKey.create!
        @access_token = user.access_tokens.where(developer_key_id: developer_key).create!
        expect(file_access_developer_key).to eql developer_key
      end

      it "returns nil without @access_token set" do
        expect(file_access_developer_key).to be_nil
      end
    end

    context "on the files domain" do
      before do
        @files_domain = true
      end

      it "returns developer key from session" do
        developer_key = DeveloperKey.create!
        session["file_access_developer_key_id"] = developer_key.id
        expect(file_access_developer_key).to eql developer_key
      end

      it "returns nil if developer key in session not set" do
        expect(file_access_developer_key).to be_nil
      end
    end
  end

  describe "file_access_root_account" do
    context "not on the files domain" do
      before do
        @domain_root_account = Account.default
        @files_domain = false
      end

      it "returns @domain_root_account" do
        expect(file_access_root_account).to eql Account.default
      end
    end

    context "on the files domain" do
      before do
        @files_domain = true
      end

      it "returns root account from session" do
        session["file_access_root_account_id"] = Account.default.id
        expect(file_access_root_account).to eql Account.default
      end

      it "returns nil if root account in session not set" do
        expect(file_access_root_account).to be_nil
      end
    end
  end

  describe "file_access_oauth_host" do
    let(:host) { "test.host" }

    context "not on the files domain" do
      let(:request) { double("request", host_with_port: host) }
      let(:logged_in_user) { user_model }

      before do
        @files_domain = false
      end

      it "returns the request's host" do
        expect(file_access_oauth_host).to eql host
      end
    end

    context "on the files domain" do
      let(:logged_in_user) { user_model }

      before do
        @files_domain = true
      end

      it "returns the host from the session" do
        session["file_access_oauth_host"] = host
        expect(file_access_oauth_host).to eql host
      end

      it "returns nil if no host in the session" do
        expect(file_access_oauth_host).to be_nil
      end
    end
  end

  describe "file_authenticator" do
    before do
      @domain_root_account = Account.default
    end

    context "not on the files domain, logged in" do
      before do
        @files_domain = false
        @current_user = user_model
      end

      let(:logged_in_user) { user_model }
      let(:current_host) { "non-files-domain" }
      let(:request) { double("request", host_with_port: current_host) }

      it "creates an authenticator for the logged in user" do
        expect(file_authenticator.user).to eql logged_in_user
      end

      it "creates an authenticator with the acting user" do
        expect(file_authenticator.acting_as).to eql @current_user
      end

      it "creates an authenticator for the current host" do
        expect(file_authenticator.oauth_host).to eql current_host
      end

      it "creates an authenticator aware of the access token if present" do
        @access_token = logged_in_user.access_tokens.create!
        expect(file_authenticator.access_token).to eql @access_token
      end

      it "creates an authenticator aware of the root account" do
        expect(file_authenticator.root_account).to eql @domain_root_account
      end
    end

    context "not on the files domain, not logged in" do
      before do
        @files_domain = false
        @current_user = nil
      end

      let(:logged_in_user) { nil }
      let(:current_host) { "non-files-domain" }
      let(:request) { double("request", host_with_port: current_host) }

      it "creates a public authenticator" do
        expect(file_authenticator.user).to be_nil
        expect(file_authenticator.acting_as).to be_nil
        expect(file_authenticator.oauth_host).to be_nil
      end
    end

    context "on the files domain with access user" do
      let(:access_user) { user_model }
      let(:real_access_user) { user_model }
      let(:developer_key) { DeveloperKey.create! }
      let(:original_host) { "non-files-domain" }

      before do
        @files_domain = true
        session["file_access_user_id"] = access_user.id
        session["file_access_real_user_id"] = real_access_user.id
        session["file_access_root_account_id"] = Account.default.id
        session["file_access_developer_key_id"] = developer_key.id
        session["file_access_oauth_host"] = original_host
      end

      let(:logged_in_user) { nil }
      let(:current_host) { "files-domain" }
      let(:request) { double("request", host_with_port: current_host) }

      it "creates an authenticator for the real access user" do
        expect(file_authenticator.user).to eql real_access_user
      end

      it "creates an authenticator with the acting access user" do
        expect(file_authenticator.acting_as).to eql access_user
      end

      it "creates an authenticator with a fake access token for the developer key from the session" do
        expect(file_authenticator.access_token).not_to eql nil
        expect(file_authenticator.access_token.global_developer_key_id).to eql developer_key.global_id
      end

      it "creates an authenticator with the root account from the session" do
        expect(file_authenticator.root_account).to eql Account.default
      end

      it "creates an authenticator with the original host from the session" do
        expect(file_authenticator.oauth_host).to be original_host
      end
    end

    context "on the files domain without access user" do
      before do
        @files_domain = true
        session["file_access_user_id"] = nil
        session["file_access_real_user_id"] = nil
      end

      let(:logged_in_user) { nil }
      let(:current_host) { "files-domain" }
      let(:request) { double("request", host_with_port: current_host) }

      it "creates a public authenticator" do
        authenticator = file_authenticator
        expect(authenticator.user).to be_nil
        expect(authenticator.acting_as).to be_nil
        expect(authenticator.oauth_host).to be_nil
      end
    end
  end

  describe "#prefetch_xhr" do
    it "inserts a script tag that will have a `fetch` call with the right id, url, and options" do
      expect(prefetch_xhr("some_url", id: "some_id", options: { headers: { "x-some-header": "some-value" } })).to eq(
        "<script>
//<![CDATA[
(window.prefetched_xhrs = (window.prefetched_xhrs || {}))[\"some_id\"] = fetch(\"some_url\", {\"credentials\":\"same-origin\",\"headers\":{\"Accept\":\"application/json+canvas-string-ids, application/json\",\"X-Requested-With\":\"XMLHttpRequest\",\"x-some-header\":\"some-value\"}})
//]]>
</script>"
      )
    end
  end

  describe "#alt_text_for_login_logo" do
    before do
      @domain_root_account = Account.default
    end

    it "returns the default value when there is no custom login logo" do
      allow(helper).to receive(:k12?).and_return(false)
      expect(helper.send(:alt_text_for_login_logo)).to eql "Canvas by Instructure"
    end

    it "returns the account short name when the logo is custom" do
      Account.default.create_brand_config!(variables: { "ic-brand-Login-logo" => "test.jpg" })
      expect(alt_text_for_login_logo).to eql "Default Account"
    end
  end

  context "content security policy enabled" do
    let(:account) { Account.create!(name: "csp_account") }
    let(:sub_account) { account.sub_accounts.create! }
    let(:sub_2_account) { sub_account.sub_accounts.create! }
    let(:headers) { {} }
    let(:js_env) { {} }

    before do
      account.enable_feature!(:javascript_csp)

      account.add_domain!("root_account.test")
      account.add_domain!("root_account2.test")
      sub_account.add_domain!("sub_account.test")
      sub_2_account.add_domain!("sub_2_account.test")

      allow(helper).to receive(:headers).and_return(headers)
      allow(helper).to receive(:js_env) { |env| js_env.merge!(env) }
      response.content_type = "text/html"
    end

    context "on root account" do
      before do
        allow(helper).to receive(:csp_context).and_return(account)
      end

      it "doesn't set the CSP report only header if not configured" do
        helper.add_csp_for_root
        helper.include_custom_meta_tags
        expect(headers).to_not have_key("Content-Security-Policy-Report-Only")
        expect(headers).to_not have_key("Content-Security-Policy")
        expect(js_env).not_to have_key(:csp)
      end

      it "doesn't set the CSP header for non-html requests" do
        response.content_type = "application/json"
        account.enable_csp!
        helper.add_csp_for_root
        expect(headers).to_not have_key("Content-Security-Policy-Report-Only")
        expect(headers).to_not have_key("Content-Security-Policy")
      end

      it "sets the CSP full header when active" do
        account.enable_csp!

        helper.add_csp_for_root
        helper.include_custom_meta_tags
        expect(headers["Content-Security-Policy"]).to eq "frame-src 'self' blob: localhost root_account.test root_account2.test; "
        expect(headers).to_not have_key("Content-Security-Policy-Report-Only")
        expect(js_env[:csp]).to eq "frame-src 'self' localhost root_account.test root_account2.test blob:; script-src 'self' 'unsafe-eval' 'unsafe-inline' localhost root_account.test root_account2.test; object-src 'self' localhost root_account.test root_account2.test; "
      end

      it "includes the report URI" do
        allow(helper).to receive(:csp_report_uri).and_return("; report-uri https://somewhere/")
        helper.add_csp_for_root
        helper.include_custom_meta_tags
        expect(headers["Content-Security-Policy-Report-Only"]).to eq "frame-src 'self' blob: localhost root_account.test root_account2.test; report-uri https://somewhere/; "
      end

      it "includes the report URI when active" do
        allow(helper).to receive(:csp_report_uri).and_return("; report-uri https://somewhere/")
        account.enable_csp!
        helper.add_csp_for_root
        helper.include_custom_meta_tags
        expect(headers["Content-Security-Policy"]).to eq "frame-src 'self' blob: localhost root_account.test root_account2.test; report-uri https://somewhere/; "
      end

      it "includes canvadocs domain if enabled" do
        account.enable_csp!

        allow(Canvadocs).to receive_messages(
          enabled?: true,
          config: { "base_url" => "https://canvadocs.instructure.com/1" }
        )
        helper.add_csp_for_root
        expect(headers["Content-Security-Policy"]).to eq "frame-src 'self' blob: canvadocs.instructure.com localhost root_account.test root_account2.test; "
      end

      it "includes inst_fs domain if enabled" do
        account.enable_csp!

        allow(InstFS).to receive_messages(
          enabled?: true,
          app_host: "https://inst_fs.instructure.com"
        )
        helper.add_csp_for_root
        expect(headers["Content-Security-Policy"]).to eq "frame-src 'self' blob: inst_fs.instructure.com localhost root_account.test root_account2.test; "
      end
    end
  end

  describe "mastery_scales_js_env" do
    before(:once) do
      course_model
      @context = @course
      @domain_root_account = @course.root_account
      @proficiency = outcome_proficiency_model(@course.root_account)
      @calculation_method = outcome_calculation_method_model(@course.root_account)
    end

    let(:js_env) { {} }

    before do
      allow(helper).to receive(:js_env) { |env| js_env.merge!(env) }
    end

    it "does not include mastery scales FF when account_level_mastery_scales disabled" do
      helper.mastery_scales_js_env
      expect(js_env).not_to have_key :ACCOUNT_LEVEL_MASTERY_SCALES
    end

    it "does not include improved outcomes management FF when account_level_mastery_scales disabled" do
      helper.mastery_scales_js_env
      expect(js_env).not_to have_key :IMPROVED_OUTCOMES_MANAGEMENT
    end

    context "when account_level_mastery_scales enabled" do
      before(:once) do
        @course.root_account.enable_feature! :account_level_mastery_scales
      end

      it "includes mastery scales FF" do
        helper.mastery_scales_js_env
        expect(js_env).to have_key :ACCOUNT_LEVEL_MASTERY_SCALES
      end

      it "includes appropriate mastery scale data" do
        helper.mastery_scales_js_env
        mastery_scale = js_env[:MASTERY_SCALE]
        expect(mastery_scale[:outcome_proficiency]).to eq @proficiency.as_json
        expect(mastery_scale[:outcome_calculation_method]).to eq @calculation_method.as_json
      end
    end
  end

  describe "show_cc_prefs?" do
    before :once do
      student_in_course(active_all: true)
      @pseudonym = @user.pseudonyms.create!(unique_id: "blah", account: Account.default)
    end

    before do
      @current_user = @user
      @current_pseudonym = @pseudonym
      @domain_root_account = Account.default
    end

    context "with no k5 enrollments" do
      before do
        allow(helper).to receive(:k5_user?).and_return(false)
      end

      it "returns true if they haven't logged in and haven't visited notification settings" do
        expect(helper).to be_show_cc_prefs
      end

      it "returns false if they have logged in more than 10 times" do
        @pseudonym.login_count = 11
        @pseudonym.save!
        expect(helper).not_to be_show_cc_prefs
      end

      it "returns false if they have already visited notification settings" do
        @user.used_feature "cc_prefs"
        expect(helper).not_to be_show_cc_prefs
      end

      it "returns false if the user is a fake student" do
        @user.preferences[:fake_student] = true
        @user.save!
        enrollment = @user.enrollments.first
        enrollment.type = "StudentViewEnrollment"
        enrollment.save!
        expect(helper).not_to be_show_cc_prefs
      end

      it "returns false if @current_user is nil" do
        @current_user = nil
        expect(helper).not_to be_show_cc_prefs
      end

      it "returns false if @current_pseudonym is nil" do
        @current_pseudonym = nil
        expect(helper).not_to be_show_cc_prefs
      end
    end

    context "with k5 enrollments" do
      before do
        allow(helper).to receive(:k5_user?).and_return(true)
      end

      it "returns false for k5 students even if they haven't logged in" do
        expect(helper).not_to be_show_cc_prefs
      end

      it "still returns false for k5 students if they have logged in" do
        @pseudonym.login_count = 11
        @pseudonym.save!
        expect(helper).not_to be_show_cc_prefs
      end

      it "returns true for k5 teachers" do
        @course.enroll_teacher(@user, enrollment_state: "active")
        expect(helper).to be_show_cc_prefs
      end

      it "returns false for k5 teachers if they've already visited notification preferences" do
        @course.enroll_teacher(@user, enrollment_state: "active")
        @user.used_feature "cc_prefs"
        expect(helper).not_to be_show_cc_prefs
      end

      it "returns true for k5 admins" do
        AccountUser.create!(user: @user, account: Account.default)
        expect(helper).to be_show_cc_prefs
      end
    end
  end

  describe "improved_outcomes_management_js_env" do
    before(:once) do
      course_model
      @context = @course
      @domain_root_account = @course.root_account
    end

    let(:js_env) { {} }

    before do
      allow(helper).to receive(:js_env) { |env| js_env.merge!(env) }
    end

    context "when improved_outcomes_management FF is enabled" do
      it "sets improved_outcomes_management key in js_env to true" do
        @course.root_account.enable_feature! :improved_outcomes_management
        helper.improved_outcomes_management_js_env
        expect(js_env).to have_key :IMPROVED_OUTCOMES_MANAGEMENT
        expect(js_env[:IMPROVED_OUTCOMES_MANAGEMENT]).to be(true)
      end
    end

    context "when improved_outcomes_management FF is disabled" do
      it "sets improved_outcomes_management key in js_env to false" do
        @course.root_account.disable_feature! :improved_outcomes_management
        helper.improved_outcomes_management_js_env
        expect(js_env).to have_key :IMPROVED_OUTCOMES_MANAGEMENT
        expect(js_env[:IMPROVED_OUTCOMES_MANAGEMENT]).to be(false)
      end
    end
  end

  describe "context_user_name" do
    before :once do
      user_factory(short_name: "User Name")
    end

    it "accepts a user" do
      expect(context_user_name(Account.default, @user)).to eq "User Name"
    end

    it "accepts a user_id" do
      expect(context_user_name(Account.default, @user.id)).to eq "User Name"
    end

    it "returns nil if supplied the id of a nonexistent user" do
      expect(context_user_name(Account.default, 0)).to be_nil
    end
  end
end
