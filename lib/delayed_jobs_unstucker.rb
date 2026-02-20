# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

# Periodically unblocks orphaned strands and singletons in the delayed_jobs
# queue. A strand/singleton becomes orphaned when no job in the group has
# next_in_strand=true, which prevents the worker from ever picking up the
# remaining jobs. This can happen due to race conditions in the PostgreSQL
# triggers, dead workers that held locks, or edge cases in singleton-strand
# transitions.
class DelayedJobsUnstucker
  def self.unstuck
    dj_shard = Switchman::Shard.current(Delayed::Backend::ActiveRecord::AbstractJob)
    SwitchmanInstJobs::JobsMigrator.unblock_strands(dj_shard)
  end
end
