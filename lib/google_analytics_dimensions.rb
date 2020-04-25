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

module GoogleAnalyticsDimensions
  # Prepare some contextual data to supplement a pageview hit when submitting to
  # GA to provide the analyst with more context surrounding the request:
  #
  #     {
  #       "enrollments": BoolMask.<student, teacher, observer>,
  #       "admin": BoolMask.<admin, site_admin>,
  #       "masquerading": Bool
  #     }
  #
  # Bool is a "0" or "1" value (encoded as strings) while "BoolMask" is a stream
  # of bools encoded also as a string. For example:
  #
  #     {
  #       "enrollments": "010", # a teacher
  #       "admin": "11",        # an admin and a site admin
  #       "masquerading": "0"   # nope
  #     }
  #
  # Encoding flags in such a way gives us the flexibility to represent future
  # values while also giving the analyst more freedom in reporting (GA supports
  # regex filtering.)
  def self.calculate(domain_root_account:, user:, real_user:)
    user_roles = user ? user.roles(domain_root_account) : []

    {
      admin: _encode_admin_status(roles: user_roles),
      enrollments: _encode_enrollments(roles: user_roles),
      masquerading: _encode_masquerading_status(user: user, real_user: real_user),
      user_id: _compute_non_compromising_user_id(user: user),
    }
  end

  # we only need some identifier that GA can utilize to track users across
  # different devices but we don't want it to know who the users are (e.g. their
  # canvas id)
  #
  # see https://support.google.com/analytics/answer/2992042?hl=en
  # see https://developers.google.com/analytics/devguides/collection/analyticsjs/cookies-user-id
  def self._compute_non_compromising_user_id(user:)
    user ? Canvas::Security.hmac_sha512(user.id.to_s)[0,32] : nil
  end

  def self._encode_admin_status(roles:)
    # again, look at User#user_roles for the definition
    %w[ admin root_admin ].map do |enrollment_type|
      roles.include?(enrollment_type) ? '1' : '0'
    end.join('')

  end

  def self._encode_enrollments(roles:)
    # keep in mind that some of these roles may be rolled up from different
    # enrollment types, see User#user_roles for the meat
    %w[ student teacher observer ].map do |enrollment_type|
      roles.include?(enrollment_type) ? '1' : '0'
    end.join('')
  end

  def self._encode_masquerading_status(user:, real_user:)
    real_user && real_user != user ? '1' : '0'
  end
end
