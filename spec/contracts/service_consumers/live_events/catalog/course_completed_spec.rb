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
#

require_relative '../live_events_pact_helper'

RSpec.describe 'Canvas LMS Live Events', :pact_live_events do
  describe 'course_completed' do
    let(:live_event) do
      LiveEvents::PactHelper::Event.new(
        event_name: 'course_completed', event_subscriber: PactConfig::LiveEventConsumers::CATALOG
      )
    end

    it 'keeps the contract' do
      live_event.emit_with do
        course_model
        assignment_model(course: @course)
        student_in_course(active_all: true, course: @course)
        @user.update(email: 'user@example.com')
        context_module = @course.context_modules.create!
        tag = context_module.add_item({ id: @assignment.id, type: 'assignment' })
        context_module.completion_requirements = { tag.id => { type: 'must_submit' } }
        context_module.update(requirement_count: 1)
        context_module_progression =
          context_module.context_module_progressions.create!(
            user_id: @user.id,
            workflow_state: 'completed',
            requirements_met: [{ id: tag.id, type: 'must_submit' }]
          )
        Canvas::LiveEvents.course_completed(context_module_progression)
      end

      expect(live_event).to have_kept_the_contract
    end
  end
end
