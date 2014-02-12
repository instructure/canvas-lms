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
  def to_atom
    self.map {|item| item.to_atom}
  end
  
  def cache_key
    if @cache_key
      @cache_key
    else
      value = self.collect{|element| ActiveSupport::Cache.expand_cache_key(element) }.to_param
      @cache_key = value unless self.frozen?
      value
    end
  end
  
  def clump_per(&block)
    self.inject({}) do |hash, item|
      mapped = block.call(item)
      hash[mapped] ||= []
      hash[mapped] << item
      hash
    end
  end
  
  def to_ics(name="", desc="")
    cal = Icalendar::Calendar.new
    # to appease Outlook
    cal.custom_property("METHOD","PUBLISH")
    cal.custom_property("X-WR-CALNAME",name)
    cal.custom_property("X-WR-CALDESC",desc)
    
    self.each do |item|
      event = item.to_ics(false)
      cal.add_event(event) if event
    end
    cal.to_ical
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
