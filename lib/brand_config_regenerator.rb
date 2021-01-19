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
        tag: "brand_config_regenerate_for_#{account.root_account.global_id}".to_sym,
        message: I18n.t("Regenerating themes...")
      )
      progress.user = current_user
      progress.reset!
      new_brand_config.save! if new_brand_config&.changed?
      progress.process_job(BrandConfigRegenerator,
        :process_sync,
        { priority: Delayed::HIGH_PRIORITY, singleton: progress.tag.to_s },
        account, new_brand_config)
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
      all_subaccounts = @account.sub_accounts_recursive(100000, nil)
      result = all_subaccounts.select(&:brand_config_md5)
      result.concat(SharedBrandConfig.where(account_id: all_subaccounts))
      if @account.site_admin?
        # note: this is only root accounts on the same shard as site admin
        @account.shard.activate do
          root_scope = Account.root_accounts.active.non_shadow.where.not(id: @account)
          result.concat(root_scope.select(&:brand_config_md5))
          result.concat(SharedBrandConfig.where(account_id: root_scope))

          sub_scope = Account.active.where(root_account_id: root_scope)
          result.concat(sub_scope.select(&:brand_config_md5))
          result.concat(SharedBrandConfig.where(account_id: sub_scope))
        end
      end
      result
    end.freeze
  end

  # Returns true if this brand config is not based on anything that needs to be regenerated.
  # This should not be common but can happen in dev/test setups that got into an inconsistent state
  def orphan?(brand_config)
    things_that_need_to_be_regenerated.none? { |thing| thing.brand_config_md5 == brand_config.parent_md5 }
  end

  # If we haven't saved a new copy for a config's parent,
  # we don't know its new parent_md5 yet.
  def ready_to_process?(account_or_shared_brand_config)
    config = account_or_shared_brand_config.brand_config
    !config.parent || @new_configs.key?(config.parent_md5) || orphan?(config)
  end

  def regenerate(thing)
    config = thing.brand_config
    return unless config
    new_parent_md5 = config.parent_md5 && @new_configs[config.parent_md5].try(:md5) || @account.brand_config_md5
    new_config = config.clone_with_new_parent(new_parent_md5)
    new_config.save_unless_dup!

    account = thing.is_a?(SharedBrandConfig) ? thing.account : thing
    job_type = thing.is_a?(SharedBrandConfig) ? :sync_to_s3_and_save_to_shared_brand_config! : :sync_to_s3_and_save_to_account!
    new_config.send(job_type, @progress, thing.id)

    @new_configs[config.md5] = new_config
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
    while thing = things_left_to_process.sample
      next unless ready_to_process?(thing)
      regenerate(thing)
      things_left_to_process.delete(thing)
    end
  end

end
