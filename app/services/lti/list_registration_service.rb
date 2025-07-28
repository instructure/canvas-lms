# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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
  class ListRegistrationService < ApplicationService
    PRELOAD_MODELS = [
      :ims_registration,
      :manual_configuration,
      :developer_key,
      :created_by, # registration's created_by
      :updated_by  # registration's updated_by
    ].freeze

    attr_reader :account, :search_terms, :sort_field, :sort_direction, :preload_overlays

    def initialize(account:, search_terms:, sort_field: :installed, sort_direction: :desc, preload_overlays: false)
      @account = account
      @search_terms = search_terms
      @sort_field = sort_field
      @sort_direction = sort_direction
      @preload_overlays = preload_overlays

      super()
    end

    # Returns a hash that contains all of the registrations that are applicable to the account, as well
    # as the preloaded associations for each registration.
    #
    # @returns { registrations: [Lti::Registration], preloaded_associations: { registration_id: { account_binding: Lti::RegistrationAccountBinding | nil, overlay: Lti::Overlay | nil } } }
    def call
      GuardRail.activate(:secondary) do
        registrations = account_registrations
        unless account.site_admin?
          registrations += forced_on_in_site_admin +
                           inherited_on_registrations(registrations) +
                           consortia_registrations
        end

        if preload_overlays
          overlays = preloaded_overlays(registrations)
        end
        account_bindings = preloaded_account_bindings(registrations)
        preloaded_associations = registrations.index_by(&:global_id).transform_values do |reg|
          acc = { account_binding: account_bindings[reg.global_id] }
          acc[:overlay] = overlays[reg.global_id] if preload_overlays

          acc.compact
        end

        registrations = filter_registrations_by_search_query(registrations) if search_terms
        registrations = sort_registrations(registrations, account_bindings)

        { registrations:, preloaded_associations: }
      end
    end

    private

    def preloaded_overlays(registrations)
      overlays = Lti::Overlay.where(account:, registration: registrations).preload(:updated_by) +
                 Lti::Overlay.find_all_in_site_admin(registrations)
      overlays.group_by(&:global_registration_id).transform_values(&:first)
    end

    def preloaded_account_bindings(registrations)
      account_bindings = Lti::RegistrationAccountBinding.where(account:, registration: registrations).preload(:created_by, :updated_by) +
                         Lti::RegistrationAccountBinding.find_all_in_site_admin(registrations)
      account_bindings.group_by(&:global_registration_id).transform_values(&:first)
    end

    # Get all registrations on this account, regardless of their bindings
    def account_registrations
      base_query.where(account:)
    end

    # Get all registration account bindings that are bound to the site admin account and that are "on,"
    # since they will apply to this account (and all accounts)
    def forced_on_in_site_admin
      base_query
        .joins(:lti_registration_account_bindings)
        .shard(Shard.default)
        .where(account: Account.site_admin)
        .where(lti_registration_account_bindings: { workflow_state: "on", account_id: Account.site_admin.id })
    end

    # Get all registration account bindings that are bound to the consortium parent account and that are "on,"
    # since they will apply to this account
    def consortia_registrations
      if account.root_account.primary_settings_root_account?
        return Lti::RegistrationAccountBinding.none
      end

      consortium_parent = account.root_account.consortium_parent_account
      base_query
        .joins(:lti_registration_account_bindings)
        .shard(consortium_parent.shard)
        .where(account: consortium_parent)
        .where(lti_registration_account_bindings: { workflow_state: "on", account: consortium_parent })
    end

    # Get all registration account bindings in this account, then fetch the registrations from their own shards
    # Omit registrations that were found in the "account_registrations" list; we're only looking for ones that
    # are uniquely being inherited from a different account.
    def inherited_on_registrations(account_registrations)
      ids = inherited_on_registration_ids(account_registrations)

      Shard.partition_by_shard(ids) do |registration_ids_for_shard|
        base_query.where(id: registration_ids_for_shard)
      end.flatten
    end

    def inherited_on_registration_ids(account_registrations)
      Lti::RegistrationAccountBinding
        .where(workflow_state: "on")
        .where(account:)
        .where.not(registration_id: account_registrations.map(&:id))
        .pluck(:registration_id)
        .uniq
    end

    def base_query
      Lti::Registration.active.preload(PRELOAD_MODELS)
    end

    def filter_registrations_by_search_query(registrations)
      # all search terms must appear, but each can be in either the name,
      # admin_nickname, or vendor name. Remove the search terms from the list
      # as they are found -- keep the registration as a matching result if the
      # list is empty at the end.
      registrations.select do |registration|
        terms_to_find = search_terms.dup
        terms_to_find.delete_if do |term|
          attributes = %i[name admin_nickname vendor]
          attributes.any? do |attribute|
            registration[attribute]&.downcase&.include?(term)
          end
        end

        terms_to_find.empty?
      end
    end

    def sort_registrations(registrations, account_bindings)
      # sort by the 'sort' parameter, or installed (a.k.a. created_at) if no parameter was given
      sorted_registrations = registrations.sort_by do |reg|
        case sort_field
        when :name
          reg.name.downcase
        when :nickname
          reg.admin_nickname&.downcase || ""
        when :lti_version
          reg.lti_version
        when :installed
          reg.created_at
        when :updated
          reg.updated_at
        when :installed_by
          reg.created_by&.name&.downcase || ""
        when :updated_by
          reg.updated_by&.name&.downcase || ""
        when :on
          account_bindings[reg.global_id]&.workflow_state || ""
        end
      end

      if sort_direction == :desc
        sorted_registrations.reverse
      else
        sorted_registrations
      end
    end
  end
end
