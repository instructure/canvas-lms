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

require_relative "../views_helper"

describe "courses/settings" do
  before :once do
    @subaccount = account_model(parent_account: Account.default, name: "subaccount")
    @other_subaccount = account_model(parent_account: Account.default)
    @sub_subaccount1 = account_model(parent_account: @subaccount)
    @sub_subaccount2 = account_model(parent_account: @subaccount)

    course_with_teacher(active_all: true, account: @subaccount)
    @course.sis_source_id = "so_special_sis_id"
    @course.workflow_state = "claimed"
    @course.save!
    assign(:context, @course)
    assign(:user_counts, {})
    assign(:all_roles, Role.custom_roles_and_counts_for_course(@course, @user))
    assign(:course_settings_sub_navigation_tools, [])
  end

  describe "Hide sections on course users page checkbox" do
    it "does not display checkbox for teacher when there is one section" do
      view_context(@course, @user)
      assign(:current_user, @user)
      render
      expect(response).to_not have_tag("input#course_hide_sections_on_course_users_page")
    end

    it "displays checkbox for teacher when there is more than one section" do
      @course.course_sections.create!
      view_context(@course, @user)
      assign(:current_user, @user)
      render
      expect(response).to have_tag("input#course_hide_sections_on_course_users_page")
    end
  end

  describe "sis_source_id edit box" do
    it "does not show to teacher" do
      view_context(@course, @user)
      assign(:current_user, @user)
      render
      expect(response).to have_tag("span#course_sis_source_id", @course.sis_source_id)
      expect(response).not_to have_tag("input#course_sis_source_id")
    end

    it "shows to sis admin" do
      admin = account_admin_user(account: @course.root_account)
      view_context(@course, admin)
      assign(:current_user, admin)
      render
      expect(response).to have_tag("input#course_sis_source_id")
    end

    it "does not show to non-sis admin" do
      role = custom_account_role("NoSissy", account: @course.root_account)
      admin = account_admin_user_with_role_changes(account: @course.root_account, role_changes: { "manage_sis" => false }, role:)
      view_context(@course, admin)
      assign(:current_user, admin)
      render
      expect(response).not_to have_tag("input#course_sis_source_id")
    end

    it "does not show to subaccount admin" do
      role = custom_account_role("CustomAdmin", account: @course.root_account)
      admin = account_admin_user_with_role_changes(account: @subaccount, role_changes: { "manage_sis" => true, "manage_courses" => true }, role:)
      view_context(@course, admin)
      assign(:current_user, admin)
      render
      expect(response).not_to have_tag("input#course_sis_source_id")
    end

    it "shows grade export when enabled" do
      admin = account_admin_user(account: @course.root_account)
      view_context(@course, admin)
      assign(:current_user, admin)
      assign(:publishing_enabled, true)
      render
      expect(response.body).to match(/<a href="#tab-grade-publishing" id="tab-grade-publishing-link">/)
      expect(response.body).to match(/<div id="tab-grade-publishing">/)
    end

    it "does not show grade export when disabled" do
      admin = account_admin_user(account: @course.root_account)
      view_context(@course, admin)
      assign(:current_user, admin)
      assign(:publishing_enabled, false)
      render
      expect(response.body).not_to match(/<a href="#tab-grade-publishing" id="tab-grade-publishing-link">/)
      expect(response.body).not_to match(/<div id="tab-grade-publishing">/)
    end
  end

  describe "quota box" do
    context "as account admin" do
      before do
        admin = account_admin_user
        view_context(@course, admin)
        assign(:current_user, admin)
      end

      it "shows quota input box" do
        render
        expect(response).to have_tag "input#course_storage_quota_mb"
      end
    end

    context "as teacher" do
      before do
        view_context(@course, @teacher)
        assign(:current_user, @teacher)
        @user = @teacher
      end

      it "does not show quota input box" do
        render
        expect(response).not_to have_tag "input#course_storage_quota_mb"
      end
    end
  end

  describe "Large Course settings" do
    before :once do
      @course.root_account.enable_feature!(:filter_speed_grader_by_student_group)
    end

    before do
      @course.root_account.reload
      view_context(@course, @teacher)
    end

    it "does not render when the 'Filter SpeedGrader by Student Group' feature flag is not enabled" do
      @course.root_account.disable_feature!(:filter_speed_grader_by_student_group)
      render
      expect(response).not_to have_tag "input#course_filter_speed_grader_by_student_group"
    end

    it "has a Large Course label" do
      render
      expect(response).to have_tag("label[for=course_large_course]")
    end

    describe "filter SpeedGrader by student group" do
      it "has a checkbox" do
        render
        expect(response).to have_tag "input#course_filter_speed_grader_by_student_group[type=checkbox]"
      end

      it "has a label describing it" do
        render
        expect(response).to have_tag("label[for=course_filter_speed_grader_by_student_group]")
      end

      it "checkbox is checked when filter_speed_grader_by_student_group is true" do
        @course.update!(filter_speed_grader_by_student_group: true)
        render
        expect(response).to have_tag "input#course_filter_speed_grader_by_student_group[type=checkbox][checked=checked]"
      end

      it "checkbox is not checked when filter_speed_grader_by_student_group is false" do
        render
        expect(response).not_to have_tag "input#course_filter_speed_grader_by_student_group[type=checkbox][checked=checked]"
      end
    end
  end

  context "account_id selection" do
    it "lets sub-account admins see other accounts within their sub-account as options" do
      Account.default.disable_feature!(:granular_permissions_manage_courses)
      @user = account_admin_user(account: @subaccount, active_user: true)
      expect(Account.default.grants_right?(@user, :manage_courses)).to be_falsey
      view_context(@course, @user)

      render
      doc = Nokogiri::HTML5(response.body)
      select = doc.at_css("select#course_account_id")
      expect(select).not_to be_nil
      # select.children.count.should == 3

      option_ids = select.search("option").map { |c| c.attributes["value"].value.to_i rescue c.to_s }
      expect(option_ids.sort).to eq [@subaccount.id, @sub_subaccount1.id, @sub_subaccount2.id].sort
    end

    it "lets sub-account admins see other accounts within their sub-account as options (granular permissions)" do
      Account.default.enable_feature!(:granular_permissions_manage_courses)
      @user = account_admin_user(account: @subaccount, active_user: true)
      expect(Account.default.grants_right?(@user, :manage_courses_admin)).to be_falsey
      view_context(@course, @user)

      render
      doc = Nokogiri.HTML5(response.body)
      select = doc.at_css("select#course_account_id")
      expect(select).not_to be_nil

      option_ids =
        select
        .search("option")
        .map do |c|
          c.attributes["value"].value.to_i
        rescue
          c.to_s
        end
      expect(option_ids.sort).to eq [@subaccount.id, @sub_subaccount1.id, @sub_subaccount2.id].sort
    end

    it "lets site admins see all accounts within their root account as options" do
      @user = site_admin_user
      view_context(@course, @user)

      render
      doc = Nokogiri::HTML5(response.body)
      select = doc.at_css("select#course_account_id")
      expect(select).not_to be_nil
      all_accounts = [Account.default] + Account.default.all_accounts

      option_ids = select.search("option").map { |c| c.attributes["value"].value.to_i }
      expect(option_ids.sort).to eq all_accounts.map(&:id).sort
    end
  end

  context "course template checkbox" do
    it "is not visible if the feature isn't enabled" do
      render
      doc = Nokogiri::HTML5(response.body)
      expect(doc.at_css("div#course_template_details")).to be_nil
    end

    context "with the feature enabled" do
      before { @course.root_account.enable_feature!(:course_templates) }

      it "is visible" do
        render
        doc = Nokogiri::HTML5(response.body)
        expect(doc.at_css("div#course_template_details")).not_to be_nil
      end

      it "is editable if you have permission" do
        @user = site_admin_user
        view_context(@course, @user)
        # have to remove the teacher
        @course.enrollments.each(&:destroy)

        render
        doc = Nokogiri::HTML5(response.body)
        placeholder_div = doc.at_css("div#course_template_details")
        expect(placeholder_div["data-is-editable"]).to eq "true"
      end

      it "is not editable even if you have permission, but it's not possible" do
        @user = site_admin_user
        view_context(@course, @user)

        render
        doc = Nokogiri::HTML5(response.body)
        placeholder_div = doc.at_css("div#course_template_details")
        expect(placeholder_div["data-is-editable"]).to eq "false"
      end
    end
  end

  describe "visibility settings" do
    it "calls Course::CUSTOMIZABLE_PERMISSIONS's get_setting_name to get translated setting name" do
      expect(Course::CUSTOMIZABLE_PERMISSIONS["syllabus"][:get_setting_name]).to receive(:call).once.and_call_original
      expect(Course::CUSTOMIZABLE_PERMISSIONS["files"][:get_setting_name]).to receive(:call).once.and_call_original
      view_context(@course, @user)
      render
    end
  end
end
