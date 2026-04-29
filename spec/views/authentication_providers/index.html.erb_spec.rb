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

describe "authentication_providers/index" do
  let(:account) { Account.default }

  before do
    assign(:context, assign(:account, account))
    assign(:domain_root_account, account)
    assign(:current_user, user_with_pseudonym)
    assign(:current_pseudonym, @pseudonym)
    assign(:saml_identifiers, [])
    assign(:saml_authn_contexts, [])
    assign(:saml_login_attributes, {})
    @presenter = assign(:presenter, AuthenticationProvidersPresenter.new(account))
  end

  it "displays the last_timeout_failure" do
    account.authentication_providers.scope.delete_all
    timed_out_aac = account.authentication_providers.create!(auth_type: "ldap")
    account.authentication_providers = [
      timed_out_aac,
      account.authentication_providers.create!(auth_type: "ldap")
    ]
    timed_out_aac.last_timeout_failure = 1.minute.ago
    timed_out_aac.save!
    expect(@presenter.configs).to include(timed_out_aac)
    render "authentication_providers/index"
    doc = Nokogiri::HTML5(response.body)
    expect(doc.css(".last_timeout_failure").length).to eq 1
  end

  it "displays more than 2 LDAP configs" do
    account.authentication_providers.scope.delete_all
    4.times do
      account.authentication_providers.create!(auth_type: "ldap")
    end
    render "authentication_providers/index"
    doc = Nokogiri::HTML5(response.body)
    expect(doc.css("input[value=ldap]").length).to eq(5) # 4 + 1 hidden for new
  end

  it "doesn't display delete button for the config the current user logged in with" do
    aac = account.authentication_providers.create!(auth_type: "ldap")
    @pseudonym.update_attribute(:authentication_provider, aac)
    render "authentication_providers/index"
    doc = Nokogiri::HTML5(response.body)
    expect(doc.css("#delete-aac-#{aac.id}")).to be_blank
  end

  describe "Discovery Page section" do
    it "renders when discovery page is allowed" do
      allow(account).to receive(:discovery_page_allowed?).and_return(true)
      render "authentication_providers/index"
      doc = Nokogiri::HTML5(response.body)
      expect(doc.css("#discovery-page-root")).to be_present
      expect(doc.css("input#discovery_page_active_field")).to be_present
      expect(response.body).to include("Discovery Page")
    end

    it "does not render when discovery page is not allowed" do
      allow(account).to receive(:discovery_page_allowed?).and_return(false)
      render "authentication_providers/index"
      doc = Nokogiri::HTML5(response.body)
      expect(doc.css("#discovery-page-root")).to be_blank
    end
  end

  context "when MFA is required" do
    before do
      account.settings[:mfa_settings] = :required
      account.save!
    end

    it "does not display MFA panel for canvas provider" do
      account.authentication_providers.scope.delete_all
      provider = account.authentication_providers.create!(auth_type: "canvas")
      render "authentication_providers/index"
      doc = Nokogiri::HTML5(response.body)
      canvas_form = doc.css("form#edit_canvas_#{provider.id}").first
      expect(canvas_form).not_to be_nil, "Should find the Canvas auth provider form"
      mfa_spans = canvas_form.css("span").select { |span| span.text.include?("MFA Required") }
      expect(mfa_spans).to be_blank
    end

    it "displays MFA panel for SAML auth provider" do
      account.authentication_providers.scope.delete_all
      account.authentication_providers.create!(auth_type: "saml")
      render "authentication_providers/index"
      doc = Nokogiri::HTML5(response.body)
      mfa_spans = doc.css("span").select { |span| span.text.include?("MFA Required") }
      expect(mfa_spans).not_to be_blank
    end

    it "displays MFA panel for LDAP auth provider" do
      account.authentication_providers.scope.delete_all
      account.authentication_providers.create!(auth_type: "ldap")
      render "authentication_providers/index"
      doc = Nokogiri::HTML5(response.body)
      mfa_spans = doc.css("span").select { |span| span.text.include?("MFA Required") }
      expect(mfa_spans).not_to be_blank
    end
  end

  context "when MFA is required for admins" do
    before do
      account.settings[:mfa_settings] = :required_for_admins
      account.save!
    end

    it "displays MFA panel for canvas provider" do
      account.authentication_providers.scope.delete_all
      provider = account.authentication_providers.create!(auth_type: "canvas")
      render "authentication_providers/index"
      doc = Nokogiri::HTML5(response.body)
      canvas_form = doc.css("form#edit_canvas_#{provider.id}").first
      expect(canvas_form).not_to be_nil, "Should find the Canvas auth provider form"
      mfa_spans = canvas_form.css("span").select { |span| span.text.include?("MFA Required") }
      expect(mfa_spans).not_to be_blank
    end
  end

  context "when MFA is disabled" do
    before do
      account.settings[:mfa_settings] = :disabled
      account.save!
    end

    it "does not display MFA panel for any auth provider" do
      account.authentication_providers.scope.delete_all
      account.authentication_providers.create!(auth_type: "canvas")
      account.authentication_providers.create!(auth_type: "ldap")
      render "authentication_providers/index"
      doc = Nokogiri::HTML5(response.body)
      mfa_spans = doc.css("span").select { |span| span.text.include?("MFA Required") }
      expect(mfa_spans).to be_blank
    end
  end
end
