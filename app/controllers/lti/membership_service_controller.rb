# Copyright (C) 2016 Instructure, Inc.
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
  class MembershipServiceController < ApplicationController
    before_action :require_context
    before_action :require_user
    before_action :check_authorized_action

    def course_index
      render_page_presenter
    end

    def group_index
      render_page_presenter
    end

    private

    def check_authorized_action
      authorized_action(@context, @current_user, :read)
    end

    def render_page_presenter
      @page = MembershipService::PagePresenter.new(@context,
                                                   @current_user,
                                                   request.base_url,
                                                   membership_service_params)

      render json: @page
    end

    def membership_service_params
      keys = %w(role page per_page)
      params.select { |k,_| keys.include?(k) }
    end
  end
end
