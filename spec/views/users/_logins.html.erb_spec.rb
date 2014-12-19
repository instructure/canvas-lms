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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "users/_logins.html.erb" do
  describe "sis_source_id edit box" do
    before do
      user_with_pseudonym
      @account = Account.default
      @student = @user
      @pseudo = @user.pseudonyms.first
      @pseudo.sis_user_id = "why_is_this_one_user_id_lame"
      @pseudo.save
      @pseudo2 = @user.pseudonyms.create!(:unique_id => 'someone@somewhere.com') { |p| p.sis_user_id = 'more' }
      assigns[:context] = @account
      assigns[:context_account] = @account
      assigns[:account] = @account
      assigns[:root_account] = @account
      assigns[:user] = @student
      assigns[:current_enrollments] = []
      assigns[:completed_enrollments] = []
      assigns[:student_enrollments] = []
      assigns[:pending_enrollments] = []
      assigns[:enrollments] = []
      assigns[:courses] = []
      assigns[:page_views] = []
      assigns[:group_memberships] = []
      assigns[:context_groups] = []
      assigns[:contexts] = []
    end

    it "should show to sis admin" do
      admin = account_admin_user
      view_context(@account, admin)
      assigns[:current_user] = admin
      render
      expect(response).to have_tag("span#sis_user_id_#{@pseudo.id}", @pseudo.sis_user_id)
      expect(response).to have_tag("div.can_edit_sis_user_id", 'true')
      page = Nokogiri('<document>' + response.body + '</document>')
      expect(page.css(".login .delete_pseudonym_link").first['style']).to eq ''
    end

    it "should not show to non-sis admin" do
      admin = account_admin_user_with_role_changes(:role_changes => {'manage_sis' => false}, :account => @account)
      view_context(@account, admin)
      assigns[:current_user] = admin
      render
      expect(response).to have_tag("span#sis_user_id_#{@pseudo.id}", @pseudo.sis_user_id)
      expect(response).to have_tag("div.can_edit_sis_user_id", 'false')
      page = Nokogiri('<document>' + response.body + '</document>')
      expect(page.css(".login .delete_pseudonym_link").first['style']).to eq 'display: none;'
    end
  end

  describe "add_pseudonym_link" do
    let(:account) { Account.default }
    let(:sally) { account_admin_user(account: account) }
    let(:bob) { student_in_course(account: account).user }

    it "should display when user has permission to create pseudonym" do
      assigns[:domain_root_account] = account
      assigns[:current_user] = sally
      assigns[:user] = bob
      render
      expect(response).to have_tag("a.add_pseudonym_link")
    end

    it "should not display when user lacks permission to create pseudonym" do
      assigns[:domain_root_account] = account
      assigns[:current_user] = bob
      assigns[:user] = sally
      render
      expect(response).not_to have_tag("a.add_pseudonym_link")
    end
  end

  describe "reset_mfa_link" do
    let(:account) { Account.default }
    let(:sally) { account_admin_user(account: account) }
    let(:bob) { student_in_course(account: account).user }

    it "should display when user has permission to reset MFA" do
      pseudonym(bob, account: account)
      bob.otp_secret_key = 'secret'

      assigns[:domain_root_account] = account
      assigns[:current_user] = sally
      assigns[:user] = bob
      render
      expect(response).to have_tag("a.reset_mfa_link")
    end

    it "should not display when user lacks permission to reset MFA" do
      pseudonym(sally, account: account)
      sally.otp_secret_key = 'secret'

      assigns[:domain_root_account] = account
      assigns[:current_user] = bob
      assigns[:user] = sally
      render
      expect(response).not_to have_tag("a.reset_mfa_link")
    end
  end

  describe "add_holder" do
    let(:account) { Account.default }
    let(:sally) { account_admin_user(account: account) }
    let(:bob) { student_in_course(account: account).user }

    it "should display when user can only reset MFA" do
      pseudonym(bob, account: account)
      bob.otp_secret_key = 'secret'

      assigns[:domain_root_account] = account
      assigns[:current_user] = bob
      assigns[:user] = bob
      render
      expect(response).to have_tag(".add_holder")
    end

    it "should display when user can only add pseudonym" do
      pseudonym(sally, account: account)
      sally.otp_secret_key = 'secret'
      account.settings[:mfa_settings] = :required
      account.save!

      assigns[:domain_root_account] = account
      assigns[:current_user] = sally
      assigns[:user] = sally
      render
      expect(response).to have_tag(".add_holder")
    end

    it "should not display when user lacks permission to do either" do
      pseudonym(bob, account: account)
      bob.otp_secret_key = 'secret'
      account.settings[:mfa_settings] = :required
      account.save!

      assigns[:domain_root_account] = Account.default
      assigns[:current_user] = bob
      assigns[:user] = bob
      render
      expect(response).not_to have_tag(".add_holder")
    end
  end
end
