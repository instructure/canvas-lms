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

require "json/jwt"

module Lti
  module IMS
    class DeepLinkingController < ApplicationController
      protect_from_forgery except: [:deep_linking_response], with: :exception

      include Lti::IMS::Concerns::DeepLinkingServices
      include Lti::IMS::Concerns::DeepLinkingModules

      before_action :require_context
      before_action :validate_jwt
      before_action :require_context_update_rights
      before_action :require_tool

      def deep_linking_response
        # one single non-line item content item for an existing module using
        # the module item selection dialog should:
        # * not create a resource link
        # * not reload the page
        if for_placement?(:link_selection) && lti_resource_links.length == 1 && !add_assignment?
          render_content_items(reload_page: false)
          return
        end

        # to prepare for further UI processing, content items that don't need resources
        # like module items or assignments created now should:
        # * have resource links associated with them
        # * not reload the page
        unless create_resources_from_content_items?
          lti_resource_links.each do |content_item|
            resource_link = Lti::ResourceLink.create_with(context, tool, content_item[:custom], content_item[:url])
            content_item[:lookup_uuid] = resource_link&.lookup_uuid
          end

          render_content_items(reload_page: false)
          return
        end

        # deep linking on the new/edit assignment page should:
        # * only use the first content item to create an assignment
        # * not create a new module
        # * reload the page
        if for_placement?(:assignment_selection)
          unless @context.root_account.feature_enabled? :lti_assignment_page_line_items
            render_content_items(reload_page: false)
            return
          end

          item_for_assignment = lti_resource_links.first
          if allow_line_items? && item_for_assignment.key?(:lineItem) && validate_line_item!(item_for_assignment)
            create_update_assignment!(item_for_assignment, params[:assignment_id])
          end

          render_content_items(items: [item_for_assignment])
          return
        end

        # create and validate assignments for content items with line items,
        # which will be added to a module later if necessary
        lti_resource_links.each do |content_item|
          next unless allow_line_items? && content_item.key?(:lineItem)
          next unless validate_line_item!(content_item)

          create_update_assignment!(content_item)
        end

        # receiving only invalid content items should:
        # * not create a new module
        # * not create any assignments
        # * show these errors to the user
        # * reload the page
        if lti_resource_links.all? { |item| item.key?(:errors) }
          render_content_items
          return
        end

        # creating only assignments from the assigments page should:
        # * not create a new module
        # * reload the page
        if for_placement?(:course_assignments_menu) && allow_line_items? && lti_resource_links.all? { |item| item.key?(:lineItem) }
          render_content_items
          return
        end

        # creating mixed content (module items and/or assignments) from the modules
        # or assignments pages should:
        # * create a new module or use existing one
        # * add valid content items to this module
        # * show any errors to the user
        # * reload the page
        context_module = if create_new_module?
                           @context.context_modules.create!(name: I18n.t("New Content From App"), workflow_state: "unpublished")
                         else
                           @context.context_modules.not_deleted.find(params[:context_module_id])
                         end

        lti_resource_links.each do |content_item|
          if allow_line_items? && content_item.key?(:lineItem)
            next if content_item[:errors]

            context_module.add_item({ type: "assignment", id: content_item[:assignment_id] })
          else
            context_module.add_item(build_module_item(content_item))
          end
        end

        render_content_items
      end

      private

      def for_placement?(placement)
        params[:placement]&.to_sym == placement
      end

      def render_content_items(items: content_items, reload_page: true)
        js_env({
                 deep_link_response: {
                   content_items: items,
                   msg: messaging_value("msg"),
                   log: messaging_value("log"),
                   errormsg: messaging_value("errormsg"),
                   errorlog: messaging_value("errorlog"),
                   ltiEndpoint: polymorphic_url([:retrieve, @context, :external_tools]),
                   reloadpage: reload_page
                 }.compact
               })

        render layout: "bare"
      end

      def require_context_update_rights
        return unless create_resources_from_content_items?

        authorized_action(@context, @current_user, %i[manage_content update])
      end

      def require_tool
        return unless create_resources_from_content_items?

        render_unauthorized_action if tool.blank?
      end
    end
  end
end
