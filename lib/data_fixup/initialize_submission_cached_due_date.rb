module DataFixup::InitializeSubmissionCachedDueDate
  def self.run
    Assignment.find_ids_in_ranges do |(min, max)|
      Assignment.send(:with_exclusive_scope) do
        DueDateCacher.recompute_batch(min..max)
      end
    end
  end
end
