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

# A class that includes this module is marked as "migratable" from LTI 1.1 to 1.3.
# It is up to the class to implement the migration logic. The class should be careful
# to migrate both directly and indirectly associated items. See the following for examples:
# @see ContentTag
# @see Assignment
module Lti::Migratable
  class NotImplemented < StandardError; end

  def self.included(base)
    base.class_eval do
      # @param [ActiveRecord::Relation<self>] base_scope The base scope to filter
      # @param [Account|Course] context The context to filter the base scope by
      # @return [ActiveRecord::Relation<self>] The scope that now includes all items within the context.
      # handles contexts of Course, root Account, and sub Account properly.
      def self.scope_to_context(base_scope, context)
        case context
        when Course
          base_scope.where(context:)
        when Account
          if context.root_account? && has_attribute?(:root_account_id)
            base_scope.where(root_account_id: context.id)
          else
            base_scope.where(context: context.associated_courses.active)
          end
        end
      end

      # @param [Integer] tool_id The ID of the LTI 1.1 tool that the resource is indirectly
      # associated with
      # @return [ActiveRecord::Relation<self>] The associated items
      # Should return all items that have a foreign key reference to the tool, or are
      # otherwise directly linked by id.
      # Scope will be filtered by context later
      def self.directly_associated_items(_tool_id)
        raise NotImplemented
      end

      # @param [Integer] tool_id The ID of the LTI 1.1 tool that the resource is indirectly
      # associated with
      # @return [ActiveRecord::Relation<self>] The associated items
      # Should return all items that could be related to the tool, mostly via url.
      # Scope will be filtered by context later
      def self.indirectly_associated_items(_tool_id)
        raise NotImplemented
      end

      # @param [Array<Integer>] ids The IDs of the resources to fetch for this batch
      # @yieldparam [self] item
      def self.fetch_direct_batch(_ids, &)
        raise NotImplemented
      end

      # @param [Integer] tool_id The ID of the LTI 1.1 tool that the resource is indirectly
      # associated with
      # @param [Array<Integer>] ids The IDs of the resources to fetch for this batch
      # @yieldparam [self] item
      def self.fetch_indirect_batch(_tool_id, _new_tool_id, _ids, &)
        raise NotImplemented
      end
    end
  end

  # Migrate this resource from LTI 1.1 to 1.3. This method should be idempotent.
  # @param [ContextExternalTool] tool The 1.3 tool that this resource should be associated with somehow.
  def migrate_to_1_3_if_needed!(_tool)
    raise NotImplemented
  end
end
