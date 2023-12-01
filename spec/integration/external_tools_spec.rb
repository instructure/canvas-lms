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

describe "External Tools" do
  describe "Assignments" do
    before do
      allow(BasicLTI::Sourcedid).to receive(:encryption_secret) { "encryption-secret-5T14NjaTbcYjc4" }
      allow(BasicLTI::Sourcedid).to receive(:signing_secret) { "signing-secret-vp04BNqApwdwUYPUI" }
      course_factory(active_all: true)
      assignment_model(course: @course, submission_types: "external_tool", points_possible: 25)
      @tool = @course.context_external_tools.create!(shared_secret: "test_secret", consumer_key: "test_key", name: "my grade passback test tool", domain: "example.com")
      @tag = @assignment.build_external_tool_tag(url: "http://example.com/one")
      @tag.content_type = "ContextExternalTool"
      @tag.save!
    end

    it "generates valid LTI parameters" do
      student_in_course(course: @course, active_all: true)
      user_session(@user)
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      expect(response).to be_successful
      doc = Nokogiri::HTML5(response.body)
      form = doc.at_css(".tool_content_wrapper > form")

      expect(form.at_css("input#launch_presentation_locale")["value"]).to eq "en"
      expect(form.at_css("input#oauth_callback")["value"]).to eq "about:blank"
      expect(form.at_css("input#oauth_signature_method")["value"]).to eq "HMAC-SHA1"
      expect(form.at_css("input#launch_presentation_return_url")["value"]).to eq "http://www.example.com/courses/#{@course.id}/external_content/success/external_tool_redirect"
      expect(form.at_css("input#lti_message_type")["value"]).to eq "basic-lti-launch-request"
      expect(form.at_css("input#lti_version")["value"]).to eq "LTI-1p0"
      expect(form.at_css("input#oauth_version")["value"]).to eq "1.0"
      expect(form.at_css("input#roles")["value"]).to eq "Learner"
    end

    it "includes outcome service params when viewing as student" do
      allow_any_instance_of(Account).to receive(:feature_enabled?) { false }
      allow_any_instance_of(Account).to receive(:feature_enabled?).with(:encrypted_sourcedids).and_return(true)
      allow(CanvasSecurity).to receive(:create_encrypted_jwt) { "an.encrypted.jwt" }
      student_in_course(course: @course, active_all: true)
      user_session(@user)

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      expect(response).to be_successful
      doc = Nokogiri::HTML5(response.body)

      expect(doc.at_css(".tool_content_wrapper > form input#lis_result_sourcedid")["value"]).to eq BasicLTI::Sourcedid.new(@tool, @course, @assignment, @user).to_s
      expect(doc.at_css(".tool_content_wrapper > form input#lis_outcome_service_url")["value"]).to eq lti_grade_passback_api_url(@tool)
      expect(doc.at_css(".tool_content_wrapper > form input#ext_ims_lis_basic_outcome_url")["value"]).to eq blti_legacy_grade_passback_api_url(@tool)
    end

    it "does not include outcome service sourcedid when viewing as teacher" do
      @course.enroll_teacher(user_factory(active_all: true))
      user_session(@user)
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      expect(response).to be_successful
      doc = Nokogiri::HTML5(response.body)
      expect(doc.at_css(".tool_content_wrapper > form input#lis_result_sourcedid")).to be_nil
      expect(doc.at_css(".tool_content_wrapper > form input#lis_outcome_service_url")).not_to be_nil
    end

    it "includes time zone in LTI paramaters if included in custom fields" do
      @tool.custom_fields = {
        "custom_time_zone" => "$Person.address.timezone",
      }
      @tool.save!
      student_in_course(course: @course, active_all: true)
      user_session(@user)

      account = @course.root_account
      account.default_time_zone = "Alaska"
      account.save!

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      expect(response).to be_successful
      doc = Nokogiri::HTML5(response.body)
      expect(doc.at_css(".tool_content_wrapper > form input#custom_time_zone")["value"]).to eq "America/Juneau"

      @user.time_zone = "Hawaii"
      @user.save!

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      expect(response).to be_successful
      doc = Nokogiri::HTML5(response.body)
      expect(doc.at_css(".tool_content_wrapper > form input#custom_time_zone")["value"]).to eq "Pacific/Honolulu"
    end

    it "redirects if the tool can't be configured" do
      @tag.update_attribute(:url, "http://example.net")

      student_in_course(active_all: true)
      user_session(@user)
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      expect(response).to redirect_to(course_url(@course))
      expect(flash[:error]).to be_present
    end

    it "renders inline external tool links with a full return url" do
      student_in_course(active_all: true)
      user_session(@user)
      get "/courses/#{@course.id}/external_tools/retrieve?url=#{CGI.escape(@tag.url)}"
      expect(response).to be_successful
      doc = Nokogiri::HTML5(response.body)
      expect(doc.at_css(".tool_content_wrapper > form")).not_to be_nil
      expect(doc.at_css("input[name='launch_presentation_return_url']")["value"]).to match(/^http/)
    end

    it "renders user navigation tools with a full return url" do
      tool = @course.root_account.context_external_tools.build(shared_secret: "test_secret", consumer_key: "test_key", name: "my grade passback test tool", domain: "example.com", privacy_level: "public")
      tool.user_navigation = { url: "http://www.example.com", text: "Example URL" }
      tool.save!

      student_in_course(active_all: true)
      user_session(@user)
      get "/users/#{@user.id}/external_tools/#{tool.id}"
      expect(response).to be_successful
      doc = Nokogiri::HTML5(response.body)
      expect(doc.at_css(".tool_content_wrapper > form")).not_to be_nil
      expect(doc.at_css("input[name='launch_presentation_return_url']")["value"]).to match(/^http/)
    end
  end

  it "highlights the navigation tab when using an external tool" do
    course_with_teacher_logged_in(active_all: true)

    @tool = @course.context_external_tools.create!(shared_secret: "test_secret", consumer_key: "test_key", name: "my grade passback test tool", domain: "example.com")
    @tool.course_navigation = { url: "http://www.example.com", text: "Example URL" }
    @tool.save!

    get "/courses/#{@course.id}/external_tools/#{@tool.id}"
    expect(response).to be_successful
    doc = Nokogiri::HTML5(response.body)
    tab = doc.at_css("a.#{@tool.asset_string}")
    expect(tab).not_to be_nil
    expect(tab["class"].split).to include("active")
  end

  it "prevents access for unverified users if account requires it" do
    course_with_teacher_logged_in(active_all: true)

    @tool = @course.context_external_tools.create!(shared_secret: "test_secret", consumer_key: "test_key", name: "my grade passback test tool", domain: "example.com")
    @tool.course_navigation = { url: "http://www.example.com", text: "Example URL" }
    @tool.save!

    Account.default.tap do |a|
      a.settings[:require_confirmed_email] = true
      a.save!
    end
    get "/courses/#{@course.id}/external_tools/#{@tool.id}"
    expect(response).to be_redirect
    expect(response.location).to eq root_url
    expect(flash[:warning]).to include("Complete registration")
  end

  context "global navigation" do
    before :once do
      @admin_tool = Account.default.context_external_tools.new(name: "a", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @admin_tool.global_navigation = { visibility: "admins", url: "http://www.example.com", text: "Example URL" }
      @admin_tool.save!
      @member_tool = Account.default.context_external_tools.new(name: "b", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @member_tool.global_navigation = { url: "http://www.example.com", text: "Example URL 2" }
      @member_tool.save!
      @permissiony_tool = Account.default.context_external_tools.new(name: "b", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @permissiony_tool.global_navigation = { required_permissions: "manage_assignments_add,manage_calendar",
                                              url: "http://www.example.com",
                                              text: "Example URL 3" }
      @permissiony_tool.save!
    end

    it "shows the admin level global navigation menu items to teachers" do
      course_with_teacher_logged_in(account: @account, active_all: true)
      get "/courses"
      expect(response).to be_successful
      doc = Nokogiri::HTML5(response.body)

      menu_link1 = doc.at_css("##{@admin_tool.asset_string}_menu_item a")
      expect(menu_link1).not_to be_nil
      expect(menu_link1["href"]).to eq account_external_tool_path(Account.default, @admin_tool, launch_type: "global_navigation")
      expect(menu_link1.text).to match_ignoring_whitespace(@admin_tool.label_for(:global_navigation))

      menu_link2 = doc.at_css("##{@member_tool.asset_string}_menu_item a")
      expect(menu_link2).not_to be_nil
      expect(menu_link2["href"]).to eq account_external_tool_path(Account.default, @member_tool, launch_type: "global_navigation")
      expect(menu_link2.text).to match_ignoring_whitespace(@member_tool.label_for(:global_navigation))
    end

    it "only shows the member level global navigation menu items to students" do
      course_with_student_logged_in(account: @account, active_all: true)
      get "/courses"
      expect(response).to be_successful
      doc = Nokogiri::HTML5(response.body)

      menu_link1 = doc.at_css("##{@admin_tool.asset_string}_menu_item a")
      expect(menu_link1).to be_nil

      menu_link2 = doc.at_css("##{@member_tool.asset_string}_menu_item a")
      expect(menu_link2).not_to be_nil
      expect(menu_link2["href"]).to eq account_external_tool_path(Account.default, @member_tool, launch_type: "global_navigation")
      expect(menu_link2.text).to match_ignoring_whitespace(@member_tool.label_for(:global_navigation))
    end

    context "caching" do
      specs_require_cache(:redis_cache_store)

      let(:highlight_nav_css_class) { "ic-app-header__menu-list-item--active" }

      it "caches the template" do
        course_with_teacher_logged_in(account: @account, active_all: true)
        get "/courses" # populate the cache once
        # We can't cache the lookup for global navigation tools due to highlighting issues,
        # so we can't assert that we don't look things up, cause we have to.
        # We can assert that we don't look up extraneous information
        # again though.
        expect(ContextExternalTool).not_to receive(:label_for)
        get "/courses"
        doc = Nokogiri::HTML5(response.body)
        expect(doc.at_css("##{@admin_tool.asset_string}_menu_item a")).to be_present
      end

      it "clears the template cache when a tool is updated" do
        course_with_teacher_logged_in(account: @account, active_all: true)
        get "/courses" # populate the cache once

        Timecop.freeze(1.minute.from_now) do # just in case caching across second boundary
          @admin_tool.global_navigation = @admin_tool.global_navigation.merge(text: "new url woo")
          @admin_tool.save!
        end
        expect(ContextExternalTool).to receive(:filtered_global_navigation_tools).at_least(:once).and_call_original
        get "/courses"
        doc = Nokogiri::HTML5(response.body)
        link = doc.at_css("##{@admin_tool.asset_string}_menu_item a")
        expect(link).to be_present
        expect(link.text).to match_ignoring_whitespace("new url woo")
      end

      it "caches the template by old visibility status (admin/nonadmin)" do
        course_with_teacher_logged_in(account: @account, active_all: true)
        get "/courses"
        doc = Nokogiri::HTML5(response.body)
        expect(doc.at_css("##{@admin_tool.asset_string}_menu_item a")).to be_present

        course_with_student_logged_in(account: @account, active_all: true)
        get "/courses"
        doc = Nokogiri::HTML5(response.body)
        expect(doc.at_css("##{@admin_tool.asset_string}_menu_item a")).to_not be_present
      end

      it "caches the template over courses if permissions are same" do
        skip("Fails in RSpecQ") if ENV["RSPECQ_REDIS_URL"]
        course_with_teacher_logged_in(account: @account, active_all: true)
        get "/courses/#{@course.id}"
        doc = Nokogiri::HTML5(response.body)
        expect(doc.at_css("##{@permissiony_tool.asset_string}_menu_item a")).to be_present

        c2 = course_with_teacher(account: @account, active_all: true, user: @teacher).course
        # We can't cache the lookup for global navigation tools due to highlighting issues,
        # so we can't assert on that. We can asssert that we don't look up extraneous information
        # again though.
        expect(ContextExternalTool).not_to receive(:label_for)
        get "/courses/#{c2.id}" # viewing different course but permissions are the same - should remain cached
        doc = Nokogiri::HTML5(response.body)
        expect(doc.at_css("##{@permissiony_tool.asset_string}_menu_item a")).to be_present
      end

      it "does not cache the template across courses if permissions are different" do
        course_with_teacher_logged_in(account: @account, active_all: true)
        get "/courses/#{@course.id}"
        doc = Nokogiri::HTML5(response.body)
        expect(doc.at_css("##{@permissiony_tool.asset_string}_menu_item a")).to be_present

        # they're a student here - doesn't have the teacher permissions anymore
        c2 = course_with_student(account: @account, active_all: true, user: @teacher).course
        expect(ContextExternalTool).to receive(:filtered_global_navigation_tools).at_least(:once).and_call_original
        get "/courses/#{c2.id}" # viewing different course but permissions are the same - should remain cached
        doc = Nokogiri::HTML5(response.body)
        expect(doc.at_css("##{@permissiony_tool.asset_string}_menu_item a")).to_not be_present
      end

      it "does not cache the template if permission overrides change" do
        course_with_teacher_logged_in(account: @account, active_all: true)
        get "/courses/#{@course.id}"
        doc = Nokogiri::HTML5(response.body)
        expect(doc.at_css("##{@permissiony_tool.asset_string}_menu_item a")).to be_present

        Timecop.freeze(1.minute.from_now) do
          Account.default.role_overrides.create!(enabled: false, permission: "manage_calendar", role: teacher_role)
          @teacher.touch # clear permission cache
        end

        expect(ContextExternalTool).to receive(:filtered_global_navigation_tools).at_least(:once).and_call_original
        get "/courses/#{@course.id}" # viewing different course but permissions are the same - should remain cached
        doc = Nokogiri::HTML5(response.body)
        expect(doc.at_css("##{@permissiony_tool.asset_string}_menu_item a")).to_not be_present
      end

      it "doesn't highlight the tool if the tool is no longer the current page" do
        admin = account_admin_user(account: @account)
        user_session(admin)
        get "/accounts/#{Account.default.id}/external_tools/#{@admin_tool.id}?launch_type=global_navigation"
        doc = Nokogiri::HTML5(response.body)
        external_tool_link = doc.at_css("##{@admin_tool.asset_string}_menu_item")
        # Expect the tool to be highlighted
        expect(external_tool_link.attributes["class"].value).to include(highlight_nav_css_class)

        get "/accounts/#{Account.default.id}"
        doc = Nokogiri::HTML5(response.body)
        external_tool_link = doc.at_css("##{@admin_tool.asset_string}_menu_item")
        expect(external_tool_link.attributes["class"].value).not_to include(highlight_nav_css_class)

        account_nav = doc.at_css("#global_nav_accounts_link").parent
        expect(account_nav.attributes["class"].value).to include(highlight_nav_css_class)
      end

      it "doesn't rebuild the html unless it detects a global_nav root account tool change" do
        skip("Fails in RSpecQ") if ENV["RSPECQ_REDIS_URL"]
        course_with_teacher_logged_in(account: @account, active_all: true)
        get "/courses/#{@course.id}"
        doc = Nokogiri::HTML5(response.body)
        expect(doc.at_css("##{@admin_tool.asset_string}_menu_item a")).to be_present

        # trigger the global_nav cache register clearing in a callback
        Account.default.context_external_tools.new(name: "b",
                                                   domain: "google.com",
                                                   consumer_key: "12345",
                                                   shared_secret: "secret")
        new_secret_settings = @admin_tool.settings
        new_secret_settings[:global_navigation][:text] = "new text"
        # update the url secretly in the db but don't update the cache_key (updated_at)
        ContextExternalTool.where(id: @admin_tool).update_all(settings: new_secret_settings)

        get "/courses/#{@course.id}"
        doc = Nokogiri::HTML5(response.body)
        # should still have the old text cached (because we didn't detect a global nav tool change)
        expect(doc.at_css("##{@admin_tool.asset_string}_menu_item a").text).to_not include("new text")

        # now update it but it still shouldn't take effect because the callback hasn't hit
        ContextExternalTool.where(id: @admin_tool).update_all(updated_at: 1.minute.from_now)
        get "/courses/#{@course.id}"
        doc = Nokogiri::HTML5(response.body)
        expect(doc.at_css("##{@admin_tool.asset_string}_menu_item a").text).to_not include("new text")

        @admin_tool.save! # trigger the callback - now it should rebuild
        get "/courses/#{@course.id}"
        doc = Nokogiri::HTML5(response.body)
        expect(doc.at_css("##{@admin_tool.asset_string}_menu_item a").text).to include("new text")
      end
    end
  end
end
