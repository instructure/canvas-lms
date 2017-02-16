module DataFixup::DeleteEmptyProgressions
  def self.run
    ContextModuleProgression.find_ids_in_ranges(:batch_size => 10000) do |min_id, max_id|
      ContextModuleProgression.where(:id => min_id..max_id, :user_id => nil, :context_module_id => nil).delete_all
    end
  end
end
