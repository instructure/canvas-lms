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

# This is what is in charge of regenerating all of the child
# brand configs when an account saves theirs in the theme editor
class BrandConfigRegenerator
  attr_reader :progresses

  class << self
    def process(account, current_user, new_brand_config)
      progress = Progress.new(
        context: account,
        tag: :"brand_config_regenerate_for_#{account.root_account.global_id}",
        message: I18n.t("Regenerating themes...")
      )
      progress.user = current_user
      progress.reset!
      new_brand_config.save! if new_brand_config&.changed?
      progress.process_job(BrandConfigRegenerator,
                           :process_sync,
                           { priority: Delayed::HIGH_PRIORITY, singleton: progress.tag.to_s },
                           account,
                           new_brand_config)
      progress
    end

    def process_sync(progress, account, new_brand_config)
      new(progress, account, new_brand_config)
    end
  end

  def initialize(progress, account, new_brand_config)
    @progress = progress
    @account = account
    old_config_md5 = @account.brand_config_md5
    @account.brand_config = new_brand_config
    @account.save!
    @new_configs = {}
    @new_configs[old_config_md5] = new_brand_config if old_config_md5
    process
  end

  private

  def things_that_need_to_be_regenerated
    @things_that_need_to_be_regenerated ||= begin
      result = []
      # In prod this will take a pretty long time for siteadmin, but we don't expect this to ever be used on siteadmin in prod
      Shard.with_each_shard(target_shards) do
        root_scope = Account.root_accounts.active.non_shadow.preload(:brand_config)
        if Shard.current == @account.shard
          root_scope = root_scope.where.not(id: @account)
        end
        root_scope = filter_root_scope(root_scope)
        if root_scope
          result.concat(root_scope.where.not(brand_config_md5: nil))
          result.concat(SharedBrandConfig.where(account_id: root_scope).preload(:brand_config))
        end

        sub_scope = if @account.root_account?
                      Account.active.where(root_account_id: [root_scope&.pluck(:id), (Shard.current == @account.shard) ? @account.id : nil].compact.flatten).preload(:brand_config)
                    else
                      Account.active.where(id: Account.sub_account_ids_recursive(@account.id))
                    end
        result.concat(sub_scope.where.not(brand_config_md5: nil))
        result.concat(SharedBrandConfig.where(account_id: sub_scope).preload(:brand_config))
      end
      result
    end.freeze
  end

  def target_shards
    if @account.site_admin?
      Shard.all
    else
      [@account.shard]
    end
  end

  def filter_root_scope(scope)
    if @account.site_admin?
      scope
    else
      nil
    end
  end

  # Returns true if this brand config is not based on anything that needs to be regenerated.
  # This should not be common but can happen in dev/test setups that got into an inconsistent state
  def orphan?(brand_config)
    things_that_need_to_be_regenerated.none? { |thing| thing.brand_config_md5 == brand_config.local_parent_md5 }
  end

  # If we haven't saved a new copy for a config's parent,
  # we don't know its new parent_md5 yet.
  def ready_to_process?(account_or_shared_brand_config)
    config = account_or_shared_brand_config.brand_config
    !config.parent || @new_configs.key?(config.local_parent_md5) || orphan?(config)
  end

  def regenerate(thing)
    config = thing.brand_config
    return unless config

    thing.shard.activate do
      new_config = config.clone_with_new_parent((config.parent_md5 && @new_configs[config.local_parent_md5]) || @account.brand_config)
      new_config.save_unless_dup!

      job_type = thing.is_a?(SharedBrandConfig) ? :sync_to_s3_and_save_to_shared_brand_config! : :sync_to_s3_and_save_to_account!
      new_config.send(job_type, @progress, thing)

      @new_configs[config.md5] = new_config
    end
  end

  def process
    # signify we started "1% completion"
    @progress.update_completion!(1)
    things_left_to_process = things_that_need_to_be_regenerated.dup
    # every "thing" gets 5 units of work
    total = things_left_to_process.length * 5
    # the initial query shoud get us to 5%; recalculate so that the balance is 95%
    five_percent = total * 5.0 / 95.0
    total += five_percent
    @progress.calculate_completion!(five_percent, total)
    # take things off the queue from front-to-back
    while (thing = things_left_to_process.shift)
      # if for some reason this one isn't ready (it _should_ be by default,
      # because we get higher tiers first) put it back on the queue to try
      # again later
      unless ready_to_process?(thing)
        things_left_to_process.push(thing)
        next
      end
      regenerate(thing)
    end
  end
end
