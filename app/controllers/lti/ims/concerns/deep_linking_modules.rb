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

    def adding_module_item?
      params[:context_module_id].present?
    end

    def multiple_module_items?
      adding_module_item? && content_items.length > 1
    end

    def valid_content_items?
      content_items.all? { |item| item[:type] == "ltiResourceLink" }
    end

    def context_module
      @context_module ||= @context.context_modules.not_deleted.find(params[:context_module_id])
    end

    # Renders if unauthorized so should be used in a before_action
    def add_module_items
      unless multiple_module_items? && valid_content_items?
        return
      end
      return unless authorized_action(context_module, @current_user, :update)
      return render_unauthorized_action if tool.blank?

      content_items.each do |content_item|
        # the iframe property in a deep linking response can contain
        # link-specific launch dimensions, which if present overrides
        # the dimensions set on the tool
        launch_dimensions = {
          selection_width: content_item[:iframe][:width],
          selection_height: content_item[:iframe][:height]
        } if content_item[:iframe]

        tag = context_module.add_item({
          type: 'context_external_tool',
          id: tool.id,
          new_tab: 0,
          indent: 0,
          url: content_item[:url],
          title: content_item[:title],
          position: 1,
          link_settings: launch_dimensions,
          custom_params: Lti::DeepLinkingUtil.validate_custom_params(content_item[:custom])
        })
        return render :json => tag.errors, :status => :bad_request unless tag&.valid?
        @context.touch
      end
    end
  end
end
