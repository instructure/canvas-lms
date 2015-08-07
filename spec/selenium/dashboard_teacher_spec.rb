require File.expand_path(File.dirname(__FILE__) + '/common')

describe "dashboard" do
  include_context "in-process server selenium tests"

  context "as a teacher" do
    before (:each) do
      course_with_teacher_logged_in(:active_cc => true)
    end

    it "should validate the functionality of soft concluded courses on courses page", priority: "1", test_id: 216396 do
      term = EnrollmentTerm.new(:name => "Super Term", :start_at => 1.month.ago, :end_at => 1.week.ago)
      term.root_account_id = @course.root_account_id
      term.save!
      c1 = @course
      c1.name = 'a_soft_concluded_course'
      c1.update_attributes!(:enrollment_term => term)
      c1.reload

      get "/courses"
      expect(fj("#past_enrollments_table a[href='/courses/#{@course.id}']")).to include_text(c1.name)
    end

    it "should display assignment to grade in to do list for a teacher", priority: "1", test_id: 216397 do
      assignment = assignment_model({:submission_types => 'online_text_entry', :course => @course})
      student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :password => 'qwerty')
      @course.enroll_user(student, "StudentEnrollment", :enrollment_state => 'active')
      assignment.reload
      assignment.submit_homework(student, {:submission_type => 'online_text_entry', :body => 'ABC'})
      assignment.reload
      enable_cache do
        get "/"

        #verify assignment is in to do list
        expect(f('.to-do-list > li')).to include_text('Grade ' + assignment.title)
      end
    end

    it "should be able to ignore an assignment to grade permanently", priority: "1", test_id: 216398 do
      assignment = assignment_model({:submission_types => 'online_text_entry', :course => @course})
      student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :password => 'qwerty')
      student2 = user_with_pseudonym(:active_user => true, :username => 'student2@example.com', :password => 'qwerty')
      @course.enroll_user(student, "StudentEnrollment", :enrollment_state => 'active')
      @course.enroll_user(student2, "StudentEnrollment", :enrollment_state => 'active')
      assignment.reload
      assignment.submit_homework(student, {:submission_type => 'online_text_entry', :body => 'ABC'})
      assignment.reload
      enable_cache do
        get "/"

        f('.to-do-list .disable_item_link').click
        wait_for_ajaximations
        f('#ignore_forever').click
        wait_for_ajaximations
        expect(f('.to-do-list > li')).to be_nil

        get "/"

        expect(f('.to-do-list')).to be_nil
      end

      assignment.reload
      assignment.submit_homework(student2, {:submission_type => 'online_text_entry', :body => 'ABC'})
      assignment.reload
      enable_cache do
        get "/"

        expect(f('.to-do-list')).to be_nil

      end

    end

    it "should be able to ignore an assignment until the next submission", priority: "1", test_id: 216399 do
      assignment = assignment_model({:submission_types => 'online_text_entry', :course => @course})
      student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :password => 'qwerty')
      student2 = user_with_pseudonym(:active_user => true, :username => 'student2@example.com', :password => 'qwerty')
      @course.enroll_user(student, "StudentEnrollment", :enrollment_state => 'active')
      @course.enroll_user(student2, "StudentEnrollment", :enrollment_state => 'active')
      assignment.reload
      assignment.submit_homework(student, {:submission_type => 'online_text_entry', :body => 'ABC'})
      assignment.reload
      enable_cache do
        get "/"

        f('.to-do-list .disable_item_link').click
        wait_for_ajaximations
        f('#ignore_until_submission').click
        wait_for_ajaximations
        expect(f('.to-do-list > li')).to be_nil

        get "/"

        expect(f('.to-do-list')).to be_nil
      end

      assignment.reload
      assignment.submit_homework(student2, {:submission_type => 'online_text_entry', :body => 'ABC'})
      assignment.reload
      enable_cache do
        get "/"

        expect(f('.to-do-list > li')).to include_text('Grade ' + assignment.title)

      end

    end

    describe "Todo Ignore Options Focus Management" do
      before :each do
        assignment = assignment_model({:submission_types => 'online_text_entry', :course => @course})
        @student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :password => 'qwerty')
        @course.enroll_user(@student, "StudentEnrollment", :enrollment_state => 'active')
        assignment.submit_homework(@student, {:submission_type => 'online_text_entry', :body => 'ABC'})
      end

      it "should focus on the previous ignore link after ignoring a todo item", priority: "1", test_id: 216400 do
        assignment2 = assignment_model({:submission_types => 'online_text_entry', :course => @course})
        assignment2.submit_homework(@student, {:submission_type => 'online_text_entry', :body => 'Number2'})
        enable_cache do
          get "/"

          all_todo_links = ff('.to-do-list .disable_item_link')
          all_todo_links.last.click
          wait_for_ajaximations
          ff('#ignore_forever').last.click
          wait_for_ajaximations

          check_element_has_focus(all_todo_links.first)
        end
      end

      it "should focus on the 'View Calendar' link if there are no other todo items", priority: "1", test_id: 216401 do
        enable_cache do
          get "/"

          f('.to-do-list .disable_item_link').click
          wait_for_ajaximations
          f('#ignore_forever').click
          wait_for_ajaximations

          check_element_has_focus(f('.event-list-view-calendar'))
        end
      end
    end

    it "should not display assignment to grade in to do list for a designer", priority: "1", test_id: 216402 do
      course_with_designer_logged_in(:active_all => true)
      assignment = assignment_model({:submission_types => 'online_text_entry', :course => @course})
      student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :password => 'qwerty')
      @course.enroll_user(student, "StudentEnrollment", :enrollment_state => 'active')
      assignment.reload
      assignment.submit_homework(student, {:submission_type => 'online_text_entry', :body => 'ABC'})
      assignment.reload
      enable_cache do
        get "/"

        expect(f('.to-do-list')).to be_nil
      end
    end

    it "should show submitted essay quizzes in the todo list", priority: "1", test_id: 216403 do
      quiz_title = 'new quiz'
      student_in_course(:active_all => true)
      q = @course.quizzes.create!(:title => quiz_title)
      q.quiz_questions.create!(:question_data => {:id => 31, :name => "Quiz Essay Question 1", :question_type => 'essay_question', :question_text => 'qq1', :points_possible => 10})
      q.generate_quiz_data
      q.workflow_state = 'available'
      q.save
      q.reload
      qs = q.generate_submission(@user)
      qs.mark_completed
      qs.submission_data = {"question_31" => "<p>abeawebawebae</p>", "question_text" => "qq1"}
      Quizzes::SubmissionGrader.new(qs).grade_submission
      get "/"

      todo_list = f('.to-do-list')
      expect(todo_list).not_to be_nil
      expect(todo_list).to include_text(quiz_title)
    end

    context "course menu customization" do

      it "should always have a link to the courses page (with customizations)", priority: "1", test_id: 216404 do
        20.times { course_with_teacher({:user => @user, :active_course => true, :active_enrollment => true}) }

        get "/"

        driver.execute_script %{$('#courses_menu_item').addClass('hover');}
        wait_for_ajaximations

        expect(fj('#courses_menu_item')).to include_text('My Courses')
        expect(fj('#courses_menu_item')).to include_text('View All or Customize')
      end
    end
  end
end