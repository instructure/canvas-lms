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
  class AppLaunchCollator
    def self.scopes(context, placements)
      [
        ContextExternalTool.all_tools_for(context).placements(*placements),
        MessageHandler.for_context(context).has_placements(*placements)
          .by_message_types('basic-lti-launch-request')
      ]
    end

    def self.bookmarked_collection(context, placements)
      external_tools, message_handlers = scopes(context, placements)
      external_tools = BookmarkedCollection.wrap(ExternalToolNameBookmarker, external_tools)
      message_handlers = BookmarkedCollection.wrap(MessageHandlerNameBookmarker, message_handlers)
      BookmarkedCollection.merge(
        ['external_tools', external_tools],
        ['message_handlers', message_handlers]
      )
    end

    def self.any?(context, placements)
      external_tools, message_handlers = scopes(context, placements)
      external_tools.exists? || message_handlers.exists?
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
      definition = {
        definition_type: tool.class.name,
        definition_id: tool.id,
        name: tool.label_for(placements.first, I18n.locale),
        description: tool.description,
        domain: tool.domain,
        placements: {}
      }
      placements.each do |p|
        if tool.has_placement?(p)
          definition[:placements][p.to_sym] = {
            message_type: tool.extension_setting(p, :message_type) || tool.extension_default_value(p, :message_type),
            url: tool.extension_setting(p, :url) || tool.extension_default_value(p, :url),
            title: tool.label_for(p, I18n.locale || I18n.default_locale.to_s),
          }
          if p.to_sym == :resource_selection || definition[:placements][p.to_sym][:message_type] == 'ContentItemSelection'
            definition[:placements][p.to_sym][:selection_width] = tool.extension_setting(:resource_selection, :selection_width)
            definition[:placements][p.to_sym][:selection_height] = tool.extension_setting(:resource_selection, :selection_height)
          end
        end
      end
      definition
    end

    def self.lti2_launch_definition(message_handler, placements)
      {
        definition_type: message_handler.class.name,
        definition_id: message_handler.id,
        name: message_handler.resource_handler.name,
        description: message_handler.resource_handler.description,
        domain: URI(message_handler.launch_path).host,
        placements: self.lti2_placements(message_handler, placements)
      }
    end

    def self.lti2_placements(message_handler, placements)
      resource_placements = message_handler.placements.pluck(:placement)
      valid_placements = resource_placements.present? ? resource_placements & placements : ResourcePlacement::DEFAULT_PLACEMENTS
      valid_placements.each_with_object({}) { |p, hsh| hsh[p.to_sym] = lti2_placement(message_handler) }
    end

    def self.lti2_placement(message_handler)
      {
        message_type: message_handler.message_type,
        url: message_handler.launch_path,
        title: message_handler.resource_handler.name
      }
    end
  end
end
