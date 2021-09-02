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

module Lti::Ims::Concerns
  module DeepLinkingModules
    extend ActiveSupport::Concern

    class InvalidContentItem < StandardError
      attr_reader :errors

      def initialize(errors)
        super
        @errors = errors
      end
    end

    def adding_module_item?
      params[:context_module_id].present?
    end

    def create_new_module?
      params[:create_new_module] && @context.root_account.feature_enabled?(:lti_deep_linking_module_index_menu)
    end

    def multiple_module_items?
      adding_module_item? && lti_resource_links.length > 1
    end

    def should_add_module_items?
      multiple_module_items? || create_new_module?
    end

    def require_context_update_rights
      return unless should_add_module_items?

      authorized_action(@context, @current_user, %i[manage_content update])
    end

    def require_tool
      return unless should_add_module_items?

      render_unauthorized_action if tool.blank?
    end

    def context_module
      @context_module ||= @context.context_modules.not_deleted.find(params[:context_module_id])
    end

    # the iframe property in a deep linking response can contain
    # link-specific launch dimensions, which if present overrides
    # the dimensions set on the tool
    def launch_dimensions(content_item)
      return nil unless content_item[:iframe]

      {
        selection_width: content_item[:iframe][:width],
        selection_height: content_item[:iframe][:height]
      }
    end

    def create_module
      @context_module =
        @context.context_modules.create!(name: 'New Module', workflow_state: 'unpublished')
    end

    def add_module_items
      create_module if create_new_module?

      lti_resource_links.each do |content_item|
        tag =
          context_module.add_item(
            {
              type: 'context_external_tool',
              id: tool.id,
              new_tab: 0,
              indent: 0,
              url: content_item[:url],
              title: content_item[:title],
              position: 1,
              link_settings: launch_dimensions(content_item),
              custom_params: Lti::DeepLinkingUtil.validate_custom_params(content_item[:custom])
            }
          )
        raise InvalidContentItem.new(tag.errors) unless tag&.valid?
      end
    end
  end
end
