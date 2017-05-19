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

describe "master courses sidebar" do
  include_context "in-process server selenium tests"

  # copied from spec/apis/v1/master_templates_api_spec.rb
  def run_master_migration
    @migration = MasterCourses::MasterMigration.start_new_migration!(@template, @master_teacher)
    run_jobs
    @migration.reload
  end

  before :once do
    Account.default.enable_feature!(:master_courses)
    @master = course_factory(active_all: true)
    @master_teacher = @teacher
    @template = MasterCourses::MasterTemplate.set_as_master_course(@master)
    @minion = @template.add_child_course!(course_factory(name: "Minion", active_all: true)).child_course
    @minion.enroll_teacher(@master_teacher).accept!

    # sets up the assignment that gets blueprinted
    @original_assmt = @master.assignments.create! title: 'Blah', points_possible: 10, due_at: 5.days.from_now, description: 'this is the original content'
    run_master_migration
    @copy_assmt = @minion.assignments.last
  end

  describe "as a master course teacher" do
    include BlueprintCourseCommon
    before :each do
      user_session(@master_teacher)
    end

    it "locks down the associated course's assignment fields", priority: "1", test_id: 3127590 do
      change_blueprint_settings(@master, points: true, due_dates: true, availability_dates: true)
      get "/courses/#{@master.id}/assignments/#{@original_assmt.id}"
      f('.bpc-lock-toggle button').click
      expect { f('.bpc-lock-toggle__label').text }.to become('Locked')
      run_master_migration
      get "/courses/#{@minion.id}/assignments/#{@copy_assmt.id}/edit"
      expect(f('#mceu_24')).not_to be nil
      expect(f('.bpc-lock-toggle__label').text).to eq('Locked')
      expect(f('#assignment_points_possible').attribute('readonly')).to be_truthy
      expect(f('#due_at').attribute('readonly')).to be_truthy
      expect(f('#unlock_at').attribute('readonly')).to be_truthy
      expect(f('#lock_at').attribute('readonly')).to be_truthy
    end

    it "locks down the associated course's assignment content and show banner", priority: "2", test_id: 3127585 do
      change_blueprint_settings(@master, content: true)
      get "/courses/#{@master.id}/assignments/#{@original_assmt.id}"
      f('.bpc-lock-toggle button').click
      expect { f('.bpc-lock-toggle__label').text }.to become('Locked')
      expect(f('#blueprint-lock-banner')).to include_text('Content')
      run_master_migration
      get "/courses/#{@minion.id}/assignments/#{@copy_assmt.id}/edit"
      expect(f('#edit_assignment_wrapper')).not_to contain_css('#mceu_24')
      expect(f('.bpc-lock-toggle__label').text).to eq('Locked')
      expect(f('#blueprint-lock-banner')).to include_text('Content')
    end
  end
end
