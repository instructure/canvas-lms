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
        lti_registration_with_tool(account: site_admin)
      end
      let_once(:registration) do
        lti_registration_with_tool(account:)
      end
      let_once(:site_admin_binding) do
        binding = Lti::RegistrationAccountBinding.find_by!(registration: site_admin_registration, account: Account.site_admin)
        binding.update!(workflow_state: "on")
        binding
      end
      let_once(:registration_binding) do
        binding = Lti::RegistrationAccountBinding.find_by!(registration:, account:)
        binding.update!(workflow_state: "on")
        binding
      end

      it "returns the registrations" do
        expect(subject[:registrations]).to match_array([registration, site_admin_registration])
      end

      it "preloads the associations" do
        expect(subject[:registrations][0].association(:created_by)).to be_loaded
        expect(subject[:registrations][0].association(:updated_by)).to be_loaded
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

    context "with sharding and site admin forced-on registrations" do
      specs_require_sharding

      let_once(:sharded_account) do
        @shard1.activate { account_model }
      end

      let(:service) do
        Lti::ListRegistrationService.new(account: sharded_account, search_terms:, sort_field:, sort_direction:)
      end

      it "does not duplicate registrations that are forced on in site admin and have inherited bindings" do
        site_admin_reg = nil
        site_admin_binding = nil

        Account.site_admin.shard.activate do
          site_admin_reg = lti_registration_with_tool(account: Account.site_admin)
          site_admin_binding = Lti::RegistrationAccountBinding.find_by!(registration: site_admin_reg, account: Account.site_admin)
          site_admin_binding.update!(workflow_state: "allow")
        end

        # The user enables the key on their account
        @shard1.activate do
          Lti::RegistrationAccountBinding.create!(
            registration: site_admin_reg,
            account: sharded_account,
            workflow_state: "on",
            created_by: user_model,
            updated_by: user_model
          )
        end

        # ...site admin comes along later and forces it on for everyone.
        Shard.default.activate do
          site_admin_binding.update!(workflow_state: "on")
        end

        result = nil
        @shard1.activate do
          result = service.call
        end

        expect(result[:registrations].count).to eq(1)
        expect(result[:registrations].first.global_id).to eq(site_admin_reg.global_id)
      end
    end
  end
end
