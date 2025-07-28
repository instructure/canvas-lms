# frozen_string_literal: true

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
  class << self
    # type: :exact, :trusted, or :implicit
    def for(user, context, type: :exact, require_sis: true, include_deleted: false, root_account: nil, in_region: false, include_all_pseudonyms: false)
      raise ArgumentError, "user is required" unless user.present?
      raise ArgumentError, "type must be :exact, :trusted, or :implicit" unless %i[exact trusted implicit].include?(type)
      raise ArgumentError, "invalid root_account" if root_account && !root_account.root_account?
      raise ArgumentError, "context must respond to .root_account" unless context.nil? || root_account&.root_account? || context.respond_to?(:root_account)
      raise ArgumentError, "type must be :implicit if context is nil" if context.nil? && type != :implicit
      raise ArgumentError, "require_sis must be false if context is nil" if context.nil? && require_sis

      sis_pseudonym =
        new(user, context, type, require_sis, include_deleted, root_account, in_region:, include_all_pseudonyms:)
      include_all_pseudonyms ? sis_pseudonym.all_pseudonyms : sis_pseudonym.pseudonym
    end

    def order(relation, table_alias = nil)
      relation.primary_shard.activate do
        table_alias ||= Pseudonym.table_name
        # false sorts before true
        relation.merge(Pseudonym.order(Arel.sql("#{table_alias}.sis_user_id IS NULL"), Pseudonym.best_unicode_collation_key("#{table_alias}.unique_id"), "#{table_alias}.position"))
      end
    end

    def collation_key(pseudonym)
      [pseudonym.workflow_state,
       pseudonym.sis_user_id ? 0 : 1,
       Canvas::ICU.collation_key(pseudonym.unique_id),
       pseudonym.position]
    end
  end

  attr_reader :user, :context, :type, :require_sis, :include_deleted, :include_all_pseudonyms

  def initialize(user, context, type, require_sis, include_deleted, root_account, in_region: false, include_all_pseudonyms: false)
    @user = user
    @context = context
    @type = type
    @require_sis = require_sis
    @include_deleted = include_deleted
    @root_account = root_account if root_account || context.nil?
    @in_region = in_region
    @include_all_pseudonyms = include_all_pseudonyms
  end

  def pseudonym
    result = @context.sis_pseudonym if @context.class <= Enrollment
    result ||= find_on_enrollment_for_context
    result = nil if exclude_deleted?(result)
    result ||= find_in_home_account if root_account
    result ||= find_in_other_accounts
    if result && result.account_id == root_account&.id
      result.account = root_account
    end
    result
  end

  def all_pseudonyms
    results = []
    results << @context.sis_pseudonym if @context.class <= Enrollment
    results << find_on_enrollment_for_context
    results << find_in_home_account if root_account
    results << find_in_other_accounts
    results = results.flatten.compact.uniq
    results.reject! { |result| exclude_deleted?(result) }
    if results.present?
      results.each do |result|
        result.account = root_account if result.account_id == root_account&.id
      end
      return results
    end
    nil
  end

  private

  def exclude_deleted?(result)
    result&.workflow_state == "deleted" && !@include_deleted
  end

  def find_on_enrollment_for_context
    if @context.is_a?(Course) || @context.is_a?(CourseSection)
      pseudonym = @context.enrollments.except(:preload).where(user_id: @user).where.not(sis_pseudonym_id: nil).preload(:sis_pseudonym).first&.sis_pseudonym
      # if the sis user id isn't here, this pointer might
      # no longer be good.  Let the fallback logic work
      # through "find_in_home_account".  It may still return this one,
      # but if the sis_user_id got moved to another pseudonym
      # it will grab that one instead.
      return nil if pseudonym&.sis_user_id.nil?
      return nil if pseudonym&.workflow_state == "deleted" && !@include_deleted

      pseudonym
    end
  end

  def find_in_other_accounts
    return nil if type == :exact

    if include_deleted
      if user.all_pseudonyms_loaded?
        return pick_user_pseudonym(user.all_pseudonyms, (type == :trusted) ? root_account.trusted_account_ids : nil)
      end
    elsif user.all_active_pseudonyms_loaded?
      return pick_user_pseudonym(user.all_active_pseudonyms, (type == :trusted) ? root_account.trusted_account_ids : nil)
    end

    if type == :trusted
      trusted_local_account_ids_by_shard = root_account.trusted_account_ids.group_by { |id| Shard.shard_for(id) }
                                                       .transform_values { |ids| ids.map { |id| Shard.local_id_for(id).first } }
    end

    # try the user's home shard first if it's fast
    # the default shard has a replica in every region, so is always fast
    user_shard_is_in_region = user.shard.in_current_region? || user.shard.default?
    if user_shard_is_in_region && (type != :trusted || (trusted_local_account_ids = trusted_local_account_ids_by_shard[user.shard]))
      user.shard.activate do
        result = find_in_trusted_accounts(trusted_local_account_ids)
        return result if result
      end
    end

    shards = @in_region ? user.in_region_associated_shards : user.associated_shards
    # only search the shards with trusted accounts
    shards &= trusted_local_account_ids_by_shard.keys if type == :trusted

    return nil if shards.empty?

    Shard.with_each_shard(shards.sort) do
      next if Shard.current == user.shard && user_shard_is_in_region

      trusted_local_account_ids = trusted_local_account_ids_by_shard[Shard.current] if type == :trusted
      result = find_in_trusted_accounts(trusted_local_account_ids)
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
        pick_user_pseudonym(user.pseudonyms, [root_account.id])
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
    (user.pseudonyms.loaded? && user.shard == shard) ||
      (include_deleted ? user.all_pseudonyms_loaded? : user.all_active_pseudonyms_loaded?)
  end

  def root_account
    unless instance_variable_defined?(:@root_account)
      @root_account = context.root_account
      raise "could not resolve root account" unless @root_account.is_a?(Account)
    end
    @root_account
  end

  def pick_pseudonym(account_ids)
    relation = Pseudonym.active.where(user_id: user)
    relation = relation.where(account_id: account_ids) if account_ids
    relation = relation.sis if require_sis
    relation = self.class.order(relation)

    if root_account.nil? && include_all_pseudonyms
      relation.to_a
    elsif type == :implicit && root_account
      if include_all_pseudonyms
        return relation.select { |p| p.works_for_account?(root_account, true) }
      end

      relation.detect { |p| p.works_for_account?(root_account, true) }
    else
      relation.first
    end
  end

  def pick_user_pseudonym(collection, account_ids)
    if include_all_pseudonyms
      collection.select do |p|
        next if account_ids && !account_ids.include?(p.account_id)
        next true if root_account.nil?
        next if !account_ids && !p.works_for_account?(root_account, type == :implicit)
        next if require_sis && !p.sis_user_id

        true
      end
    else
      collection.sort_by do |p|
        self.class.collation_key(p)
      end.detect do |p|
        next if account_ids && !account_ids.include?(p.account_id)
        next true if root_account.nil?
        next if !account_ids && !p.works_for_account?(root_account, type == :implicit)
        next if require_sis && !p.sis_user_id

        include_deleted || p.workflow_state != "deleted"
      end
    end
  end
end
