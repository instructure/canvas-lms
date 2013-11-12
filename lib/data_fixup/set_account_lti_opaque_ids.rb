module DataFixup::SetAccountLtiOpaqueIds

  def self.run
    Account.root_accounts.each do |root|
      root.lti_guid = "#{ContextExternalTool.opaque_identifier_for(root, root.shard)}.#{HostUrl.context_host(root)}"
      root.save!
    end
  end

end
