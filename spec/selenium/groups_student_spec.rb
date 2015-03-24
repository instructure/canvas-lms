require File.expand_path(File.dirname(__FILE__) + '/common')

describe "student groups" do
  include_examples "in-process server selenium tests"

  before (:each) do
    course_with_student_logged_in(:active_all => true)
  end

  it "should allow student group leaders to edit the group name" do
    category1 = @course.group_categories.create!(:name => "category 1")
    category1.configure_self_signup(true, false)
    category1.save!
    g1 = @course.groups.create!(:name => "some group", :group_category => category1)

    g1.add_user @student
    g1.leader = @student
    g1.save!

    get "/groups/#{g1.id}"

    keep_trying_until do
      f('#edit_group').click
      set_value f('#group_name'), "new group name"
      f('#ui-id-2').find_element(:css, 'button[type=submit]').click
      wait_for_ajaximations
    end

    expect(g1.reload.name).to eq "new group name"
  end

  it "should not show student organized, invite only groups" do
    g1 = @course.groups.create!(:name => "my group")

    get "/courses/#{@course.id}/groups"

    expect(ff("#group_#{g1.id}")).to be_empty
  end

  describe "new groups page" do
    it "should allow a student to create a group" do
      skip
      @course.root_account.enable_feature!(:student_groups_next)
      student_in_course
      student_in_course

      get "/courses/#{@course.id}/groups"

      keep_trying_until do
        f(".add_group_link").click
        wait_for_animations
      end

      f("#group_name").send_keys("My Group")
      expect(ff("#group_join_level option").length).to eq 2
      f("#invitees_#{@student.id}").click
      fj('button.confirm-dialog-confirm-btn').click
      wait_for_ajaximations

      new_group_el = fj(".student-group-header:first").text
      expect(new_group_el).to include "My Group"
      expect(new_group_el).to include "2 students"
    end
  end
end
