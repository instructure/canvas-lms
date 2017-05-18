#
# Copyright (C) 2016 - present Instructure, Inc.
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

class UserListV2
  # not really much better than the first one
  # stealing some things from it because I don't feel like reinventing the whole wheel
  # but with some key differences that would make it difficult to keep in one class

  # - only search on particular columns
  # - don't worry about whether we can create users or not: they either exist or they don't


  SEARCH_TYPES = %w{unique_id sis_user_id cc_path}.freeze

  def initialize(list_in, root_account: Account.default, search_type: nil, current_user: nil, can_read_sis: false)
    @errors = []
    @addresses = []

    @all_results = []
    @resolved_results = []
    @duplicate_results = []
    @missing_results = []

    @root_account = root_account
    @current_user = current_user
    @can_read_sis = can_read_sis
    raise "search_type must be one of #{SEARCH_TYPES}" unless SEARCH_TYPES.include?(search_type)

    parse_list(list_in)

    case search_type
    when "unique_id"
      resolve_by_unique_id
    when "sis_user_id"
      raise "cannot read sis ids" unless @can_read_sis
      resolve_by_sis_user_id
    when "cc_path"
      resolve_by_cc_path
    end
    resolve_duplicates_and_missing
  end

  attr_reader :errors, :addresses, :resolved_results, :duplicate_results, :missing_results

  include UserList::Parsing

  def as_json(*options)
    {
      :users => @resolved_results,
      :duplicates => @duplicate_results,
      :missing => @missing_results,
      :errors => @errors
    }
  end

  private

  def all_account_ids
    @all_account_ids ||= begin
      trusted_account_ids = @root_account.trusted_account_ids
      if @current_user && (!@current_user.associated_shards.include?(Account.site_admin.shard) ||
        !Account.site_admin.pseudonyms.active.merge(@current_user.pseudonyms).exists?)
        trusted_account_ids.delete(Account.site_admin.id)
      end
      [@root_account.id] + trusted_account_ids
    end
  end

  def restrict_shards
    return unless GlobalLookups.enabled?
    # we can use the global lookups to restrict our search to only the necessary shards

    all_shards = Set.new(all_account_ids.map{|id| Shard.shard_for(id)}.uniq)
    # however it doesn't seem like it makes much sense to all hit the global_lookups if we're looking on at most 2-3 shards
    return if all_shards.count <= Setting.get('global_lookups_shard_threshold', '3').to_i

    restricted_shards = Set.new
    restricted_shards << @root_account.shard
    @addresses.each do |address|
      restricted_shards.merge(yield(address[:address]))
      return if (all_shards - restricted_shards).empty? # no sense continuing on at this point
    end
    restricted_shards
  end

  def add_rows(rows, original_shard)
    rows.uniq!{|r| r[1]} # unique on user_id
    rows.each do |address, user_id, account_id, user_name, account_name|
      if Shard.current != original_shard
        user_id = Shard.global_id_for(user_id)
        account_id = Shard.global_id_for(account_id)
      end
      @all_results << {:address => address, :user_id => user_id, :user_name => user_name,
        :account_id => account_id, :account_name => account_name}
    end
  end

  def resolve_duplicates_and_missing
    grouped_results = @all_results.group_by{|r| @lowercase ? r[:address].downcase : r[:address]}

    grouped_results.each do |_a, results|
      if results.count == 1
        @resolved_results << results.first
      elsif results.uniq{|r| Shard.global_id_for(r[:user_id])}.count == 1
        @resolved_results << results.detect{|r| r[:account_id] == @root_account.id} || results.first # prioritize local result first
      else
        @duplicate_results << results
      end
    end
    add_additional_data_for_duplicates

    @addresses.each do |a|
      address = @lowercase ? a[:address].downcase : a[:address]
      unless grouped_results.key?(address)
        if name = a.delete(:name)
          a[:user_name] = name
        end
        @missing_results << a
      end
    end
  end

  def add_additional_data_for_duplicates
    return unless @duplicate_results.any?

    duplicate_user_ids = @duplicate_results.map{|set| set.map{|h| h[:user_id]}}.flatten.uniq
    user_map = User.where(:id => duplicate_user_ids).preload(:pseudonyms).to_a.index_by(&:id)

    @duplicate_results.each do |set|
      set.each do |dup_hash|
        user = user_map[dup_hash[:user_id]]

        dup_hash[:email] = user.email
        pseudonym = SisPseudonym.for(user, @root_account, type: :trusted, require_sis: false)
        if @can_read_sis
          dup_hash[:sis_user_id] = pseudonym.sis_user_id if pseudonym
        end
        dup_hash[:login_id] = pseudonym.unique_id if pseudonym
      end
    end
  end

  def search_for_results(restricted_shards)
    original_shard = Shard.current
    Shard.partition_by_shard(all_account_ids) do |account_ids|
      next if restricted_shards && !restricted_shards.include?(Shard.current)
      add_rows(yield(account_ids), original_shard)
    end
  end

  def resolve_by_unique_id
    restricted_shards = restrict_shards do |address|
      Pseudonym.associated_shards_for_column(:unique_id, address)
    end

    unique_ids = @addresses.map{|a| a[:address].downcase}

    search_for_results(restricted_shards) do |account_ids|
      Pseudonym.active.where(:account_id => account_ids).
        where("LOWER(unique_id) IN (?)", unique_ids).joins(:user, :account).
        pluck(:unique_id, :user_id, :account_id, 'users.name', 'accounts.name')
    end
    @lowercase = true
  end

  # NOTE: sis_user_id includes integration_id because nothing in this forsaken world makes any sense
  def resolve_by_sis_user_id
    restricted_shards = restrict_shards do |address|
      Pseudonym.associated_shards_for_column(:sis_user_id, address) +
        Pseudonym.associated_shards_for_column(:integration_id, address)
    end

    ids = @addresses.map{|a| a[:address]}
    search_for_results(restricted_shards) do |account_ids|
      rows = Pseudonym.active.where(:account_id => account_ids, :sis_user_id => ids).joins(:user, :account).
        pluck(:sis_user_id, :user_id, :account_id, 'users.name', 'accounts.name')
      rows += Pseudonym.active.where(:account_id => account_ids, :integration_id => ids).joins(:user, :account).
        pluck(:integration_id, :user_id, :account_id, 'users.name', 'accounts.name')
      rows
    end
  end

  def resolve_by_cc_path
    restricted_shards = restrict_shards do |address|
      CommunicationChannel.associated_shards(address)
    end

    sms_paths = []
    sms_path_header_map = {}
    email_paths = []
    @addresses.each do |a|
      if a[:type] == :sms
        path_header = a[:address].gsub(/[^\d]/, '')
        sms_path_header_map[path_header] = a[:address]
        sms_paths << path_header + "@%"
      else
        email_paths << a[:address].downcase
      end
    end

    search_for_results(restricted_shards) do |account_ids|
      rows = []
      if sms_paths.any?
        sms_rows = Pseudonym.active.where(:account_id => account_ids).joins(:user => :communication_channels).joins(:account).
          where("communication_channels.workflow_state<>'retired' AND path_type='sms' AND (#{(["path LIKE ?"] * sms_paths.count).join(" OR ")})", *sms_paths).
          pluck('communication_channels.path', :user_id, :account_id, 'users.name', 'accounts.name')
        sms_rows.each{|r| r[0] = sms_path_header_map[r[0].split("@").first]} # replace the actual path with the original address
        rows += sms_rows
      end
      rows += Pseudonym.active.where(:account_id => account_ids).joins(:user => :communication_channels).joins(:account).
        where("communication_channels.workflow_state<>'retired' AND path_type='email' AND LOWER(path) IN (?)", email_paths).
        pluck('communication_channels.path', :user_id, :account_id, 'users.name', 'accounts.name') if email_paths.any?
      rows
    end
    @lowercase = true
  end
end
