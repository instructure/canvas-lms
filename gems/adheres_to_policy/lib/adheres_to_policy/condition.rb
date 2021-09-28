# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

module AdheresToPolicy
  class Condition
    attr_reader :given, :rights, :parent

    def initialize(given, parent = nil)
      @parent = parent
      @given = given
      @rights = Set.new
    end

    def can(right, *rights)
      @rights.merge([right, rights].flatten)
    end

    # Internal: Checks whether this condition currently holds for the specified
    # object.
    #
    # object    - The object to check
    # user      - The user passed to the condition to determine if they pass the
    #             condition.
    # session   - The session passed to the condition to determine if the user
    #             passes the condition.
    #
    # Examples
    #
    #   Condition.new(->(user) { true }).applies?(some_object, user, session)
    #   # => true
    #
    #   Condition.new(->(user, session){ false }).applies?(some_object, user, session)
    #   # => false
    #
    # Returns true or false on whether the user passes the condition.
    def applies?(object, user, session)
      return false if parent && !parent.applies?(object, user, session)

      if given.arity == 1
        object.instance_exec(user, &given)
      else
        object.instance_exec(user, session, &given)
      end
    end
  end
end