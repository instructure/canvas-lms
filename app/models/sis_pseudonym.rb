#
# Copyright (C) 2015 - present Instructure, Inc.
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

class SisPseudonym
  # type: :exact, :trusted, or :implicit
  def self.for(user, context, type: :exact, require_sis: true, include_deleted: false)
    raise ArgumentError("type must be :exact, :trusted, or :implicit") unless [:exact, :trusted, :implicit].include?(type)
    self.new(user, context, type, require_sis, include_deleted).pseudonym
  end

  attr_reader :user, :context, :type, :require_sis, :include_deleted

  def initialize(user, context, type, require_sis, include_deleted)
    @user = user
    @context = context
    @type = type
    @require_sis = require_sis
    @include_deleted = include_deleted
  end

  def pseudonym
    result = @context.sis_pseudonym if @context.class <= Enrollment
    result ||= find_in_home_account
    result ||= find_in_other_accounts
    if result
      result.account = root_account if result.account_id == root_account.id
    end
    result
  end

  private
  def find_in_other_accounts
    return nil if type == :exact
    if include_deleted
      if user.all_pseudonyms_loaded?
        return pick_user_pseudonym(user.all_pseudonyms, type == :trusted ? root_account.trusted_account_ids : nil)
      end
    else
      if user.all_active_pseudonyms_loaded?
        return pick_user_pseudonym(user.all_active_pseudonyms, type == :trusted ? root_account.trusted_account_ids : nil)
      end
    end

    shards = user.associated_shards
    trusted_account_ids = root_account.trusted_account_ids.group_by { |id| Shard.shard_for(id) }
    if type == :trusted
      # only search the shards with trusted accounts
      shards &= trusted_account_ids.keys
    end
    return nil if shards.empty?

    Shard.with_each_shard(shards.sort) do
      account_ids = trusted_account_ids[Shard.current] if type == :trusted
      result = find_in_trusted_accounts(account_ids)
      return result if result
    end

    nil
  end

  def find_in_trusted_accounts(account_ids)
    if use_loaded_collection?(Shard.current)
      pick_user_pseudonym(user.pseudonyms, account_ids)
    else
      pick_pseudonym(account_ids)
    end
  end

  def find_in_home_account
    if use_loaded_collection?(root_account.shard)
      if user.pseudonyms.loaded?
        pick_user_pseudonym(user.pseudonyms,[root_account.id])
      else
        pick_user_pseudonym(include_deleted ? user.all_pseudonyms : user.all_active_pseudonyms,
                            [root_account.id])
      end
    else
      root_account.shard.activate do
        pick_pseudonym([root_account.id])
      end
    end
  end

  def use_loaded_collection?(shard)
    user.pseudonyms.loaded? && user.shard == shard ||
      (include_deleted ? user.all_pseudonyms_loaded? : user.all_active_pseudonyms_loaded?)
  end

  def root_account
    @root_account ||= begin
      account = context.root_account
      raise "could not resolve root account" unless account.is_a?(Account)
      account
     end
  end

  def pick_pseudonym(account_ids)
    relation = Pseudonym.active.where(user_id: user)
    relation = relation.where(account_id: account_ids) if account_ids
    relation = if require_sis
                 relation.where.not(sis_user_id: nil)
               else
                 # false sorts before true
                 relation.order(Arel.sql("sis_user_id IS NULL"))
               end
    relation.primary_shard.activate do
      relation = relation.order(Pseudonym.best_unicode_collation_key(:unique_id))
    end
    if type == :implicit
      relation.detect { |p| p.works_for_account?(root_account, true) }
    else
      relation.first
    end
  end

  def pick_user_pseudonym(collection, account_ids)
    collection.sort_by {|p| [p.workflow_state, p.sis_user_id ? 0 : 1, Canvas::ICU.collation_key(p.unique_id)] }.detect do |p|
      next if account_ids && !account_ids.include?(p.account_id)
      next if !account_ids && !p.works_for_account?(root_account, type == :implicit)
      next if require_sis && !p.sis_user_id
      include_deleted || p.workflow_state != 'deleted'
    end
  end
end
