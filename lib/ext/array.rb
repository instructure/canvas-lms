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
  def to_csv(options = {})
    if all? { |e| e.respond_to?(:to_row) }
      header_row = first.export_columns(options[:format]).to_csv
      content_rows = map { |e| e.to_row(options[:format]) }.map(&:to_csv)
      ([header_row] + content_rows).join
    else
      FasterCSV.generate_line(self, options)
    end
  end

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
  
  def once_per(&block)
    finds = {}
    self.inject([]) do |array, item|
      mapped = block.call(item)
      found = finds[mapped]
      finds[mapped] = true
      array << item unless found
      array
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
  
  def count_per(&block)
    self.inject({}) do |hash, item|
      mapped = block.call(item)
      hash[mapped] ||= 0
      hash[mapped] += 1
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
  
  # Returns the tail of the array from +position+.
  #
  #   %w( a b c d ).from(0)  # => %w( a b c d )
  #   %w( a b c d ).from(2)  # => %w( c d )
  #   %w( a b c d ).from(10) # => nil
  #   %w().from(0)           # => nil
  def from(position)
    self[position..-1]
  end
  
  # Returns the beginning of the array up to +position+.
  #
  #   %w( a b c d ).to(0)  # => %w( a )
  #   %w( a b c d ).to(2)  # => %w( a b c )
  #   %w( a b c d ).to(10) # => %w( a b c d )
  #   %w().to(0)           # => %w()
  def to(position)
    self[0..position]
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
