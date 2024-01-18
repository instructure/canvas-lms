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

describe "users/_logins" do
  describe "sis_source_id edit box" do
    before do
      user_with_pseudonym
      @account = Account.default
      @student = @user
      @pseudo = @user.pseudonyms.first
      @pseudo.sis_user_id = "why_is_this_one_user_id_lame"
      @pseudo.integration_id = "and_this_one_even_lamer"
      @pseudo.save
      @pseudo2 = @user.pseudonyms.create!(unique_id: "someone@somewhere.com") { |p| p.sis_user_id = "more" }
      assign(:context, @account)
      assign(:context_account, @account)
      assign(:account, @account)
      assign(:root_account, @account)
      assign(:user, @student)
      assign(:current_enrollments, [])
      assign(:completed_enrollments, [])
      assign(:student_enrollments, [])
      assign(:pending_enrollments, [])
      assign(:enrollments, [])
      assign(:courses, [])
      assign(:page_views, [])
      assign(:group_memberships, [])
      assign(:context_groups, [])
      assign(:contexts, [])
    end

    it "shows to sis admin" do
      admin = account_admin_user
      view_context(@account, admin)
      assign(:current_user, admin)
      render
      expect(response).to have_tag("span#sis_user_id_#{@pseudo.id}", @pseudo.sis_user_id)
      expect(response).to have_tag("span#integration_id_#{@pseudo.id}", @pseudo.integration_id)
      expect(response).to have_tag("div.can_edit_sis_user_id", "true")
      page = Nokogiri("<document>" + response.body + "</document>")
      expect(page.css(".login .delete_pseudonym_link").first["style"]).to eq ""
    end

    it "does not show to non-sis admin" do
      admin = account_admin_user_with_role_changes(role_changes: { "manage_sis" => false }, account: @account)
      view_context(@account, admin)
      assign(:current_user, admin)
      render
      expect(response).to have_tag("span#sis_user_id_#{@pseudo.id}", @pseudo.sis_user_id)
      expect(response).to have_tag("span#integration_id_#{@pseudo.id}", @pseudo.integration_id)
      expect(response).to have_tag("div.can_edit_sis_user_id", "false")
      page = Nokogiri("<document>" + response.body + "</document>")
      expect(page.css(".login .delete_pseudonym_link").first["style"]).to eq "display: none;"
    end
  end

  describe "add_pseudonym_link" do
    let(:account) { Account.default }
    let(:sally) { account_admin_user(account:) }
    let(:bob) { student_in_course(account:).user }

    it "displays when user has permission to create pseudonym" do
      assign(:domain_root_account, account)
      assign(:current_user, sally)
      assign(:user, bob)
      render
      expect(response).to have_tag("a.add_pseudonym_link", with: { "data-can-manage-sis" => "true" })
    end

    it "does not display when user lacks permission to create pseudonym" do
      assign(:domain_root_account, account)
      assign(:current_user, bob)
      assign(:user, sally)
      render
      expect(response).not_to have_tag("a.add_pseudonym_link")
    end
  end

  describe "reset_mfa_link" do
    let(:account) { Account.default }
    let(:sally) { account_admin_user(account:) }
    let(:bob) { student_in_course(account:).user }

    it "displays when user has permission to reset MFA" do
      pseudonym(bob, account:)
      bob.otp_secret_key = "secret"

      assign(:domain_root_account, account)
      assign(:current_user, sally)
      assign(:user, bob)
      render
      expect(response).to have_tag("a.reset_mfa_link")
    end

    it "does not display when user lacks permission to reset MFA" do
      pseudonym(sally, account:)
      sally.otp_secret_key = "secret"

      assign(:domain_root_account, account)
      assign(:current_user, bob)
      assign(:user, sally)
      render
      expect(response).not_to have_tag("a.reset_mfa_link")
    end
  end

  describe "add_holder" do
    let(:account) { Account.default }
    let(:sally) { account_admin_user(account:) }
    let(:bob) { student_in_course(account:).user }

    it "displays when user can only reset MFA" do
      pseudonym(bob, account:)
      bob.otp_secret_key = "secret"

      assign(:domain_root_account, account)
      assign(:current_user, bob)
      assign(:user, bob)
      render
      expect(response).to have_tag(".add_holder")
    end

    it "displays when user can only add pseudonym" do
      pseudonym(sally, account:)
      sally.otp_secret_key = "secret"
      account.settings[:mfa_settings] = :required
      account.save!

      assign(:domain_root_account, account)
      assign(:current_user, sally)
      assign(:user, sally)
      render
      expect(response).to have_tag(".add_holder")
    end

    it "does not display when user lacks permission to do either" do
      pseudonym(bob, account:)
      bob.otp_secret_key = "secret"
      account.settings[:mfa_settings] = :required
      account.save!

      assign(:domain_root_account, Account.default)
      assign(:current_user, bob)
      assign(:user, bob)
      render
      expect(response).not_to have_tag(".add_holder")
    end
  end

  context "authentication providers" do
    it "doesn't show an icon for SAML" do
      account_with_saml
      user_with_pseudonym(active_all: 1)
      ap = @account.authentication_providers.first
      @pseudonym.authentication_provider = ap
      @pseudonym.save!

      assign(:domain_root_account, @account)
      assign(:current_user, @user)
      assign(:user, @user)
      render

      doc = Nokogiri::HTML5(response)
      expect(doc.at_css(".screenreader-only")).to be_nil
    end

    it "shows icon when authentication provider id is set to canvas" do
      @account = Account.default
      user_with_pseudonym(active_all: 1)
      ap = @account.authentication_providers.first
      @pseudonym.authentication_provider_id = ap
      @pseudonym.save!

      assign(:domain_root_account, @account)
      assign(:current_user, @user)
      assign(:user, @user)
      render

      doc = Nokogiri::HTML5(response)
      expect(doc.at_css(".screenreader-only")).not_to be_nil
    end
  end
end
