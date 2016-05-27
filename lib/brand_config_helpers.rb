module BrandConfigHelpers
  def branding_allowed?
    root_account? || root_account.sub_account_includes?
  end

  def effective_brand_config
    first_config_in_chain(
      brand_config_chain(include_self: true).select(&:branding_allowed?)
    )
  end

  def first_parent_brand_config
    first_config_in_chain(brand_config_chain(include_self: false))
  end

  def brand_config_chain(include_self:)
    chain = self.account_chain(include_site_admin: true)
    chain.shift unless include_self
    chain.select{ |a| a.shard == self.shard }
  end
  private :brand_config_chain

  def first_config_in_chain(chain)
    chain.find(&:brand_config_md5).try(:brand_config)
  end
  private :first_config_in_chain
end
