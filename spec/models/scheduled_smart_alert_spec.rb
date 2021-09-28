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

require 'spec_helper'

describe 'ScheduledSmartAlert' do
  context 'due_date_reminder alert' do
    before(:once) do
      assignment_model({due_at: 3.days.from_now})
      @override = create_section_override_for_assignment(@a, {due_at: 1.day.from_now})
    end

    it 'correctly calculates the runnable scope' do
      offset = 12
      Timecop.freeze(13.hours.from_now) do
        runnable = ScheduledSmartAlert.runnable(offset, @c.account.id)
        # AssignmentOverride was due in 24 hours, is now within the offset window
        expect(runnable).to include(an_object_having_attributes(context_type: 'AssignmentOverride', context_id: @override.id))
        # Assignment was due in 72 hours, is not yet within the offset window
        expect(runnable).to_not include(an_object_having_attributes(context_type: 'Assignment', context_id: @a.id))
      end
    end

    it 'upserts instead of creating duplicate records when the due date is changed' do
      starting_number_of_records = ScheduledSmartAlert.all.length
      @a.due_at = 3.days.from_now
      @a.save!
      expect(ScheduledSmartAlert.all.length).to eq starting_number_of_records
    end
  end
end
