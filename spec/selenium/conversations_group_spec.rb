require File.expand_path(File.dirname(__FILE__) + '/helpers/conversations_common')

describe "conversations group" do
  it_should_behave_like "in-process server selenium tests"
  it_should_behave_like "conversations selenium tests"

  before(:each) do
    @course.update_attribute(:name, "the course")
    @course.default_section.update_attribute(:name, "the section")
    @other_section = @course.course_sections.create(:name => "the other section")

    s1 = User.create(:name => "student 1")
    @course.enroll_user(s1)
    s2 = User.create(:name => "student 2")
    @course.enroll_user(s2, "StudentEnrollment", :section => @other_section)

    @group = @course.groups.create(:name => "the group")
    @group.users << s1

    new_conversation
    @input = fj("#create_message_form input:visible")
    @checkbox = f("#group_conversation")
  end

  def choose_recipient(*names)
    name = names.shift
    level = 1

    @input.send_keys(name)
    wait_for_ajaximations(150)
    loop do
      keep_trying_until { ffj('.autocomplete_menu:visible .list').size == level }
      driver.execute_script("return $('.autocomplete_menu:visible .list').last().find('ul').last().find('li').toArray();").detect { |e|
        (e.find_element(:tag_name, :b).text rescue e.text) == name
      }.click
      wait_for_ajaximations

      break if names.empty?

      level += 1
      name = names.shift
    end
    keep_trying_until { fj('.autocomplete_menu:visible').nil? }
  end

  it "should not be an option with no recipients" do
    @checkbox.should_not be_displayed
  end

  it "should not be an option for a single individual recipient" do
    choose_recipient("student 1")
    @checkbox.should_not be_displayed
  end

  it "should be an option, default false, for a single 'bulk' recipient" do
    choose_recipient("the course", "Everyone", "Select All")
    @checkbox.should be_displayed
    is_checked("#group_conversation").should be_false
  end

  it "should be an option, default false, for multiple individual recipients" do
    choose_recipient("student 1")
    choose_recipient("student 2")
    @checkbox.should be_displayed
    is_checked("#group_conversation").should be_false
  end

  it "should disappear when there are no longer multiple recipients" do
    choose_recipient("student 1")
    choose_recipient("student 2")
    @input.send_keys([:backspace])
    @checkbox.should_not be_displayed
  end

  it "should revert to false after disappearing and reappearing" do
    choose_recipient("student 1")
    choose_recipient("student 2")
    @checkbox.click
    @input.send_keys([:backspace])
    choose_recipient("student 2")
    @checkbox.should be_displayed
    is_checked("#group_conversation").should be_false
  end
end
