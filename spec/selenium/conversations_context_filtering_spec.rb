require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/conversations_common')

describe "conversations context filtering" do
  it_should_behave_like "in-process server selenium tests"
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

  it "should order by active-ness before name or type" do
    @course2.complete!
    new_conversation
    @input = find_with_jquery("#context_tags_filter input:visible")
    search("th", "context_tags") do
      menu.should eql ["the course", "the group", "that course"]
    end
  end

  it "should let you browse for filters" do
    new_conversation
    @browser = fj("#context_tags_filter .browser:visible")
    @input = fj("#context_tags_filter input:visible")
    browse_menu

    menu.should eql ["that course", "the course", "the group"]
    browse "that course" do
      menu.should eql ["that course", "Everyone", "Teachers", "Students"]
      browse("Everyone") { menu.should eql ["nobody@example.com", "student1", "User"] }
      browse("Teachers") { menu.should eql ["nobody@example.com", "User"] }
      browse("Students") { menu.should eql ["student1"] }
    end
    browse "the course" do
      menu.should eql ["the course", "Everyone", "Teachers", "Students", "Student Groups"]
      browse("Everyone") { menu.should eql ["nobody@example.com", "student1", "student2"] }
      browse("Teachers") { menu.should eql ["nobody@example.com"] }
      browse("Students") { menu.should eql ["student1", "student2"] }
      browse "Student Groups" do
        menu.should eql ["the group"]
        browse("the group") { menu.should eql ["the group", "nobody@example.com", "student1", "student2"] }
      end
    end
    browse("the group") { menu.should eql ["the group", "nobody@example.com", "student1", "student2"] }
  end

  it "should let you filter by a course" do
    new_conversation
    browse_menu
    browse("the course", "Everyone") { click "student2" }
    browse_menu
    browse("that course", "Everyone") { click "student1" }
    submit_message_form(:add_recipient => false, :message => "asdf") # tagged with both courses

    new_conversation(false)
    browse_menu
    browse("that course", "Everyone") { click "Select All" }
    submit_message_form(:add_recipient => false, :message => "qwerty")

    get_conversations.size.should eql 2

    @input = find_with_jquery("#context_tags_filter input:visible")
    search("the course", "context_tags") { browse("the course") { click("the course") } }

    keep_trying_until {
      conversations = get_conversations
      conversations.size.should eql 1
      conversations.first.find_element(:css, 'p').text.should eql 'asdf'
    }

    # filtered course should be first in the audience's contexts
    get_conversations.first.find_element(:css, '.audience em').text.should eql 'the course and that course'
  end

  it "should let you filter by a course that was concluded a long time ago" do
    new_conversation
    browse_menu
    browse("the course", "Everyone") { click "Select All" }
    submit_message_form(:add_recipient => false, :message => "asdf")

    new_conversation(false)
    browse_menu
    browse("that course", "Everyone") { click "Select All" }
    submit_message_form(:add_recipient => false, :message => "qwerty")

    get_conversations.size.should eql 2

    @course1.complete!
    @course1.update_attribute :conclude_at, 1.year.ago

    get "/conversations/sent"
    
    @input = find_with_jquery("#context_tags_filter input:visible")
    search("the course", "context_tags") { browse("the course") { click("the course") } }

    keep_trying_until {
      conversations = get_conversations
      conversations.size.should eql 1
      conversations.first.find_element(:css, 'p').text.should eql 'asdf'
    }
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

    keep_trying_until {
      conversations = get_conversations
      conversations.size.should eql 1
      conversations.first.find_element(:css, 'p').text.should eql 'asdf'
    }

    # filtered student should be first in the audience
    get_conversations.first.find_element(:css, '.audience').text.should eql 'student2 and student1 the course'
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
      browse("the group") { click("the group") }
    }

    keep_trying_until {
      conversations = get_conversations
      conversations.size.should eql 1
      conversations.first.find_element(:css, 'p').text.should eql 'qwerty'
    }
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