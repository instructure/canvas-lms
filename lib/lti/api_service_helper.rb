#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

module Lti
  module ApiServiceHelper
    def lti_authenticate
      @tool_proxy = ToolProxy.where(guid: oauth_consumer_key).first
      render_unauthorized_action unless @tool_proxy && oauth_authenticated_request?(@tool_proxy.shared_secret)
    end

    def oauth_authenticated_request?(secret)
      !!OAuth::Signature.build(request, :consumer_secret => secret).verify()
    end

    def oauth_consumer_key
      @oauth_consumer_key ||= OAuth::Helper.parse_header(request.authorization)['oauth_consumer_key']
    end

  end
end