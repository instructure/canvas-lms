# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

describe Lti::ListRegistrationService do
  let_once(:account) { account_model }
  let_once(:site_admin) { Account.site_admin }

  let(:service) do
    Lti::ListRegistrationService.new(account:, search_terms:, sort_field:, sort_direction:)
  end
  let(:search_terms) { nil }
  let(:sort_field) { nil }
  let(:sort_direction) { nil }

  describe "#call" do
    subject { service.call }

    context "when there are no registrations" do
      it "returns an empty array" do
        expect(subject).to eq({ registrations: [], preloaded_associations: {} })
      end
    end

    context "with registrations" do
      let_once(:site_admin_registration) do
        lti_tool_configuration_model(account: site_admin).lti_registration
      end
      let_once(:registration) do
        lti_tool_configuration_model(account:).lti_registration
      end
      let_once(:site_admin_binding) do
        binding = Lti::RegistrationAccountBinding.create!(registration: site_admin_registration, account: Account.site_admin, workflow_state: "on")
        binding
      end
      let_once(:registration_binding) do
        binding = Lti::RegistrationAccountBinding.create!(registration:, account:, workflow_state: "on")
        binding
      end

      before do
        site_admin_binding
        registration_binding
      end

      it "returns the registrations" do
        expect(subject[:registrations]).to match_array([registration, site_admin_registration])
      end

      it "preloads the associations" do
        expect(subject[:preloaded_associations]).to eq({
                                                         registration.global_id => { account_binding: registration_binding },
                                                         site_admin_registration.global_id => { account_binding: site_admin_binding }
                                                       })
      end

      context "the site admin registration is turned off" do
        before do
          site_admin_binding.update!(workflow_state: "off")
        end

        it "doesn't return the site admin registration" do
          expect(subject[:registrations]).to match_array([registration])
        end
      end

      context "the site admin registration is set to allow" do
        before do
          site_admin_binding.update!(workflow_state: "allow")
        end

        it "doesn't return the site admin registration" do
          expect(subject[:registrations]).to match_array([registration])
        end
      end

      context "in site admin account" do
        let(:account) { site_admin }

        it "only returns the site admin registration" do
          expect(subject[:registrations]).to match_array([site_admin_registration])
        end

        it "preloads the associations" do
          expect(subject[:preloaded_associations][site_admin_registration.global_id]).to eq({ account_binding: site_admin_binding })
        end

        context "when the site admin registration is turned off" do
          before do
            site_admin_binding.update!(workflow_state: "off")
          end

          it "still returns the site admin registration" do
            expect(subject[:registrations]).to match_array([site_admin_registration])
          end
        end
      end
    end
  end
end
