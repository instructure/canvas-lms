# This is what is in charge of regenerating all of the child
# brand configs when an account saves theirs in the theme editor
class BrandConfigRegenerator

  attr_reader :progresses

  def initialize(account, current_user, new_brand_config)
    @account = account
    @current_user = current_user
    old_config_md5 = @account.brand_config_md5
    @account.brand_config = new_brand_config
    @account.save!
    @new_configs = {}
    @new_configs[old_config_md5] = new_brand_config if old_config_md5
    @progresses = []
    process
  end

  def things_that_need_to_be_regenerated
    @things_that_need_to_be_regenerated ||= begin
      all_subaccounts = @account.sub_accounts_recursive(100000, nil)
      branded_subaccounts = all_subaccounts.select(&:brand_config)
      branded_subaccounts + SharedBrandConfig.where(account_id: all_subaccounts)
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
    progress = Progress.new(
      context: @current_user,
      tag: "#{job_type}_for_#{thing.id}".to_sym,
      message: "Syncing for #{account.name}#{thing.is_a?(SharedBrandConfig) ? ": #{thing.name}" : ''}"
    )
    progress.user = @current_user
    progress.reset!
    progress.process_job(new_config, job_type, {priority: Delayed::HIGH_PRIORITY}, thing.id)

    @new_configs[config.md5] = new_config
    @progresses << progress
  end

  def process
    things_left_to_process = things_that_need_to_be_regenerated.dup
    while thing = things_left_to_process.sample
      next unless ready_to_process?(thing)
      regenerate(thing)
      things_left_to_process.delete(thing)
    end
  end

end
