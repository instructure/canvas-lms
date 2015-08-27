require File.expand_path(File.dirname(__FILE__) + '/common')

describe "concluded/unconcluded" do
  include_context "in-process server selenium tests"

  before do
    username = "nobody@example.com"
    password = "asdfasdf"
    u = user_with_pseudonym :active_user => true,
                            :username => username,
                            :password => password
    u.save!
    @e = course_with_teacher :active_course => true,
                             :user => u,
                             :active_enrollment => true
    @e.save!

    user_model
    @student = @user
    @course.enroll_student(@student).accept
    @group = @course.assignment_groups.create!(:name => "default")
    @assignment = @course.assignments.create!(:submission_types => 'online_quiz', :title => 'quiz assignment', :assignment_group => @group)
    create_session(u.pseudonym)
  end

  it "should let the teacher edit the gradebook by default" do
    get "/courses/#{@course.id}/gradebook"
    wait_for_ajax_requests

    entry = f(".slick-cell.l2.r2")
    expect(entry).to be_displayed
    entry.click
    expect(entry.find_element(:css, ".gradebook-cell-editable")).to be_displayed
  end

  it "should not let the teacher edit the gradebook when concluded" do
    @e.conclude
    get "/courses/#{@course.id}/gradebook"

    entry = f(".slick-cell.l2.r2")
    expect(entry).to be_displayed
    entry.click
    expect(entry.find_element(:css, ".gradebook-cell")).not_to have_class('gradebook-cell-editable')
  end

  it "should let the teacher add comments to the gradebook by default" do
    get "/courses/#{@course.id}/gradebook"

    entry = f(".slick-cell.l2.r2")
    expect(entry).to be_displayed
    driver.execute_script("$('.slick-cell.l2.r2').mouseover();")
    entry.find_element(:css, ".gradebook-cell-comment").click
    wait_for_ajaximations
    expect(f(".submission_details_dialog")).to be_displayed
    expect(f(".submission_details_dialog #add_a_comment")).to be_displayed
  end

  it "should not let the teacher add comments to the gradebook when concluded" do
    @e.conclude
    get "/courses/#{@course.id}/gradebook"

    entry = f(".slick-cell.l2.r2")
    expect(entry).to be_displayed
    driver.execute_script("$('.slick-cell.l2.r2').mouseover();")
    expect(entry.find_element(:css, ".gradebook-cell-comment")).not_to be_displayed
  end
end
