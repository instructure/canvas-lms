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

class EmailList
  def initialize(string)
    @addresses = []
    @errors = []
    @duplicates = []
    parse_list(string)
  end
  
  attr_reader :addresses, :errors, :duplicates
  
  def parse_single_address(string, original_string)
    #for some reason TMail thinks that things like "adsf" are valid email addresses
    begin
      temp = TMail::Address.parse(string)
    rescue
      # try to handle things like "Bob O'Connor <boconnor@pcschools.us>"
      temp = TMail::Address.parse(original_string) rescue nil
    end
    if temp && string.include?('@')
      if @addresses.any?{ |a| a.hash == temp.hash  }
        @duplicates << temp
      else
        @addresses.push temp         
      end
    else
      @errors.push string
    end
  end
  
  def parse_list(str)
    addresses = []
    at_index = 0
    comma_index = 0
    last_comma = 0
    old_str = str
    str = str.strip.gsub(/“|”|'|“/, "\"").gsub(/\n+/, ",").gsub(/\s+/, " ")
    str.split("").each_with_index do |char, i|
      if char == '@'
        at_index = i;
      end
      if char == ','
        comma_index = i
      end
      if (comma_index > at_index && at_index > 0)
        parse_single_address(str[last_comma, comma_index - last_comma], old_str[last_comma, comma_index - last_comma])
        last_comma = comma_index + 1
        at_index = 0
      end
      if i == (str.length - 1)
        parse_single_address(str[last_comma, str.length - last_comma], old_str[last_comma, str.length - last_comma])
      end
    end
  end
  
  def to_json(*options)
    {
      :addresses => addresses.collect{|a| {:name => a.name, :address => a.address} },
      :duplicates => duplicates.collect{|a| {:name => a.name, :address => a.address} },
      :errored_addresses => errors
    }.to_json
  end
  
end
