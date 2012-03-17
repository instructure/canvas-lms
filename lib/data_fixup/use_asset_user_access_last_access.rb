module DataFixup::UseAssetUserAccessLastAccess

  def self.run
    loop do
      updated = AssetUserAccess.update_all("last_access = updated_at", "last_access is null", :limit => 1000)
      break if updated == 0
    end
  end

end
