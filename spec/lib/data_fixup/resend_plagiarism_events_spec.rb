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
      context 'when configured submissions have no originality report' do
        before { assignment.submit_homework(student, body: 'done') }

        it 'sends events for the submission' do
          expect(Canvas::LiveEvents).to receive(:post_event_stringified).once.with('plagiarism_resubmit', anything, anything)
          DataFixup::ResendPlagiarismEvents.run
        end
      end

      context 'when configured submissions have a non-scored originality report' do
        before do
          submission = assignment.submit_homework(student, body: 'done')
          submission.originality_reports.create!(workflow_state: 'pending')
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
          submission = assignment.submit_homework(student, body: 'done')
          submission.update!(submitted_at: start_time - 1.hour)
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

  describe '#trigger_plagiarism_resubmit_for' do
    before :once do
      assignment.submit_homework(student, body: 'done')
      submission = assignment_two.submit_homework(student, body: 'done')
      submission.originality_reports.create!(workflow_state: 'pending')
    end

    it 'should retrigger itself when there are more submissions than the current batch' do
      Setting.set('trigger_plagiarism_resubmit', '1,10')
      expect(DataFixup::ResendPlagiarismEvents).to receive(:trigger_plagiarism_resubmit_for).twice.and_call_original
      DataFixup::ResendPlagiarismEvents.send(:trigger_plagiarism_resubmit_for,
        Submission.where(assignment_id: [assignment.id, assignment_two.id]))
    end

    it 'should not retrigger itself when the batch has the last id for the scope' do
      expect(DataFixup::ResendPlagiarismEvents).to receive(:trigger_plagiarism_resubmit_for).once.and_call_original
      DataFixup::ResendPlagiarismEvents.send(:trigger_plagiarism_resubmit_for,
        Submission.where(assignment_id: [assignment.id, assignment_two.id]))
    end
  end
end