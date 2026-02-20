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

require_relative "../spec_helper"

describe DelayedJobsUnstucker do
  describe ".unstuck" do
    it "calls unblock_strands on the current delayed jobs shard" do
      dj_shard = Switchman::Shard.current(Delayed::Backend::ActiveRecord::AbstractJob)
      expect(SwitchmanInstJobs::JobsMigrator).to receive(:unblock_strands).with(dj_shard)
      described_class.unstuck
    end
  end
end
