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

require_relative '../../common'
require_relative '../../helpers/assignments_common'
require_relative '../../helpers/public_courses_context'
require_relative '../../helpers/files_common'

describe "assignments" do
  include_context "in-process server selenium tests"
  include FilesCommon
  include AssignmentsCommon

  # note: due date testing can be found in assignments_overrides_spec

  context "as a teacher" do
    before(:each) do
      course_with_teacher_logged_in
      enable_all_rcs @course.account
      stub_rcs_config
      @course.start_at = nil
      @course.save!
      @course.require_assignment_group
    end

    context "save and publish button" do

      def create_assignment(publish = true, params = {name: "Test Assignment"})
        @assignment = @course.assignments.create(params)
        @assignment.unpublish unless publish
        get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
      end

      it "should not exist in a published assignment", priority: "1", test_id: 140648 do
        create_assignment

        expect(f("#content")).not_to contain_css(".save_and_publish")
      end
    end

    it "should switch text editor context from RCE to HTML", priority: "1", test_id: 699624 do
      get "/courses/#{@course.id}/assignments/new"
      wait_for_ajaximations
      text_editor=f('.mce-tinymce')
      expect(text_editor).to be_displayed
      html_editor_link=fln('HTML Editor')
      expect(html_editor_link).to be_displayed
      type_in_tiny 'textarea[name=description]', 'Testing HTML- RCE Toggle'
      html_editor_link.click
      wait_for_ajaximations
      rce_link=fln('Rich Content Editor')
      rce_editor=f('#assignment_description')
      expect(html_editor_link).not_to be_displayed
      expect(rce_link).to be_displayed
      expect(text_editor).not_to be_displayed
      expect(rce_editor).to be_displayed
      expect(f('#assignment_description')).to have_value('<p>Testing HTML- RCE Toggle</p>')
    end

    it "should create an assignment using main add button", priority: "1", test_id: 132582 do
      skip 'fragile spec, needs to be reworked, see CORE-877'
      assignment_name = 'first assignment'
      # freeze for a certain time, so we don't get unexpected ui complications
      time = DateTime.new(Time.now.year,1,7,2,13)
      Timecop.freeze(time) do
        due_at = format_time_for_view(time)

        get "/courses/#{@course.id}/assignments"
        wait_for_ajaximations
        #create assignment
        f(".new_assignment").click
        wait_for_ajaximations
        f('#assignment_name').send_keys(assignment_name)
        f('#assignment_points_possible').send_keys('10')
        ['#assignment_text_entry', '#assignment_online_url', '#assignment_online_upload'].each do |element|
          f(element).click
        end
        f('.DueDateInput').send_keys(due_at)

        submit_assignment_form
        #confirm all our settings were saved and are now displayed
        wait_for_ajaximations
        expect(f('h1.title')).to include_text(assignment_name)
        expect(fj('#assignment_show .points_possible')).to include_text('10')
        expect(f('#assignment_show fieldset')).to include_text('a text entry box, a website url, or a file upload')

        expect(f('.assignment_dates')).to include_text(due_at)
      end
    end

    it "should keep erased field on more options click", priority: "2", test_id: 622615 do
      enable_cache do
        middle_number = '15'
        expected_date = (Time.now - 1.month).strftime("%b #{middle_number}")
        @assignment = @course.assignments.create!(
            :title => "Test Assignment",
            :points_possible => 10,
            :due_at => expected_date
        )
        section = @course.course_sections.create!(:name => "new section")
        @assignment.assignment_overrides.create! do |override|
          override.set = section
          override.title = "All"
        end

        get "/courses/#{@course.id}/assignments"
        wait_for_ajaximations
        driver.execute_script "$('.edit_assignment').first().hover().click()"
        assignment_title = f("#assign_#{@assignment.id}_assignment_name")
        assignment_points_possible = f("#assign_#{@assignment.id}_assignment_points")
        replace_content(assignment_title, "")
        replace_content(assignment_points_possible, "")
        wait_for_ajaximations
        expect_new_page_load { fj('.more_options:eq(1)').click }
        expect(f("#assignment_name").text).to match ""
        expect(f("#assignment_points_possible").text).to match ""

        first_input_val = driver.execute_script("return $('.DueDateInput__Container:first input').val();")
        expect(first_input_val).to match expected_date
        second_input_val = driver.execute_script("return $('.DueDateInput__Container:last input').val();")
        expect(second_input_val).to match ""
      end
    end

    it "should validate that a group category is selected", priority: "1", test_id: 626905 do
      assignment_name = 'first test assignment'
      @assignment = @course.assignments.create({
        :name => assignment_name,
        :assignment_group => @course.assignment_groups.create!(:name => "default")
      })

      get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
      f('#has_group_category').click
      close_visible_dialog
      f('.btn-primary[type=submit]').click
      wait_for_ajaximations
      keep_trying_until do
        expect(driver.execute_script(
          "return $('.errorBox').filter('[id!=error_box_template]')"
        )).to be_present
      end
      errorBoxes = driver.execute_script("return $('.errorBox').filter('[id!=error_box_template]').toArray();")
      visBoxes, hidBoxes = errorBoxes.partition { |eb| eb.displayed? }
      expect(visBoxes.first.text).to eq "Please create a group set"
    end

    context "group assignments" do
      before(:each) do
        ag = @course.assignment_groups.first
        @assignment1, @assignment2 = [1,2].map do |i|
          gc = GroupCategory.create(:name => "gc#{i}", :context => @course)
          group = @course.groups.create!(:group_category => gc)
          group.users << student_in_course(:course => @course, :active_all => true).user
          ag.assignments.create!(
            context: @course,
            name: "assignment#{i}",
            group_category: gc,
            submission_types: 'online_text_entry',
            peer_reviews: "1",
            automatic_peer_reviews: true)
        end
        submission = @assignment1.submit_homework(@student)
        submission.submission_type = "online_text_entry"
        submission.save!
      end

      it "should not allow group set to be changed if there are submissions", priority: "1", test_id: 626907 do
        get "/courses/#{@course.id}/assignments/#{@assignment1.id}/edit"
        wait_for_ajaximations
        # be_disabled
        expect(f("#assignment_group_category_id")).to be_disabled
      end

      it "should still show deleted group set only on an attached assignment with " +
        "submissions", priority: "2", test_id: 627149 do
        @assignment1.group_category.destroy
        @assignment2.group_category.destroy

        # ensure neither deleted group shows up on an assignment with no submissions
        get "/courses/#{@course.id}/assignments/#{@assignment2.id}/edit"
        wait_for_ajaximations

        expect(f("#assignment_group_category_id")).not_to include_text @assignment1.group_category.name
        expect(f("#assignment_group_category_id")).not_to include_text @assignment2.group_category.name

        # ensure an assignment attached to a deleted group shows the group it's attached to,
        # but no other deleted groups, and that the dropdown is disabled
        get "/courses/#{@course.id}/assignments/#{@assignment1.id}/edit"
        wait_for_ajaximations

        expect(get_value("#assignment_group_category_id")).to eq @assignment1.group_category.id.to_s
        expect(f("#assignment_group_category_id")).not_to include_text @assignment2.group_category.name
        expect(f("#assignment_group_category_id")).to be_disabled
      end

      it "should revert to a blank selection if original group is deleted with no submissions", priority: "2", test_id: 627150 do
        @assignment2.group_category.destroy
        get "/courses/#{@course.id}/assignments/#{@assignment2.id}/edit"
        wait_for_ajaximations
        expect(f("#assignment_group_category_id option[selected][value='blank']")).to be_displayed
      end

      it "should show and hide the intra-group peer review toggle depending on group setting" do
        get "/courses/#{@course.id}/assignments/#{@assignment2.id}/edit"
        wait_for_ajaximations

        expect(f("#intra_group_peer_reviews")).to be_displayed
        f("#has_group_category").click
        expect(f("#intra_group_peer_reviews")).not_to be_displayed
      end
    end

    context 'publishing' do
      before do
        ag = @course.assignment_groups.first
        @assignment = ag.assignments.create! :context => @course, :title => 'to publish'
        @assignment.unpublish
      end

      it "should show publishing status on the edit page", priority: "2", test_id: 647852 do
        get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
        wait_for_ajaximations

        expect(f("#edit_assignment_header").text).to match "Not Published"
      end
    end

    context 'save to sis' do
      it 'should not show when no passback configured', priority: "1", test_id: 244956 do
        get "/courses/#{@course.id}/assignments/new"
        wait_for_ajaximations
        expect(f("#content")).not_to contain_css('#assignment_post_to_sis')
      end

      it 'should show when powerschool is enabled', priority: "1", test_id: 244913 do
        Account.default.set_feature_flag!('post_grades', 'on')
        @course.sis_source_id = 'xyz'
        @course.save

        get "/courses/#{@course.id}/assignments/new"
        wait_for_ajaximations
        expect(f('#assignment_post_to_sis')).to_not be_nil
      end

      it 'should show when post_grades lti tool installed', priority: "1", test_id: 244957 do
        create_post_grades_tool

        get "/courses/#{@course.id}/assignments/new"
        wait_for_ajaximations
        expect(f('#assignment_post_to_sis')).to_not be_nil
      end

      it 'should not show when post_grades lti tool not installed', priority: "1", test_id: 250261 do
        Account.default.set_feature_flag!('post_grades', 'off')

        get "/courses/#{@course.id}/assignments/new"
        wait_for_ajaximations
        expect(f("#content")).not_to contain_css('#assignment_post_to_sis')
      end
    end
  end

  context "post to sis default setting" do
    before do
      account_rcs_model
      @account.set_feature_flag! 'post_grades', 'on'
      course_with_teacher_logged_in(:active_all => true, :account => @account)
      enable_all_rcs @course.account
      stub_rcs_config
    end

    it "should default to post grades if account setting is enabled", priority: "2", test_id: 498879 do
      @account.settings[:sis_default_grade_export] = {:locked => false, :value => true}
      @account.save!

      get "/courses/#{@course.id}/assignments/new"
      expect(is_checked('#assignment_post_to_sis')).to be_truthy
    end

    it "should not default to post grades if account setting is not enabled", priority: "2", test_id: 498874 do
      get "/courses/#{@course.id}/assignments/new"
      expect(is_checked('#assignment_post_to_sis')).to be_falsey
    end
  end

  context 'adding new assignment groups from assignment creation page' do
    before do
      course_with_teacher_logged_in
      enable_all_rcs @course.account
      stub_rcs_config
      @new_group = 'fine_leather_jacket'
      get "/courses/#{@course.id}/assignments/new"
      wait_for_ajaximations
      click_option('#assignment_group_id', '[ New Group ]')

      # type something in here so you can check to make sure it was not added
      fj('div.controls > input:visible').send_keys(@new_group)
    end

    it "should add a new assignment group", priority: "1", test_id:525190 do
      fj('.button_type_submit:visible').click
      wait_for_ajaximations

      expect(f('#assignment_group_id')).to include_text(@new_group)
    end

    it "should cancel adding new assignment group via the cancel button", priority: "2", test_id: 602873 do
      fj('.cancel-button:visible').click
      wait_for_ajaximations

      expect(f('#assignment_group_id')).not_to include_text(@new_group)
    end

    it "should cancel adding new assignment group via the x button", priority: "2", test_id: 602874 do
      fj('button.ui-dialog-titlebar-close:visible').click
      wait_for_ajaximations

      expect(f('#assignment_group_id')).not_to include_text(@new_group)
    end
  end
end
