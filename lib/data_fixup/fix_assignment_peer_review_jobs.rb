#
# Copyright (C) 2017 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

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
