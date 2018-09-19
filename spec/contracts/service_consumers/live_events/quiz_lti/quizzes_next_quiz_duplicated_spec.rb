#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative '../live_events_pact_helper'

RSpec.describe 'Canvas LMS Live Events', :pact_live_events do
  describe 'quizzes_next_quiz_duplicated' do

    let(:live_event) do
      LiveEvents::PactHelper::Event.new(
        event_name: 'quizzes_next_quiz_duplicated',
        event_subscriber: PactConfig::Consumers::QUIZ_LTI
      )
    end

    it 'keeps the contract' do
      live_event.emit_with do
        # arrange
        params = {
          :name => "Quizzes.Next",
          :url => 'http://example.com/launch',
          :domain => "example.com",
          :consumer_key => 'test_key',
          :shared_secret => 'test_secret',
          :privacy_level => 'public',
          :tool_id => 'Quizzes 2'
        }
        Account.default.enable_feature!(:lor_for_account)
        Account.default.context_external_tools.create!(params)

        old_course = course_model(uuid: '100005')
        old_course.root_account.settings[:provision] = {'lti' => 'lti url'}
        old_course.root_account.save!
        old_course.enable_feature!(:quizzes_next)
        old_assignment = assignment_model(course: old_course)
        old_assignment.quiz_lti!
        old_assignment.save!

        new_course = course_model(uuid: '100006')
        new_course.root_account.settings[:provision] = {'lti' => 'lti url'}
        new_course.root_account.save!
        new_course.enable_feature!(:quizzes_next)

        # act
        exported_content = QuizzesNext::ExportService.begin_export(old_course, {})
        QuizzesNext::ExportService.send_imported_content(new_course, ContentMigration.new, exported_content)
      end

      # assert
      expect(live_event).to have_kept_the_contract
    end
  end
end
