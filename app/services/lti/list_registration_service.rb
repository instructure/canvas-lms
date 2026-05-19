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
        if templates_enabled?
          # Only queries local account registrations - no consortia or inherited registrations
          # (CMC consortia registrations will become local copies when fully rolled out)
          registrations = account_registrations(apply_filters: true, apply_sort: true)
        else
          registrations = account_registrations

          unless account.site_admin?
            # Without templates, use bindings to find inherited Site Admin registrations
            forced_on = forced_on_in_site_admin
            inherited_on = inherited_on_registrations(registrations, forced_on)
            registrations += forced_on +
                             inherited_on +
                             consortia_registrations(forced_on, inherited_on)
          end

          registrations = filter_registrations_by_search_query(registrations) if search_terms
        end

        if preload_overlays
          overlays = preloaded_overlays(registrations)
        end
        account_bindings = preloaded_account_bindings(registrations)

        unless templates_enabled?
          registrations = sort_registrations(registrations, account_bindings)
        end
        pending_updates = preloaded_pending_updates(registrations)
        preloaded_associations = registrations.index_by(&:global_id).transform_values do |reg|
          acc = { account_binding: account_bindings[reg.global_id] }
          acc[:overlay] = overlays[reg.global_id] if preload_overlays
          acc[:pending_update] = pending_updates[reg.global_id]&.first

          acc.compact
        end

        { registrations:, preloaded_associations: }
      end
    end

    private

    def preloaded_overlays(registrations)
      overlays = Lti::Overlay.where(account:, registration: registrations).preload(:updated_by, :registration)
      # Only query site admin overlays when templates are disabled (inherited registrations exist)
      overlays += Lti::Overlay.find_all_in_site_admin(registrations) unless templates_enabled?
      overlays.group_by(&:global_registration_id).transform_values(&:first)
    end

    def preloaded_account_bindings(registrations)
      account_bindings = Lti::RegistrationAccountBinding.active.where(account:, registration: registrations).preload(:created_by, :updated_by)
      # Only query site admin bindings when templates are disabled (inherited registrations exist)
      account_bindings += Lti::RegistrationAccountBinding.find_all_in_site_admin(registrations) unless templates_enabled?
      account_bindings.group_by(&:global_registration_id).transform_values(&:first)
    end

    def preloaded_pending_updates(registrations)
      return {} unless account.root_account.feature_enabled?(:lti_dr_registrations_update)

      # Get the most recent update request per registration, regardless of status
      all_latest = Lti::RegistrationUpdateRequest.where(lti_registration: registrations)
                                                 .select("DISTINCT ON (lti_registration_id) *")
                                                 .order(:lti_registration_id, created_at: :desc)

      # Only include requests that are still pending (most recent and not yet processed)
      all_latest.select(&:pending?)
                .group_by { |u| Shard.global_id_for(u.lti_registration_id, Shard.current) }
    end

    # Get all registrations on this account, regardless of their bindings
    def account_registrations(apply_filters: false, apply_sort: false)
      query = base_query.where(account:)
      # When templates are disabled, exclude local copies - they shouldn't be visible
      # When templates are enabled, include them - they'll be shown instead of Site Admin registrations
      query = query.where(template_registration_id: nil) unless templates_enabled?

      query = apply_search_filters(query) if apply_filters && search_terms.present?
      query = apply_database_sort(query) if apply_sort

      query
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
    def consortia_registrations(forced_on, inherited_on)
      if account.root_account.primary_settings_root_account?
        return Lti::RegistrationAccountBinding.none
      end

      consortium_parent = account.root_account.consortium_parent_account
      base_query
        .joins(:lti_registration_account_bindings)
        .shard(consortium_parent.shard)
        .where(account: consortium_parent)
        .where(lti_registration_account_bindings: { workflow_state: "on", account: consortium_parent })
        # Ensure we're only getting unique registrations we haven't already considered elsewhere
        .where.not(id: (forced_on.map(&:id) + inherited_on.map(&:id)).uniq)
    end

    # Get all registration account bindings in this account, then fetch the
    # registrations from their own shards. Omit registrations that were found in
    # the "account_registrations" list or the "forced_on" list; we're only looking
    # for ones that are uniquely being inherited from a different account and
    # aren't already forced on.
    #
    # A registration might have been inherited_on at one point, then, when the
    # site admin key is forced to on, the old account binding record still hangs
    # around. Thus, we have to explicitly filter out forced_on_registrations for
    # cases like this.
    def inherited_on_registrations(account_registrations, forced_on_registrations)
      ids = inherited_on_registration_ids(account_registrations, forced_on_registrations)

      Shard.partition_by_shard(ids) do |registration_ids_for_shard|
        base_query.where(id: registration_ids_for_shard)
      end.flatten
    end

    def inherited_on_registration_ids(account_registrations, forced_on_registrations)
      scope = Lti::RegistrationAccountBinding
              .where(account:)
              .where.not(registration_id: (account_registrations.map(&:id) + forced_on_registrations.map(&:id)).uniq)

      scope = if account.root_account.feature_enabled?(:lti_deactivate_registrations)
                scope.where.not(workflow_state: :deleted)
              else
                scope.where(workflow_state: :on)
              end

      scope
        .pluck(:registration_id)
        .uniq
    end

    def base_query
      Lti::Registration.active.preload(PRELOAD_MODELS)
    end

    def apply_search_filters(query)
      # Each search term must match at least one of the three fields
      # Use Canvas's wildcard helper for case-insensitive ILIKE
      search_terms.each do |term|
        condition = Lti::Registration.wildcard(
          "lti_registrations.name",
          "lti_registrations.admin_nickname",
          "lti_registrations.vendor",
          term
        )
        query = query.where(condition)
      end
      query
    end

    def apply_database_sort(query)
      # For user joins, we need to alias the tables to avoid conflicts
      # when joining both created_by and updated_by
      if sort_field == :installed_by
        query = query.joins(
          "LEFT OUTER JOIN #{User.quoted_table_name} AS created_by_users " \
          "ON created_by_users.id = lti_registrations.created_by_id"
        )
      end

      if sort_field == :updated_by
        query = query.joins(
          "LEFT OUTER JOIN #{User.quoted_table_name} AS updated_by_users " \
          "ON updated_by_users.id = lti_registrations.updated_by_id"
        )
      end

      # For status sorting, join pending update requests
      if sort_field == :status && Account.site_admin.feature_enabled?(:lti_dr_registrations_update)

        # Join a subquery that gets the most recent update request per registration (regardless of status)
        # Using DISTINCT ON to get only the latest request per registration
        pending_updates_subquery = <<~SQL.squish
          LEFT OUTER JOIN (
            SELECT DISTINCT ON (lti_registration_id)
              lti_registration_id,
              id,
              accepted_at,
              rejected_at
            FROM #{Lti::RegistrationUpdateRequest.quoted_table_name}
            ORDER BY lti_registration_id, created_at DESC
          ) AS pending_updates
          ON pending_updates.lti_registration_id = lti_registrations.id
        SQL

        query = query.joins(pending_updates_subquery)

        # Sort by whether the most recent update request is pending
        # A request is pending if both accepted_at and rejected_at are NULL
        # 0 = up to date (no request or request is accepted/rejected)
        # 1 = pending (has most recent request that is still pending)
        order_dir = (sort_direction == :desc) ? "DESC" : "ASC"
        return query.order(
          Arel.sql("CASE WHEN pending_updates.id IS NOT NULL AND pending_updates.accepted_at IS NULL AND pending_updates.rejected_at IS NULL THEN 1 ELSE 0 END #{order_dir}")
        )
      end

      order_clause = case sort_field
                     when :name
                       "LOWER(lti_registrations.name)"
                     when :nickname
                       "LOWER(COALESCE(lti_registrations.admin_nickname, ''))"
                     when :updated
                       "lti_registrations.updated_at"
                     when :installed_by
                       # Use NULLS FIRST to ensure nulls sort before non-nulls in ascending order
                       order_dir = (sort_direction == :desc) ? "DESC" : "ASC"
                       return query.order(Arel.sql("LOWER(created_by_users.name) #{order_dir} NULLS FIRST"))
                     when :updated_by
                       # Use NULLS FIRST to ensure nulls sort before non-nulls in ascending order
                       order_dir = (sort_direction == :desc) ? "DESC" : "ASC"
                       return query.order(Arel.sql("LOWER(updated_by_users.name) #{order_dir} NULLS FIRST"))
                     when :on
                       # Sort by registration workflow_state
                       "lti_registrations.workflow_state"
                     when :lti_version
                       # lti_version is a method that returns a constant, cannot sort at DB level
                       # Fall back to in-memory sort
                       return query
                     else
                       # Default sort for :installed and unknown sort fields
                       "lti_registrations.created_at"
                     end

      direction = (sort_direction == :desc) ? "DESC" : "ASC"
      query.order(Arel.sql(Lti::Registration.sanitize_sql_for_order("#{order_clause} #{direction}")))
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
          if check_registration_workflow_state?
            reg.workflow_state
          else
            account_bindings[reg.global_id]&.workflow_state || ""
          end
        end
      end

      if sort_direction == :desc
        sorted_registrations.reverse
      else
        sorted_registrations
      end
    end

    def check_registration_workflow_state?
      return @check_registration_workflow_state if defined?(@check_registration_workflow_state)

      @check_registration_workflow_state = account.root_account.feature_enabled?(:lti_deactivate_registrations)
    end

    def templates_enabled?
      return @templates_enabled if defined?(@templates_enabled)

      @templates_enabled = account.root_account.feature_enabled?(:lti_registrations_templates)
    end

    # Get all registrations from consortium parent account when templates are enabled.
    # Only queries registrations directly, not bindings.
    def consortia_registrations_with_templates
      if account.root_account.primary_settings_root_account?
        return []
      end

      consortium_parent = account.root_account.consortium_parent_account
      base_query
        .shard(consortium_parent.shard)
        .where(account: consortium_parent)
    end
  end
end
