require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/conversations_common')

describe "conversations context filtering" do
  it_should_behave_like "conversations selenium tests"

  before (:each) do
    @course.update_attribute(:name, "the course")
    @course1 = @course
    @s1 = User.create(:name => "student1")
    @s2 = User.create(:name => "student2")
    @course1.enroll_user(@s1).update_attribute(:workflow_state, 'active')
    @course1.enroll_user(@s2).update_attribute(:workflow_state, 'active')
    @group = @course1.groups.create(:name => "the group")
    @group.users << @user << @s1 << @s2

    @course2 = course(:active_all => true, :course_name => "that course")
    @course2.enroll_teacher(@user).accept
    @course2.enroll_user(@s1).update_attribute(:workflow_state, 'active')
  end

  it "should capture the course when sending a message to a group" do
    new_conversation
    browse_menu

    browse("the course", "Student Groups", "the group") { click "Select All" }
    submit_message_form(:add_recipient => false)

    audience = find_with_jquery("#create_message_form ul.conversations .audience")
    audience.text.should include @course1.name
    audience.text.should_not include @course2.name
    audience.text.should include @group.name
  end

  it "should capture the course when sending a message to a user under a course" do
    new_conversation
    browse_menu

    browse("the course") { search("stu") { click "student1" } }
    submit_message_form(:add_recipient => false)

    audience = find_with_jquery("#create_message_form ul.conversations .audience")
    audience.text.should include @course1.name
    audience.text.should_not include @course2.name
    audience.text.should_not include @group.name
  end

  it "should let you filter by a course" do
    new_conversation
    browse_menu
    browse("the course", "Everyone") { click "Select All" }
    submit_message_form(:add_recipient => false, :message => "asdf")

    new_conversation(false)
    browse_menu
    browse("that course", "Everyone") { click "Select All" }
    submit_message_form(:add_recipient => false, :message => "qwerty")

    find_all_with_jquery('#conversations > ul > li:visible').size.should eql 2

    @input = find_with_jquery("#context_tags_filter input:visible")
    search("the course", "context_tags") { click("the course") }

    keep_trying_until { driver.find_element(:id, "create_message_form") }
    conversations = find_all_with_jquery('#conversations > ul > li:visible')
    conversations.size.should eql 1
    conversations.first.find_element(:css, 'p').text.should eql 'asdf'
  end

  it "should let you filter by a user" do
    new_conversation
    browse_menu
    browse("the course", "Everyone") { click "Select All" }
    submit_message_form(:add_recipient => false, :message => "asdf")

    new_conversation(false)
    browse_menu
    browse("that course", "Everyone") { click "Select All" }
    submit_message_form(:add_recipient => false, :message => "qwerty")

    @input = find_with_jquery("#context_tags_filter input:visible")
    search("student2", "context_tags") { click("student2") }

    keep_trying_until { driver.find_element(:id, "create_message_form") }
    conversations = find_all_with_jquery('#conversations > ul > li:visible')
    conversations.size.should eql 1
    conversations.first.find_element(:css, 'p').text.should eql 'asdf'
  end

  it "should let you filter by a group" do
    new_conversation
    browse_menu
    browse("the course", "Everyone") { click "Select All" }
    submit_message_form(:add_recipient => false, :message => "asdf")

    new_conversation(false)
    browse_menu
    browse("the group") { click "Select All" }
    submit_message_form(:add_recipient => false, :message => "qwerty")

    @input = find_with_jquery("#context_tags_filter input:visible")
    search("the group", "context_tags") {
      menu.should eql ["the group"]
      elements.first.first.text.should include "the course" # make sure the group context is shown
      click("the group")
    }

    keep_trying_until { driver.find_element(:id, "create_message_form") }
    conversations = find_all_with_jquery('#conversations > ul > li:visible')
    conversations.size.should eql 1
    conversations.first.find_element(:css, 'p').text.should eql 'qwerty'
  end

  it "should show the term name by the course" do
    new_conversation
    browse_menu

    browse("the course") { search("stu") { click "student1" } }
    submit_message_form(:add_recipient => false)

    @input = find_with_jquery("#context_tags_filter input:visible")
    search("the course", "context_tags") do
      term_info = driver.find_element(:css, '.autocomplete_menu .name .context_info')
      term_info.text.should == "(#{@course1.enrollment_term.name})"
    end
  end

  it "should not show the default term name" do
    new_conversation
    browse_menu

    browse("the course") { search("stu") { click "student1" } }
    submit_message_form(:add_recipient => false)

    @input = find_with_jquery("#context_tags_filter input:visible")
    search("that course", "context_tags") do
      term_info = driver.find_element(:css, '.autocomplete_menu .name')
      term_info.text.should == "that course"
    end
  end
end