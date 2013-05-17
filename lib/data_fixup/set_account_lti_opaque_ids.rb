module DataFixup::SetAccountLtiOpaqueIds

  def self.run
    Account.root_accounts.each do |root|
      root.lti_guid = "#{root.opaque_identifier(:asset_string)}.#{HostUrl.context_host(root)}"
      root.save!
    end
  end

end
