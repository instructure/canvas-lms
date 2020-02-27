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

describe "master courses banner" do
  include_context "in-process server selenium tests"
  include BlueprintCourseCommon

  before :once do
    @master = course_factory(active_all: true)
    @master_teacher = @teacher
    @template = MasterCourses::MasterTemplate.set_as_master_course(@master)
    @minion = @template.add_child_course!(course_factory(name: "Minion", active_all: true)).child_course
    @minion.enroll_teacher(@master_teacher).accept!
  end

  describe "as a master course teacher" do
    before :each do
      user_session(@master_teacher)
    end

    context "for pages" do
      before :once do
        # sets up the page that gets blueprinted
        @original_page = @master.wiki_pages.create! title: 'Unicorn', body: 'don\'t exist! Sorry James'
        run_master_course_migration(@master)
        @copy_page = @minion.wiki_pages.last
      end

      it "locks down the content and shows banner", priority:"2", test_id: 3248172 do
        change_blueprint_settings(@master, content: true)
        get "/courses/#{@master.id}/pages/#{@original_page.id}"
        f('.bpc-lock-toggle button').click
        expect(f('.bpc-lock-toggle__label')).to include_text('Locked')
        expect(f('#blueprint-lock-banner')).to include_text('Content')
        run_master_course_migration(@master)
        get "/courses/#{@minion.id}/pages/#{@copy_page.id}/edit"
        assert_flash_warning_message("You are not allowed to edit the page")
      end

      it "shows locked banner when locking", priority:"2", test_id: 3248173 do
        change_blueprint_settings(@master, content: true, points: true, due_dates: true, availability_dates: true)
        get "/courses/#{@master.id}/pages/#{@original_page.id}"
        f('.bpc-lock-toggle button').click
        expect(f('.bpc-lock-toggle__label')).to include_text('Locked')
        expect(f('#blueprint-lock-banner')).to include_text('Content, Points, Due Dates & Availability Dates')
      end
    end

    context "for assignments" do
      before :once do
        # sets up the assignment that gets blueprinted
        @original_assmt = @master.assignments.create! title: 'Blah', points_possible: 10, due_at: 5.days.from_now
        @original_assmt.description = 'this is the original content'
        run_master_course_migration(@master)
        @copy_assmt = @minion.assignments.last
      end

      it "locks down the content and show banner", priority: "2", test_id: 3127585 do
        change_blueprint_settings(@master, content: true)
        get "/courses/#{@master.id}/assignments/#{@original_assmt.id}"
        f('.bpc-lock-toggle button').click
        expect(f('.bpc-lock-toggle__label')).to include_text('Locked')
        expect(f('#blueprint-lock-banner')).to include_text('Content')
        run_master_course_migration(@master)
        get "/courses/#{@minion.id}/assignments/#{@copy_assmt.id}/edit"
        expect(f('#edit_assignment_wrapper')).not_to contain_css('#tinymce')
        expect(f('.bpc-lock-toggle__label')).to include_text('Locked')
        expect(f('#blueprint-lock-banner')).to include_text('Content')
      end

      it "shows locked banner when locking", priority:"1", test_id: 3127589 do
        change_blueprint_settings(@master, content: true, points: true, due_dates: true, availability_dates: true)
        get "/courses/#{@master.id}/assignments/#{@original_assmt.id}"
        f('.bpc-lock-toggle button').click
        expect(f('.bpc-lock-toggle__label')).to include_text('Locked')
        expect(f('#blueprint-lock-banner')).to include_text('Content, Points, Due Dates & Availability Dates')
      end
    end

    context "for discussions" do
      before :once do
        # sets up the assignment that gets blueprinted
        @original_disc = @master.discussion_topics.create!(title: 'Discussion time!')
        run_master_course_migration(@master)
        @copy_disc = @minion.discussion_topics.last
      end

      it "shows locked banner when locking", priority:"2", test_id: 3263121 do
        change_blueprint_settings(@master, content: true, points: true, due_dates: true, availability_dates: true)
        get "/courses/#{@master.id}/discussion_topics/#{@original_disc.id}"
        f('.bpc-lock-toggle button').click
        expect(f('.bpc-lock-toggle__label')).to include_text('Locked')
        expect(f('#blueprint-lock-banner')).to include_text('Content, Points, Due Dates & Availability Dates')
      end
    end

    context "for quizzes" do
      before :once do
        # sets up the quiz that gets blueprinted
        @original_quiz = @master.quizzes.create!(title: 'Discussion time!', due_at: 5.days.from_now)
        @original_quiz.description = 'this is the original content for the quiz'
        run_master_course_migration(@master)
        @copy_quiz = @minion.quizzes.last
      end

      it "shows locked banner when locking", priority:"2", test_id: 3263119 do
        change_blueprint_settings(@master, content: true, points: true, due_dates: true, availability_dates: true)
        get "/courses/#{@master.id}/quizzes/#{@original_quiz.id}"
        f('.bpc-lock-toggle button').click
        expect(f('.bpc-lock-toggle__label')).to include_text('Locked')
        expect(f('#blueprint-lock-banner')).to include_text('Content, Points, Due Dates & Availability Dates')
      end
    end
  end
end
