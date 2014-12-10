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
  class ToolProxyController < ApplicationController
    before_filter :require_context
    before_filter :require_user

    def destroy
      if authorized_action(@context, @current_user, :update)
        Lti::ToolProxy.find(params[:tool_proxy_id]).update_attribute(:workflow_state, 'deleted')
        render json: '{"status":"success"}'
      end
    end

  end
end
