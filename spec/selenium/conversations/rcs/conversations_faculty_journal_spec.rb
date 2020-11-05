# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../helpers/conversations_common')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/assignment_overrides')

describe "conversations new" do
  include_context "in-process server selenium tests"
  include AssignmentOverridesSeleniumHelper
  include ConversationsCommon

  let(:account) { Account.default }
  let(:account_settings_url) { "/accounts/#{account.id}/settings" }
  let(:user_notes_url) { "/courses/#{@course.id}/user_notes"}
  let(:student_user_notes_url) {"/users/#{@s1.id}/user_notes"}

  before do
    conversation_setup
    @s1 = user_factory(name: "first student")
    @s2 = user_factory(name: "second student")
    @s3 = user_factory(name: 'third student')
    [@s1, @s2, @s3].each { |s| @course.enroll_student(s).update_attribute(:workflow_state, 'active') }
    cat = @course.group_categories.create(:name => "the groups")
    @group = cat.groups.create(:name => "the group", :context => @course)
    @group.users = [@s1, @s2]
  end

  context "Course with Faculty Journal not enabled" do
    before(:each) do
      site_admin_logged_in
      stub_rcs_config
    end

    it "should allow a site admin to enable faculty journal", priority: "2", test_id: 75005 do
      get account_settings_url
      f('#account_enable_user_notes').click
      f('.Button.Button--primary[type="submit"]').click
      wait_for_ajaximations
      expect(is_checked('#account_enable_user_notes')).to be_truthy
    end
  end

  context "Course with Faculty Journal enabled" do
    before(:each) do
      site_admin_logged_in
      @course.account.update_attribute(:enable_user_notes, true)
    end

    it "should clear the subject and body when cancel is clicked", priority: "1", test_id: 458518
  end
end
