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

module Lti
  # Service for checking if a domain is already in use by other LTI registrations.
  # Returns a list of registrations that use the same domain across three scopes:
  # - Account-owned registrations
  # - Site Admin registrations forced on
  # - Inherited registrations that are enabled
  class CheckDomainDuplicatesService < ApplicationService
    attr_reader :account, :domain

    # @param account [Account] The account to search within
    # @param domain [String] The domain to search for (case-insensitive)
    def initialize(account:, domain:)
      @account = account
      @domain = domain

      super()
    end

    # Finds all registrations in the given account that have the same domain.
    # @return [Array<Hash>] Array of hashes with :id, :name, :admin_nickname
    def call
      return [] if domain.blank? || domain.strip.blank?

      normalized_domain = domain.strip.downcase

      GuardRail.activate(:secondary) do
        account_regs = account_registrations
        forced_on_regs = forced_on_site_admin
        inherited_regs = inherited_on_registrations

        account_results = registrations_with_domain(account_regs, normalized_domain)
        forced_on_results = registrations_with_domain(forced_on_regs, normalized_domain)
        inherited_results = registrations_with_domain(inherited_regs, normalized_domain)

        (account_results + forced_on_results + inherited_results)
      end
    end

    private

    # Get IDs of all registrations owned by this account
    def account_registrations
      Lti::Registration.active.where(account:)
    end

    # Get IDs of all registrations forced on in site admin
    def forced_on_site_admin
      Account.site_admin.shard.activate do
        Lti::Registration.active
                         .joins(:lti_registration_account_bindings)
                         .where(account: Account.site_admin)
                         .where(lti_registration_account_bindings: { workflow_state: "on", account: Account.site_admin })
      end
    end

    # Get IDs of all registrations inherited on for this account
    def inherited_on_registrations
      base_scope = Lti::RegistrationAccountBinding.enabled
                                                  .where(account:)
                                                  .left_outer_joins(:registration)
      # Handle the case of either site admin being on the same shard or it being on a separate
      # shard. If site admin is on a separate shard, *all* registration's will have a global id
      # that points to the same shard,
      # as only site admin registration's can be inherited on. If we ever let consortia parent's
      # do inheriting, we'll likely need to change this logic.
      Lti::Registration.where(
        id: base_scope.where(registration: { account: Account.site_admin }).or(
          base_scope.where("registration_id > ?", Shard::IDS_PER_SHARD)
        ).pluck(:registration_id) - forced_on_site_admin.pluck(:id)
      )
    end

    # Finds registrations with matching domain from a scope. Limits results to 3,
    # as that's all we show in the UI.
    # Uses LOWER() expression to match the expression indices
    # @param registration_ids [Array<Integer>] IDs of registrations to check
    # @param normalized_domain [String] Lowercase domain to match
    # @param source_shard [Shard] The shard the scope is being run on
    # @return [Array<Hash>] Array of hashes with :id, :name, :admin_nickname
    def registrations_with_domain(scope, normalized_domain)
      results = scope.shard_value.activate do
        scope
          .left_joins(:manual_configuration, :ims_registration)
          .where(
            "LOWER(#{Lti::ToolConfiguration.quoted_table_name}.domain) = ? OR " \
            "LOWER(#{Lti::IMS::Registration.quoted_table_name}.lti_tool_configuration->>'domain') = ?",
            normalized_domain,
            normalized_domain
          ).limit(3).pluck(:id, :name, :admin_nickname)
      end

      results.map do |id, name, admin_nickname|
        {
          id: Shard.relative_id_for(id, scope.shard_value, Shard.current),
          name:,
          admin_nickname:
        }.compact
      end
    end
  end
end
