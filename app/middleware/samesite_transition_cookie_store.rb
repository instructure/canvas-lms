# frozen_string_literal: true

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
    super
    @legacy_key = options[:legacy_key]
  end

  def set_cookie(request, _session_id, cookie)
    if cookie[:same_site]
      legacy_cookie = cookie.dup
      legacy_cookie[:same_site] = nil
      cookie_jar(request)[@legacy_key] = legacy_cookie
    end
    cookie_jar(request)[@key] = cookie
  end

  def get_cookie(req)
    super
    cookie_jar(req)[@key] || cookie_jar(req)[@legacy_key]
  end

  # TODO: When we remove this samesite transition thing,
  # we probably still want to keep this useful logging
  # for diagnosing auth issues quickly.  Maybe rename the
  # store something else and keep it, dropping the
  # cookie accessor wrappers.
  def unmarshal(data, options = {})
    unmarshalled_data = nil
    begin
      unmarshalled_data = super
    rescue ArgumentError => e
      # if the data being provided is not formatted in such a way that
      # we can extract appropriately sized segments from it,
      # then this is an auth problem (bad cookie), not a real
      # exception.  We'll return nil as though the cookie
      # was unauthorized (and it is), and log the failure, but not explode because
      # handling this as some 4xx is more accurate than a 500.
      Canvas::Errors.capture_exception(:cookie_store, e, :info)
      return nil
    end
    if unmarshalled_data.nil? && data.present?
      Rails.logger.warn("[AUTH] Cookie data (present) failed to unmarshal. Inactivity timeout or invalid digest.")
    end
    unmarshalled_data
  end
end
