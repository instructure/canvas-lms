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
  module GradebookServices
    extend ActiveSupport::Concern

    included do
      before_action :verify_tool_in_context, :verify_tool_permissions

      def line_item
        @_line_item ||= Lti::LineItem.find(params.fetch(:line_item_id, params[:id]))
      end

      def context
        @_context ||= Course.not_completed.find(params[:course_id])
      end

      def tool
        # TODO: hook this up to a real tool when 1.3 done
        Struct.new(:id).new(1)
      end

      def user
        @_user ||= User.where(lti_context_id: params[:userId]).where.not(lti_context_id: nil).
          or(User.where(id: params.fetch(:userId, params[:user_id]))).take
      end

      def pagination_args
        params[:limit] ? { per_page: params[:limit] } : {}
      end

      def verify_tool_in_context
        # TODO: remove once 1.3 security checks are added
        render_unauthorized_action if Rails.env.production?

        # TODO: render unauthorized if LTI 1.3 tool is not installed in the requested context
        context
      end

      def verify_tool_permissions
        # TODO: render unauthorized if the LTI 1.3 tool does not have the LineItem.url capability
        #       If the tool is using the decoupled model also verify it has additional capabilities
      end

      def verify_user_in_context
        return if context.user_is_student? user
        render_error('User not found in course or is not a student', :unprocessable_entity)
      end

      def verify_line_item_in_context
        line_item_context_id = Assignment.where(id: line_item.assignment_id).pluck(:context_id).first
        raise ActiveRecord::RecordNotFound if line_item_context_id != params[:course_id].to_i || context.blank?
        return if params[:ltiLinkId].blank? || line_item.resource_link.resource_link_id == params[:ltiLinkId]
        render_error("The specified LTI link ID is not associated with the line item.")
      end

      def render_error(message, status = :precondition_failed)
        error_response = {
          errors: {
            type: status,
            message: message
          }
        }
        render json: error_response, status: status
      end
    end
  end
end
