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
  describe 'quiz_export_complete' do

    let(:live_event) do
      LiveEvents::PactHelper::Event.new(
        event_name: 'quiz_export_complete',
        event_subscriber: PactConfig::Consumers::QUIZ_LTI
      )
    end

    it 'keeps the contract' do
      live_event.emit_with do
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

        course = course_model
        course.root_account.settings[:provision] = {'lti' => 'lti url'}
        course.root_account.save!
        course.enable_feature!(:quizzes_next)

        @quiz = course.quizzes.create!(
          title: 'quiz 1',
          quiz_type: 'assignment'
        )
        @ce = course.content_exports.create!(
          export_type: ContentExport::QUIZZES2,
          selected_content: @quiz.id
        )
        @quizzes2 = Exporters::Quizzes2Exporter.new(@ce)
        @quizzes2.export

        @ce.settings[:quizzes2] = @quizzes2.build_assignment_payload
        @ce.settings[:quizzes2][:qti_export] = {}
        @ce.settings[:quizzes2][:qti_export][:url] = "fake_url.com"
        @ce.progress = 100

        @ce.mark_exported
        @ce.save!

      end

      expect(live_event).to have_kept_the_contract
    end
  end
end
