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
  describe 'content_migration_completed' do

    let(:live_event) do
      LiveEvents::PactHelper::Event.new(
        event_name: 'content_migration_completed',
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
        account = Account.default
        account.enable_feature!(:lor_for_account)
        account.context_external_tools.create!(params)
        account.settings[:provision] = {'lti' => 'lti url'}
        account.lti_context_id = '1'
        account.enable_feature!(:quizzes_next)
        account.enable_feature!(:import_to_quizzes_next)
        account.save!

        course_model(uuid: '100006')
        teacher = user_model

        migration = ContentMigration.create!(
          context: account,
          user: teacher,
          workflow_state: 'importing',
          migration_settings: {
            import_quizzes_next: true
          }
        )
        migration.workflow_state = 'imported'

        # act
        migration.save!
      end

      # assert
      expect(live_event).to have_kept_the_contract
    end
  end
end
