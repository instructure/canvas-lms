module DataFixup::InitializeSubmissionLateness  
  def self.run
    Submission.joins(:assignment).
        where("submissions.submitted_at IS NOT NULL AND assignments.due_at IS NOT NULL AND assignments.due_at < submissions.submitted_at").
        find_in_batches do |submissions|
      Submission.where(:id => submissions).update_all(:late => true)
    end

    AssignmentOverride.find_each do |override|
      override.send(:recompute_submission_lateness)
    end
  end
end
