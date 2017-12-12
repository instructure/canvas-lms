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

require File.expand_path(File.dirname(__FILE__) + '/../common')

module BlueprintCourseCommon
    # call this via change_blueprint_settings(course, content: false, points: false, due_dates: false, availability_dates: false)
    def change_blueprint_settings(course, master_blueprint_settings={})
        template = MasterCourses::MasterTemplate.full_template_for(course)
        template.update(default_restrictions: master_blueprint_settings)
        course.reload
    end

    # built upon the method in spec/apis/v1/master_templates_api_spec.rb
    def run_master_course_migration(master)
      template = master.master_course_templates.first
      master_teacher = master.teachers.first
      @migration = MasterCourses::MasterMigration.start_new_migration!(template, master_teacher)
      run_jobs
      @migration.reload
    end

    def create_and_migrate_master_assignments(master)
      template = master.master_course_templates.first
      @assignment1 = master.assignments.create!(title: "Assignment 1", grading_type: "points",
                                                points_possible: 10.0, unlock_at: Time.zone.now + 2.days)
      template.create_content_tag_for!(@assignment1)
      @assignment2 = master.assignments.create!(title: "Assignment 2", grading_type: "points",
                                                points_possible: 10.0, unlock_at: Time.zone.now + 2.days)
      tag1 = template.create_content_tag_for!(@assignment2)
      tag1.update(restrictions: {points: true, availability_dates: true})
      run_master_course_migration(master)
    end

    def update_child_assignment(minion, attribute, value)
      child_assignment = minion.assignments.where(title: @assignment1.title).first
      child_assignment.update(attribute => value)
    end

    def update_master_assignment_and_migrate(master, attribute, value)
      @assignment1.update(attribute => value)
      @assignment2.update(attribute => value)
      run_master_course_migration(master)
    end

    def create_and_migrate_master_discussions(master)
      template = master.master_course_templates.first
      @discussion1 = master.discussion_topics.create!(title: "Discussion 1", delayed_post_at: Time.zone.now+2.days)
      template.create_content_tag_for!(@discussion1)
      @discussion2 = master.discussion_topics.create!(title: "Discussion 2", delayed_post_at: Time.zone.now+3.days)
      tag1 = template.create_content_tag_for!(@discussion2)
      tag1.update(restrictions: {availability_dates: true})
      run_master_course_migration(master)
    end

    def update_child_discussion(minion)
      child_discussion = minion.discussion_topics.where(title: @discussion1.title).first
      child_discussion.update(delayed_post_at: Time.zone.now+3.days)
    end

    def update_master_discussion_and_migrate(master)
      @discussion1.update(delayed_post_at: Time.zone.now+1.day)
      @discussion2.update(delayed_post_at: Time.zone.now+1.day)
      run_master_course_migration(master)
    end

    def create_and_migrate_master_pages(master)
      template = master.master_course_templates.first
      @page1 = master.wiki_pages.create!(title: "Page 1", body: "Wiki Page 1")
      template.create_content_tag_for!(@page1)
      @page2 = master.wiki_pages.create!(title: "Page 2", body: "Wiki Page 2")
      tag1 = template.create_content_tag_for!(@page2)
      tag1.update(restrictions: {content: true})
      run_master_course_migration(master)
    end

    def update_child_page(minion)
      child_page = minion.wiki_pages.where(title: @page1.title).first
      child_page.update(body: "Child Wiki Page updated")
    end

    def update_master_page_and_migrate(master)
      @page1.update(body: "Wiki Page 1 updated")
      @page2.update(body: "Wiki Page 2 updated")
      run_master_course_migration(master)
    end

    def create_and_migrate_master_quizzes(master)
      template = master.master_course_templates.first
      @quiz1 = master.quizzes.create!(title: "Quiz 1", due_at: Time.zone.now+2.days)
      template.create_content_tag_for!(@quiz1)
      @quiz2 = master.quizzes.create!(title: "Quiz 2", due_at: Time.zone.now+2.days)
      tag1 = template.create_content_tag_for!(@quiz2)
      tag1.update(restrictions: {due_dates: true})
      run_master_course_migration(master)
    end

    def update_child_quiz(minion)
      child_quiz = minion.quizzes.where(title: @quiz1.title).first
      child_quiz.update(due_at: Time.zone.now + 1.day)
    end

    def update_master_quiz_and_migrate(master)
      @quiz1.update(due_at: Time.zone.now + 3.days)
      @quiz2.update(due_at: Time.zone.now + 3.days)
      run_master_course_migration(master)
    end

    ##### sidebar and associated modal helpers #####
    # open the blueprint sidebar
    def open_blueprint_sidebar
      f('.blueprint__root .bcs__wrapper .bcs__trigger').click
    end

    # open the associations modal
    def open_associations
      open_blueprint_sidebar
      f('#mcSidebarAsscBtn').click                              # open the associations modal
      expect(f('.bcs__modal-content-wrapper')).to be_displayed  # the modal is open
    end

    # open the course list behind the toggle on the associations modal
    # and make sure the data has arrived
    # this turned out to be messier than one would think
    def open_courses_list
      details_wrapper = f('.bca-course-details__wrapper')
      wait_for_ajaximations

      # Clicking the button was not reliable.
      # Focusing the filter textbox has the side effect of opening the courses list.
      driver.execute_script("document.querySelector('.bca-course-filter input').focus()")
      wait_for_ajaximations

      # confirm it's open
      expect(details_wrapper).to contain_css('.bca-table__course-row')
    end

    # reutrn the <tboey> holding the list of avaiable courses
    def available_courses_table
      f('.bca-table__content-wrapper tbody')
    end

    # return the <tr>s holding with the current list of available courses
    def available_courses
      ff('.bca-table__content-wrapper tbody tr.bca-table__course-row')
    rescue
      [] if f('.bca-table__no-results')
    end

    # return the <tbody> holding the current associations
    def current_associations_table
      ff('.bca-associations-table table tbody')[0]
    end

    # return the <tr>s holding the list of associated courses
    def current_associations
      current_tbody = current_associations_table
      current_courses = ff('tr', current_tbody)
      current_courses.shift # shift removes the row with the "current" sub-heading
      current_courses
    end

    # return the tbody holding the to be added courses
    def to_be_added_table
      ff('.bca-associations-table table tbody')[1]
    end

    # return the <tr>s holding the current list of courses to be added as
    # children of the current master course
    def to_be_added
      to_be_tbody = to_be_added_table
      to_be_courses = ff('tr', to_be_tbody)
      to_be_courses.shift # shift removes the row with the sub-heading
      to_be_courses
    end

    # return the Done/Save button (which is the last button on the page)
    def save_button
      buttons = ff('span button')
      buttons[buttons.length - 1] # last button on the page
    end

    # click the Save button and wait for it to complete
    def do_save
      save_button().click
      expect(f('#flashalert_message_holder')).to contain_css('div') # the alert saying the save completed
    end

    shared_context "blueprint courses files context" do

      def options_panel
        f('.al-options')
      end

      def options_button
        f('.al-trigger')
      end

      def files_page_header
        f('.ef-header')
      end

      def file_object
        f('.ef-item-row .ef-date-created-col')
      end

      def lock_icon_container
        f('.ef-directory .ef-item-row .lock-icon')
      end
    end



end
