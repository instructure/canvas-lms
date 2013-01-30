require File.expand_path(File.dirname(__FILE__) + '/helpers/conversations_common')

describe "conversations recipient finder" do
  it_should_behave_like "in-process server selenium tests"
  it_should_behave_like "conversations selenium tests"

  before(:each) do
    @course.update_attribute(:name, "the course")
    @course.default_section.update_attribute(:name, "the section")
    @other_section = @course.course_sections.create(:name => "the other section")

    @s1 = User.create(:name => "student 1")
    @course.enroll_user(@s1)
    @s2 = User.create(:name => "student 2")
    @course.enroll_user(@s2, "StudentEnrollment", :section => @other_section)

    @group = @course.groups.create(:name => "the group")
    @group.users << @s1 << @user

    new_conversation
  end

  it "should allow browsing" do
    browse_menu

    menu.should == ["the course", "the group"]
    browse "the course" do
      menu.should == ["Everyone", "Teachers", "Students", "Course Sections", "Student Groups"]
      browse("Everyone") { menu.should == ["Select All", "nobody@example.com", "student 1", "student 2"] }
      browse("Teachers") { menu.should == ["nobody@example.com"] }
      browse("Students") { menu.should == ["Select All", "student 1", "student 2"] }
      browse "Course Sections" do
        menu.should == ["the other section", "the section"]
        browse "the other section" do
          menu.should == ["Students"]
          browse("Students") { menu.should == ["student 2"] }
        end
        browse "the section" do
          menu.should == ["Everyone", "Teachers", "Students"]
          browse("Everyone") { menu.should == ["Select All", "nobody@example.com", "student 1"] }
          browse("Teachers") { menu.should == ["nobody@example.com"] }
          browse("Students") { menu.should == ["student 1"] }
        end
      end
      browse "Student Groups" do
        menu.should == ["the group"]
        browse("the group") { menu.should == ["Select All", "nobody@example.com", "student 1"] }
      end
    end
    browse("the group") { menu.should == ["Select All", "nobody@example.com", "student 1"] }
  end

  it "should return recently concluded courses" do
    @course.complete!

    browse_menu
    menu.should == ["the course", "the group"]

    search("course") do
      menu.should == ["the course"]
    end
  end

  it "should not show concluded enrollments as students in the course" do
    pending('bug 7583 - concluded students in a live course still show up as students in the course when addressing messages in the inbox') do
      student_1_enrollment = @s1.enrollments.last
      student_1_enrollment.update_attributes(:workflow_state => 'completed')
      student_1_enrollment.save!
      student_1_enrollment.reload
      browse_menu
      browse("the course") do
        browse("Students") { menu.should == ["Select All", "student 2"] }
      end
    end
  end

  it "should not return courses concluded a long time ago" do
    @course.complete!
    @course.update_attribute :conclude_at, 1.year.ago

    browse_menu
    menu.should == ["the group"]

    search("course") do
      menu.should == ["No results found"]
    end
  end

  it "should check already-added tokens when browsing" do
    browse_menu

    browse("the group") do
      menu.should == ["Select All", "nobody@example.com", "student 1"]
      toggle "student 1"
      tokens.should == ["student 1"]
    end

    browse("the course") do
      browse("Everyone") do
        toggled.should == ["student 1"]
      end
    end
  end

  it "should have working select all checkboxes in appropriate contexts" do
    browse_menu

    browse "the course" do
      toggle "Everyone"
      toggled.should == ["Everyone", "Teachers", "Students"]
      tokens.should == ["the course: Everyone"]

      toggle "Everyone"
      toggled.should == []
      tokens.should == []

      toggle "Students"
      toggled.should == ["Students"]
      tokens.should == ["the course: Students"]

      toggle "Teachers"
      toggled.should == ["Everyone", "Teachers", "Students"]
      tokens.should == ["the course: Everyone"]

      toggle "Teachers"
      toggled.should == ["Students"]
      tokens.should == ["the course: Students"]

      browse "Teachers" do
        toggle "nobody@example.com"
        toggled.should == ["nobody@example.com"]
        tokens.should == ["the course: Students", "nobody@example.com"]

        toggle "nobody@example.com"
        toggled.should == []
        tokens.should == ["the course: Students"]
      end
      toggled.should == ["Students"]

      toggle "Teachers"
      toggled.should == ["Everyone", "Teachers", "Students"]
      tokens.should == ["the course: Everyone"]

      browse "Students" do
        toggle "Select All"
        toggled.should == []
        tokens.should == ["the course: Teachers"]

        toggle "student 1"
        toggle "student 2"
        toggled.should == ["Select All", "student 1", "student 2"]
        tokens.should == ["the course: Everyone"]
      end
      toggled.should == ["Everyone", "Teachers", "Students"]

      browse "Everyone" do
        toggle "student 1"
        toggled.should == ["nobody@example.com", "student 2"]
        tokens.should == ["nobody@example.com", "student 2"]
      end
      toggled.should == []
    end
  end

  it "should allow searching" do
    search("t") do
      menu.should == ["the course", "the other section", "the section", "student 1", "student 2"]
    end
  end

  it "should show the group context when searching at the top level" do
    search("the group") do
      menu.first.should == "the group"
      elements.first.first.text.should include "the course"
    end
  end

  it "should omit already-added tokens when searching" do
    search("student") do
      menu.should == ["student 1", "student 2"]
      click "student 1"
    end
    tokens.should == ["student 1"]
    search("stu") do
      menu.should == ["student 2"]
    end
  end

  it "should allow searching under supported contexts" do
    browse_menu
    browse "the course" do
      search("t") { menu.should == ["the other section", "the section", "the group", "student 1", "student 2"] }
      browse "Everyone" do
        # only returns users
        search("T") { menu.should == ["student 1", "student 2"] }
      end
      browse "Course Sections" do
        # only returns sections
        search("student") { menu.should == ["No results found"] }
        search("r") { menu.should == ["the other section"] }
        browse "the section" do
          search("s") { menu.should == ["student 1"] }
        end
      end
      browse "Student Groups" do
        # only returns groups
        search("student") { menu.should == ["No results found"] }
        search("the") { menu.should == ["the group"] }
        browse "the group" do
          search("s") { menu.should == ["student 1"] }
          search("group") { menu.should == ["No results found"] }
        end
      end
    end
  end

  it "should allow a user id in the url hash to add recipient" do
    # check without any user_name
    get conversations_path(:user_id => @s1.id)
    wait_for_ajaximations
    tokens.should == ["student 1"]
    # explanation of user_name param: we used to pass the user name in the
    # hash fragment, and it was spoofable. now we load that data via ajax.
    get conversations_path(:user_id => @s1.id, :user_name => "some_fake_name")
    wait_for_ajaximations
    tokens.should == ["student 1"]
  end

  it "should reject a non-contactable user id in the url hash" do
    other = User.create(:name => "other guy")
    get conversations_path(:user_id => other.id)
    wait_for_ajaximations
    tokens.should == []
  end

  it "should allow a non-contactable user in the hash if a shared conversation exists" do
    other = User.create(:name => "other guy")
    # if the users have a conversation in common already, then the recipient can be added
    c = Conversation.initiate([@user.id, other.id], true)
    get conversations_path(:user_id => other.id, :from_conversation_id => c.id)
    wait_for_ajaximations
    tokens.should == ["other guy"]
  end

  it "should not show student view student to other students" do
    @fake_student = @course.student_view_student
    search(@fake_student.name) do
      menu.should == ["No results found"]
    end
  end
end
