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
  # open_registration is true, false, or nil. if nil, it defaults to root_account.open_registration?
  def initialize(string, root_account = nil, open_registration = nil)
    @addresses = []
    @errors = []
    @duplicate_addresses = []
    @root_account = root_account || Account.default
    @open_registration = open_registration
    @open_registration = @root_account.open_registration? if @open_registration.nil?
    parse_list(string)
    resolve
  end
  
  attr_reader :errors, :addresses, :duplicate_addresses
  
  def to_json(*options)
    {
      :users => addresses,
      :duplicates => duplicate_addresses,
      :errored_users => errors
    }.to_json
  end

  def users
    existing = @addresses.select { |a| a[:user_id] }
    existing_users = User.find_all_by_id(existing.map { |a| a[:user_id] }) unless existing.empty?
    existing_users ||= []

    non_existing = @addresses.select { |a| !a[:user_id] }
    non_existing_users = non_existing.map do |a|
      user = User.new(:name => a[:name] || a[:address])
      user.communication_channels.build(:path => a[:address], :path_type => 'email')
      user.workflow_state = 'creation_pending'
      user.save!
      user
    end
    existing_users + non_existing_users
  end

  private
  
  def parse_single_user(path)
    return if path.blank?

    # look for phone numbers by searching for 10 digits, allowing
    # any non-word characters
    number = path.gsub(/[^\d\w]/, '')
    if number =~ /^\d{10}$/
      type = :sms
      path = "(#{number[0,3]}) #{number[3,3]}-#{number[6,4]}"
    elsif path.include?('@') && (address = TMail::Address::parse(path) rescue nil)
      type = :email
      name = address.name
      path = address.address
    elsif path =~ Pseudonym.validates_format_of_login_field_options[:with]
      type = :pseudonym
    else
      @errors << { :address => path, :details => :unparseable }
      return
    end

    @addresses << { :name => name, :address => path, :type => type }
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
  
  def resolve
    pseudonyms = @addresses.select { |a| a[:type] == :pseudonym }
    emails = @addresses.select { |a| a[:type] == :email } unless @open_registration
    emails ||= []
    pseudonyms.concat emails

    # Search for matching pseudonyms
    @root_account.pseudonyms.connection.select_all("
        SELECT p.unique_id AS address, u.name AS name, p.user_id AS user_id
        FROM pseudonyms p INNER JOIN users u ON p.user_id = u.id
        WHERE p.account_id=#{@root_account.id}
          AND p.workflow_state='active'
          AND LOWER(p.unique_id) IN (#{pseudonyms.map {|x| Pseudonym.sanitize(x[:address].downcase)}.join(", ")})
        ").map(&:symbolize_keys).each do |login|
      addresses = @addresses.select { |a| [:pseudonym, :email].include?(a[:type]) && a[:address].downcase == login[:address].downcase }
      #sis_user_id = login.delete(:sis_user_id)
      addresses.each do |address|
        address.merge!(login)
        address[:type] = :pseudonym if address[:type] == :email
      end
    end if !pseudonyms.empty?

    # Search for matching emails (only if open registration is disabled)
    CommunicationChannel.connection.select_all("
        SELECT cc.path AS address, u.name AS name, cc.user_id AS user_id, cc.workflow_state AS workflow_state
        FROM communication_channels cc
          INNER JOIN users u ON cc.user_id=u.id
          INNER JOIN pseudonyms p ON p.user_id=u.id
        WHERE p.account_id=#{@root_account.id}
          AND p.workflow_state='active'
          AND cc.workflow_state<>'retired'
          AND LOWER(cc.path) IN (#{emails.map {|x| CommunicationChannel.sanitize(x[:address].downcase)}.join(", ")})
        ").map(&:symbolize_keys).each do |login|
      addresses = @addresses.select { |a| a[:type] == :email && a[:address].downcase == login[:address].downcase }
      addresses.each do |address|
        # if all we've seen is unconfirmed, and this one is active, we'll allow this one to overrule
        if address[:workflow_state] == 'unconfirmed' && login[:workflow_state] == 'active'
          address.delete(:user_id)
          address.delete(:details)
        end
        # if we've seen an active, and this one is unconfirmed, skip it
        next if address[:workflow_state] == 'active' && login[:workflow_state] == 'unconfirmed'

        # ccs are not unique; just error out on duplicates
        # we're in a bit of a pickle if open registration is disabled, and there are conflicting
        # e-mails, but none of them are from an SIS pseudonym
        if address.has_key?(:user_id)
          address[:user_id] = false
          address[:details] = :non_unique
        else
          address.merge!(login)
        end
      end
    end if !@open_registration && !emails.empty?

    # Search for matching SMS
    smses = @addresses.select { |a| a[:type] == :sms }
    CommunicationChannel.connection.select_all("
        SELECT communication_channels.path AS address, users.name AS name, communication_channels.user_id AS user_id
        FROM communication_channels INNER JOIN users ON communication_channels.user_id = users.id
        WHERE communication_channels.workflow_state='active'
          AND communication_channels.path_type='sms'
          AND (#{smses.map{|x| "path LIKE '#{x[:address].gsub(/[^\d]/, '')}%'" }.join(" OR ")})
        ").map(&:symbolize_keys).each do |sms|
      address = sms.delete(:address)[/\d+/]
      addresses = @addresses.select { |a| a[:type] == :sms && a[:address].gsub(/[^\d]/, '') == address }
      addresses.each do |address|
        # ccs are not unique; just error out on duplicates
        if address.has_key?(:user_id)
          address[:user_id] = false
          address[:details] = :non_unique
        else
          address.merge!(sms)
        end
      end
    end unless smses.empty?

    all_addresses = @addresses
    @addresses = []
    all_addresses.each do |address|
      # This is a temporary flag
      address.delete :workflow_state
      # Only allow addresses that we found a user, or that we can implicitly create the user
      if address[:user_id].present?
        (@addresses.find { |a| a[:user_id] == address[:user_id] } ? @duplicate_addresses : @addresses) << address
      elsif address[:type] == :email && @open_registration
        (@addresses.find { |a| a[:address].downcase == address[:address].downcase } ? @duplicate_addresses : @addresses) << address
      else
        @errors << { :address => address[:address], :details => (address[:details] || :not_found) }
      end
    end
  end
  
end
