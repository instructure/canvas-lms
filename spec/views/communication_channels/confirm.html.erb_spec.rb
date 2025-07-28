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

describe "communication_channels/confirm" do
  before do
    user_factory
    assign(:user, @user)
    @cc = @communication_channel = assign(:communication_channel, communication_channel(@user, { username: "johndoe@example.com" }))
    assign(:nonce, @cc.confirmation_code)
    assign(:body_classes, [])
    assign(:domain_root_account, assign(:root_account, Account.default))
    allow(view).to receive(:require_terms?).and_return(nil) # since controller-defined helper methods don't get plumbed down here
  end

  shared_examples_for "user registration" do
    it "only shows the registration form if no merge opportunities" do
      assign(:merge_opportunities, [])
      render
      page = Nokogiri::HTML5("<document>" + response.body + "</document>")
      registration_form = page.css("#registration_confirmation_form").first
      expect(registration_form).not_to be_nil
      if @enrollment
        expect(registration_form["style"]).to match(/display:\s*none/)
        expect(page.css("#register.btn").first).not_to be_nil
        expect(page.css("#back.btn").first).to be_nil
      else
        expect(registration_form["style"]).to be_blank
        # no "back", "use this account", "new account", etc. buttons
        expect(page.css("a.btn")).to be_empty
      end
    end

    it "follows the simple path for not logged in" do
      user_with_pseudonym(active_all: 1)
      assign(:merge_opportunities, [[@user, [@user.pseudonym]]])
      render
      page = Nokogiri::HTML5("<document>" + response.body + "</document>")
      registration_form = page.css("#registration_confirmation_form").first
      expect(registration_form).not_to be_nil
      expect(registration_form["style"]).to match(/display:\s*none/)
      expect(page.css('input[type="radio"][name="pseudonym_select"]')).to be_empty
      expect(page.css("#register.btn").first).not_to be_nil
      merge_button = page.css("#merge.btn").first
      expect(merge_button).not_to be_nil
      expect(merge_button["href"]).to eq login_url(host: HostUrl.default_host, confirm: @communication_channel.confirmation_code, enrollment: @enrollment.try(:uuid), pseudonym_session: { unique_id: @pseudonym.unique_id }, expected_user_id: @pseudonym.user_id)
      expect(page.css("#back.btn").first).not_to be_nil
    end

    it "follows the simple path for logged in as a matching user" do
      user_with_pseudonym(active_all: 1)
      communication_channel(@user, { username: "johndoe@example.com", active_cc: true })
      assign(:merge_opportunities, [[@user, [@user.pseudonym]]])
      assign(:current_user, @user)
      render
      page = Nokogiri::HTML5("<document>" + response.body + "</document>")
      registration_form = page.css("#registration_confirmation_form").first
      expect(registration_form).not_to be_nil
      expect(registration_form["style"]).to match(/display:\s*none/)
      expect(page.css('input[type="radio"][name="pseudonym_select"]')).to be_empty
      expect(page.css("#register.btn").first).not_to be_nil
      merge_button = page.css("#merge.btn").first
      expect(merge_button).not_to be_nil
      expect(merge_button.text).to eq "Yes"
      expect(merge_button["href"]).to eq registration_confirmation_path(@communication_channel.confirmation_code, enrollment: @enrollment.try(:uuid), confirm: 1)
      expect(page.css("#back.btn").first).not_to be_nil
    end

    it "follows the simple path for logged in as a non-matching user" do
      user_with_pseudonym(active_all: 1)
      assign(:merge_opportunities, [[@user, [@user.pseudonym]]])
      assign(:current_user, @user)
      render
      page = Nokogiri::HTML5("<document>" + response.body + "</document>")
      registration_form = page.css("#registration_confirmation_form").first
      expect(registration_form).not_to be_nil
      expect(registration_form["style"]).to match(/display:\s*none/)
      expect(page.css('input[type="radio"][name="pseudonym_select"]')).to be_empty
      expect(page.css("#register.btn").first).not_to be_nil
      merge_button = page.css("#merge.btn").first
      expect(merge_button).not_to be_nil
      expect(merge_button["href"]).to eq registration_confirmation_path(@communication_channel.confirmation_code, enrollment: @enrollment.try(:uuid), confirm: 1)
      expect(merge_button.text).to eq "Yes, Add Email Address"
      expect(page.css("#back.btn").first).not_to be_nil
    end

    it "follows the mostly-simple-path for not-logged in with multiple pseudonyms" do
      user_with_pseudonym(active_all: 1)
      account2 = Account.create!
      assign(:merge_opportunities, [[@user, [@user.pseudonym, @user.pseudonyms.create!(unique_id: "johndoe", account: account2)]]])
      render
      page = Nokogiri::HTML5("<document>" + response.body + "</document>")
      registration_form = page.css("#registration_confirmation_form").first
      expect(registration_form).not_to be_nil
      expect(registration_form["style"]).to match(/display:\s*none/)
      expect(page.css('input[type="radio"][name="pseudonym_select"]').length).to eq 2
      expect(page.css("#register.btn").first).not_to be_nil
      merge_button = page.css("#merge.btn").first
      expect(merge_button).not_to be_nil
      expect(merge_button["href"]).to eq login_url(host: HostUrl.default_host, confirm: @communication_channel.confirmation_code, enrollment: @enrollment.try(:uuid), pseudonym_session: { unique_id: @pseudonym.unique_id }, expected_user_id: @pseudonym.user_id)
      expect(page.css("#back.btn").first).not_to be_nil
    end

    it "renders for multiple merge opportunities" do
      @user1 = user_with_pseudonym(active_all: 1)
      @user2 = user_with_pseudonym(active_all: 1, username: "janedoe@example.com")
      @user3 = user_with_pseudonym(active_all: 1, username: "freddoe@example.com")
      account2 = Account.create!
      @user3.pseudonyms.create!(unique_id: "johndoe", account: account2)
      @user4 = user_with_pseudonym(active_all: 1, username: "georgedoe@example.com", account: account2)
      assign(:merge_opportunities, [
               [@user1, [@user1.pseudonym]],
               [@user2, [@user2.pseudonym]],
               [@user3, @user3.pseudonyms],
               [@user4, [@user4.pseudonym]]
             ])
      assign(:current_user, @user1)
      render
      page = Nokogiri::HTML5("<document>" + response.body + "</document>")
      registration_form = page.css("#registration_confirmation_form").first
      expect(registration_form).not_to be_nil
      expect(registration_form["style"]).to match(/display:\s*none/)
      expect(page.css('input[type="radio"][name="pseudonym_select"]').length).to eq 6
      expect(page.css("#register.btn")).to be_empty
      merge_button = page.css("#merge.btn").first
      expect(merge_button).not_to be_nil
      expect(merge_button["href"]).to eq registration_confirmation_path(@communication_channel.confirmation_code, enrollment: @enrollment.try(:uuid), confirm: 1)
      expect(page.css("#back.btn").first).not_to be_nil
    end

    it "displays an asterisk and marks the Password field as required" do
      assign(:merge_opportunities, [])
      render
      page = Nokogiri::HTML5("<document>" + response.body + "</document>")
      label = page.css("label[for='pseudonym_password']").first
      expect(label).not_to be_nil
      expect(label.text).to match(/Password:?\s*\*/)
      field = page.css("#pseudonym_password").first
      expect(field).not_to be_nil
      expect(field["required"]).to eq "required"
    end
  end

  context "invitations" do
    before do
      course_factory(active_all: true)
      assign(:course, @course)
      @enrollment = assign(:enrollment, @course.enroll_user(@user))
    end

    it "renders transfer enrollment form" do
      assign(:merge_opportunities, [])
      @user.register
      @pseudonym1 = @user.pseudonyms.create!(unique_id: "jt@instructure.com")
      user_with_pseudonym(active_all: 1)
      assign(:current_user, @user)

      render
      page = Nokogiri::HTML5("<document>" + response.body + "</document>")
      expect(page.css("#registration_confirmation_form").first).to be_nil
      transfer_button = page.css("#transfer.btn").first
      expect(transfer_button).not_to be_nil
      expect(transfer_button["href"]).to eq registration_confirmation_path(@communication_channel.confirmation_code, enrollment: @enrollment.uuid, transfer_enrollment: 1)
      login_button = page.css("#login.btn").first
      expect(login_button).not_to be_nil
      expect(login_button["href"]).to eq login_url(enrollment: @enrollment.uuid, expected_user_id: @pseudonym1.user_id, login_hint: "jt@instructure.com")
    end

    context "open registration" do
      before do
        @user.update_attribute(:workflow_state, "creation_pending")
        assign(:pseudonym, @user.pseudonyms.build(account: Account.default))
      end

      include_examples "user registration"
    end
  end

  context "merging" do
    before do
      @user.register
    end

    it "renders to merge with the current user" do
      user_with_pseudonym(active_all: 1)
      assign(:current_user, @user)
      assign(:merge_opportunities, [[@user, [@pseudonym]]])
      render
      page = Nokogiri::HTML5("<document>" + response.body + "</document>")
      expect(page.css('input[type="radio"][name="pseudonym_select"]')).to be_empty
      expect(page.css("#registration_confirmation_form").first).to be_nil
      expect(page.css("#register.btn").first).to be_nil
      merge_button = page.css("#merge.btn").first
      expect(merge_button).not_to be_nil
      expect(merge_button.text).to eq "Combine"
      expect(merge_button["href"]).to eq registration_confirmation_path(@communication_channel.confirmation_code, confirm: 1, enrollment: nil)
    end

    it "renders to merge with the current user that doesn't have a pseudonym in the default account" do
      account = Account.create!
      user_with_pseudonym(active_all: 1, account:)
      assign(:current_user, @user)
      assign(:merge_opportunities, [[@user, [@pseudonym]]])
      render
      page = Nokogiri::HTML5("<document>" + response.body + "</document>")
      expect(page.css('input[type="radio"][name="pseudonym_select"]')).to be_empty
      expect(page.css("#registration_confirmation_form").first).to be_nil
      expect(page.css("#register.btn").first).to be_nil
      merge_button = page.css("#merge.btn").first
      expect(merge_button).not_to be_nil
      expect(merge_button.text).to eq "Combine"
      expect(merge_button["href"]).to eq registration_confirmation_path(@communication_channel.confirmation_code, confirm: 1, enrollment: nil)
    end

    it "renders to merge multiple users" do
      user_with_pseudonym(active_all: 1)
      @user1 = @user
      @pseudonym1 = @pseudonym
      user_with_pseudonym(active_all: 1, username: "georgedoe@example.com")
      @user2 = @user
      assign(:merge_opportunities, [[@user1, [@user1.pseudonym]], [@user2, [@user2.pseudonym]]])
      render
      page = Nokogiri::HTML5("<document>" + response.body + "</document>")
      expect(page.css('input[type="radio"][name="pseudonym_select"]').length).to eq 2
      expect(page.css("#registration_confirmation_form").first).to be_nil
      expect(page.css("#register.btn").first).to be_nil
      merge_button = page.css("#merge.btn").first
      expect(merge_button).not_to be_nil
      expect(merge_button.text).to eq "Continue"
      expect(merge_button["href"]).to eq login_url(host: HostUrl.default_host, confirm: @communication_channel.confirmation_code, pseudonym_session: { unique_id: @pseudonym1.unique_id }, expected_user_id: @pseudonym1.user_id)
    end
  end

  context "self-registration" do
    before do
      assign(:pseudonym, @user.pseudonyms.create!(unique_id: "johndoe@example.com"))
    end

    include_examples "user registration"
  end
end
