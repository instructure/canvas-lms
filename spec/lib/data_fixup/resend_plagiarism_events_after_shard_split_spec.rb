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

describe DataFixup::ResendPlagiarismEventsAfterShardSplit do
  include_context 'plagiarism_platform'

  describe '#run' do
    subject { ResendPlagiarismEventsAfterShardSplit.run('wdransfield') }

    let(:canvas_domain) { 'wdransfield' }

    context 'when there are configured assignments' do
      before do
        assignment.tool_settings_tool = message_handler
        assignment_two.tool_settings_tool = message_handler
        assignment.save!
        assignment_two.save!
      end

      context 'when configured submissions have no originality report' do
        before { assignment.submit_homework(student, body: 'done') }

        it 'sends events for the submission' do
          expect(Canvas::LiveEvents).to receive(:post_event_stringified).once.with('plagiarism_resubmit', anything, anything)
          DataFixup::ResendPlagiarismEventsAfterShardSplit.run(canvas_domain)
        end
      end

      context 'when configured submissions have a non-scored originality report' do
        before do
          submission = assignment.submit_homework(student, body: 'done')
          submission.originality_reports.create!(workflow_state: 'pending')
        end

        it 'sends events for the submission' do
          expect(Canvas::LiveEvents).to receive(:post_event_stringified).once.with('plagiarism_resubmit', anything, anything)
          DataFixup::ResendPlagiarismEventsAfterShardSplit.run(canvas_domain)
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
          DataFixup::ResendPlagiarismEventsAfterShardSplit.run(
            canvas_domain,
            start_time,
            end_time
          )
        end
      end
    end
  end
end