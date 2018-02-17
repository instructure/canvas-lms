#
# Copyright (C) 2012 - present Instructure, Inc.
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
require_relative '../helpers/assignments_common'
require_relative '../helpers/google_drive_common'

describe "assignments" do
  include_context "in-process server selenium tests"
  include GoogleDriveCommon
  include AssignmentsCommon

  context "as a student" do

    before(:each) do
      course_with_student_logged_in
    end

    before do
      @due_date = Time.now.utc + 2.days
      @assignment = @course.assignments.create!(:title => 'default assignment', :name => 'default assignment', :due_at => @due_date)
    end

    it "should order undated assignments by title and dated assignments by first due" do
      @second_assignment = @course.assignments.create!(:title => 'assignment 2', :name => 'assignment 2', :due_at => nil)
      @third_assignment = @course.assignments.create!(:title => 'assignment 3', :name => 'assignment 3', :due_at => nil)
      @fourth_assignment = @course.assignments.create!(:title => 'assignment 4', :name => 'assignment 4', :due_at => @due_date - 1.day)

      get "/courses/#{@course.id}/assignments"
      titles = ff('.ig-title')
      expect(titles[0].text).to eq @fourth_assignment.title
      expect(titles[1].text).to eq @assignment.title
      expect(titles[2].text).to eq @second_assignment.title
      expect(titles[3].text).to eq @third_assignment.title
    end

    it "should highlight mini-calendar dates where stuff is due" do
      @course.assignments.create!(:title => 'test assignment', :name => 'test assignment', :due_at => @due_date)

      get "/courses/#{@course.id}/assignments/syllabus"
      wait_for_ajaximations
      expect(f(".mini_calendar_day.date_#{@due_date.strftime("%m_%d_%Y")}")).to have_class('has_event')
    end

    it "should not show submission data when muted" do
      assignment = @course.assignments.create!(:title => 'test assignment', :name => 'test assignment')

      assignment.update_attributes(:submission_types => "online_url,online_upload")
      submission = assignment.submit_homework(@student)
      submission.submission_type = "online_url"
      submission.save!

      submission.add_comment(:author => @teacher, :comment => "comment before muting")
      assignment.mute!
      assignment.update_submission(@student, :hidden => true, :comment => "comment after muting")

      outcome_with_rubric
      @rubric.associate_with(assignment, @course, :purpose => "grading")

      get "/courses/#{@course.id}/assignments/#{assignment.id}"
      details = f(".details")
      expect(details).not_to include_text('comment before muting')
      expect(details).not_to include_text('comment after muting')
    end

    it "should have group comment radio buttons for individually graded group assignments" do
      u1 = @user
      student_in_course(:course => @course)
      u2 = @user
      assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload,online_text_entry", :group_category => GroupCategory.create!(:name => "groups", :context => @course), :grade_group_students_individually => true)
      group = assignment.group_category.groups.create!(:name => 'g1', :context => @course)
      group.users << u1
      group.users << @user

      get "/courses/#{@course.id}/assignments/#{assignment.id}"

      acceptable_tabs = ffj('#submit_online_upload_form,#submit_online_text_entry_form,#submit_online_url_form')
      expect(acceptable_tabs.size).to be 3
      acceptable_tabs.each do |tabby|
        expect(ffj('.formtable input[type="radio"][name="submission[group_comment]"]', tabby).size).to be 2
      end
    end

    it "should have hidden group comment input for group graded group assignments" do
      u1 = @user
      student_in_course(:course => @course)
      u2 = @user
      assignment = @course.assignments.create!(
        :title => "some assignment",
        :submission_types => "online_url,online_upload,online_text_entry",
        :group_category => GroupCategory.create!(:name => "groups", :context => @course),
        :grade_group_students_individually => false)
      group = assignment.group_category.groups.create!(:name => 'g1', :context => @course)
      group.users << u1
      group.users << @user

      get "/courses/#{@course.id}/assignments/#{assignment.id}"

      acceptable_tabs = ffj('#submit_online_upload_form,#submit_online_text_entry_form,#submit_online_url_form')
      expect(acceptable_tabs.size).to be 3
      acceptable_tabs.each do |tabby|
        expect(ffj('.formtable input[type="hidden"][name="submission[group_comment]"]', tabby).size).to be 1
      end
    end

    it "should not show assignments in an unpublished course" do
      new_course = Course.create!(:name => 'unpublished course')
      assignment = new_course.assignments.create!(:title => "some assignment")
      new_course.enroll_user(@user, 'StudentEnrollment')
      get "/courses/#{new_course.id}/assignments/#{assignment.id}"

      expect(f('.ui-state-error')).to be_displayed
      expect(f("#content")).not_to contain_css('#assignment_show')
    end

    it "should verify lock until date is enforced" do
      assignment_name = 'locked assignment'
      unlock_time = 1.day.from_now
      locked_assignment = @course.assignments.create!(:name => assignment_name, :unlock_at => unlock_time)

      get "/courses/#{@course.id}/assignments/#{locked_assignment.id}"
      expect(f('#content')).to include_text(format_date_for_view(unlock_time))
      locked_assignment.update_attributes(:unlock_at => Time.now)
      refresh_page # to show the updated assignment
      expect(f('#content')).not_to include_text('This assignment is locked until')
    end

    it "should verify due date is enforced" do
      due_date_assignment = @course.assignments.create!(:name => 'due date assignment', :due_at => 5.days.ago)
      get "/courses/#{@course.id}/assignments"
      expect(f("#assignment_group_past #assignment_#{due_date_assignment.id}")).to be_displayed
      due_date_assignment.update_attributes(:due_at => 2.days.from_now)
      refresh_page # to show the updated assignment
      expect(f("#assignment_group_upcoming #assignment_#{due_date_assignment.id}")).to be_displayed
    end

    it "should show assignment data if locked by due date or lock date" do
      assignment = @course.assignments.create!(:name => 'locked assignment',
                                               :due_at => 5.days.ago,
                                               :lock_at => 3.days.ago)
      get "/courses/#{@course.id}/assignments/#{assignment.id}"
      wait_for_ajaximations
      expect(f("#content")).not_to contain_css('.submit_assignment_link')
      expect(f(".student-assignment-overview")).to be_displayed
    end


    it "should still not show assignment data if locked by unlock date" do
      assignment = @course.assignments.create!(:name => 'not unlocked assignment',
                                               :due_at => 5.days.from_now,
                                               :unlock_at => 3.days.from_now)
      get "/courses/#{@course.id}/assignments/#{assignment.id}"
      wait_for_ajaximations
      expect(f("#content")).not_to contain_css(".student-assignment-overview")
    end

    context "overridden lock_at" do
      before :each do
        setup_sections_and_overrides_all_future
        @course.enroll_user(@student, 'StudentEnrollment', :section => @section2, :enrollment_state => 'active')
      end

      it "should show overridden lock dates for student" do
        extend TextHelper
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        expected_unlock = datetime_string(@override.unlock_at).gsub(/\s+/, ' ')
        expected_lock_at = datetime_string(@override.lock_at).gsub(/\s+/, ' ')
        expect(f('#content')).to include_text "locked until #{expected_unlock}."
      end

      it "should allow submission when within override locks" do
        @assignment.update_attributes(:submission_types => 'online_text_entry')
        # Change unlock dates to be valid for submission
        @override.unlock_at = Time.now.utc - 1.days   # available now
        @override.save!

        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        f('.submit_assignment_link').click
        wait_for_ajaximations
        assignment_form = f('#submit_online_text_entry_form')
        wait_for_tiny(assignment_form)
        wait_for_ajaximations
        body_text = 'something to submit'
        expect do
          type_in_tiny('#submission_body', body_text)
          wait_for_ajaximations
          submit_form(assignment_form)
          wait_for_ajaximations
        end.to change {
          @assignment.submissions.find_by!(user: @student).body
        }.from(nil).to("<p>#{body_text}</p>")
      end
    end

    context "click_away_accept_alert" do #this context exits to handle the click_away_accept_alert method call after each spec that needs it even if it fails early to prevent other specs from failing
      after(:each) do
        click_away_accept_alert
      end

      it "should expand the comments box on click" do
        @assignment.update_attributes(:submission_types => 'online_upload')

        get "/courses/#{@course.id}/assignments/#{@assignment.id}"

        f('.submit_assignment_link').click
        wait_for_ajaximations
        expect(driver.execute_script("return $('#submission_comment').height()")).to eq 20
        driver.execute_script("$('#submission_comment').focus()")
        wait_for_ajaximations
        expect(driver.execute_script("return $('#submission_comment').height()")).to eq 72
      end

      it "should validate file upload restrictions" do
        filename_txt, fullpath_txt, data_txt, tempfile_txt = get_file("testfile4.txt")
        filename_zip, fullpath_zip, data_zip, tempfile_zip = get_file("testfile5.zip")
        @assignment.update_attributes(:submission_types => 'online_upload', :allowed_extensions => '.txt')
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        f('.submit_assignment_link').click

        submit_file_button = f('#submit_file_button')
        submission_input = f('.submission_attachment input')
        ext_error = f('.bad_ext_msg')

        submission_input.send_keys(fullpath_txt)
        expect(ext_error).not_to be_displayed
        expect(submit_file_button['disabled']).to be_nil
        submission_input.send_keys(fullpath_zip)
        expect(ext_error).to be_displayed
        expect(submit_file_button).to be_disabled
      end
    end

    context "google drive" do
      before do
        PluginSetting.create!(:name => 'google_drive', :settings => {})
        setup_google_drive()
      end

      it "should have a google doc tab if google docs is enabled", priority: "1", test_id: 161884 do
        @assignment.update_attributes(:submission_types => 'online_upload')
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        f('.submit_assignment_link').click
        wait_for_animations

        expect(f("a[href*='submit_google_doc_form']")).to_not be_nil
      end

      context "select file or folder" do
        before(:each) do
          # double out function calls
          google_drive_connection = double()
          allow(google_drive_connection).to receive(:service_type).and_return('google_drive')
          allow(google_drive_connection).to receive(:retrieve_access_token).and_return('access_token')
          allow(google_drive_connection).to receive(:authorized?).and_return(true)

          # double files to show up from "google drive"
          file_list = create_file_list
          allow(google_drive_connection).to receive(:list_with_extension_filter).and_return(file_list)

          allow_any_instance_of(ApplicationController).to receive(:google_drive_connection).and_return(google_drive_connection)

          # create assignment
          @assignment.update_attributes(:submission_types => 'online_upload')
          get "/courses/#{@course.id}/assignments/#{@assignment.id}"
          f('.submit_assignment_link').click
          f("a[href*='submit_google_doc_form']").click
          wait_for_animations
        end

        it "should select a file from google drive", priority: "1", test_id: 161886 do
          # find file in list
          # the file we are looking for is created as the second file in the list
          expect(ff(".filename")[1]).to include_text("test.mydoc")
        end

        it "should select a file in a folder from google drive", priority: "1", test_id: 161885 do
          # open folder
          f(".folder").click
          wait_for_animations

          # find file in list
          expect(f(".filename")).to include_text("nested.mydoc")
        end
      end

      it "forces users to authenticate", priority: "1", test_id: 161892 do
        # double out google drive
        google_drive_connection = double()
        allow(google_drive_connection).to receive(:service_type).and_return('google_drive')
        allow(google_drive_connection).to receive(:retrieve_access_token).and_return(nil)
        allow(google_drive_connection).to receive(:authorized?).and_return(nil)
        allow_any_instance_of(ApplicationController).to receive(:google_drive_connection).and_return(google_drive_connection)

        @assignment.update_attributes(:submission_types => 'online_upload')
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        f('.submit_assignment_link').click
        f("a[href*='submit_google_doc_form']").click
        wait_for_animations

        # button that forces users to authenticate if they want to use google drive
        expect(fln("Authorize Google Drive Access")).to be_truthy
      end
    end

    it "should list the assignments" do
      ag = @course.assignment_groups.first

      get "/courses/#{@course.id}/assignments"
      wait_for_ajaximations

      move_to_click("label[for=show_by_type]")
      ag_el = f("#assignment_group_#{ag.id}")
      expect(ag_el).to be_present
      expect(ag_el.text).to match @assignment.name
    end

    it "should not show add/edit/delete buttons" do
      ag = @course.assignment_groups.first

      get "/courses/#{@course.id}/assignments"
      wait_for_ajaximations

      expect(f("#content")).not_to contain_css('.new_assignment')
      expect(f("#content")).not_to contain_css('#addGroup')
      expect(f("#content")).not_to contain_css('.add_assignment')
      move_to_click("label[for=show_by_type]")
      expect(f("#content")).not_to contain_css("ag_#{ag.id}_manage_link")
    end

    it "should default to grouping by date" do
      @course.assignments.create!(:title => 'undated assignment', :name => 'undated assignment')

      get "/courses/#{@course.id}/assignments"
      wait_for_ajaximations

      expect(is_checked('#show_by_date')).to be_truthy

      # assuming two undated and two future assignments created above
      expect(f('#assignment_group_upcoming')).not_to be_nil
      expect(f('#assignment_group_undated')).not_to be_nil
    end

    it "should allowing grouping by assignment group (and remember)" do
      ag = @course.assignment_groups.first

      get "/courses/#{@course.id}/assignments"
      wait_for_ajaximations

      move_to_click("label[for=show_by_type]")
      expect(is_checked('#show_by_type')).to be_truthy
      expect(f("#assignment_group_#{ag.id}")).not_to be_nil

      get "/courses/#{@course.id}/assignments"
      wait_for_ajaximations
      expect(is_checked('#show_by_type')).to be_truthy
    end

    it "should not show empty groups" do
      # assuming two undated and two future assignments created above
      empty_ag = @course.assignment_groups.create!(:name => "Empty")

      get "/courses/#{@course.id}/assignments"
      wait_for_ajaximations

      expect(f("#content")).not_to contain_css('#assignment_group_overdue')
      expect(f("#content")).not_to contain_css('#assignment_group_past')

      move_to_click("label[for=show_by_type]")
      expect(f("#content")).not_to contain_css("#assignment_group_#{empty_ag.id}")
    end

    it "should show empty assignment groups if they have a weight" do
      @course.group_weighting_scheme = "percent"
      @course.save!

      ag = @course.assignment_groups.first
      ag.group_weight = 90
      ag.save!

      empty_ag = @course.assignment_groups.create!(:name => "Empty", :group_weight => 10)

      get "/courses/#{@course.id}/assignments"
      wait_for_ajaximations

      move_to_click("label[for=show_by_type]")
      expect(f("#assignment_group_#{empty_ag.id}")).not_to be_nil
    end

    it "should correctly categorize assignments by date" do
      # assuming two undated and two future assignments created above
      undated, upcoming = @course.assignments.partition{ |a| a.due_date.nil? }

      get "/courses/#{@course.id}/assignments"
      wait_for_ajaximations

      undated.each do |a|
        expect(f("#assignment_group_undated #assignment_#{a.id}")).not_to be_nil
      end

      upcoming.each do |a|
        expect(f("#assignment_group_upcoming #assignment_#{a.id}")).not_to be_nil
      end
    end
  end
end
