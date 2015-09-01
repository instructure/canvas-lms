require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/public_courses_context')
require File.expand_path(File.dirname(__FILE__) + '/helpers/files_common')

describe "course syllabus" do
  include_context "in-process server selenium tests"

  def add_assignment(title, points)
    #assignment data
    assignment = assignment_model({
                                      :course => @course,
                                      :title => title,
                                      :due_at => nil,
                                      :points_possible => points,
                                      :submission_types => 'online_text_entry',
                                      :assignment_group => @group
                                  })
    rubric_model
    @association = @rubric.associate_with(assignment, @course, :purpose => 'grading')
    assignment.reload
  end

  context "as a teacher" do

    before (:each) do
      course_with_teacher_logged_in

      @group = @course.assignment_groups.create!(:name => 'first assignment group')
      @assignment_1 = add_assignment('first assignment title', 50)
      @assignment_2 = add_assignment('second assignment title', 100)

      get "/courses/#{@course.id}/assignments/syllabus"
      wait_for_ajaximations
    end

    it "should confirm existing assignments and dates are correct", priority:"1", test_id: 237016 do
      assignment_details = ff('td.name')
      expect(assignment_details[0].text).to eq @assignment_1.title
      expect(assignment_details[1].text).to eq @assignment_2.title
    end

    it "should edit the description", priority:"1", test_id: 237017 do
      new_description = "new syllabus description"
      f('.edit_syllabus_link').click
      # check that the wiki sidebar is visible
      expect(f('#editor_tabs .wiki-sidebar-header')).to include_text("Insert Content into the Page")
      edit_form = f('#edit_course_syllabus_form')
      wait_for_tiny(keep_trying_until { f('#edit_course_syllabus_form') })
      type_in_tiny('#course_syllabus_body', new_description)
      submit_form(edit_form)
      wait_for_ajaximations
      expect(f('#course_syllabus').text).to eq new_description
    end

    it "should insert a file using RCE in the syllabus", priority: "1", test_id: 126672 do
      file = @course.attachments.create!(display_name: 'some test file', uploaded_data: default_uploaded_data)
      file.context = @course
      file.save!
      get "/courses/#{@course.id}/assignments/syllabus"
      f('.edit_syllabus_link').click
      insert_file_from_rce
    end

    it "should validate Jump to Today works on the mini calendar", priority:"1", test_id: 237017 do
      2.times { f('.next_month_link').click }
      f('.jump_to_today_link').click
      expect(f('.mini_month .today')).to have_attribute('id', "mini_day_#{Time.now.strftime('%Y_%m_%d')}")
    end

    describe "Accessibility" do
      it "should set focus to the Jump to Today link after clicking Edit the Description", priority:"2", test_id: 237019 do
        f('.edit_syllabus_link').click
        check_element_has_focus(f('.jump_to_today_link'))
      end
    end
  end

  context "when a public course is accessed" do
    include_context "public course as a logged out user"

    it "should display course syllabus", priority: "1", test_id: 270034 do
      get "/courses/#{public_course.id}/assignments/syllabus"
      expect(f('#course_syllabus')).to be_displayed
    end
  end
end
