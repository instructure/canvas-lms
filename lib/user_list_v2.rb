# frozen_string_literal: true

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
  class ParameterError < StandardError
    def response_status
      400
    end
  end

  # not really much better than the first one
  # stealing some things from it because I don't feel like reinventing the whole wheel
  # but with some key differences that would make it difficult to keep in one class

  # - only search on particular columns
  # - don't worry about whether we can create users or not: they either exist or they don't

  SEARCH_TYPES = %w[unique_id sis_user_id cc_path].freeze

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
    unless SEARCH_TYPES.include?(search_type)
      raise ParameterError, "search_type must be one of #{SEARCH_TYPES}"
    end

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

  def as_json(*)
    {
      users: @resolved_results,
      duplicates: @duplicate_results,
      missing: @missing_results,
      errors: @errors
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

    all_shards = Set.new(all_account_ids.map { |id| Shard.shard_for(id) }.uniq)
    # however it doesn't seem like it makes much sense to all hit the global_lookups if we're looking on at most 2-3 shards
    return if all_shards.count <= 3

    restricted_shards = Set.new
    restricted_shards << @root_account.shard
    @addresses.each do |address|
      restricted_shards.merge(yield(address[:address]))
      return if (all_shards - restricted_shards).empty? # no sense continuing on at this point
    end
    restricted_shards
  end

  def add_rows(rows, original_shard)
    rows.uniq! { |r| r[1] } # unique on user_id
    rows.each do |address, user_id, user_uuid, account_id, user_name, account_name|
      if Shard.current != original_shard
        user_id = Shard.relative_id_for(user_id, Shard.current, original_shard)
        account_id = Shard.relative_id_for(account_id, Shard.current, original_shard)
      end
      @all_results << { address:,
                        user_id:,
                        user_token: User.token(user_id, user_uuid),
                        user_name:,
                        account_id:,
                        account_name: }
    end
  end

  def resolve_duplicates_and_missing
    grouped_results = @all_results.group_by { |r| @lowercase ? r[:address].downcase : r[:address] }

    grouped_results.each_value do |results|
      if results.count == 1
        @resolved_results << results.first
      elsif results.uniq { |r| Shard.global_id_for(r[:user_id]) }.count == 1
        (@resolved_results << results.detect { |r| r[:account_id] == @root_account.id }) || results.first # prioritize local result first
      else
        @duplicate_results << results
      end
    end
    add_additional_data_for_duplicates

    @addresses.each do |a|
      address = @lowercase ? a[:address].downcase : a[:address]
      next if grouped_results.key?(address)

      if (name = a.delete(:name))
        a[:user_name] = name
      end
      @missing_results << a
    end
  end

  def add_additional_data_for_duplicates
    return unless @duplicate_results.any?

    duplicate_user_ids = @duplicate_results.map { |set| set.pluck(:user_id) }.flatten.uniq
    user_map = User.where(id: duplicate_user_ids).preload(:pseudonyms).to_a.index_by(&:id)

    @duplicate_results.each do |set|
      set.each do |dup_hash|
        user = user_map[dup_hash[:user_id]]

        dup_hash[:email] = user.email
        pseudonym = SisPseudonym.for(user, @root_account, type: :trusted, require_sis: false)
        if @can_read_sis && pseudonym
          dup_hash[:sis_user_id] = pseudonym.sis_user_id
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

    unique_ids = @addresses.map { |a| a[:address].downcase }

    search_for_results(restricted_shards) do |account_ids|
      Pseudonym.active.where(account_id: account_ids)
               .where("LOWER(unique_id) IN (?)", unique_ids).joins(:user, :account)
               .pluck(:unique_id, :user_id, "users.uuid", :account_id, "users.name", "accounts.name")
    end
    @lowercase = true
  end

  # NOTE: sis_user_id includes integration_id because nothing in this forsaken world makes any sense
  def resolve_by_sis_user_id
    restricted_shards = restrict_shards do |address|
      Pseudonym.associated_shards_for_column(:sis_user_id, address) +
        Pseudonym.associated_shards_for_column(:integration_id, address)
    end

    ids = @addresses.pluck(:address)
    search_for_results(restricted_shards) do |account_ids|
      rows = Pseudonym.active.where(account_id: account_ids, sis_user_id: ids).joins(:user, :account)
                      .pluck(:sis_user_id, :user_id, "users.uuid", :account_id, "users.name", "accounts.name")
      rows += Pseudonym.active.where(account_id: account_ids, integration_id: ids).joins(:user, :account)
                       .pluck(:integration_id, :user_id, "users.uuid", :account_id, "users.name", "accounts.name")
      rows
    end
  end

  def resolve_by_cc_path
    # strictly speaking, when searching via e-mail address we should
    # be looking at all shards that have a user with that e-mail, since
    # they don't necessarily have to exist on a shard with a trusted
    # account. but we need to clean up GlobalLookups a bit before we
    # do that. (i.e. don't call restrict_shards here)
    restricted_shards = restrict_shards do |address|
      CommunicationChannel.associated_shards(address)
    end

    sms_paths = []
    sms_path_header_map = {}
    email_paths = []
    @addresses.each do |a|
      if a[:type] == :sms
        path_header = a[:address].gsub(/[^\d]/, "")
        sms_path_header_map[path_header] = a[:address]
        sms_paths << (path_header + "@%")
      else
        email_paths << a[:address].downcase
      end
    end

    search_for_results(restricted_shards) do
      ccs = []
      scope = if @root_account.feature_enabled?(:allow_unconfirmed_users_in_user_list)
                CommunicationChannel.unretired
              else
                CommunicationChannel.active
              end

      if sms_paths.any?
        ccs = scope
              .sms
              .preload(user: :pseudonyms)
              .where((["path LIKE ?"] * sms_paths.count).join(" OR "), *sms_paths)
              .to_a
      end
      ccs += scope
             .email
             .preload(user: :pseudonyms)
             .where("LOWER(path) IN (?)", email_paths)
             .to_a

      ccs.filter_map do |cc|
        next unless (p = SisPseudonym.for(cc.user, @root_account, type: :trusted, require_sis: false))

        path = cc.path
        # replace the actual path with the original address for SMS
        path = sms_path_header_map[path.split("@").first] if cc.path_type == "sms"
        [path, cc.user_id, cc.user.uuid, p.account_id, cc.user.name, p.account.name]
      end
    end
    @lowercase = true
  end
end
