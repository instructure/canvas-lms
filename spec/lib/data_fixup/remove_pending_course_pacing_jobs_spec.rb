# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

describe DataFixup::RemovePendingCoursePacingJobs do
  before(:once) do
    course_with_teacher(active_all: true)
    @course.root_account.enable_feature!(:course_paces)
    @course.enable_course_paces = true
    @course.save!
    course_pace_model(course: @course)

    @p1 = Progress.create!(context: @course_pace, tag: "course_pace_publish", workflow_state: "queued")
    @p1.update_attribute(:delayed_job_id, "1234")

    @p2 = Progress.create!(context: @course_pace, tag: "course_pace_publish", workflow_state: "queued")
    @p2.delayed_job = Delayed::Job.create!
    @p2.update_attribute(:delayed_job_id, @p2.delayed_job.id)
  end

  it "marks queued progress with no existing delayed job as failed" do
    described_class.run(@p1.id, @p2.id)

    expect(@p1.reload.workflow_state).to eq "failed"
    expect(@p2.reload.workflow_state).to eq "queued"
  end

  it "does not fail progress not tagged as course_pace_publish" do
    @p3 = Progress.create!(context: @course_pace, tag: "assignment_bulk_update", workflow_state: "queued")
    @p3.update_attribute(:delayed_job_id, "5678")

    described_class.run(@p1.id, @p3.id)

    expect(@p1.reload.workflow_state).to eq "failed"
    expect(@p2.reload.workflow_state).to eq "queued"
    expect(@p3.reload.workflow_state).to eq "queued"
  end

  it "does not fail progress not in a queued state" do
    @p1.update_attribute(:workflow_state, "completed")
    described_class.run(@p1.id, @p2.id)

    expect(@p1.reload.workflow_state).to eq "completed"
    expect(@p2.reload.workflow_state).to eq "queued"
  end
end
