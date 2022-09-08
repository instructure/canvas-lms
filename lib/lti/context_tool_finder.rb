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
# context, with other possible options.
module Lti
  class ContextToolFinder
    attr_reader :context, :options

    def initialize(context, options = {})
      @context = context
      @options = options
    end

    # Temporary shim functions until we can switch away from them
    def self.all_tools_for(*args)
      new(*args).single_shard_scope
    end

    def single_shard_scope
      placements = * options[:placements] || options[:type]
      contexts = []
      if options[:user]
        contexts << options[:user]
      end
      contexts.concat ContextExternalTool.contexts_to_search(context)
      return nil if contexts.empty?

      context.shard.activate do
        scope = ContextExternalTool.shard(context.shard).where(context: contexts).active
        scope = scope.placements(*placements)
        scope = scope.selectable if Canvas::Plugin.value_to_boolean(options[:selectable])
        scope = scope.where(tool_id: options[:tool_ids]) if options[:tool_ids].present?
        if Canvas::Plugin.value_to_boolean(options[:only_visible])
          scope = scope.visible(options[:current_user], context, options[:session], options[:visibility_placements], scope)
        end
        scope.order(ContextExternalTool.best_unicode_collation_key("context_external_tools.name")).order(Arel.sql("context_external_tools.id"))
      end
    end
  end
end
