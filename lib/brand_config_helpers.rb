module BrandConfigHelpers
  def branding_allowed?
    self.root_account? || self.root_account.sub_account_includes?
  end

  def first_parent_brand_config
    @first_parent_brand_config ||= begin
      _, *chain = self.account_chain
      chain.find do |a|
        config = a.brand_config
        break config if config
      end
    end
  end

  def recompile_descendant_brand_configs(user)
    new_configs_by_account_id = get_descendant_configs_by_account_id(
      nil,
      is_base_theme: true,
      base_md5: brand_config.try(:md5)
    )

    new_configs_by_account_id.map do |account_id, config|
      tag_name = "brand_config_save_and_sync_to_s3_for_account_#{account_id}"
      child_progress = Progress.new(context: user, tag: tag_name.to_sym)
      child_progress.user = user
      child_progress.reset!
      if config
        config.save! if config.new_record?
        child_progress.process_job(
          config,
          :sync_to_s3_and_save_to_account!,
          {priority: Delayed::HIGH_PRIORITY},
          account_id
        )
      end
      child_progress
    end
  end

  def get_descendant_configs_by_account_id(new_parent_md5, opts={})
    if opts[:is_base_theme]
      my_md5 = opts[:base_md5]
      # base theme already compiled, so dont include
      my_new_config_by_id = {}
    else
      my_new_config = new_brand_config(new_parent_md5)
      my_md5 = my_new_config.md5
      my_new_config_by_id = {self.id => my_new_config}
    end

    child_accounts_with_config.reduce(my_new_config_by_id) do |memo, sub_account|
      memo.merge(sub_account.get_descendant_configs_by_account_id(my_md5))
    end
  end

  def child_accounts_with_config
    self.sub_accounts.preload(:brand_config).where('brand_config_md5 IS NOT NULL')
  end

  def new_brand_config(new_parent_md5)
    BrandConfig.for(
      variables: brand_config.variables,
      js_overrides: brand_config.js_overrides,
      css_overrides: brand_config.css_overrides,
      parent_md5: new_parent_md5
    )
  end
end
