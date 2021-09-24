# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

module Login
  class CleverController < Oauth2Controller
    def create
      # Clever does an insecure half-flow OAuth2 for "Instant Login";
      # catch when they do this, and start the flow from the beginning.
      # This is sufficient to prevent the attack described at
      # http://www.twobotechnologies.com/blog/2014/02/importance-of-state-in-oauth2.html
      # (because an attacker would be trying to inject his own state param,
      # and starting the login process over will generate a new CSRF nonce)
      if !params[:state]
        return redirect_to(clever_login_url)
      end
      super
    end

    # we have to send to our own special callback URL
    def oauth2_login_callback_url
      clever_callback_url
    end
  end
end
