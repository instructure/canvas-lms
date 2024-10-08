# frozen_string_literal: true

# Copyright (C) 2022 - present Instructure, Inc.
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

# This middleware removes the `sentry-trace` header unless the request's `Referrer` header is the same origin as the
# hostname of the request. This is to prevent the pollution of Sentry by associating requests with trace IDs from third
# parties.
class SentryTraceScrubber
  def initialize(app)
    @app = app
  end

  def call(env)
    if (ref = env["HTTP_REFERRER"])
      begin
        referrer = URI.parse(ref)
      rescue URI::InvalidURIError
        # ignore
      end
    end
    request = Rack::Request.new(env)

    # Remove the sentry-trace header unless it's a same-origin request
    env.delete("HTTP_SENTRY_TRACE") unless request.host == referrer&.host

    @app.call(env)
  end
end
