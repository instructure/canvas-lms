# Copyright (C) 2014 Instructure, Inc.
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
  class AppCollator

    def self.bookmarked_collection(context, placements)
      external_tools_scope = ContextExternalTool.all_tools_for(context, selectable: placements.include?('module_item'))
      external_tools_collection = BookmarkedCollection.wrap(ExternalToolBookmarker, external_tools_scope)
      message_handler_scope = MessageHandler.for_context(context).by_message_types('basic-lti-launch-request')
      message_handler_collection = BookmarkedCollection.wrap(MessageHandlerBookmarker, message_handler_scope)
      BookmarkedCollection.merge(
        ['external_tools', external_tools_collection],
        ['message_handlers', message_handler_collection]
      )
    end

    def self.launch_definitions(collection, placements)
      collection.map do |o|
        case o
          when ContextExternalTool
            lti1_launch_definition(o, placements)
          when MessageHandler
            lti2_launch_definition(o, placements)
        end
      end
    end


    private

    def self.lti1_launch_definition(tool, placements)
      placement = 'resource_selection'
      definition = {
        definition_type: tool.class.name,
        definition_id: tool.id,
        name: tool.name,
        domain: tool.domain,
        placements: {}
      }
      placements.each do |p|
        if tool.has_placement?(p) || p == 'module_item'
          definition[:placements][p.to_sym] = {
            message_type: tool.extension_setting(placement, :message_type) || tool.extension_default_value(placement, :message_type),
            url: tool.extension_setting(placement, :url) || tool.extension_default_value(placement, :url),
            title: tool.label_for(placement, I18n.locale || I18n.default_locale.to_s),
          }
        end
      end
      definition
    end

    def self.lti2_launch_definition(message_handler, placements)
      {
        definition_type: message_handler.class.name,
        definition_id: message_handler.id,
        name: message_handler.resource_handler.name,
        domain: URI(message_handler.launch_path).host,
        placements: {
          module_item: {
            message_type: message_handler.message_type,
            url: message_handler.launch_path,
            title: message_handler.resource_handler.name,
          }
        }
      }
    end

    module MessageHandlerBookmarker
      def self.bookmark_for(message_handler)
        message_handler.resource_handler.name
      end

      def self.validate(bookmark)
        bookmark.is_a?(String)
      end

      def self.restrict_scope(scope, pager)
        if pager.current_bookmark
          name = pager.current_bookmark
          comparison = (pager.include_bookmark ? ">=" : ">")
          scope = scope.where(
            "name #{comparison} ?",
            name)
        end
        scope.order('lti_resource_handlers.name')
      end
    end

    module ExternalToolBookmarker
      def self.bookmark_for(external_tool)
        external_tool.name
      end

      def self.validate(bookmark)
        bookmark.is_a?(String)
      end

      def self.restrict_scope(scope, pager)
        if pager.current_bookmark
          name = pager.current_bookmark
          comparison = (pager.include_bookmark ? ">=" : ">")
          scope = scope.where(
            "name #{comparison} ?",
            name)
        end
        scope.order(:name)
      end
    end

  end
end