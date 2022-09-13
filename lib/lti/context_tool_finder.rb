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
    attr_reader :context, :options

    def initialize(context, options = {})
      @context = context
      @options = options
    end

    def self.all_tools_scope_union(*args)
      new(*args).send(:all_tools_scope_union)
    end

    # TEMPORARY shim function until we can switch away from it.
    # Returns a scope, only on the context's shard, so doesn't look at
    # the context's root account's federated parent account
    def self.all_tools_for(*args)
      new(*args).single_shard_scope
    end

    # TEMPORARY shim function until we can switch away from all_tools_for
    def single_shard_scope
      scopes(include_federated_parent: false).first
            &.order(ContextExternalTool.best_unicode_collation_key("context_external_tools.name"))
            &.order(Arel.sql("context_external_tools.id"))
    end

    # If exclude_admin_visibility is true, does not return any tools where the options[:type]
    # placement visibility is "admins"
    def all_tools_sorted_array(exclude_admin_visibility: false)
      tools = all_tools_scope_union.to_unsorted_array

      if exclude_admin_visibility
        tools.reject! { |tool| tool.send(options[:type].to_sym, :visibility) == "admins" }
      end

      tools.sort_by(&:sort_key)
    end

    def all_tools_scope_union
      Lti::ScopeUnion.new(scopes)
    end

    private

    # Returns an array of scopes (which have no SQL order) for all tools.
    # Higher-priority scopes are first. (In practice there will only be
    # one or two scopes -- two if there is a cross-shard federated parent)
    # 'include_federated_parent' option is temporary (it will in the future
    # always be true) until we can move away from usages of all_tools_for
    def scopes(include_federated_parent: true)
      placements = * options[:placements] || options[:type]
      contexts = []
      if options[:user]
        contexts << options[:user]
      end
      contexts.concat ContextExternalTool.contexts_to_search(context, include_federated_parent: include_federated_parent)

      return [] if contexts.empty?

      Shard.partition_by_shard(contexts) do |contexts_by_shard|
        scope = ContextExternalTool.where(context: contexts_by_shard).active
        scope = scope.placements(*placements)
        scope = scope.selectable if Canvas::Plugin.value_to_boolean(options[:selectable])
        scope = scope.where(tool_id: options[:tool_ids]) if options[:tool_ids].present?
        if Canvas::Plugin.value_to_boolean(options[:only_visible])
          scope = scope.visible(options[:current_user], context, options[:session], options[:visibility_placements], scope)
        end
        [scope] # partition_by_shard expects an array
      end
    end
  end
end
