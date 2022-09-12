# frozen_string_literal: true

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
#

# Abstraction on scopes which cannot be joined into one scope (for instance,
# they involve different shards) that implements many methods a scope would
# implement.
# NOTE: if scopes have an "ORDER BY" that would likely have to reimplemented
# with a ruby sort.
module Lti
  class ScopeUnion
    attr_reader :scopes

    def initialize(scopes)
      @scopes = scopes
    end

    def exists?
      scopes.any?(&:exists?)
    end
  end
end
