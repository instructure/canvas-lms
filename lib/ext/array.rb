#
# Copyright (C) 2011 Instructure, Inc.
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

class Array
  def cache_key
    if @cache_key
      @cache_key
    else
      value = self.collect{|element| ActiveSupport::Cache.expand_cache_key(element) }.to_param
      @cache_key = value unless self.frozen?
      value
    end
  end

  # backport from ActiveSupport 3.x
  # Like uniq, but using a criteria given by a block, similar to sort_by
  unless method_defined?(:uniq_by)
    def uniq_by
      hash, array = {}, []
      each { |i| hash[yield(i)] ||= (array << i) }
      array
    end
  end
end
