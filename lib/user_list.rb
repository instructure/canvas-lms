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
  # Initialize a new UserList.
  #
  # open_registration is true, false, or nil. if nil, it defaults to root_account.open_registration?
  #
  # ==== Arguments
  # * <tt>list_in</tt> - either a comma/semi-colon/newline separated string or an array of paths
  # * <tt>options</tt> - a hash of additional optional data.
  #
  # ==== Options
  # * <tt>:search_method</tt> - configures how e-mails are handled. Defaults to :infer.
  # * <tt>:root_account</tt> - the account to use as the root account. Defaults to Account.default
  # * <tt>:initial_type</tt> - the initial enrollment type used for creating any new users.
  #                            Value is used when setting a new user's 'initial_enrollment_type'.
  #                            Defaults to +nil+.
  #
  # ==== Search Methods
  # The supported list of search methods.
  #
  # * <tt>:open</tt> - e-mails that don't match a pseudonym always create temporary users
  # * <tt>:closed</tt> - e-mails must belong to a user
  # * <tt>:preferred</tt> - if the e-mail belongs to a single user, that user
  #                         is used. otherwise a temporary user is created
  # * <tt>:infer</tt> - uses :open or :closed according to root_account.open_registration
  #
  def initialize(list_in, options = {})
    options.reverse_merge! :root_account => Account.default,
                           :search_method => :infer,
                           :initial_type => nil
    @options = options
    @addresses = []
    @errors = []
    @duplicate_addresses = []
    @root_account = @options[:root_account]
    @search_method = @options[:search_method]
    @search_method = (@root_account.open_registration? ? :open : :closed) if @search_method == :infer
    parse_list(list_in)
    resolve
  end
  
  attr_reader :errors, :addresses, :duplicate_addresses
  
  def as_json(*options)
    {
      :users => addresses.map { |a| a.reject { |k, v| k == :shard } },
      :duplicates => duplicate_addresses,
      :errored_users => errors
    }
  end

  def users
    existing = @addresses.select { |a| a[:user_id] }
    existing_users = Shard.partition_by_shard(existing, lambda { |a| a[:shard] } ) do |shard_existing|
      User.find_all_by_id(shard_existing.map { |a| a[:user_id] })
    end

    non_existing = @addresses.select { |a| !a[:user_id] }
    non_existing_users = non_existing.map do |a|
      user = User.new(:name => a[:name] || a[:address])
      cc = user.communication_channels.build(:path => a[:address], :path_type => 'email')
      cc.user = user
      user.workflow_state = 'creation_pending'
      user.initial_enrollment_type = User.initial_enrollment_type_from_text(@options[:initial_type])
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
    elsif path.include?('@') && (address = (Mail::Address.new(path)) rescue nil)
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
    all_account_ids = [@root_account.id] + @root_account.trusted_account_ids
    associated_shards = @addresses.map {|x| Pseudonym.associated_shards(x[:address].downcase) }.flatten.to_set
    # Search for matching pseudonyms
    Shard.partition_by_shard(all_account_ids) do |account_ids|
      next if GlobalLookups.enabled? && !associated_shards.include?(Shard.current)
      Pseudonym.active.
          select('unique_id AS address, (SELECT name FROM users WHERE users.id=user_id) AS name, user_id, account_id, sis_user_id').
          where("(LOWER(unique_id) IN (?) OR sis_user_id IN (?)) AND account_id IN (?)", @addresses.map {|x| x[:address].downcase}, @addresses.map {|x| x[:address]}, account_ids).
          map { |pseudonym| pseudonym.attributes.symbolize_keys }.each do |login|
        addresses = @addresses.select { |a| a[:address].downcase == login[:address].downcase ||
            a[:address] ==  login[:sis_user_id]}
        login.delete(:sis_user_id)
        addresses.each do |address|
          # already found a matching pseudonym
          if address[:user_id]
            # we already have the one from this-account, just go with it
            next if address[:account_id] == @root_account.local_id && address[:shard] == @root_account.shard
            # neither is from this-account, flag an error
            if (login[:account_id] != @root_account.local_id || Shard.current != @root_account.shard) &&
              (login[:user_id] != address[:user_id] || Shard.current != address[:shard])
              address[:type] = :pseudonym if address[:type] == :email
              address[:user_id] = false
              address[:details] = :non_unique
              address.delete(:name)
              address.delete(:shard)
              next
            end
            # allow this one to overrule, since it's from this-account
            address.delete(:details)
          end
          address.merge!(login)
          address[:type] = :pseudonym
          address[:shard] = Shard.current
        end
      end
    end if !@addresses.empty?

    # Search for matching emails (only if not open registration; otherwise there's no point - we just
    # create temporary users)
    emails = @addresses.select { |a| a[:type] == :email } if @search_method != :open
    associated_shards = @addresses.map {|x| CommunicationChannel.associated_shards(x[:address].downcase) }.flatten.to_set
    Shard.partition_by_shard(all_account_ids) do |account_ids|
      next if GlobalLookups.enabled? && !associated_shards.include?(Shard.current)
      Pseudonym.active.
          select('path AS address, users.name AS name, communication_channels.user_id AS user_id, communication_channels.workflow_state AS workflow_state').
          joins(:user => :communication_channels).
          where("communication_channels.workflow_state<>'retired' AND LOWER(path) IN (?) AND account_id IN (?)", emails.map { |x| x[:address].downcase}, account_ids).
          map { |pseudonym| pseudonym.attributes.symbolize_keys }.each do |login|
        addresses = emails.select { |a| a[:address].downcase == login[:address].downcase }
        addresses.each do |address|
          # if all we've seen is unconfirmed, and this one is active, we'll allow this one to overrule
          if address[:workflow_state] == 'unconfirmed' && login[:workflow_state] == 'active'
            address.delete(:user_id)
            address.delete(:details)
            address.delete(:shard)
          end
          # if we've seen an active, and this one is unconfirmed, skip it
          next if address[:workflow_state] == 'active' && login[:workflow_state] == 'unconfirmed'

          # ccs are not unique; just error out on duplicates
          # we're in a bit of a pickle if open registration is disabled, and there are conflicting
          # e-mails, but none of them are from a pseudonym
          if address.has_key?(:user_id) && (address[:user_id] != login[:user_id] || address[:shard] != Shard.current)
            address[:user_id] = false
            address[:details] = :non_unique
            address.delete(:name)
            address.delete(:shard)
          else
            address.merge!(login)
            address[:shard] = Shard.current
          end
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
    sms_account_ids = @search_method != :closed ? [@root_account] : all_account_ids
    Shard.partition_by_shard(sms_account_ids) do |account_ids|
      sms_scope = @search_method != :closed ? Pseudonym : Pseudonym.where(:account_id => account_ids)
      sms_scope.active.
          select('path AS address, users.name AS name, communication_channels.user_id AS user_id').
          joins(:user => :communication_channels).
          where("communication_channels.workflow_state='active' AND (#{smses.map{|x| "path LIKE '#{x[:address].gsub(/[^\d]/, '')}%'" }.join(" OR ")})").
          map { |pseudonym| pseudonym.attributes.symbolize_keys }.each do |sms|
        address = sms.delete(:address)[/\d+/]
        addresses = smses.select { |a| a[:address].gsub(/[^\d]/, '') == address }
        addresses.each do |address|
          # ccs are not unique; just error out on duplicates
          if address.has_key?(:user_id) && (address[:user_id] != login[:user_id] || address[:shard] != Shard.current)
            address[:user_id] = false
            address[:details] = :non_unique
            address.delete(:name)
            address.delete(:shard)
          else
            sms[:user_id] = sms[:user_id].to_i
            address.merge!(sms)
            address[:shard] = Shard.current
          end
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
        (@addresses.find { |a| a[:user_id] == address[:user_id] && a[:shard] == address[:shard] } ? @duplicate_addresses : @addresses) << address
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
