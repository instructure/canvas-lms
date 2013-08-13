# Copyright (C) 2013 Instructure, Inc.
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
require 'set'

module Canvas
class RequestThrottle
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionController::Request.new(env)
    # workaround a rails bug where some ActionController::Request methods blow
    # up when using certain servers until request_uri is called once to set env['REQUEST_URI']
    request.request_uri

    if !allowed?(request)
      rate_limit_exceeded
    else
      @app.call(env)
    end
  end

  def allowed?(request)
    case
      # note that the whitelist isn't useful until usage-based throttling is
      # added, since anything not in the blacklist is allowed through anyway
      when whitelisted?(request)       then true
      when blacklisted?(request)       then false
      else
        true
    end
  end

  def blacklisted?(request)
    client_id = client_identifier(request)
    (client_id && self.class.blacklist.include?(client_id)) ||
      self.class.blacklist.include?(request.remote_ip)
  end

  def whitelisted?(request)
    client_id = client_identifier(request)
    return false unless client_id
    self.class.whitelist.include?(client_id)
    # we don't check the whitelist for remote_ip, whitelist is primarily
    # intended for grandfathering in some API users by access token
  end

  # This is cached on the request, so a theoretical change to the request
  # object won't be caught.
  def client_identifier(request)
    request.env['canvas.request_throttle.user_id'] ||=
      AuthenticationMethods.access_token(request, :GET) || AuthenticationMethods.user_id(request).to_s
  end

  def self.blacklist
    @blacklist ||= list_from_setting('request_throttle.blacklist')
  end

  def self.whitelist
    @whitelist ||= list_from_setting('request_throttle.whitelist')
  end

  def self.reload!
    @whitelist = @blacklist = nil
  end

  def self.list_from_setting(key)
    Set.new(Setting.get(key, '').split(',').map(&:strip))
  end

  def rate_limit_exceeded
    [ 403,
      { 'Content-Type' => 'text/plain; charset=utf-8' },
      ["403 #{Rack::Utils::HTTP_STATUS_CODES[403]} (Rate Limit Exceeded)\n"]
    ]
  end
end
end
