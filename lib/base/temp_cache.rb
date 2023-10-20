# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

class TempCache
  # tl;dr wrap code around an `enable` block
  # and then cache pieces that would otherwise get called over and over again
  def self.enable
    if @enabled
      yield
    else
      begin
        clear
        @enabled = true
        yield
      ensure
        @enabled = false
        clear
      end
    end
  end

  def self.clear
    @cache = {}
  end

  def self.create_key(*args)
    args.map do |arg|
      case arg
      when Array
        create_key(*arg)
      when ActiveRecord::Base
        arg.global_asset_string
      else
        arg.to_s
      end
    end.join("/")
  end

  def self.cache(*args)
    if @enabled
      key = create_key(*args)
      if @cache.key?(key)
        @cache[key]
      else
        @cache[key] = yield
      end
    else
      yield
    end
  end
end
