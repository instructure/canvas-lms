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

module Canvas
  class RedisWrapper < SimpleDelegator
    # We don't marshal for the data wrapper
    def set(key, value, options = nil)
      options ||= {}
      super(key, value, options.merge(raw: true))
    end

    def setnx(key, value, options = nil)
      options ||= {}
      super(key, value, options.merge(raw: true))
    end

    def setex(key, expiry, value, options = nil)
      options ||= {}
      super(key, expiry, value, options.merge(raw: true))
    end

    def get(key, options = nil)
      options ||= {}
      super(key, options.merge(raw: true))
    end

    def mget(*keys)
      options = keys.extract_options!
      super(*keys, options.merge(raw: true))
    end
  end
end
