# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

module SessionsTimeout

  # When loading an account, set the expire_after key if they have set up session
  # timeouts in the plugin settings. :expire_after is relative to Time.now and
  # should be a Integer. This will work it's way up to encrypted_cookie_store.rb
  # where the session's expire time is determined. EncryptedCookieStore is in a gem.
  def get_cookie(req)
    sessions_settings = Canvas::Plugin.find('sessions').settings

    # Grab settings, convert them to seconds.(everything is converted down to seconds)
    if sessions_settings && sessions_settings["session_timeout"].present?
      expire_after = sessions_settings["session_timeout"].to_f.minutes
      req.get_header(Rack::RACK_SESSION_OPTIONS)[:expire_after] = expire_after
    end

    super
  end
end
