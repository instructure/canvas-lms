# frozen_string_literal: true

# Copyright (C) 2021 - present Instructure, Inc.
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

##
# Namespaces in a pulsar instance can be shared
# across clusters for topic replication, but need
# distinct namespaces in each cluster if you intend
# to support disjoint topic sets in each "same-purposed"
# namespace.  This class exists to ensure that if
# canvas has a regional code, it gets included as part of
# namespace specification in working with the message bus library.
#
# In an open-source/single-tenant canvas installation,
# the regional config will be nil, and no suffix need be applied.
module MessageBus
  class Namespace
    def initialize(namespace_base_string)
      @base_string = namespace_base_string
      @suffix = Canvas.region_code
    end

    def self.build(namespace)
      return namespace if namespace.is_a?(::MessageBus::Namespace)

      self.new(namespace)
    end

    # If somehow the consuming code is already injecting
    # the topic suffix, or if we mistakenly wrap a string
    # multiple times, don't continue to add suffixes.
    def to_s
      return @base_string if @suffix.nil?

      extension = "-#{@suffix}"
      return @base_string if @base_string[(-1 * (extension.length))..] == extension

      @base_string + extension
    end
  end
end
