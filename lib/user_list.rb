# encoding: UTF-8
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

class UserList
  def initialize(string, root_account=nil, should_resolve_logins=true)
    @addresses = []
    @errors = []
    @duplicate_addresses = []
    @duplicate_logins = []
    @logins = []
    parse_list(string)
    resolve_logins root_account if should_resolve_logins && root_account
  end
  
  attr_reader :errors, :addresses, :duplicate_addresses, :logins, :duplicate_logins
  
  def to_json(*options)
    {
      :users => users,
      :duplicates => duplicate_addresses.collect{|a| {:name => a.name, :address => a.address} } + duplicate_logins,
      :errored_users => errors
    }.to_json
  end
  
  def users
    @addresses.collect{|a| {:name => a.name, :address => a.address}} + @logins
  end
  
  private
  
  def parse_single_user(string)
    return if string.blank?
    if string.include?('@')
      address = TMail::Address.parse(string) rescue nil
      if address
        if @addresses.any?{ |a| a.hash == address.hash  }
          @duplicate_addresses << address
        else
          @addresses << address
        end
      else
        @errors << string
      end
    else
      if @logins.any?{ |l| l[:login] == string }
        @duplicate_logins << { :login => string }
      else
        @logins << { :login => string }
      end
    end
  end
  
  def quote_ends(chars, i)
    loop do
      i = i + 1
      return false if i >= chars.size
      return false if chars[i] == '@'
      return true if chars[i] == '"'
    end
  end

  def parse_list(str)
    str = str.strip.gsub(/“|”/, "\"").gsub(/\n+/, ",").gsub(/\s+/, " ").gsub(/;/, ",") + ","
    chars = str.split("")
    user_start = 0
    in_quotes = false
    chars.each_with_index do |char, i|
      if not in_quotes
        case char
        when ','
          user_line = str[user_start, i - user_start].strip
          parse_single_user(user_line) unless user_line.blank?
          user_start = i + 1
        when '"'
          in_quotes = true if quote_ends(chars, i)
        end
      else
        in_quotes = false if char == '"'
      end
    end
  end
  
  def resolve_logins(root_account)
    return if @logins.empty?
    all_logins = @logins
    @logins = []
    
    valid_logins = {}
    Pseudonym.connection.select_all("
        SELECT pseudonyms.unique_id AS login, users.name AS name
        FROM pseudonyms, users
        WHERE pseudonyms.user_id = users.id
          AND pseudonyms.account_id = #{root_account.id}
          AND (#{Pseudonym.send(:sanitize_sql_array, Pseudonym.active.proxy_options[:conditions])})
          AND LOWER(pseudonyms.unique_id) in (#{all_logins.map{|x| Pseudonym.sanitize(x[:login].downcase)}.join(", ")})
        ").map(&:symbolize_keys).each do |login|
      valid_logins[login[:login]] = login
    end
    all_logins.each do |login|
      if valid_logins.has_key?(login[:login])
        @logins << valid_logins[login[:login]]
      else
        @errors << login[:login]
      end
    end
  end
  
end
