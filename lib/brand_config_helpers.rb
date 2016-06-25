module BrandConfigHelpers
  def branding_allowed?
    root_account? || root_account.sub_account_includes?
  end

  def effective_brand_config
    return brand_config if root_account? || (branding_allowed? && brand_config)
    parent_account.effective_brand_config
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

end
