# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

# Class concerned with finding available ContextExternalTools for a particular
# context, with other possible options. Looks in the context and parents, which
# may include a federated parent, so tools may be on another shard.
module Lti
  class ContextToolFinder
    attr_reader :context

    # Notes on base_scope:
    # * if the scope uses an order, it will apply to each scope in the scope union separately
    # * the scope carries the shard it was created in but applies to each shard
    #   results are in; ids will be translated if necessary. e.g. if base_scope
    #   is [on shard 1] CET.where(id: 1), and contexts_to_search are on shard 1 and shard2,
    #   the ScopeUnion will have [shard 1] CET.where(id: 1) and [shard 2] CET.where(id: 10000000000001)
    # TODO: would be nice to merge 'placements' and 'type'

    def initialize(context,
                   base_scope: nil,
                   order_in_scope: false,
                   order_by_context: false,
                   placements: nil,
                   type: nil,
                   only_visible: false,
                   current_user: nil,
                   session: nil,
                   selectable: false,
                   tool_ids: nil)
      @context = context
      @base_scope = base_scope
      @order_in_scope = order_in_scope
      @order_by_context = order_by_context
      @placements = placements
      @type = type
      @only_visible = only_visible
      @current_user = current_user
      @session = session
      @selectable = selectable
      @tool_ids = tool_ids
    end

    # Most places that ask for a context's external tools are actually asking
    # for "all tools installed somewhere in this context's account chain", which
    # is what all_tools_for and all_tools_sorted_array do. This method is for
    # the rare cases where you want only tools associated directly with this context,
    # and functions as a confirmation for callers and future code spelunkers that
    # this is an exception to the rule.
    def self.only_for(context)
      return ContextExternalTool.none unless context.respond_to? :context_external_tools

      context.context_external_tools
    end

    def self.all_tools_scope_union(context, **)
      new(context, **).send(:all_tools_scope_union)
    end

    # TEMPORARY shim function until we can switch away from it.
    # Returns a scope, only on the context's shard, so doesn't look at
    # the context's root account's federated parent account
    def self.all_tools_for(context, **)
      new(context, order_in_scope: true, **).single_shard_scope
    end

    # TEMPORARY shim function until we can switch away from all_tools_for
    # When we remove this we should remove the include_federated_parent keyword
    # parameter
    def single_shard_scope
      scopes(include_federated_parent: false).first
    end

    # Just like all_tools_scope_union but orders by nearest context first
    def self.ordered_by_context_scope_union(context, **)
      new(context, order_by_context: true, order_in_scope: true, **).all_tools_scope_union
    end

    # Just like all_tools_for but orders by nearest context first
    def self.ordered_by_context_for(context, **)
      new(context, order_by_context: true, order_in_scope: true, **).single_shard_scope
    end

    # If exclude_admin_visibility is true, does not return any tools where the
    # placement visibility is "admins"
    def all_tools_sorted_array(exclude_admin_visibility: false)
      tools = all_tools_scope_union.to_unsorted_array

      if exclude_admin_visibility
        tools.reject! { |tool| tool.send(@type.to_sym, :visibility) == "admins" }
      end

      tools.sort_by(&:sort_key)
    end

    # Normally will be UNSORTED, and the ScopeUnion methods generally concatenate results
    # rather than sorting them together in any way.
    def all_tools_scope_union
      Lti::ScopeUnion.new(scopes)
    end

    def self.contexts_to_search(context, include_federated_parent: false)
      case context
      when Course
        [:self, :account_chain]
      when Group
        if context.context
          [:self, :recursive]
        else
          [:self, :account_chain]
        end
      when Account
        [:account_chain]
      when Assignment
        [:recursive]
      else
        []
      end.flat_map do |component|
        case component
        when :self
          context
        when :recursive
          contexts_to_search(context.context, include_federated_parent:)
        when :account_chain
          inc_fp = include_federated_parent &&
                   Account.site_admin.feature_enabled?(:lti_tools_from_federated_parents) &&
                   !context.root_account.primary_settings_root_account?
          context.account_chain(include_federated_parent: inc_fp)
        end
      end
    end

    # Produces an SQL fragment for ordering by context. This should be used
    # in a JOIN clause and coupled with an "ORDER BY context_order.ordering" clause.
    #
    # @param contexts [Array<Context>] the context chain, usually from contexts_to_search
    # @return [String] SQL fragment for ordering by context. use in .joins
    def self.context_ordering_sql(contexts)
      table_name = ContextExternalTool.quoted_table_name
      context_order = contexts.map.with_index { |c, i| "(#{c.id},'#{c.class.polymorphic_name}',#{i})" }.join(",")

      ContextExternalTool.sanitize_sql(
        <<~SQL.squish
          INNER JOIN (values #{context_order}) as context_order (context_id, class, ordering)
          ON #{table_name}.context_id = context_order.context_id
          AND #{table_name}.context_type = context_order.class
        SQL
      )
    end

    private

    # Returns an array of scopes (which have no SQL order) for all tools.
    # Higher-priority scopes are first. (In practice there will only be
    # one or two scopes -- two if there is a cross-shard federated parent)
    #
    # 'include_federated_parent' option is temporary (it will in the future
    # always be true) until we can move away from usages of all_tools_for. We
    # need it now so all_tools_for won't pick up same-shard CMC parent when FF
    # is on
    def scopes(include_federated_parent: true)
      placements = * @placements || @type
      contexts = Lti::ContextToolFinder.contexts_to_search(context, include_federated_parent:)

      return [ContextExternalTool.none] if contexts.empty?

      Shard.partition_by_shard(contexts, ->(c) { c.shard }) do |contexts_by_shard|
        # Important to use .shard() here to get a scope on the current shard but translate any ids
        scope = @base_scope&.shard(Shard.current) || ContextExternalTool
        scope = scope.where(context: contexts_by_shard).active
        scope = scope.placements(*placements)
        scope = scope.selectable if Canvas::Plugin.value_to_boolean(@selectable)
        scope = scope.where(tool_id: @tool_ids) if @tool_ids.present?

        if Canvas::Plugin.value_to_boolean(@only_visible)
          scope = scope.visible(@current_user, context, @session, placements, scope)
        end

        if @order_by_context
          scope = scope.joins(Lti::ContextToolFinder.context_ordering_sql(contexts)).order("context_order.ordering")
        end

        if @order_in_scope
          scope = scope.order(ContextExternalTool.best_unicode_collation_key("context_external_tools.name"))
                       .order(Arel.sql("context_external_tools.id"))
        end

        [scope] # partition_by_shard expects an array
      end
    end
  end
end
