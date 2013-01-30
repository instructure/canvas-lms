module DataFixup::InitializeSubmissionLateness  
  def self.run
    Submission.find_in_batches(
      :conditions => "submissions.submitted_at IS NOT NULL AND assignments.due_at IS NOT NULL AND assignments.due_at < submissions.submitted_at",
      :joins => :assignment
    ) do |submissions|
      Submission.update_all({:late => true}, {:id => submissions.map(&:id)})
    end

    AssignmentOverride.find_each do |override|
      override.send(:recompute_submission_lateness)
    end
  end
end
