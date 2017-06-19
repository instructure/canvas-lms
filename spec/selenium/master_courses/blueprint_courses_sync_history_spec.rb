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

require_relative '../common'
require_relative '../helpers/blueprint_common'

describe "sync history modal" do
  include_context "in-process server selenium tests"
  include BlueprintCourseCommon

  before :once do
    Account.default.enable_feature!(:master_courses)
    @master = course_factory(active_all: true)
    @master_teacher = @teacher
    @template = MasterCourses::MasterTemplate.set_as_master_course(@master)
    @minion = @template.add_child_course!(course_factory(name: "Minion", active_all: true)).child_course
    run_master_course_migration(@master)
  end

  context "assignments" do
    before :once do
      create_and_migrate_master_assignments(@master)
    end

    before :each do
      user_session(@master_teacher)
    end

    it "shows sync history modal for assignment", priority: "2", test_id: 3178864 do
      update_child_assignment(@minion, :points_possible, 8.0)
      update_master_assignment_and_migrate(@master, :points_possible, 15.0)
      get "/courses/#{@master.id}"
      f('.blueprint__root .bcs__wrapper .bcs__trigger').click
      f('#mcSyncHistoryBtn').click
      run_jobs
      second_migration = f('.bcs__history-item:nth-of-type(2)')
      expect(second_migration.find_element(:xpath, "//span[text()[contains(.,'Created')]]")).to be_displayed
      first_migration = f('.bcs__history-item:nth-of-type(1)')
      expect(first_migration.find_element(:xpath, "//span[text()[contains(.,'Updated')]]")).to be_displayed
      f('.bcs__history-item:nth-of-type(1) .pill').click
      expect(f('.bcs__history-item__change-exceps').
               find_element(:xpath, "//span[text()[contains(., 'Points changed exceptions')]]")).to be_displayed
    end
  end

  context "discussions" do
    before :once do
      create_and_migrate_master_discussions(@master)
    end

    before :each do
      user_session(@master_teacher)
    end

    it "shows sync history modal for discussions", priority: "2", test_id: 3179204 do
      update_child_discussion(@minion)
      update_master_discussion_and_migrate(@master)
      get "/courses/#{@master.id}"
      f('.blueprint__root .bcs__wrapper .bcs__trigger').click
      f('#mcSyncHistoryBtn').click
      run_jobs
      second_migration = f('.bcs__history-item:nth-of-type(2)')
      expect(second_migration.find_element(:xpath, "//span[text()[contains(.,'Created')]]")).to be_displayed
      first_migration = f('.bcs__history-item:nth-of-type(1)')
      expect(first_migration.find_element(:xpath, "//span[text()[contains(.,'Updated')]]")).to be_displayed
      f('.bcs__history-item:nth-of-type(1) .pill').click
      expect(f('.bcs__history-item__change-exceps').
               find_element(:xpath, "//span[text()[contains(., 'Settings changed exceptions')]]")).to be_displayed
    end
  end

  context "availability dates exception" do
    before :once do
      create_and_migrate_master_assignments(@master)
    end

    before :each do
      user_session(@master_teacher)
    end

    it "shows sync history for availability dates exception in assignments", priority: "2", test_id: 3179204 do
      update_child_assignment(@minion, :unlock_at, Time.zone.now + 1.day)
      update_master_assignment_and_migrate(@master, :unlock_at, Time.zone.now + 3.days)
      get "/courses/#{@master.id}"
      f('.blueprint__root .bcs__wrapper .bcs__trigger').click
      f('#mcSyncHistoryBtn').click
      run_jobs
      second_migration = f('.bcs__history-item:nth-of-type(2)')
      expect(second_migration.find_element(:xpath, "//span[text()[contains(.,'Created')]]")).to be_displayed
      first_migration = f('.bcs__history-item:nth-of-type(1)')
      expect(first_migration.find_element(:xpath, "//span[text()[contains(.,'Updated')]]")).to be_displayed
      f('.bcs__history-item:nth-of-type(1) .pill').click
      expect(f('.bcs__history-item__change-exceps').
             find_element(:xpath, "//span[text()[contains(., 'Availability Dates changed exceptions')]]")).
             to be_displayed
    end
  end

  context "pages" do
    before :once do
      create_and_migrate_master_pages(@master)
    end

    before :each do
      user_session(@master_teacher)
    end

    it "shows sync history modal for pages", priority: "2", test_id: 3179205 do
      update_child_page(@minion)
      update_master_page_and_migrate(@master)
      get "/courses/#{@master.id}"
      f('.blueprint__root .bcs__wrapper .bcs__trigger').click
      f('#mcSyncHistoryBtn').click
      run_jobs
      second_migration = f('.bcs__history-item:nth-of-type(2)')
      expect(second_migration.find_element(:xpath, "//span[text()[contains(.,'Created')]]")).to be_displayed
      first_migration = f('.bcs__history-item:nth-of-type(1)')
      expect(first_migration.find_element(:xpath, "//span[text()[contains(.,'Updated')]]")).to be_displayed
      f('.bcs__history-item:nth-of-type(1) .pill').click
      expect(f('.bcs__history-item__change-exceps').
               find_element(:xpath, "//span[text()[contains(., 'Content changed exceptions')]]")).to be_displayed
    end
  end

  context "quizzes" do
    before :once do
      create_and_migrate_master_quizzes(@master)
    end

    before :each do
      user_session(@master_teacher)
    end

    it "shows sync history modal for quizzes", priority: "2", test_id: 3179206 do
      update_child_quiz(@minion)
      update_master_quiz_and_migrate(@master)
      get "/courses/#{@master.id}"
      f('.blueprint__root .bcs__wrapper .bcs__trigger').click
      f('#mcSyncHistoryBtn').click
      run_jobs
      second_migration = f('.bcs__history-item:nth-of-type(2)')
      expect(second_migration.find_element(:xpath, "//span[text()[contains(.,'Created')]]")).to be_displayed
      first_migration = f('.bcs__history-item:nth-of-type(1)')
      expect(first_migration.find_element(:xpath, "//span[text()[contains(.,'Updated')]]")).to be_displayed
      f('.bcs__history-item:nth-of-type(1) .pill').click
      expect(f('.bcs__history-item__change-exceps').
               find_element(:xpath, "//span[text()[contains(., 'Due Dates changed exceptions')]]")).to be_displayed
    end
  end
end
