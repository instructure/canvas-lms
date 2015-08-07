require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/groups_common')

describe "student groups" do
  include_context "in-process server selenium tests"
  let(:group_name){ 'Windfury' }
  let(:group_category_name){ 'cat1' }

  context "As a teacher" do

    before(:each) do
      course_with_teacher_logged_in
    end

    it "if there are no student groups, there should not be a student groups tab", priority:"2", test_id: 182050 do
      get "/courses/#{@course.id}/users"
      all_tabs = ffj(".group-category-tab-link")

      all_tabs.each do |tab|
        expect(tab).to_not include_text("Student Groups")
      end
    end

    it "if there are student groups, there should be a student groups tab", priority:"2", test_id: 182051 do
      create_student_group_as_a_teacher(group_name)
      get "/courses/#{@course.id}/users"
      all_tabs = ffj(".group-category-tab-link")

      all_tabs.each do |tab|
        expect(tab).to include_text("Student Groups")
      end
    end

    context "with a student group created" do
      let(:students_in_group){ 4 }

      before(:each) do
        create_student_group_as_a_teacher(group_name, (students_in_group-1))
        get("/courses/#{@course.id}/groups")
      end

      it "should have warning text", priority: "1", test_id: 182055 do
        expect(f(".alert")).to include_text("These groups are self-organized by students")
      end

      it "list student groups" do
        expect(f(".group-name")).to include_text(group_name.to_s)
      end

      it "have correct student count", priority: "1", test_id: 182059 do
        expect(f(".group")).to include_text("#{students_in_group} students")
      end

      it "teacher can delete a student group", priority: "1", test_id: 182060 do
        expect(f(".group-name")).to include_text(group_name.to_s)
        delete_group
        expect(f(".group-name")).to be_nil
      end

      it "should list all students in the student group", priority: "1", test_id: 182061 do
        # expand group
        f(".group-name").click
        wait_for_animations

        # verify each student is in the group
        expected_students = ["Test Student 1","Test Student 2","Test Student 3","Test Student 4"]
        users = fj("[data-view=groupUsers]")
        expected_students.each do |student|
          keep_trying_until(2) { expect(users).to include_text(student.to_s) }
        end
      end

      it "should set a student as a group leader", priority: "1", test_id: 184461 do
        # expand group
        f(".group-name").click
        wait_for_animations

        # Sets user as group leader
        f('.group-user-actions').click
        wait_for_ajaximations
        fj('.set-as-leader:visible').click
        wait_for_ajaximations

        # Looks for student to have a group leader icon
        expect(f('.icon-user.group-leader')).to be_displayed
        # Verifies group leader silhouette and leader's name appear in the group header
        expect(f('.span3.ellipsis.group-leader')).to be_displayed
        expect(f('.span3.ellipsis.group-leader')).to include_text("Test Student 1")
      end
    end
  end
end