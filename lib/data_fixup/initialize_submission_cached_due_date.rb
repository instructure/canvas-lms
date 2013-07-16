module DataFixup::InitializeSubmissionCachedDueDate
  def self.run
    Assignment.find_ids_in_ranges do |min, max|
      DueDateCacher.recompute_batch(min.to_i..max.to_i)
    end
  end
end
