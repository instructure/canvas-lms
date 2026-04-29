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

      before do
        # Disable the template flag to test the original behavior
        account.disable_feature!(:lti_registrations_templates)
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

      context "when an inherited registration has an account binding turned off" do
        let(:allow_site_admin_reg) { lti_registration_with_tool(account: site_admin) }
        let(:sub_account_off_binding) do
          lti_registration_account_binding_model(
            registration: allow_site_admin_reg,
            account:,
            workflow_state: "off"
          )
        end

        context "when flag enabled" do
          before { account.enable_feature!(:lti_deactivate_registrations) }

          it "includes the registration in the list" do
            sub_account_off_binding
            expect(service.call[:registrations]).to include(allow_site_admin_reg)
          end
        end

        context "when flag disabled" do
          before { account.disable_feature!(:lti_deactivate_registrations) }

          it "does not include the registration in the list" do
            sub_account_off_binding
            expect(service.call[:registrations]).not_to include(allow_site_admin_reg)
          end
        end
      end

      context "when a site admin registration has never been bound in this account" do
        let(:allow_site_admin_reg) { lti_registration_with_tool(account: site_admin) }

        it "does not include the registration in the list" do
          allow_site_admin_reg
          expect(service.call[:registrations]).not_to include(allow_site_admin_reg)
        end
      end
    end

    context "when sorting by workflow_state" do
      let(:sort_field) { :on }
      let(:sort_direction) { :asc }

      it "sorts registrations by workflow_state when flag is enabled" do
        account.enable_feature!(:lti_deactivate_registrations)

        active_reg = lti_registration_model(account:, name: "Active reg")
        lti_registration_account_binding_model(registration: active_reg, account:, workflow_state: "on")

        inactive_reg = lti_registration_model(account:, name: "Inactive reg")
        lti_registration_account_binding_model(registration: inactive_reg, account:, workflow_state: "on")
        inactive_reg.deactivate!

        result = service.call
        workflow_states = result[:registrations].map(&:workflow_state)
        expect(workflow_states).to eq(%w[active inactive])
      end

      it "sorts registrations by account binding state when flag is disabled" do
        account.disable_feature!(:lti_deactivate_registrations)

        off_reg = lti_registration_model(account:, name: "Off reg")
        lti_registration_account_binding_model(registration: off_reg, account:, workflow_state: "off")

        on_reg = lti_registration_model(account:, name: "On reg")
        lti_registration_account_binding_model(registration: on_reg, account:, workflow_state: "on")

        result = service.call
        names = result[:registrations].map(&:name)
        expect(names).to eq(["Off reg", "On reg"])
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

      before do
        # Disable the template flag to test the original cross-shard behavior
        @shard1.activate do
          sharded_account.disable_feature!(:lti_registrations_templates)
        end
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

    context "with lti_registrations_templates feature flag" do
      let_once(:site_admin_registration) do
        lti_registration_model(account: site_admin, name: "Site Admin Registration")
      end
      let_once(:local_copy) do
        lti_registration_model(
          account:,
          name: "Local Copy",
          template_registration_id: site_admin_registration.id
        )
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
        lti_registration_with_tool(account:)
      end

      context "when flag is disabled" do
        before do
          account.disable_feature!(:lti_registrations_templates)
        end

        it "shows the Site Admin registration that the binding points to" do
          local_copy # ensure it's created
          account_binding_to_site_admin # ensure binding exists
          regular_registration # ensure it's created

          test_service = Lti::ListRegistrationService.new(account:, search_terms: nil, sort_field: nil, sort_direction: nil)
          result = test_service.call

          # Should show the Site Admin registration (what the binding points to)
          expect(result[:registrations]).to include(site_admin_registration)
          expect(result[:registrations]).to include(regular_registration)
          # Should NOT show the local copy
          expect(result[:registrations]).not_to include(local_copy)
        end
      end

      context "when flag is enabled" do
        before do
          account.enable_feature!(:lti_registrations_templates)
        end

        it "shows local copies directly without querying bindings" do
          local_copy # ensure it's created
          account_binding_to_site_admin # ensure binding exists (but shouldn't be queried)
          regular_registration # ensure it's created

          result = service.call

          # Should show the local copy (from account_registrations)
          expect(result[:registrations]).to include(local_copy)
          expect(result[:registrations]).to include(regular_registration)
          # Should NOT show the Site Admin registration (bindings not queried)
          expect(result[:registrations]).not_to include(site_admin_registration)
        end

        it "shows the local copy with template_registration_id" do
          local_copy # ensure it's created

          result = service.call
          found_copy = result[:registrations].find { |r| r.id == local_copy.id }
          expect(found_copy).to be_present
          expect(found_copy.template_registration_id).to eq(site_admin_registration.id)
        end

        it "does not use bindings to find inherited registrations" do
          local_copy # ensure it's created
          regular_registration # ensure it's created

          result = service.call

          # All registrations should come from account_registrations directly
          # Not from querying bindings and then fetching registrations
          expect(result[:registrations].all? { |r| r.account == account }).to be true
        end

        context "database-level filtering" do
          let_once(:reg1) { lti_registration_model(account:, name: "Canvas Tool", vendor: "Instructure") }
          let_once(:reg2) { lti_registration_model(account:, name: "Test Tool", admin_nickname: "Canvas Tests", vendor: "Vendor A") }
          let_once(:reg3) { lti_registration_model(account:, name: "Other Tool", vendor: "Different") }

          before do
            reg1
            reg2
            reg3
          end

          it "filters by single search term case-insensitively" do
            service = Lti::ListRegistrationService.new(
              account:,
              search_terms: ["canvas"],
              sort_field: :name,
              sort_direction: :asc
            )
            result = service.call
            expect(result[:registrations]).to match_array([reg1, reg2])
          end

          it "filters by multiple search terms (AND logic)" do
            service = Lti::ListRegistrationService.new(
              account:,
              search_terms: ["canvas", "tool"],
              sort_field: :name,
              sort_direction: :asc
            )
            result = service.call
            expect(result[:registrations]).to match_array([reg1, reg2])
          end

          it "searches across name, admin_nickname, and vendor" do
            service = Lti::ListRegistrationService.new(
              account:,
              search_terms: ["instructure"],
              sort_field: :name,
              sort_direction: :asc
            )
            result = service.call
            expect(result[:registrations]).to match_array([reg1])
          end

          it "returns empty when no matches found" do
            service = Lti::ListRegistrationService.new(
              account:,
              search_terms: ["nonexistent"],
              sort_field: :name,
              sort_direction: :asc
            )
            result = service.call
            expect(result[:registrations]).to be_empty
          end

          it "returns an ActiveRecord::Relation when optimized" do
            service = Lti::ListRegistrationService.new(
              account:,
              search_terms: ["canvas"],
              sort_field: :name,
              sort_direction: :asc
            )
            result = service.call
            expect(result[:registrations]).to be_a(ActiveRecord::Relation)
          end
        end

        context "database-level sorting" do
          let_once(:user1) { user_model(name: "Alice") }
          let_once(:user2) { user_model(name: "Bob") }

          let_once(:reg_a) do
            lti_registration_model(
              account:,
              name: "DBSort Alpha Tool",
              admin_nickname: "A Nickname",
              vendor: "SortVendor",
              created_by: user1,
              updated_by: user2
            )
          end

          let_once(:reg_b) do
            lti_registration_model(
              account:,
              name: "DBSort Beta Tool",
              admin_nickname: nil,
              vendor: "SortVendor",
              created_by: user2,
              updated_by: user1
            )
          end

          let_once(:reg_c) do
            reg = lti_registration_model(
              account:,
              name: "DBSort Gamma Tool",
              admin_nickname: "Z Nickname",
              vendor: "SortVendor"
            )
            # Explicitly set user IDs to NULL
            reg.update_columns(created_by_id: nil, updated_by_id: nil)
            reg
          end

          before do
            reg_a
            reg_b
            reg_c
            # Update timestamps to create a predictable order
            reg_a.update_column(:created_at, 3.days.ago)
            reg_b.update_column(:created_at, 2.days.ago)
            reg_c.update_column(:created_at, 1.day.ago)
            reg_a.update_column(:updated_at, 1.day.ago)
            reg_b.update_column(:updated_at, 3.days.ago)
            reg_c.update_column(:updated_at, 2.days.ago)
          end

          it "sorts by name ascending" do
            service = Lti::ListRegistrationService.new(
              account:,
              search_terms: ["sortvendor"],
              sort_field: :name,
              sort_direction: :asc
            )
            result = service.call
            expect(result[:registrations].map(&:name)).to eq(["DBSort Alpha Tool", "DBSort Beta Tool", "DBSort Gamma Tool"])
          end

          it "sorts by name descending" do
            service = Lti::ListRegistrationService.new(
              account:,
              search_terms: ["sortvendor"],
              sort_field: :name,
              sort_direction: :desc
            )
            result = service.call
            expect(result[:registrations].map(&:name)).to eq(["DBSort Gamma Tool", "DBSort Beta Tool", "DBSort Alpha Tool"])
          end

          it "sorts by admin_nickname with null handling" do
            service = Lti::ListRegistrationService.new(
              account:,
              search_terms: ["sortvendor"],
              sort_field: :nickname,
              sort_direction: :asc
            )
            result = service.call
            # Nulls (empty string) should come first, then "A Nickname", then "Z Nickname"
            expect(result[:registrations].map(&:name)).to eq(["DBSort Beta Tool", "DBSort Alpha Tool", "DBSort Gamma Tool"])
          end

          it "sorts by installed (created_at)" do
            service = Lti::ListRegistrationService.new(
              account:,
              search_terms: ["sortvendor"],
              sort_field: :installed,
              sort_direction: :asc
            )
            result = service.call
            # Oldest first: reg_a, reg_b, reg_c
            expect(result[:registrations].to_a).to eq([reg_a, reg_b, reg_c])
          end

          it "sorts by updated (updated_at)" do
            service = Lti::ListRegistrationService.new(
              account:,
              search_terms: ["sortvendor"],
              sort_field: :updated,
              sort_direction: :asc
            )
            result = service.call
            # Oldest update first: reg_b (3 days), reg_c (2 days), reg_a (1 day)
            expect(result[:registrations].to_a).to eq([reg_b, reg_c, reg_a])
          end

          it "sorts by installed_by (created_by.name) with nulls" do
            service = Lti::ListRegistrationService.new(
              account:,
              search_terms: ["sortvendor"],
              sort_field: :installed_by,
              sort_direction: :asc
            )
            result = service.call
            # Nulls first (empty string), then Alice, then Bob
            names = result[:registrations].map { |r| r.created_by&.name || "" }
            expect(names).to eq(["", "Alice", "Bob"])
          end

          it "sorts by updated_by (updated_by.name) with nulls" do
            service = Lti::ListRegistrationService.new(
              account:,
              search_terms: ["sortvendor"],
              sort_field: :updated_by,
              sort_direction: :asc
            )
            result = service.call
            # Nulls first (empty string), then Alice, then Bob
            names = result[:registrations].map { |r| r.updated_by&.name || "" }
            expect(names).to eq(["", "Alice", "Bob"])
          end

          it "sorts by workflow_state when deactivate flag enabled" do
            account.enable_feature!(:lti_deactivate_registrations)

            # Deactivate one registration
            reg_b.deactivate!

            service = Lti::ListRegistrationService.new(
              account:,
              search_terms: ["sortvendor"],
              sort_field: :on,
              sort_direction: :asc
            )
            result = service.call
            # "active" comes before "inactive" alphabetically
            workflow_states = result[:registrations].map(&:workflow_state)
            expect(workflow_states).to eq(%w[active active inactive])
          end

          it "sorts by status (pending updates) ascending" do
            Account.site_admin.enable_feature!(:lti_dr_registrations_update)

            # Create pending update requests for some registrations
            # Must include lti_ims_registration or canvas_lti_configuration per check constraint
            Lti::RegistrationUpdateRequest.create!(
              lti_registration: reg_a,
              root_account: account,
              lti_ims_registration: {}
            )
            Lti::RegistrationUpdateRequest.create!(
              lti_registration: reg_c,
              root_account: account,
              lti_ims_registration: {}
            )

            service = Lti::ListRegistrationService.new(
              account:,
              search_terms: ["sortvendor"],
              sort_field: :status,
              sort_direction: :asc
            )
            result = service.call
            # Up to date (0) comes before pending (1) in ascending order
            # reg_b has no pending update, reg_a and reg_c have pending updates
            expect(result[:registrations].first).to eq(reg_b)
            expect(result[:registrations][1..2]).to match_array([reg_a, reg_c])
          end

          it "sorts by status (pending updates) descending" do
            Account.site_admin.enable_feature!(:lti_dr_registrations_update)

            # Create pending update request for one registration
            # Must include lti_ims_registration or canvas_lti_configuration per check constraint
            Lti::RegistrationUpdateRequest.create!(
              lti_registration: reg_b,
              root_account: account,
              lti_ims_registration: {}
            )

            service = Lti::ListRegistrationService.new(
              account:,
              search_terms: ["sortvendor"],
              sort_field: :status,
              sort_direction: :desc
            )
            result = service.call
            # Pending (1) comes before up to date (0) in descending order
            # reg_b has pending update, reg_a and reg_c have no pending updates
            expect(result[:registrations].first).to eq(reg_b)
            expect(result[:registrations][1..2]).to match_array([reg_a, reg_c])
          end

          it "treats accepted/rejected update requests as up to date" do
            Account.site_admin.enable_feature!(:lti_dr_registrations_update)

            # Create pending update request for reg_a
            Lti::RegistrationUpdateRequest.create!(
              lti_registration: reg_a,
              root_account: account,
              lti_ims_registration: {}
            )

            # Create accepted update request for reg_b (should be treated as up to date)
            Lti::RegistrationUpdateRequest.create!(
              lti_registration: reg_b,
              root_account: account,
              lti_ims_registration: {},
              accepted_at: Time.zone.now
            )

            # Create rejected update request for reg_c (should be treated as up to date)
            Lti::RegistrationUpdateRequest.create!(
              lti_registration: reg_c,
              root_account: account,
              lti_ims_registration: {},
              rejected_at: Time.zone.now
            )

            service = Lti::ListRegistrationService.new(
              account:,
              search_terms: ["sortvendor"],
              sort_field: :status,
              sort_direction: :asc
            )
            result = service.call

            # Up to date (0) comes before pending (1) in ascending order
            # reg_b and reg_c have accepted/rejected updates (treated as up to date)
            # reg_a has pending update
            expect(result[:registrations].to_a[0..1]).to match_array([reg_b, reg_c])
            expect(result[:registrations].last).to eq(reg_a)
          end

          it "falls back to created_at sort when status sorting but feature disabled" do
            Account.site_admin.disable_feature!(:lti_dr_registrations_update)

            service = Lti::ListRegistrationService.new(
              account:,
              search_terms: ["sortvendor"],
              sort_field: :status,
              sort_direction: :asc
            )
            result = service.call

            # Should still use database optimization (returns ActiveRecord::Relation)
            # but fall back to sorting by created_at since status sorting requires the feature
            expect(result[:registrations]).to be_a(ActiveRecord::Relation)
            # Should be sorted by created_at ascending (oldest first)
            expect(result[:registrations].to_a).to eq([reg_a, reg_b, reg_c])
          end
        end
      end
    end
  end
end
