#
# Copyright (C) 2017 - present Instructure, Inc.
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


require_relative '../helpers/blueprint_common'

describe "blueprint courses assignments" do
  include_context "in-process server selenium tests"
  include BlueprintCourseCommon

  before :once do
    Account.default.enable_feature!(:master_courses)
    @master = course_factory(active_all: true)
    @master_teacher = @teacher
    @template = MasterCourses::MasterTemplate.set_as_master_course(@master)
    @minion = @template.add_child_course!(course_factory(name: "Minion", active_all: true)).child_course
    @minion.enroll_teacher(@master_teacher).accept!

    # sets up the assignment that gets blueprinted
    @original_assmt = @master.assignments.create! title: 'Blah', points_possible: 10, due_at: 5.days.from_now
    @original_assmt.description = 'this is the original content'
    run_master_course_migration(@master)
    @copy_assmt = @minion.assignments.last
  end

  describe "as a blueprint's teacher" do
    before :each do
      user_session(@master_teacher)
    end

    it "can lock down associated course's assignment fields", priority: "1", test_id: 3127590 do
      change_blueprint_settings(@master, points: true, due_dates: true, availability_dates: true)
      get "/courses/#{@master.id}/assignments/#{@original_assmt.id}"
      f('.bpc-lock-toggle button').click
      expect(f('.bpc-lock-toggle__label')).to include_text('Locked')
      run_master_course_migration(@master)
      get "/courses/#{@minion.id}/assignments/#{@copy_assmt.id}/edit"
      expect(f('#edit_assignment_form')).to contain_css('.mce-tinymce.mce-container.mce-panel')
      expect(f('.bpc-lock-toggle__label')).to include_text('Locked')
      expect(f("#assignment_points_possible")).to have_attribute('readonly', 'true')
      expect(f("#due_at")).to have_attribute('readonly', 'true')
      expect(f("#unlock_at")).to have_attribute('readonly', 'true')
      expect(f("#lock_at")).to have_attribute('readonly', 'true')
    end
  end
end
