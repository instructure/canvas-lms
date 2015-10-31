#
# Copyright (C) 2011 Instructure, Inc.
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

require 'securerandom'

class RequestContextGenerator
  def initialize(app)
    @app = app
  end

  def call(env)
    request_id = SecureRandom.uuid

    # rack.session.options (where the session_id is saved by our session
    # store) isn't availalbe at this point in the middleware stack. It is
    # lazily loaded the first time the session is accessed, so we won't get
    # session_ids in the log on the very first request (usually loading the
    # login page).  It is written out to a cookie so that we can pick it up for
    # logs in subsequent requests. See RequestContextSession, we can't write it
    # to a cookie in this middleware because the cookie header has already been
    # written by the time this app.call returns.
    session_id = ActionDispatch::Request.new(env).cookie_jar[:log_session_id]
    meta_headers = ""
    Thread.current[:context] = {
      request_id:   request_id,
      session_id:   session_id,
      meta_headers: meta_headers,
    }

    status, headers, body = @app.call(env)

    # The session id may have been reset in the request, in which case
    # we want to log the new one,
    session_id = (env['rack.session.options'] || {})[:id]
    headers['X-Session-Id'] = session_id if session_id
    headers['X-Request-Context-Id'] = request_id
    headers['X-Canvas-Meta'] = meta_headers if meta_headers.present?

    [ status, headers, body ]
  end

  def self.request_id
    Thread.current[:context].try(:[], :request_id)
  end

  def self.add_meta_header(name, value)
    return if value.blank?
    meta_headers = Thread.current[:context].try(:[], :meta_headers)
    return if !meta_headers
    meta_headers << "#{name}=#{value};"
  end

  def self.store_request_meta(request, context)
    self.add_meta_header("o", request.path_parameters[:controller])
    self.add_meta_header("n", request.path_parameters[:action])
    if context
      self.add_meta_header("t", context.class)
      self.add_meta_header("i", context.id)
    end
  end

  def self.store_page_view_meta(page_view)
    self.add_meta_header("x", page_view.interaction_seconds)
    self.add_meta_header("p", page_view.participated? ? "t" : "f")
    self.add_meta_header("e", page_view.asset_user_access_id)
  end
end
