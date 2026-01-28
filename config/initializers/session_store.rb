# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

# Be sure to restart your server when you modify this file.

require_dependency "setting"

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
begin
  secret = Setting.get("session_secret_key", SecureRandom.hex(64), set_if_nx: true)
rescue
  # The database may not exist yet
  secret = SecureRandom.hex(64)
end

base_config = {
  key: "_normandy_session",
  secret:
}
# Only use same_site :none in environments where we can use secure cookies, as browsers otherwise don't accept it
if Rails.application.config.force_ssl
  base_config[:same_site] = :none
  base_config[:secure] = true
end
config = base_config.merge((Canvas.load_config_from_consul("session_store", failsafe_cache: true) || {}).symbolize_keys)

# :expire_after is the "true" option, and :expires is a legacy option, but is applied
# to the cookie after :expire_after is, so by setting it to nil, we force the lesser
# of session expiration or expire_after
config[:expire_after] ||= 1.day
config[:expires] = nil
config[:logger] = Rails.logger

Autoextend.hook(:EncryptedCookieStore, :SessionsTimeout)

CanvasRails::Application.config.session_store(:enhanced_cookie_store, **config)
CanvasRails::Application.config.secret_token = config[:secret]
