module DataFixup::PopulateLockVersionOnContextModuleProgressions
  def self.run
    ContextModuleProgression.where(lock_version: nil).find_ids_in_ranges do |min_id, max_id|
      ContextModuleProgression.where(id: min_id..max_id, lock_version: nil).update_all(lock_version: 0)
    end
  end
end
