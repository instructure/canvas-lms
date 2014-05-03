require File.expand_path(File.dirname(__FILE__) + '/common')

describe "cross-listing" do
  include_examples "in-process server selenium tests"

  before do
    course_with_teacher_logged_in
    @course1       = @course
    @course2       = course_with_teacher(
      :active_course     => true,
      :user              => @user,
      :active_enrollment => true).course

    @course2.update_attribute(:name, 'my course')
    @section = @course1.course_sections.first
    get "/courses/#{@course1.id}/sections/#{@section.id}"
  end

  it "should allow cross-listing a section" do
    f('.crosslist_link').click
    form = f('#crosslist_course_form')
    submit_btn = form.find_element(:css, '.submit_button')
    form.should_not be_nil
    form.find_element(:css, '.submit_button').should have_attribute(:disabled,'true')

    course_id   = form.find_element(:id, 'course_id')
    course_name = f('#course_autocomplete_name')

    # crosslist a valid course
    course_id.click
    course_id.clear
    course_id.send_keys([:control, 'a'], @course2.id.to_s, "\n")
    keep_trying_until { course_name.text != "Confirming Course ID \"#{@course2.id}\"..." }
    course_name.text.should == @course2.name
    form.find_element(:id, 'course_autocomplete_id').should have_attribute(:value, @course.id.to_s)
    submit_btn.should_not have_class('disabled')
    submit_form(form)
    wait_for_ajaximations
    keep_trying_until { driver.current_url.match /courses\/#{@course2.id}/ }

    # verify teacher doesn't have de-crosslist privileges
    get "/courses/#{@course2.id}/sections/#{@section.id}"
    ff('.uncrosslist_link').length.should == 0

    # enroll teacher and de-crosslist
    @course1.enroll_teacher(@user).accept
    get "/courses/#{@course2.id}/sections/#{@section.id}"
    f('.uncrosslist_link').click
    f('#uncrosslist_form').should be_displayed
    submit_form('#uncrosslist_form')
    wait_for_ajaximations
    keep_trying_until { driver.current_url.should match /courses\/#{@course1.id}/ }
  end

  it "should not allow cross-listing an invalid section" do
    f('.crosslist_link').click
    form = f('#crosslist_course_form')
    course_id   = form.find_element(:id, 'course_id')
    course_name = f('#course_autocomplete_name')
    course_id.click
    course_id.send_keys "-1\n"
    keep_trying_until { course_name.text != 'Confirming Course ID "-1"...' }
    course_name.text.should == 'Course ID "-1" not authorized for cross-listing'
  end


  it "should allow cross-listing a section" do
    pending('marked as pending instead of commenting out the whole block, I assume this was an intermittent failure')
    # so, we have two courses with the teacher enrolled in both.
    course_with_teacher_logged_in
    course = @course
    other_course = course_with_teacher(:active_course => true,
                                       :user => @user,
                                       :active_enrollment => true).course
    other_course.update_attribute(:name, "cool course")
    section = course.course_sections.first

    # we visit the first course's section. the teacher is enrolled in this
    # section. we're going to crosslist it.
    get "/courses/#{course.id}/sections/#{section.id}"
    f(".crosslist_link").click
    form = f("#crosslist_course_form")
    form.find_element(:css, ".submit_button").should have_attribute(:disabled, "true")
    form.should_not be_nil

    # let's try and crosslist an invalid course
    form.find_element(:css, "#course_id").click
    form.find_element(:css, "#course_id").send_keys("-1\n")
    keep_trying_until { f("#course_autocomplete_name").text != "Confirming Course ID \"-1\"..." }
    f("#course_autocomplete_name").text.should ==("Course ID \"-1\" not authorized for cross-listing")

    # k, let's crosslist to the other course
    form.find_element(:css, "#course_id").click
    form.find_element(:css, "#course_id").clear
    form.find_element(:css, "#course_id").send_keys([:control, 'a'], other_course.id.to_s, "\n")
    keep_trying_until { f("#course_autocomplete_name").text != "Confirming Course ID \"#{other_course.id}\"..." }
    f("#course_autocomplete_name").text.should == other_course.name
    form.find_element(:css, "#course_autocomplete_id").should have_attribute(:value, other_course.id.to_s)
    form.find_element(:css, ".submit_button").should have_attribute(:disable, 'false')
    submit_form(form)
    keep_trying_until { driver.current_url.match(/courses\/#{other_course.id}/) }

    # yay, so, now the teacher is not enrolled in the first course (the section
    # they were enrolled in got moved). they don't have the rights to
    # uncrosslist.
    get "/courses/#{other_course.id}/sections/#{section.id}"
    ff(".uncrosslist_link").length.should == 0

    # enroll, and make sure the teacher can uncrosslist.
    course.enroll_teacher(@user).accept
    get "/courses/#{other_course.id}/sections/#{section.id}"
    f(".uncrosslist_link").click
    f("#uncrosslist_form").should be_displayed
    submit_form("#uncrosslist_form")
    keep_trying_until { driver.current_url.match(/courses\/#{course.id}/) }
  end
end
