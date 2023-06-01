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
# with a ruby sort. (See ContextToolFinder#all_tools_sorted_array)
module Lti
  class ScopeUnion
    attr_reader :scopes

    def initialize(scopes)
      @scopes = scopes
    end

    def exists?
      scopes.any?(&:exists?)
    end

    def to_unsorted_array
      scopes.flat_map(&:to_a)
    end

    # Looks at each shard in order. (In ContextToolFinder, the first shard is
    # the one the context is on, rather than a federated parent shard)
    def take
      scopes.each do |scope|
        taken = scope.take
        return taken if taken
      end
      nil
    end

    def pluck(*args)
      scopes.inject([]) { |agg, scope| agg.concat(scope.pluck(*args)) }
    end

    def each(&)
      scopes.each do |scope|
        scope.each(&)
      end
    end
  end
end
