# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

describe Lti::CheckDomainDuplicatesService do
  let_once(:account) { account_model }
  let_once(:site_admin) { Account.site_admin }
  let(:domain) { "example.com" }

  let(:service) do
    Lti::CheckDomainDuplicatesService.new(account:, domain:)
  end

  describe "#call" do
    subject { service.call }

    context "when domain is blank" do
      let(:domain) { "" }

      it "returns an empty array" do
        expect(subject).to eq([])
      end
    end

    context "with registrations" do
      let_once(:config_with_domain) do
        {
          title: "Test Tool",
          target_link_uri: "https://example.com/launch",
          domain: "example.com",
          oidc_initiation_url: "https://example.com/oidc",
          public_jwk_url: "https://example.com/jwks"
        }
      end

      let_once(:registration) do
        reg = lti_registration_model(account:, name: "Test Registration")
        Lti::ToolConfiguration.create!(
          lti_registration: reg,
          **config_with_domain
        )
        lti_registration_account_binding_model(registration: reg, account:, workflow_state: "on")
        reg
      end

      it "finds registrations with matching domain" do
        registration # ensure it's created
        results = subject
        expect(results.length).to eq(1)
        expect(results.first[:name]).to eq("Test Registration")
      end

      it "performs case-insensitive domain matching" do
        registration # ensure it's created
        service = Lti::CheckDomainDuplicatesService.new(account:, domain: "EXAMPLE.COM")
        results = service.call
        expect(results.length).to eq(1)
      end

      it "limits results to 3 registrations" do
        # Create 4 registrations with the same domain
        4.times do |i|
          reg = lti_registration_model(account:, name: "Test Registration #{i}")
          Lti::ToolConfiguration.create!(
            lti_registration: reg,
            **config_with_domain
          )
          lti_registration_account_binding_model(registration: reg, account:, workflow_state: "on")
        end

        results = subject
        expect(results.length).to eq(3)
      end
    end

    context "with lti_registrations_templates feature flag" do
      let_once(:config_with_domain) do
        {
          title: "Test Tool",
          target_link_uri: "https://example.com/launch",
          domain: "example.com",
          oidc_initiation_url: "https://example.com/oidc",
          public_jwk_url: "https://example.com/jwks"
        }
      end

      let_once(:site_admin_registration) do
        reg = lti_registration_model(account: site_admin, name: "Site Admin Registration")
        Lti::ToolConfiguration.create!(
          lti_registration: reg,
          **config_with_domain
        )
        reg
      end

      let_once(:local_copy) do
        reg = lti_registration_model(
          account:,
          name: "Local Copy",
          template_registration_id: site_admin_registration.id
        )
        Lti::ToolConfiguration.create!(
          lti_registration: reg,
          **config_with_domain
        )
        reg
      end

      let_once(:account_binding_to_site_admin) do
        # Binding always points to the Site Admin registration (not the local copy)
        lti_registration_account_binding_model(
          registration: site_admin_registration,
          account:,
          workflow_state: "on"
        )
      end

      let_once(:regular_registration) do
        reg = lti_registration_model(account:, name: "Regular Registration")
        Lti::ToolConfiguration.create!(
          lti_registration: reg,
          **config_with_domain
        )
        lti_registration_account_binding_model(registration: reg, account:, workflow_state: "on")
        reg
      end

      context "when flag is disabled" do
        before do
          account.disable_feature!(:lti_registrations_templates)
        end

        it "shows the Site Admin registration that the binding points to" do
          local_copy # ensure it's created
          account_binding_to_site_admin # ensure binding exists
          regular_registration # ensure it's created

          results = subject
          names = results.pluck(:name)
          expect(names).to include("Regular Registration")
          expect(names).to include("Site Admin Registration")
          # Should NOT show the local copy
          expect(names).not_to include("Local Copy")
        end
      end

      context "when flag is enabled" do
        before do
          account.enable_feature!(:lti_registrations_templates)
        end

        it "shows local copy directly without querying Site Admin" do
          local_copy # ensure it's created
          account_binding_to_site_admin # ensure binding exists (but shouldn't be queried)
          regular_registration # ensure it's created

          results = subject
          names = results.pluck(:name)
          expect(names).to include("Local Copy")
          expect(names).to include("Regular Registration")
          # Should NOT show the Site Admin registration (not queried)
          expect(names).not_to include("Site Admin Registration")
        end

        it "only checks account registrations for duplicates" do
          local_copy # ensure it's created
          regular_registration # ensure it's created

          # Should only query account registrations, not Site Admin
          expect(Lti::Registration).to receive(:active).and_call_original
          expect_any_instance_of(Lti::CheckDomainDuplicatesService)
            .not_to receive(:forced_on_site_admin)
          expect_any_instance_of(Lti::CheckDomainDuplicatesService)
            .not_to receive(:inherited_on_registrations)

          subject
        end
      end
    end
  end
end
