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
  # Replaces ContextExternalTool#find_external_tool and friends.
  #
  # For finding all tools available for a given context, use Lti::ContextToolFinder.
  class ToolFinder
    class << self
      def from_assignment(assignment)
        tag = assignment.external_tool_tag
        return unless tag

        from_content_tag(tag, assignment.context)
      end

      def from_content_tag(tag, context)
        return nil if tag.blank? || context.blank?

        # We can return the tool in content if we
        # know it uses the preferred LTI version.
        # No need to go through the tool lookup logic.
        content = tag.content
        return content if content&.active? && content&.uses_preferred_lti_version?

        # Lookup the tool by the usual
        # method. Fall back on the tag's content if
        # no matches found.
        from_url(
          tag.url,
          context,
          preferred_tool_id: content&.id
        )
      end

      # Order of precedence: Basic LTI defines precedence as first
      # checking for a match on domain.  Subdomains count as a match
      # on less-specific domains, but the most-specific domain will
      # match first.  So awesome.bob.example.com matches an
      # external_tool with example.com as the domain, but only if
      # there isn't another external_tool where awesome.bob.example.com
      # or bob.example.com is set as the domain.
      #
      # If there is no domain match then check for an exact url match
      # as configured by an admin.  If there is still no match
      # then check for a match on the current context (configured by
      # the teacher).
      #
      # Tools with exclude_tool_id as their ID will never be returned.
      def from_url(
        url,
        context,
        preferred_tool_id: nil,
        exclude_tool_id: nil,
        preferred_client_id: nil,
        only_1_3: false,
        prefer_1_1: false
      )
        GuardRail.activate(:secondary) do
          preferred_tool = ContextExternalTool.where(id: preferred_tool_id).first if preferred_tool_id # don't raise an exception if it's not found
          original_client_id = preferred_tool&.developer_key_id
          can_use_preferred_tool = preferred_tool&.active? && Lti::ContextToolFinder.contexts_to_search(context).member?(preferred_tool.context)

          # always use the preferred_tool_id if url isn't provided
          return preferred_tool if url.blank? && can_use_preferred_tool
          return nil unless url

          sorted_external_tools = find_and_order_tools(
            context:,
            preferred_tool_id:,
            exclude_tool_id:,
            preferred_client_id:,
            original_client_id:,
            only_1_3:,
            prefer_1_1:
          )

          # Check for a tool that exactly matches the given URL
          match = find_matching_tool(url, sorted_external_tools)

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

      def associated_1_1_tool(tool, context, launch_url)
        return nil unless launch_url && tool.use_1_3?

        # Finding tools is expensive and this relationship doesn't change very often, so
        # it's worth it to maintain this possibly "incorrect" relationship for 5 minutes.
        id = Rails.cache.fetch([tool.global_asset_string, context.global_asset_string, launch_url.slice(0..1024)].cache_key, expires_in: 5.minutes) do
          # Rails themselves recommends against caching ActiveRecord models directly
          # https://guides.rubyonrails.org/caching_with_rails.html#avoid-caching-instances-of-active-record-objects
          GuardRail.activate(:secondary) do
            sorted_external_tools = context.shard.activate do
              table_name = ContextExternalTool.quoted_table_name
              contexts = Lti::ContextToolFinder.contexts_to_search(context)
              context_order = contexts.map.with_index { |c, i| "(#{c.id},'#{c.class.polymorphic_name}',#{i})" }.join(",")

              order_clauses = [
                # prefer tools that are not duplicates
                sort_by_sql_string("identity_hash != 'duplicate'"),
                # prefer tools from closer contexts
                "context_order.ordering",
                # prefer tools with more subdomains
                precedence_sql_string
              ]
              query = ContextExternalTool.where(context: contexts, lti_version: "1.1")
              query.joins(ContextExternalTool.sanitize_sql("INNER JOIN (values #{context_order}) as context_order (context_id, class, ordering)
              ON #{table_name}.context_id = context_order.context_id AND #{table_name}.context_type = context_order.class"))
                   .order(Arel.sql(ContextExternalTool.sanitize_sql_for_order(order_clauses.join(","))))
            end

            find_matching_tool(launch_url, sorted_external_tools)&.id
          end
        end

        ContextExternalTool.find_by(id:)
      end

      private

      # Sorts all tools in the context chain by a variety of criteria in SQL
      # as opposed to in memory, in order to make it easier to find a tool that matches
      # the given URL.
      #
      # Criteria:
      # * closer contexts preferred (Course over Account over Root Account etc)
      # * more specific subdomains preferred (sub.domain.instructure.com over instructure.com)
      # * LTI 1.3 tools preferred over 1.1 tools
      # * if preferred_tool_id is provided, moves that tool to the front
      # * if preferred_client_id is provided, only retrieves tools that came from that developer key
      # * if exclude_tool_id is provided, does not retrieve that tool
      #
      # Theoretically once this method is done, the very first tool to match the URL will be
      # the right tool, making it possible to eventually perform the rest of the URL matching
      # in SQL as well.
      def find_and_order_tools(
        context:,
        preferred_tool_id: nil,
        exclude_tool_id: nil,
        preferred_client_id: nil,
        original_client_id: nil,
        only_1_3: false,
        prefer_1_1: false
      )
        context.shard.activate do
          table_name = ContextExternalTool.quoted_table_name
          preferred_tool_id = Shard.integral_id_for(preferred_tool_id)
          contexts = Lti::ContextToolFinder.contexts_to_search(context)
          context_order = contexts.map.with_index { |c, i| "(#{c.id},'#{c.class.polymorphic_name}',#{i})" }.join(",")

          preferred_version = prefer_1_1 ? "1.1" : "1.3" # Hack required for one Turnitin case :( see git blame

          order_clauses = [
            # prefer 1.3 tools (unless told otherwise)
            sort_by_sql_string("lti_version = '#{preferred_version}'"),
            # prefer tools that are not duplicates
            sort_by_sql_string("identity_hash != 'duplicate'"),
            # prefer tools from closer contexts
            "context_order.ordering",
            # prefer tools with more subdomains
            precedence_sql_string
          ]
          # move preferred tool to the front when requested, and only if the id
          # is in an actual id format
          if preferred_tool_id
            order_clauses << sort_by_sql_string("#{table_name}.id = #{preferred_tool_id}")
          end

          # prefer tools from the original developer key when requested,
          # and over other order clauses like context
          prefer_original_client_id = context.root_account.feature_enabled?(:lti_find_external_tool_prefer_original_client_id)
          if prefer_original_client_id && (original_client_id = Shard.integral_id_for(original_client_id))
            order_clauses.prepend(sort_by_sql_string("developer_key_id = #{original_client_id}"))
          end

          query = ContextExternalTool.where(context: contexts).active
          query = query.where(lti_version: "1.3") if only_1_3
          query = query.where(developer_key_id: preferred_client_id) if preferred_client_id
          query = query.where.not(id: exclude_tool_id) if exclude_tool_id

          query.joins(ContextExternalTool.sanitize_sql("INNER JOIN (values #{context_order}) as context_order (context_id, class, ordering)
            ON #{table_name}.context_id = context_order.context_id AND #{table_name}.context_type = context_order.class"))
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
