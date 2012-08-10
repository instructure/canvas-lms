require File.expand_path(File.dirname(__FILE__) + '/helpers/conversations_common')

describe "conversations user notes" do
  it_should_behave_like "in-process server selenium tests"
  it_should_behave_like "conversations selenium tests"

  before(:each) do
    @the_teacher = User.create(:name => "teacher bob")
    @course.enroll_teacher(@the_teacher)
    @the_student = User.create(:name => "student bob")
    @course.enroll_student(@the_student)
  end

  it "should not allow user notes if not enabled" do
    @course.account.update_attribute(:enable_user_notes, false)
    new_conversation
    add_recipient("student bob")
    f("#add_to_faculty_journal").should_not be_displayed
  end

  it "should not allow user notes to teachers" do
    @course.account.update_attribute(:enable_user_notes, true)
    new_conversation
    add_recipient("teacher bob")
    f("#add_to_faculty_journal").should_not be_displayed
  end

  it "should not allow user notes on group conversations" do
    @course.account.update_attribute(:enable_user_notes, true)
    new_conversation
    add_recipient("student bob")
    add_recipient("teacher bob")
    f("#add_to_faculty_journal").should_not be_displayed
    fj("#create_message_form input:visible").send_keys :backspace
    f("#add_to_faculty_journal").should be_displayed
  end

  it "should allow user notes on new private conversations with students" do
    @course.account.update_attribute(:enable_user_notes, true)
    new_conversation
    add_recipient("student bob")
    checkbox = f("#add_to_faculty_journal")
    checkbox.should be_displayed
    checkbox.click
    submit_message_form(:add_recipient => false)
    @the_student.user_notes.size.should eql(1)
  end

  it "should allow user notes on existing private conversations with students" do
    @course.account.update_attribute(:enable_user_notes, true)
    new_conversation
    add_recipient("student bob")
    submit_message_form(:add_recipient => false)
    checkbox = f("#add_to_faculty_journal")
    checkbox.should be_displayed
    checkbox.click
    submit_message_form
    @the_student.user_notes.size.should eql(1)
  end
end
