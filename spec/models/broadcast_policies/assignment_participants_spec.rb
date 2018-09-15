#
# Copyright (C) 2016 - present Instructure, Inc.
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

require File.expand_path('../../spec_helper', File.dirname(__FILE__))

describe BroadcastPolicies::AssignmentParticipants do
  before :once do
    course_with_student(active_all: true)
    assignment_model course: @course
    @excluded_ids = nil
  end

  subject do
    BroadcastPolicies::AssignmentParticipants.new(@assignment, @excluded_ids)
  end

  describe '#to' do
    it 'includes students with access to the assignment' do
      expect(subject.to).to include(@student)
    end

    it 'excludes students in concluded sections' do
      @section = @course.course_sections.create!(end_at: Time.zone.now - 1.day)
      create_enrollment @course, @student, section: @section
      expect(subject.to).not_to include(@ended_section_user)
    end

    context 'with students whose enrollments have not yet started' do
      before :once do
        student_in_course({
          course: @course,
          start_at: 1.month.from_now
        })
      end

      it 'excludes said students' do
        expect(subject.to).not_to include(@student)
      end
    end

    context 'when provided with excluded_ids' do
      before :once do
        student_in_course(active_all: true)
        @excluded_ids = [@student.id]
      end

      it 'excludes students with provided ids' do
        expect(subject.to).not_to include(@student)
      end
    end
  end
end
