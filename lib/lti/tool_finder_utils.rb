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
#

module Lti
  class ToolFinderUtils
    class << self
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

      def contexts_to_search(context, include_federated_parent: false)
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
    end
  end
end
