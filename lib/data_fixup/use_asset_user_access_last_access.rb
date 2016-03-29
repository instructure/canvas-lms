module DataFixup::UseAssetUserAccessLastAccess

  def self.run
    loop do
      updated = AssetUserAccess.where("last_access is null").limit(1000).update_all("last_access = updated_at")
      break if updated == 0
    end
  end

end
