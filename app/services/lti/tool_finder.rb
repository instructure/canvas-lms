# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
  # Centralized tool finding logic for single LTI tools.
  # Replaces ContextExternalTool#find_external_tool, #find_for, and friends.
  #
  # Single place to find tools and confirm that they are available in the
  # given context, since admins will soon be able to limit availability without
  # uninstalling tools.
  #
  # Finding a single tool is usually done either by ID or URL. This class has a
  # variety of methods that fall into these two categories to fit most needs.
  # It's not always possible to directly match a tool by its Canvas ID, like when a
  # tool is uninstalled and reinstalled from the same 1.3 registration, or when content
  # items that link to a tool only store a URL. This is the reason that URL matching
  # is needed, and why it ends up being so complex.
  #
  # For finding all tools available for a given context, use Lti::ContextToolFinder.
  class ToolFinder
    class << self
      # ----------
      # Find by ID
      # ----------

      # Returns the ContextExternalTool with this id, given that
      # it is available in the given context.
      # Replaces ContextExternalTool#find_for.
      #
      # @param id [Integer] The id of the ContextExternalTool
      # @param context [Course|Group|Account] Base context for searching
      # @param placement [String] If provided, will only return tools that use this placement
      #
      # @return [ContextExternalTool] The tool that matches the given id and criteria
      # @raise [ActiveRecord::RecordNotFound] If no tool is found
      def from_id!(id, context, placement: nil)
        from_id(id, context, placement:) || raise(ActiveRecord::RecordNotFound)
      end

      # Returns the ContextExternalTool with this id, given that
      # it is available in the given context.
      # Replaces ContextExternalTool#find_for.
      #
      # @param id [Integer] The id of the ContextExternalTool
      # @param context [Course|Group|Account] Base context for searching
      # @param placement [String] If provided, will only return tools that use this placement
      #
      # @return [ContextExternalTool] The tool that matches the given id and criteria, or nil
      def from_id(id, context, placement: nil)
        id = id[Api::ID_REGEX] if id.is_a?(String)
        return nil unless id.present?

        context.shard.activate do
          scope = ContextExternalTool.active.where(id:, context: Lti::ContextToolFinder.contexts_to_search(context))
          scope = scope.placements(placement) if placement
          scope.first
        end
      end

      # Returns the first ContextExternalTool present and available in
      # the given context that matches the given scope.
      #
      # @param context [Course|Group|Account] Base context for searching
      # @param scope [String] A ContextExternalTool query to narrow the search
      #
      # @return [ContextExternalTool] The first tool that matches the given scope
      def from_context(context, scope:)
        scope.find_by(context: Lti::ContextToolFinder.contexts_to_search(context))
      end

      # Returns the ContextExternalTool for this id, given that it is
      # available in the given context.
      #
      # Use instead of Rails' find_by to respect admin tool availability decisions.
      #
      # @param id [Integer] The id of the ContextExternalTool
      # @param scope [ActiveRecord::Relation] Optionally, a ContextExternalTool query to narrow the search
      #
      # @return [ContextExternalTool] The tool that matches the given id
      def find_by(id:, scope: nil)
        scope ||= ContextExternalTool.all
        scope.find_by(id:)
      end

      # Returns the ContextExternalTool for this id, given that it is
      # available in the given context.
      #
      # Use instead of Rails' find to respect admin tool availability decisions.
      #
      # @param id [Integer] The id of the ContextExternalTool
      # @param scope [ActiveRecord::Relation] Optionally, a ContextExternalTool query to narrow the search
      #
      # @return [ContextExternalTool] The tool that matches the given id
      # @raise [ActiveRecord::RecordNotFound] If no tool is found
      def find(id, scope: nil)
        scope ||= ContextExternalTool.all
        scope.find(id)
      end

      # -----------
      # Find by URL
      # -----------

      # Returns the ContextExternalTool associated with this assignment.
      #
      # Prefers the tool directly linked to the assignment's ContentTag
      # if it uses LTI 1.3. Otherwise, searches using from_url.
      #
      # @param assignment [Assignment] an LTI assignment
      # @return [ContextExternalTool] the tool associated with the assignment
      def from_assignment(assignment)
        tag = assignment.external_tool_tag
        return unless tag

        from_content_tag(tag, assignment.context)
      end

      # Returns the ContextExternalTool associated with this content tag.
      #
      # Prefers the tool directly linked to the ContentTag
      # if it uses LTI 1.3. Otherwise, searches using from_url.
      # Ignores tags linked to content that aren't LTI tools,
      # including those linked to LTI 2.0 tools.
      #
      # @param tag [ContentTag] an LTI content item, like module item or assignment.external_tool_tag
      # @param context [Context] the context in which the tag is being used
      # @return [ContextExternalTool] the tool associated with the content tag
      def from_content_tag(tag, context)
        return nil if tag.blank? || context.blank?

        content = tag.content
        is_external_tool_tag = content.blank? || content.is_a?(ContextExternalTool)
        return nil unless is_external_tool_tag

        # We can return the tool in content if we
        # know it uses the preferred LTI version.
        # No need to go through the tool lookup logic.
        if content.present? &&
           content.active? &&
           content.uses_preferred_lti_version? &&
           content.available_in_context?(context)
          return content
        end

        # Lookup the tool by the usual
        # method. Fall back on the tag's content if
        # no matches found.
        from_url(
          tag.url,
          context,
          preferred_tool_id: content&.id
        )
      end

      # Returns the ContextExternalTool that matches the given URL.
      #
      # Given URL is compared against all potential tool matches available
      # in the given context, sorted by the context chain (nearest first, so
      # prefers tool installed in a Course vs a tool installed in an Account).
      #
      # Matching checks against the tool's base URL, appropriate environment-specific
      # URL overrides, and then the tool's domain. Tools are also sorted by most specific
      # subdomains. A URL with "awesome.bob.example.com" will match a tool with a domain
      # of "example.com" but only if there isn't also a potential matching tool with a
      # domain of "awesome.bob.example.com" or "bob.example.com".
      #
      # @param url [String] the URL to match against
      # @param context [Context] search in all contexts up the chain from this
      # @param preferred_tool_id [Integer] Returns this tool if it matches the URL,
      #   unless the tool is an LTI 1.1 tool and another matched tool is an LTI 1.3 tool.
      # @param exclude_tool_id [Integer] Will never return this tool
      # @param preferred_client_id [Integer] Matches only against tools from this registration
      # @param use_context_controls [Boolean] If true, filters out tools that are marked as
      #  unavailable in the given context, based on LTI::ContextControls. Note that this will only
      #  filter LTI 1.3 tools, since LTI 1.1 tools do not support context controls, and are always considered
      #  available so long as they are active.
      # @param only_1_3 [Boolean] Matches only against LTI 1.3 tools
      # @param prefer_1_1 [Boolean] Sorts LTI 1.1 tools in front of LTI 1.3 tools
      # @return [ContextExternalTool] the tool that matches the given URL
      def from_url(
        url,
        context,
        preferred_tool_id: nil,
        exclude_tool_id: nil,
        preferred_client_id: nil,
        check_availability: true,
        only_1_3: false,
        prefer_1_1: false
      )
        GuardRail.activate(:secondary) do
          preferred_tool = ContextExternalTool.where(id: preferred_tool_id).first if preferred_tool_id # don't raise an exception if it's not found
          original_client_id = preferred_tool&.developer_key_id
          can_use_preferred_tool = preferred_tool.present? &&
                                   preferred_tool.active? &&
                                   Lti::ContextToolFinder.contexts_to_search(context).member?(preferred_tool.context)

          can_use_preferred_tool &&= preferred_tool.available_in_context?(context) if check_availability

          # always use the preferred_tool_id if url isn't provided
          return preferred_tool if url.blank? && can_use_preferred_tool
          return nil unless url

          potential_tools = potential_matching_tools(
            context:,
            preferred_tool_id:,
            original_client_id:,
            prefer_1_1:
          ).active

          potential_tools = filter_by_unavailable_context_controls(potential_tools, context) if check_availability

          potential_tools = potential_tools.where(developer_key_id: preferred_client_id) if preferred_client_id
          potential_tools = potential_tools.where.not(id: exclude_tool_id) if exclude_tool_id
          potential_tools = potential_tools.where(lti_version: "1.3") if only_1_3

          # Check for a tool that exactly matches the given URL
          match = find_matching_tool(url, potential_tools)

          # always use the preferred tool id *unless* the preferred tool is a 1.1 tool
          # and the matched tool is a 1.3 tool, since 1.3 is the preferred version of a tool
          if can_use_preferred_tool && preferred_tool.matches_host?(url)
            if match&.use_1_3? && !preferred_tool.use_1_3?
              return match
            end

            return preferred_tool
          end

          match
        end
      end

      # Finds an LTI 1.1 tool associated with the given LTI 1.3 tool.
      #
      # @param tool [ContextExternalTool] must be an LTI 1.3 tool
      # @param context [Context] search in all contexts up the chain from this
      # @param launch_url [String] the specific URL to match against
      def associated_1_1_tool(tool, context, launch_url)
        return nil unless tool&.use_1_3?

        launch_url ||= tool.url || tool.domain
        return nil unless launch_url

        # Finding tools is expensive and this relationship doesn't change very often, so
        # it's worth it to maintain this possibly "incorrect" relationship for 5 minutes.
        # Rails themselves recommends against caching ActiveRecord models directly
        # https://guides.rubyonrails.org/caching_with_rails.html#avoid-caching-instances-of-active-record-objects
        id = Rails.cache.fetch([tool.global_asset_string, context.global_asset_string, launch_url.slice(0..1024)].cache_key, expires_in: 5.minutes) do
          GuardRail.activate(:secondary) do
            sorted_external_tools = potential_matching_tools(context:).where(lti_version: "1.1")
            find_matching_tool(launch_url, sorted_external_tools)&.id
          end
        end

        ContextExternalTool.find_by(id:)
      end

      private

      # Filters the given scope of ContextExternalTools by the context controls
      # that are set for the given context.
      #
      # @param scope [ActiveRecord::Relation] a ContextExternalTool query to narrow the search
      # @param context [Account | Course | Group | Assignment] the current context
      # @return [ActiveRecord::Relation] the scope filtered by context controls. All LTI 1.1 tools are included
      #  since they do not support context controls and are always considered available so long as they are active.
      def filter_by_unavailable_context_controls(scope, context)
        return scope unless context.root_account.feature_enabled?(:lti_registrations_next)

        deployment_ids = Lti::ContextControl.deployment_ids_for_context(context)

        context.shard.activate do
          scope.where(id: deployment_ids).or(scope.lti_1_1)
        end
      end

      # Sorts all tools in the context chain by a variety of criteria in SQL
      # as opposed to in memory, in order to make it easier to find a tool that matches
      # the given URL.
      #
      # Criteria:
      # * closer contexts preferred (Course over Account over Root Account etc)
      # * more specific subdomains preferred (sub.domain.instructure.com over instructure.com)
      # * LTI 1.3 tools preferred over 1.1 tools unless prefer_1_1: true is provided
      # * if preferred_tool_id is provided, moves that tool to the front
      # * if original_client_id is provided, sorts tools from that registration to the front
      #     ahead of all other criteria
      #
      # Theoretically once this method is done, the very first tool to match the URL will be
      # the right tool, making it possible to eventually perform the rest of the URL matching
      # in SQL as well.
      # Note that currently, this mehod does *not* filter out deleted tools. We
      # need to be able to look at deleted tools to find an associated LTI 1.1
      # tool for an LTI 1.3 tool. This could likely be resolved in the future by
      # adding yet another boolean here, but for now, be aware of this behavior.
      # @param context [Course|Group|Assignment|Account] Base context for
      # searching
      # @param preferred_tool_id [Integer | nil] If provided, moves
      # this tool to the front of the list
      # @param original_client_id [Integer | nil] If provided, sorts tools from
      # this developer key to the front
      # @param prefer_1_1 [Boolean] If true, sorts LTI 1.1 tools in front of LTI
      # 1.3 tools (you almost certainly don't want this)
      def potential_matching_tools(
        context:,
        preferred_tool_id: nil,
        original_client_id: nil,
        prefer_1_1: false
      )
        context.shard.activate do
          order_clauses = [
            # prefer 1.3 tools (unless told otherwise)
            sort_by_sql_string("lti_version = '#{prefer_1_1 ? "1.1" : "1.3"}'"),
            # prefer tools that are not duplicates
            sort_by_sql_string("identity_hash != 'duplicate'"),
            # prefer tools from closer contexts, uses context_ordering_sql below
            "context_order.ordering",
            # prefer tools with more subdomains
            precedence_sql_string
          ]

          # move preferred tool to the front when requested, and id is well-formed
          preferred_tool_id = Shard.integral_id_for(preferred_tool_id)
          if preferred_tool_id
            order_clauses << sort_by_sql_string("#{ContextExternalTool.quoted_table_name}.id = #{preferred_tool_id}")
          end

          # prefer tools from the original developer key when requested,
          # and over other order clauses like context
          prefer_original_client_id = context.root_account.feature_enabled?(:lti_find_external_tool_prefer_original_client_id)
          if prefer_original_client_id && (original_client_id = Shard.integral_id_for(original_client_id))
            order_clauses.prepend(sort_by_sql_string("developer_key_id = #{original_client_id}"))
          end

          contexts = Lti::ContextToolFinder.contexts_to_search(context)
          ContextExternalTool
            .where(context: contexts)
            .joins(Lti::ContextToolFinder.context_ordering_sql(contexts))
            .order(Arel.sql(ContextExternalTool.sanitize_sql_for_order(order_clauses.join(","))))
        end
      end

      # prefer tools that have more specific subdomains, in SQL for order clauses
      def precedence_sql_string
        <<~SQL.squish
          CASE WHEN domain IS NOT NULL
            THEN 25 - ARRAY_LENGTH(STRING_TO_ARRAY(domain, '.'), 1)
            ELSE CASE WHEN url IS NOT NULL
              THEN 25
              ELSE 26
            END
          END
        SQL
      end

      # Used in an SQL order clause to push tools that match the condition to the front of the relation.
      def sort_by_sql_string(condition)
        "CASE WHEN #{condition} THEN 1 ELSE 2 END"
      end

      # Given a collection of tools, finds the first tool that matches the given conditions.
      #
      # First only loads non-duplicate tools into memory for matching, then will load
      # all tools if necessary.
      def find_tool_match(tool_collection, matcher, matcher_condition)
        possible_match = tool_collection.not_duplicate.find do |tool|
          matcher_condition.call(tool) && matcher.call(tool)
        end

        # an LTI 1.1 non-duplicate match means we still need to search
        # all tools since a 1.3 match with 'duplicate' identity_hash
        # still takes precedence
        return possible_match if possible_match&.use_1_3?

        tool_collection.find do |tool|
          matcher_condition.call(tool) && matcher.call(tool)
        end
      end

      def find_matching_tool(url, sorted_external_tools)
        # Check for a tool that exactly matches the given URL
        match = find_tool_match(
          sorted_external_tools,
          ->(t) { t.matches_url?(url) },
          ->(t) { t.url.present? }
        )

        # If exactly match doesn't work, try to match by ignoring extra query parameters
        match ||= find_tool_match(
          sorted_external_tools,
          ->(t) { t.matches_url?(url, false) },
          ->(t) { t.url.present? }
        )

        # If still no matches, use domain matching to try to find a tool
        match ||= find_tool_match(
          sorted_external_tools,
          ->(t) { t.matches_tool_domain?(url) },
          ->(t) { t.domain.present? }
        )

        # repeat matches with environment-specific url and domain overrides
        if ApplicationController.test_cluster?
          match ||= find_tool_match(
            sorted_external_tools,
            ->(t) { t.matches_url?(url, use_environment_overrides: true) },
            ->(t) { t.url.present? }
          )

          match ||= find_tool_match(
            sorted_external_tools,
            ->(t) { t.matches_url?(url, false, use_environment_overrides: true) },
            ->(t) { t.url.present? }
          )

          match ||= find_tool_match(
            sorted_external_tools,
            ->(t) { t.matches_tool_domain?(url, use_environment_overrides: true) },
            ->(t) { t.domain.present? }
          )
        end
        match
      end
    end
  end
end
