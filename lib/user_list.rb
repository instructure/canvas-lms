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
  # list_in is either a comma/semi-colon/newline separated string or an array of paths
  # open_registration is true, false, or nil. if nil, it defaults to root_account.open_registration?
  # search_method configures how e-mails are handled
  #   :open e-mails that don't match a pseudonym always create temporary users
  #   :closed e-mails must belong to a user
  #   :preferred if the e-mail belongs to a single user, that user is used. otherwise a temporary user is created
  #   :infer :open or :closed according to root_account.open_registration
  def initialize(list_in, root_account = nil, search_method = :infer)
    @addresses = []
    @errors = []
    @duplicate_addresses = []
    @root_account = root_account || Account.default
    @search_method = search_method
    @search_method = (@root_account.open_registration? ? :open : :closed) if search_method == :infer
    parse_list(list_in)
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
    if path =~ /^([^\d\w]*\d[^\d\w]*){10}$/
      type = :sms
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

  def parse_list(list_in)
    if list_in.is_a?(Array)
      list = list_in.map(&:strip)
      list.each{ |path| parse_single_user(path) }
    else
      str = list_in.strip.gsub(/“|”/, "\"").gsub(/\n+/, ",").gsub(/\s+/, " ").gsub(/;/, ",") + ","
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
  end
  
  def resolve
    # Search for matching pseudonyms
    Pseudonym.trusted_by_including_self(@root_account).active.find(:all,
      :select => 'unique_id AS address, users.name AS name, user_id, account_id',
      :joins => :user,
      :conditions => ["pseudonyms.workflow_state='active' AND LOWER(unique_id) IN (?)", @addresses.map {|x| x[:address].downcase}]
    ).map { |pseudonym| pseudonym.attributes.symbolize_keys }.each do |login|
      addresses = @addresses.select { |a| a[:address].downcase == login[:address].downcase }
      addresses.each do |address|
        # already found a matching pseudonym
        if address[:user_id]
          # we already have the one from this-account, just go with it
          next if address[:account_id] == @root_account.id
          # neither is from this-account, flag an error
          if login[:account_id] != @root_account.id && login[:user_id] != address[:user_id]
            address[:type] = :pseudonym if address[:type] == :email
            address[:user_id] = false
            address[:details] = :non_unique
            address.delete(:name)
            next
          end
          # allow this one to overrule, since it's from this-account
          address.delete(:details)
        end
        address.merge!(login)
        address[:type] = :pseudonym
      end
    end if !@addresses.empty?

    # Search for matching emails (only if not open registration; otherwise there's no point - we just
    # create temporary users)
    emails = @addresses.select { |a| a[:type] == :email } if @search_method != :open
    Pseudonym.trusted_by_including_self(@root_account).active.find(:all,
        :select => 'path AS address, users.name AS name, communication_channels.user_id AS user_id, communication_channels.workflow_state AS workflow_state',
        :joins => { :user => :communication_channels },
        :conditions => ["communication_channels.workflow_state<>'retired' AND LOWER(path) IN (?)", emails.map { |x| x[:address].downcase}]
    ).map { |pseudonym| pseudonym.attributes.symbolize_keys }.each do |login|
      addresses = emails.select { |a| a[:address].downcase == login[:address].downcase }
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
        # e-mails, but none of them are from a pseudonym
        if address.has_key?(:user_id) && address[:user_id] != login[:user_id]
          address[:user_id] = false
          address[:details] = :non_unique
          address.delete(:name)
        else
          address.merge!(login)
        end
      end
    end if @search_method != :open && !emails.empty?

    # Search for matching SMS
    smses = @addresses.select { |a| a[:type] == :sms }
    # reformat
    smses.each do |sms|
      number = sms[:address].gsub(/[^\d\w]/, '')
      sms[:address] = "(#{number[0,3]}) #{number[3,3]}-#{number[6,4]}"
    end
    sms_scope = @search_method != :closed ? Pseudonym : Pseudonym.trusted_by_including_self(@root_account)
    sms_scope.active.find(:all,
        :select => 'path AS address, users.name AS name, communication_channels.user_id AS user_id',
        :joins => { :user => :communication_channels },
        :conditions => "communication_channels.workflow_state='active' AND (#{smses.map{|x| "path LIKE '#{x[:address].gsub(/[^\d]/, '')}%'" }.join(" OR ")})"
    ).map { |pseudonym| pseudonym.attributes.symbolize_keys }.each do |sms|
      address = sms.delete(:address)[/\d+/]
      addresses = smses.select { |a| a[:address].gsub(/[^\d]/, '') == address }
      addresses.each do |address|
        # ccs are not unique; just error out on duplicates
        if address.has_key?(:user_id) && address[:user_id] != login[:user_id]
          address[:user_id] = false
          address[:details] = :non_unique
          address.delete(:name)
        else
          sms[:user_id] = sms[:user_id].to_i
          address.merge!(sms)
        end
      end
    end unless smses.empty?

    all_addresses = @addresses
    @addresses = []
    all_addresses.each do |address|
      # This is temporary working data
      address.delete :workflow_state
      address.delete :account_id
      # Only allow addresses that we found a user, or that we can implicitly create the user
      if address[:user_id].present?
        (@addresses.find { |a| a[:user_id] == address[:user_id] } ? @duplicate_addresses : @addresses) << address
      elsif address[:type] == :email && @search_method == :open
        (@addresses.find { |a| a[:address].downcase == address[:address].downcase } ? @duplicate_addresses : @addresses) << address
      else
        if @search_method == :preferred && (address[:details] == :non_unique || address[:type] == :email)
          address.delete :user_id
          (@addresses.find { |a| a[:address].downcase == address[:address].downcase } ? @duplicate_addresses : @addresses) << address
        else
          @errors << { :address => address[:address], :type => address[:type], :details => (address[:details] || :not_found) }
        end
      end
    end
  end
  
end
