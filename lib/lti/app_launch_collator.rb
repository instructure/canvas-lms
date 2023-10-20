# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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
    CONTENT_MESSAGE_TYPES = %w[
      ContentItemSelection
      ContentItemSelectionRequest
      LtiDeepLinkingRequest
    ].freeze

    class << self
      def external_tools_for(context, placements, options = {})
        tools_options = {}
        if options[:current_user]
          tools_options[:current_user] = options[:current_user]
          tools_options[:user] = options[:current_user]
        end
        if options[:only_visible]
          tools_options[:only_visible] = options[:only_visible]
          tools_options[:session] = options[:session] if options[:session]
          tools_options[:visibility_placements] = placements
        end

        Lti::ContextToolFinder.all_tools_for(context, tools_options).placements(*placements)
      end

      def message_handlers_for(context, placements)
        MessageHandler.for_context(context).has_placements(*placements)
                      .by_message_types("basic-lti-launch-request")
      end

      def bookmarked_collection(context, placements, options = {})
        external_tools = external_tools_for(context, placements, options)
        external_tools = BookmarkedCollection.wrap(ExternalToolNameBookmarker, external_tools)

        message_handlers = message_handlers_for(context, placements)
        message_handlers = BookmarkedCollection.wrap(MessageHandlerNameBookmarker, message_handlers)

        BookmarkedCollection.merge(
          ["external_tools", external_tools],
          ["message_handlers", message_handlers]
        )
      end

      def any?(context, placements)
        external_tools = external_tools_for(context, placements)
        message_handlers = message_handlers_for(context, placements)
        external_tools.exists? || message_handlers.exists?
      end

      def launch_definitions(collection, placements)
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

      def selection_property_value(property, tool, placement, message_type)
        placement = placement.to_sym

        # Only return selection property if the message type offers content selection
        return unless CONTENT_MESSAGE_TYPES.include?(message_type) || placement == :resource_selection

        # For backward compatibility, check the "resource_selection" placement before the requested placement
        tool.extension_setting(:resource_selection, property) || tool.extension_setting(placement, property)
      end

      def lti1_launch_definition(tool, placements)
        definition = {
          definition_type: tool.class.name,
          definition_id: tool.id,
          url: tool.url,
          name: tool.label_for(placements.first, I18n.locale),
          description: tool.description,
          domain: tool.domain,
          placements: {}
        }
        placements.each do |p|
          next unless tool.has_placement?(p)

          definition[:placements][p.to_sym] = {
            message_type: tool.extension_setting(p, :message_type) || tool.extension_default_value(p, :message_type),
            url: tool.extension_setting(p, :url) || tool.extension_default_value(p, :url) || tool.extension_default_value(p, :target_link_uri),
            title: tool.label_for(p, I18n.locale || I18n.default_locale.to_s),
          }

          message_type = definition.dig(:placements, p.to_sym, :message_type)

          if (width = selection_property_value(:selection_width, tool, p, message_type))
            definition[:placements][p.to_sym][:selection_width] = width
          end

          if (height = selection_property_value(:selection_height, tool, p, message_type))
            definition[:placements][p.to_sym][:selection_height] = height
          end

          %i[launch_width launch_height].each do |property|
            if tool.extension_setting(p, property)
              definition[:placements][p.to_sym][property] = tool.extension_setting(p, property)
            end
          end
        end
        definition
      end

      def lti2_launch_definition(message_handler, placements)
        {
          definition_type: message_handler.class.name,
          definition_id: message_handler.id,
          name: message_handler.resource_handler.name,
          description: message_handler.resource_handler.description,
          domain: URI(message_handler.launch_path).host,
          placements: lti2_placements(message_handler, placements)
        }
      end

      def lti2_placements(message_handler, placements)
        resource_placements = message_handler.placements.pluck(:placement)
        valid_placements =
          if resource_placements.present?
            resource_placements & placements.map(&:to_s)
          else
            ResourcePlacement::LEGACY_DEFAULT_PLACEMENTS
          end
        valid_placements.each_with_object({}) { |p, hsh| hsh[p.to_sym] = lti2_placement(message_handler) }
      end

      def lti2_placement(message_handler)
        {
          message_type: message_handler.message_type,
          url: message_handler.launch_path,
          title: message_handler.resource_handler.name
        }
      end
    end
  end
end
