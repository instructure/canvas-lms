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

class EnhancedCookieStore < ActionDispatch::Session::EncryptedCookieStore
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
