module DataFixup::UseAssetUserAccessLastAccess

  def self.run
    AssetUserAccess.update_all("last_access = updated_at", "last_access is null")
  end

end
