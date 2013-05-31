module DataFixup::InitializeSubmissionCachedDueDate
  def self.run
    Assignment.find_in_batches do |assignments|
      DueDateCacher.recompute_batch(assignments)
    end
  end
end
