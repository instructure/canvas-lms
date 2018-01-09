module DataFixup
  class FixAssignmentPeerReviewJobs
    def self.run
      Delayed::Job.transaction do
        Delayed::Job.future.where(:tag => "Assignment#do_auto_peer_review", :locked_by => nil).lock.find_each do |job|
          assmt_id = job.handler.match(/Assignment (\d+)/)[1]
          shard = job.current_shard
          assignment = shard ? shard.activate { Assignment.find(assmt_id) } : Assignment.find(assmt_id)
          next unless assignment.needs_auto_peer_reviews_scheduled?
          run_at_frd = assignment.peer_reviews_assign_at || assignment.due_at
          next unless run_at_frd
          if run_at_frd != job.run_at
            job.update_attribute(:run_at, run_at_frd)
          end
        end
      end
    end
  end
end
