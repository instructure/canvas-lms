#
# Copyright (C) 2020 - present Instructure, Inc.
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

# The superclass is at actionpack-5.2.4.1/lib/action_dispatch/middleware/session and this childclass overrides a few key
# methods to make the session cookie work with SameSite=none key as well as a backup legacy key as documented as an idea
# at https://web.dev/samesite-cookie-recipes/#handling-incompatible-clients We can probably go back to default after
# iOS12 is gone from the earth.
class SamesiteTransitionCookieStore < ActionDispatch::Session::EncryptedCookieStore
  def initialize(app, options = {})
    super(app, options)
    @legacy_key = options[:legacy_key]
  end

  def set_cookie(request, session_id, cookie)
    if cookie[:same_site]
      legacy_cookie = cookie.dup
      legacy_cookie[:same_site] = nil
      cookie_jar(request)[@legacy_key] = legacy_cookie
    end
    cookie_jar(request)[@key] = cookie
  end

  def get_cookie(req)
    super(req)
    cookie_jar(req)[@key] || cookie_jar(req)[@legacy_key]
  end
end
