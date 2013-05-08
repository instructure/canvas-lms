require File.expand_path(File.dirname(__FILE__) + '/common')

describe "course settings" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in :limit_privileges_to_course_section => false
    @account = @course.account
    custom_student_role("custom stu")
  end

  describe "course users" do
    def select_from_auto_complete(text, input_id)
      fj(".token_input input:visible").send_keys(text)
      keep_trying_until { driver.execute_script("return $('##{input_id}').data('token_input').selector.list.query.search") == text }
      wait_for_ajaximations
      elements = driver.execute_script("return $('.autocomplete_menu:visible .list').last().find('ul').last().find('li').toArray();").map { |e|
        [e, (e.find_element(:tag_name, :b).text rescue e.text)]
      }
      element = elements.detect { |e| e.last == text } or raise "menu item does not exist"

      element.first.click
      wait_for_ajaximations
    end

    def go_to_users_tab
      get "/courses/#{@course.id}/settings#tab-users"
      wait_for_ajaximations
    end

    it "should not show the student view student" do
      @fake_student = @course.student_view_student
      go_to_users_tab
      ff(".student_enrollments #user_#{@fake_student.id}").should be_empty
    end
  end

end
