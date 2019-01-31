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
    include AdvantageServices

    included do
      before_action :verify_line_item_client_id_connection, only: %i[show update destroy]

      def line_item
        @_line_item ||= Lti::LineItem.where(id: params.fetch(:line_item_id, params[:id])).eager_load(:resource_link).take!
      end

      def context
        @_context ||= Course.not_completed.find(params[:course_id])
      end

      def user
        @_user ||= User.where(lti_context_id: params[:userId]).where.not(lti_context_id: nil).
          or(User.where(id: params.fetch(:userId, params[:user_id]))).take
      end

      def pagination_args
        params[:limit] ? { per_page: params[:limit] } : {}
      end

      def verify_user_in_context
        return if context.user_is_student? user
        render_error('User not found in course or is not a student', :unprocessable_entity)
      end

      def verify_line_item_client_id_connection
        render_error('Tool does not have permission to view line_item') unless line_item.client_id == developer_key.global_id
      end

      def verify_line_item_in_context
        line_item_context_id = Assignment.where(id: line_item.assignment_id).pluck(:context_id).first
        raise ActiveRecord::RecordNotFound if line_item_context_id != params[:course_id].to_i || context.blank?
        return if params[:resourceLinkId].blank? || line_item.resource_link.resource_link_id == params[:resourceLinkId]
        render_error("The specified LTI link ID is not associated with the line item.")
      end
    end
  end
end
