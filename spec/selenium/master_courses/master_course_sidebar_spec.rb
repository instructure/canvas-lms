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
require_relative '../../apis/api_spec_helper'

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
    @master = course_factory(:active_all => true)
    @master_teacher = @teacher
    @template = MasterCourses::MasterTemplate.set_as_master_course(@master)
    @minion =  @template.add_child_course!(course_factory(:name => "Minion", :active_all => true)).child_course

    # setup some stuff
    @file = attachment_model(:context => @master, :display_name => 'Some File')
    @assignment = @master.assignments.create! :title => 'Blah', :points_possible => 10
    run_master_migration

    # now push some incremental changes
    Timecop.freeze(2.seconds.from_now) do
      @page = @master.wiki.wiki_pages.create! :title => 'Unicorn'
      page_tag = @template.content_tag_for(@page)
      page_tag.restrictions = @template.default_restrictions
      page_tag.save!
      @quiz = @master.quizzes.create! :title => 'TestQuiz'
      @file = attachment_model(:context => @master, :display_name => 'Some File')
      @file.update_attribute :display_name, 'I Can Rename Files Too'
      @assignment.destroy
    end
  end

  describe "as a master course teacher" do
    before :each do
      user_session(@master_teacher)
    end

    it "should show sidebar trigger tab" do
     get "/courses/#{@master.id}"
     expect(f('.blueprint__root .bcs__wrapper .bcs__trigger')).to be_displayed
    end

    it "should show sidebar when trigger is clicked" do
      get "/courses/#{@master.id}"
      f('.blueprint__root .bcs__wrapper .bcs__trigger').click
      expect(f('.bcs__content')).to be_displayed
    end

    it "should not show the Associations buton" do
      get "/courses/#{@master.id}"
      f('.blueprint__root .bcs__wrapper .bcs__trigger').click
      expect(f('.bcs__content')).not_to contain_css('button#mcSidebarAsscBtn')
    end

    it "should show Sync History modal when button is clicked" do
      get "/courses/#{@master.id}"
      f('.blueprint__root .bcs__wrapper .bcs__trigger').click
      f('button#mcSyncHistoryBtn').click
      expect(f('div[aria-label="Sync History"]')).to be_displayed
    end

    it "should show Unsynced Changes modal when button is clicked" do
      get "/courses/#{@master.id}"
      f('.blueprint__root .bcs__wrapper .bcs__trigger').click
      wait_for_ajaximations
      f('button#mcUnsyncedChangesBtn').click
      wait_for_ajaximations
      expect(f('div[aria-label="Unsynced Changes"]')).to be_displayed
    end
  end

  describe "as a master course admin" do
    before :once do
      account_admin_user(:active_all => true)
    end

    before :each do
      user_session(@admin)
    end

    it "should show the Associations buton" do
      get "/courses/#{@master.id}"
      f('.blueprint__root .bcs__wrapper .bcs__trigger').click
      expect(f('.bcs__content')).to contain_css('button#mcSidebarAsscBtn')
    end

    it "should show Associations modal when button is clicked" do
      get "/courses/#{@master.id}"
      f('.blueprint__root .bcs__wrapper .bcs__trigger').click
      f('button#mcSidebarAsscBtn').click
      expect(f('div[aria-label="Associations"]')).to be_displayed
    end
  end
end
