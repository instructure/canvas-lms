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


class RequestContextGenerator
  def initialize(app)
    @app = app
  end

  def call(env)
    # This is a crummy way to plumb this data through to the logger
    request_id = CanvasUUID.generate
    session_id = (env['rack.session.options'] || {})[:id]
    Thread.current[:context] = {
      :request_id => request_id,
      :session_id => session_id
    }
    
    status, headers, body = @app.call(env)

    # The session id may have been reset in the request, in which case
    # we want to log the new one,
    session_id = (env['rack.session.options'] || {})[:id]
    headers['X-Session-Id'] = session_id if session_id
    headers['X-Request-Context-Id'] = request_id

    [ status, headers, body ]
  end

  def self.request_id
    Thread.current[:context].try(:[], :request_id)
  end
end
