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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "/users/name" do
  it "should allow deletes for unmanagaged pseudonyms with correct privileges" do
    account_admin_user :account => Account.default
    course_with_student :account => Account.default
    view_context(Account.default, @admin)
    assign(:user, @student)
    assign(:enrollments, [])
    render :partial => "users/name"
    expect(response.body).to match /Delete from #{Account.default.name}/
  end

  it "should allow deletes for managaged pseudonyms with correct privileges" do
    account_admin_user :account => Account.default
    course_with_student :account => Account.default
    managed_pseudonym(@student, :account => account_model)
    view_context(Account.default, @admin)
    assign(:user, @student)
    assign(:enrollments, [])
    render :partial => "users/name"
    expect(response.body).to match /Delete from #{Account.default.name}/
  end

  it "should not allow deletes for managed pseudonyms without correct privileges" do
    @admin = user_factory :account => Account.default
    course_with_student :account => Account.default
    managed_pseudonym(@student, :account => account_model)
    view_context(Account.default, @admin)
    assign(:user, @student)
    assign(:enrollments, [])
    render :partial => "users/name"
    expect(response.body).not_to match /Delete from #{Account.default.name}/
  end

  it "should not allow deletes for unmanaged pseudonyms without correct privileges" do
    @admin = user_factory :account => Account.default
    course_with_student :account => Account.default
    view_context(Account.default, @admin)
    assign(:user, @student)
    assign(:enrollments, [])
    render :partial => "users/name"
    expect(response.body).not_to match /Delete from #{Account.default.name}/
  end

  describe "default email address" do
    before :once do
      course_with_teacher :active_all => true
      student_in_course :active_all => true
      @student.communication_channels.create!(:path_type => 'email', :path => 'secret@example.com').confirm!
    end

    it "includes email address for teachers by default" do
      view_context(@course, @teacher)
      assign(:user, @student)
      assign(:enrollments, [])
      render :partial => "users/name"
      expect(response.body).to include 'secret@example.com'
    end

    it "does not include it if the permission is denied" do
      RoleOverride.create!(:context => Account.default, :permission => 'read_email_addresses',
                     :role => Role.get_built_in_role('TeacherEnrollment'), :enabled => false)
      view_context(@course, @teacher)
      assign(:user, @student)
      assign(:enrollments, [])
      render :partial => "users/name"
      expect(response.body).not_to include 'secret@example.com'
    end
  end

  describe "merge_user_link" do
    let(:account) { Account.default }
    let(:sally) { account_admin_user(account: account) }
    let(:bob) { teacher_in_course(account: account, active_enrollment: true).user }

    it "should display when acting user has permission to merge shown user" do
      pseudonym(bob, account: account)

      assign(:domain_root_account, account)
      assign(:context, account)
      assign(:current_user, sally)
      assign(:user, bob)
      assign(:enrollments, [])
      render partial: "users/name"
      expect(response).to have_tag("a.merge_user_link")
    end

    it "should not display when acting user lacks permission to merge shown user" do
      pseudonym(sally, account: account)

      assign(:domain_root_account, account)
      assign(:context, account)
      assign(:current_user, bob)
      assign(:user, sally)
      assign(:enrollments, [])
      render partial: "users/name"
      expect(response).not_to have_tag("a.merge_user_link")
    end

    it "should not display when non-admin looking at self" do
      # has permission to merge on self, but wouldn't be able to select any
      # merge targets
      pseudonym(bob, account: account)

      assign(:domain_root_account, account)
      assign(:context, @course)
      assign(:current_user, bob)
      assign(:user, bob)
      assign(:enrollments, [])
      render partial: "users/name"
      expect(response).to have_tag("a.edit_user_link")
      expect(response).not_to have_tag("a.merge_user_link")
    end
  end
end
