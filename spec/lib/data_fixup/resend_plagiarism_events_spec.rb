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

require 'plagiarism_platform_spec_helper'

describe DataFixup::ResendPlagiarismEvents do
  include_context 'plagiarism_platform'

  before do
    assignment.tool_settings_tool = message_handler
    assignment_two.tool_settings_tool = message_handler
    assignment.save!
    assignment_two.save!
  end

  describe '#run' do
    context 'when there are configured assignments' do
      before do
        @submission = assignment.submit_homework(student, body: 'done')
      end

      context 'when configured submissions have no originality report' do
        it 'sends events for the submission' do
          expect(Canvas::LiveEvents).to receive(:post_event_stringified).once.with('plagiarism_resubmit', anything, anything)
          DataFixup::ResendPlagiarismEvents.run
        end
      end

      context 'when configured submissions have a non-scored originality report' do
        before do
          @submission.originality_reports.create!(workflow_state: 'pending')
        end

        it 'sends events for the submission' do
          expect(Canvas::LiveEvents).to receive(:post_event_stringified).once.with('plagiarism_resubmit', anything, anything)
          DataFixup::ResendPlagiarismEvents.run
        end
      end

      context 'when a time range is specified' do
        let(:start_time) { 1.hour.ago }
        let(:end_time) { Time.zone.now }

        before do
          @submission.update!(submitted_at: start_time - 1.hour)
        end

        it 'only resends events for submissions in the given time range' do
          expect(Canvas::LiveEvents).not_to receive(:post_event_stringified)
          DataFixup::ResendPlagiarismEvents.run(
            start_time,
            end_time
          )
        end
      end
    end
  end

  describe '#trigger_plagiarism_resubmit_by_id' do
    before do
      @submission = assignment.submit_homework(student, body: 'done')
      @submission_two = assignment_two.submit_homework(student, body: 'done')
      @submission_two.originality_reports.create!(workflow_state: 'pending')
    end

    it 'should trigger the next job in the batch after it finishes' do
      Setting.set('trigger_plagiarism_resubmit', '1,10')
      dj = Delayed::Job.create(strand: "plagiarism_event_resend", locked_at: nil, run_at: 1.year.from_now)
      expect(Canvas::LiveEvents).to receive(:post_event_stringified).twice.with('plagiarism_resubmit', anything, anything)
      DataFixup::ResendPlagiarismEvents.trigger_plagiarism_resubmit_by_id(1.month.ago, Time.zone.now,
        @submission.id, @submission_two.id)
      expect(dj.reload.run_at).to be < 11.seconds.from_now
    end
  end
end