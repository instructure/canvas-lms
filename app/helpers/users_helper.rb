# frozen_string_literal: true

# Copyright (C) 2024 - present Instructure, Inc.
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

module UsersHelper
  module_function

  def aggregated_login_details(pseudonyms)
    return Pseudonym.new if pseudonyms.empty?
    return pseudonyms.first if pseudonyms.length == 1

    p = Pseudonym.new
    p.last_request_at = pseudonyms.filter_map(&:last_request_at).max
    current_login = pseudonyms.select(&:current_login_at).max_by(&:current_login_at)
    p.current_login_at = current_login&.current_login_at
    p.current_login_ip = current_login&.current_login_ip

    last_login = pseudonyms.flat_map do |p2|
      [[p2.current_login_at, p2.current_login_ip],
       [p2.last_login_at, p2.last_login_ip]]
    end.reject { it.first.nil? }.sort_by(&:first)[-2]

    p.last_login_at = last_login&.first
    p.last_login_ip = last_login&.last
    p
  end

  def sso_icon_exists?(pseudonym)
    return false unless pseudonym

    partial = "shared/svg/svg_icon_#{pseudonym.authentication_provider&.auth_type}"
    lookup_context.exists?( # rubocop:disable Rails/WhereExists
      partial,
      [],
      true,
      formats: [:svg]
    ) && partial
  end
end
