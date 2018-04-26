#
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

require_relative '../../../spec_helper'

describe Api::V1::Context do
  include Api::V1::Context

  describe '.context_data' do
    it 'should return effective context code data if use_effective_code is true' do
      student_in_course active_all: true
      appointment_participant_model participant: @student, course: @course
      context_data = context_data(@event, use_effective_code: true)
      expect(context_data).to eq({
        'context_type' => 'Course',
        'course_id' => @course.id
      })
    end

    it 'should not return effective context code data if use_effective_code is false or not sent' do
      student_in_course active_all: true
      appointment_participant_model participant: @student, course: @course
      context_data = context_data(@event)
      expect(context_data).to eq({
        'context_type' => 'User',
        'user_id' => @student.id
      })
    end
  end
end
