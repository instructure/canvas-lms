# Copyright (C) 2018 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe QuizzesNext::ExportService do
  ExportService = QuizzesNext::ExportService

  describe '.applies_to_course?' do
    let(:course) { double('course') }

    context 'service enabled for context' do
      it 'returns true' do
        allow(QuizzesNext::Service).to receive(:enabled_in_context?).and_return(true)
        expect(ExportService.applies_to_course?(course)).to eq(true)
      end
    end

    context 'service not enabled for context' do
      it 'returns false' do
        allow(QuizzesNext::Service).to receive(:enabled_in_context?).and_return(false)
        expect(ExportService.applies_to_course?(course)).to eq(false)
      end
    end
  end

  describe '.begin_export' do
    let(:course) { double('course') }

    before do
      allow(course).to receive(:uuid).and_return(1234)
    end

    context 'no assignments' do
      it 'does nothing' do
        allow(QuizzesNext::Service).to receive(:active_lti_assignments_for_course).and_return([])

        expect(ExportService.begin_export(course, {})).to be_nil
      end
    end

    it "filters to selected assignments with selective exports" do
      export_opts = {:selective => true, :exported_assets => ['assignment_42', 'wiki_page_84']}
      expect(QuizzesNext::Service).to receive(:active_lti_assignments_for_course).with(course, selected_assignment_ids: ["42"]).and_return([])
      ExportService.begin_export(course, export_opts)
    end

    it 'returns metadata for each assignment' do
      assignment1 = double('assignment')
      assignment2 = double('assignment')
      lti_assignments = [
        assignment1,
        assignment2
      ]

      lti_assignments.each_with_index do |assignment, index|
        allow(assignment).to receive(:lti_resource_link_id).and_return("link-id-#{index}")
        allow(assignment).to receive(:id).and_return(index)
      end

      allow(QuizzesNext::Service).to receive(:active_lti_assignments_for_course).and_return(lti_assignments)

      expect(ExportService.begin_export(course, {})).to eq(
        {
          "original_course_uuid": 1234,
          "assignments": [
            {"original_resource_link_id": "link-id-0", "$canvas_assignment_id": 0, "original_assignment_id": 0},
            {"original_resource_link_id": "link-id-1", "$canvas_assignment_id": 1, "original_assignment_id": 1}
          ]
        }
      )
    end
  end

  describe '.retrieve_export' do
    it 'returns what is sent in' do
      expect(ExportService.retrieve_export('foo')).to eq('foo')
    end
  end

  describe '.send_imported_content' do
    let(:new_course) { double('course') }
    let(:new_assignment1) { assignment_model(id: 1) }
    let(:new_assignment2) { assignment_model(id: 2) }
    let(:old_assignment1) { assignment_model(id: 3) }
    let(:old_assignment2) { assignment_model(id: 4) }
    let(:basic_import_content) do
      {
        'original_course_uuid': '100005',
        'assignments': [
          {
            'original_resource_link_id': 'link-1234',
            '$canvas_assignment_id': new_assignment1.id,
            'original_assignment_id': old_assignment1.id
          }
        ]
      }
    end

    before do
      allow(new_course).to receive(:uuid).and_return('100006')
      allow(new_course).to receive(:lti_context_id).and_return('ctx-1234')
    end

    it 'emits live events for each copied assignment' do
      basic_import_content[:assignments] << {
        'original_resource_link_id': 'link-5678',
        '$canvas_assignment_id': new_assignment2.id,
        'original_assignment_id': old_assignment2.id
      }

      expect(Canvas::LiveEvents).to receive(:quizzes_next_quiz_duplicated).twice
      ExportService.send_imported_content(new_course, basic_import_content)
    end

    it 'ignores not found assignments' do
      basic_import_content[:assignments] << {
        'original_resource_link_id': '5678',
        '$canvas_assignment_id': Canvas::Migration::ExternalContent::Translator::NOT_FOUND
      }

      expect(Canvas::LiveEvents).to receive(:quizzes_next_quiz_duplicated).once
      ExportService.send_imported_content(new_course, basic_import_content)
    end

    it 'includes the new assignment id in the live event payload' do
      expect(Canvas::LiveEvents).to receive(:quizzes_next_quiz_duplicated).with(
        hash_including(new_assignment_id: new_assignment1.global_id)
      )
      ExportService.send_imported_content(new_course, basic_import_content)
    end

    it 'puts new assignments in the "duplicating" state' do
      allow(Canvas::LiveEvents).to receive(:quizzes_next_quiz_duplicated)

      ExportService.send_imported_content(new_course, basic_import_content)
      expect(new_assignment1.reload.workflow_state).to eq('duplicating')
    end

    it 'sets the new assignment as duplicate of the old assignment' do
      allow(Canvas::LiveEvents).to receive(:quizzes_next_quiz_duplicated)

      ExportService.send_imported_content(new_course, basic_import_content)
      expect(new_assignment1.reload.duplicate_of).to eq(old_assignment1)
    end

    it 'sets the external_tool_tag to be the same as the old tag' do
      allow(Canvas::LiveEvents).to receive(:quizzes_next_quiz_duplicated)

      ExportService.send_imported_content(new_course, basic_import_content)
      expect(new_assignment1.reload.external_tool_tag).to eq(old_assignment1.external_tool_tag)
    end

    it 'skips assignments that are not duplicates' do
      basic_import_content[:assignments] << {
        'original_resource_link_id': '5678',
        '$canvas_assignment_id': new_assignment2.id
      }

      expect(Canvas::LiveEvents).to receive(:quizzes_next_quiz_duplicated).once
      # The specific error I care about here is `KeyError`, because that is what
      # is raised when we try to access a key that is not present in the
      # assignment hash, which is what has led to this fix.
      expect { ExportService.send_imported_content(new_course, basic_import_content) }.not_to raise_error
    end
  end
end
