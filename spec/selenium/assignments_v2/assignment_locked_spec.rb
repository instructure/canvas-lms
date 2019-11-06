#
# Copyright (C) 2019 - present Instructure, Inc.
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

require_relative '../common'


describe 'assignments' do
  include_context "in-process server selenium tests"

  context 'as a student' do

    before(:once) do
      course_with_student(active_all: true)
      @course.account.root_account.enable_feature!(:assignments_2_student)
      @assignment = @course.assignments.create!(
        name: 'locked_assignment',
        due_at: 5.days.ago,
        lock_at: 3.days.ago,
        submission_types: 'online_text_entry'
      )
    end

    before do
      user_session(@student)
      get "/courses/#{@course.id}/assignments/#{@assignment.id}/"
    end

    it 'should show a locked image' do
      expect(f("img[alt='Assignment Locked']")).to be_displayed
    end

    it 'should show a locked stepper' do
      expect(f("svg[name='IconLock']")).to be_displayed
    end
  end
end
