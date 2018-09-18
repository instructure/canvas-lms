#
# Copyright (C) 2018 - present Instructure, Inc.
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

module Lti::Ims::Helpers
  class MembershipsFinder
    include Api::V1::User

    attr_reader :context

    def initialize(context)
      @context = context
    end

    def find
      memberships(find_memberships)
    end

    protected

    def find_memberships
      memberships = memberships_scope.to_a
      user_json_preloads(memberships.map(&:user), true, { accounts: false })
      memberships
    end

    def memberships_scope
      throw 'Abstract Method'
    end

    def memberships(memberships)
      memberships.map { |m| membership(m) }
    end

    # Fix up the membership so it conforms to a std interface expected by Lti::Ims::NamesAndRolesSerializer
    def membership(membership)
      membership
    end

  end
end
