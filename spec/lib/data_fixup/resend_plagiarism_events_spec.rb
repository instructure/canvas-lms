# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require "plagiarism_platform_spec_helper"

describe DataFixup::ResendPlagiarismEvents do
  include_context "plagiarism_platform"

  before do
    assignment.tool_settings_tool = message_handler
    assignment_two.tool_settings_tool = message_handler
    assignment.save!
    assignment_two.save!

    @submission = assignment.submit_homework(student, body: "done")
    @submission_two = assignment_two.submit_homework(student, body: "done")
    @submission_two.originality_reports.create!(workflow_state: "pending")
    student2 = student_in_course(course: assignment_two.course).user
    @submission_three = assignment_two.submit_homework(student2, body: "done")
    @submission_three.originality_reports.create!(workflow_state: "error")
  end

  describe "#run" do
    context "when only_errors is not provided" do
      it "sends events for submissions with no originality report and pending originality reports" do
        stub_const("DataFixup::ResendPlagiarismEvents::RESUBMIT_LIMIT", 1)

        Timecop.freeze do
          DataFixup::ResendPlagiarismEvents.run
          djs = Delayed::Job.where(tag: "DataFixup::ResendPlagiarismEvents.trigger_plagiarism_resubmit_by_time").order(:id)
          expect(djs.count).to eq 2
          expect(djs.map { |j| j.payload_object.args }).to eq([[@submission_two.submitted_at, Time.zone.now, false],
                                                               [@submission.submitted_at, @submission_two.submitted_at, false]])
          expect(djs.map(&:run_at)).to eq([3.minutes.from_now, 1.year.from_now])
        end
      end
    end

    context "when only_errors is true" do
      it "sends events for the errored submissions" do
        Timecop.freeze do
          DataFixup::ResendPlagiarismEvents.run(only_errors: true)
          expect(Delayed::Job.where(tag: "DataFixup::ResendPlagiarismEvents.trigger_plagiarism_resubmit_by_time").count).to eq 1
          dj = Delayed::Job.where(tag: "DataFixup::ResendPlagiarismEvents.trigger_plagiarism_resubmit_by_time").take
          expect(dj.payload_object.args).to eq([@submission_three.submitted_at, Time.zone.now, true])
          expect(dj.run_at).to eq(3.minutes.from_now)
        end
      end
    end

    context "when a time range is specified" do
      let(:start_time) { 1.hour.ago }
      let(:end_time) { 30.minutes.ago }

      it "only resends events for submissions in the given time range" do
        expect do
          DataFixup::ResendPlagiarismEvents.run(
            start_time:,
            end_time:
          )
        end.not_to change { Delayed::Job.count }
      end
    end
  end

  describe "#trigger_plagiarism_resubmit_by_id" do
    it "triggers the next job in the batch after it finishes" do
      stub_const("DataFixup::ResendPlagiarismEvents::RESUBMIT_LIMIT", 1)
      stub_const("DataFixup::ResendPlagiarismEvents::RESUBMIT_WAIT_TIME", 10.seconds)
      dj = Delayed::Job.create(strand: "plagiarism_event_resend", locked_at: nil, run_at: 1.year.from_now)
      expect(Canvas::LiveEvents).to receive(:post_event_stringified).twice.with("plagiarism_resubmit", anything, anything)
      DataFixup::ResendPlagiarismEvents.trigger_plagiarism_resubmit_by_time(1.month.ago, Time.zone.now)
      expect(dj.reload.run_at).to be < 11.seconds.from_now
    end
  end
end
