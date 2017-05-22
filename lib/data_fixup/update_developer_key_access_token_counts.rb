module DataFixup::UpdateDeveloperKeyAccessTokenCounts
  def self.run
    DeveloperKey.find_each { |key| DeveloperKey.reset_counters(key.id, :access_tokens) }
  end
end
