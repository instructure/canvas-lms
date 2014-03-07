require File.expand_path(File.dirname(__FILE__) + '/common')

describe "course syllabus" do
  include_examples "in-process server selenium tests"

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

    it "should confirm existing assignments and dates are correct" do
      assignment_details = ff('td.name')
      assignment_details[0].text.should == @assignment_1.title
      assignment_details[1].text.should == @assignment_2.title
    end

    it "should edit the description" do
      new_description = "new syllabus description"
      f('.edit_syllabus_link').click
      # check that the wiki sidebar is visible
      f('#editor_tabs .wiki-sidebar-header').should include_text("Insert Content into the Page")
      edit_form = f('#edit_course_syllabus_form')
      wait_for_tiny(keep_trying_until { f('#edit_course_syllabus_form') })
      type_in_tiny('#course_syllabus_body', new_description)
      submit_form(edit_form)
      wait_for_ajaximations
      f('#course_syllabus').text.should == new_description
    end

    it "should validate Jump to Today works on the mini calendar" do
      2.times { f('.next_month_link').click }
      f('.jump_to_today_link').click
      f('.mini_month .today').should have_attribute('id', "mini_day_#{Time.now.strftime('%Y_%m_%d')}")
    end
  end
end
