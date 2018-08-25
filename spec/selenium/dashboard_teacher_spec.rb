#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require_relative 'common'
require_relative 'helpers/notifications_common'

describe "dashboard" do
  include NotificationsCommon
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
      student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :password => 'qwertyuiop')
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

    it "should be able to ignore an assignment until the next submission", priority: "1", test_id: 216399 do
      assignment = assignment_model({:submission_types => 'online_text_entry', :course => @course})
      student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :password => 'qwertyuiop')
      student2 = user_with_pseudonym(:active_user => true, :username => 'student2@example.com', :password => 'qwertyuiop')
      @course.enroll_user(student, "StudentEnrollment", :enrollment_state => 'active')
      @course.enroll_user(student2, "StudentEnrollment", :enrollment_state => 'active')
      assignment.reload
      assignment.submit_homework(student, {:submission_type => 'online_text_entry', :body => 'ABC'})
      assignment.reload
      enable_cache do
        get "/"

        ignore_link = f('.to-do-list .disable_item_link')
        expect(ignore_link['title']).to include("Ignore until new submission")
        ignore_link.click
        wait_for_ajaximations
        expect(f("#content")).not_to contain_css('.to-do-list > li')

        get "/"

        expect(f("#content")).not_to contain_css('.to-do-list')
      end

      assignment.reload
      assignment.submit_homework(student2, {:submission_type => 'online_text_entry', :body => 'ABC'})
      assignment.reload
      enable_cache do
        get "/"

        expect(f('.to-do-list > li')).to include_text('Grade ' + assignment.title)

      end

    end

    context 'stream items' do
      before :once do
        setup_notification(@teacher, name: 'Assignment Created')
      end

      it 'shows an assignment stream item under Recent Activity in dashboard', priority: "1", test_id: 108723 do
        assignment_model({:submission_types => ['online_text_entry'], :course => @course})
        get "/"
        f('#DashboardOptionsMenu_Container button').click
        fj('span[role="menuitemradio"]:contains("Recent Activity")').click
        find('.toggle-details').click
        expect(fj('.fake-link:contains("Unnamed")')).to be_present
      end

      it 'does not show an unpublished assignment under recent activity under dashboard', priority: "2", test_id: 108722 do
        # manually creating assignment as assignment created through backend are published by default
        get "/courses/#{@course.id}/assignments"
        wait_for_ajaximations

        # create assignment
        f('.new_assignment').click
        wait_for_ajaximations
        f('#assignment_name').send_keys('unpublished assignment')
        f("input[type=checkbox][id=assignment_text_entry]").click
        f(".datePickerDateField[data-date-type='due_at']").send_keys(Time.zone.now + 1.day)

        expect_new_page_load { f('.btn-primary[type=submit]').click }
        wait_for_ajaximations

        get "/"
        expect(f('.no_recent_messages')).to be_truthy
      end
    end

    context "moderation to do" do
      before do
        @teacher = @user
        @student = student_in_course(:course => @course, :active_all => true).user
        @assignment = @course.assignments.create!(
          title: "some assignment",
          submission_types: ['online_text_entry'],
          moderated_grading: true,
          grader_count: 2,
          final_grader: @teacher
        )
        @assignment.submit_homework(@student, :body => "submission")
      end

      it "should show assignments needing moderation" do
        enable_cache do
          Timecop.freeze(1.minute.from_now) do
            get "/"
            expect(f('.to-do-list')).to_not include_text("Moderate #{@assignment.title}")
          end

          Timecop.freeze(2.minutes.from_now) do
            # create a provisional grade
            @assignment.grade_student(@student, :grade => "1", :grader => @teacher, :provisional => true)

            run_jobs # touching admins is done in a delayed job

            get "/"
            expect(f('.to-do-list')).to include_text("Moderate #{@assignment.title}")
          end

          Timecop.freeze(3.minutes.from_now) do
            @assignment.update_attribute(:grades_published_at, Time.now.utc)
            @teacher.touch # would be done by the publishing endpoint

            get "/"
            expect(f('.to-do-list')).to_not include_text("Moderate #{@assignment.title}")
          end
        end
      end

      it "should be able to ignore assignments needing moderation until next provisional grade change" do
        @assignment.grade_student(@student, :grade => "1", :grader => @teacher, :provisional => true)
        pg = @assignment.provisional_grades.first

        enable_cache do
          get "/"

          ff('.to-do-list .disable_item_link').each do |link|
            expect(link['title']).to include("Ignore until new mark")
            link.click
            wait_for_ajaximations
          end

          expect(f("#content")).not_to contain_css('.to-do-list > li')

          get "/"

          expect(f("#content")).not_to contain_css('.to-do-list')
        end

        pg.save! # reload

        enable_cache do
          get "/"
          expect(f('.to-do-list')).to include_text("Moderate #{@assignment.title}")
        end
      end
    end

    describe "Todo Ignore Options Focus Management" do
      before :each do
        assignment = assignment_model({:submission_types => 'online_text_entry', :course => @course})
        @student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :password => 'qwertyuiop')
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

          check_element_has_focus(all_todo_links.first)
        end
      end

      it "should focus on the 'To Do' header if there are no other todo items", priority: "1", test_id: 216401 do
        enable_cache do
          get "/"

          f('.to-do-list .disable_item_link').click
          wait_for_ajaximations

          check_element_has_focus(f('.todo-list-header'))
        end
      end
    end

    it "should not display assignment to grade in to do list for a designer", priority: "1", test_id: 216402 do
      course_with_designer_logged_in(:active_all => true)
      assignment = assignment_model({:submission_types => 'online_text_entry', :course => @course})
      student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :password => 'qwertyuiop')
      @course.enroll_user(student, "StudentEnrollment", :enrollment_state => 'active')
      assignment.reload
      assignment.submit_homework(student, {:submission_type => 'online_text_entry', :body => 'ABC'})
      assignment.reload
      enable_cache do
        get "/"

        expect(f("#content")).not_to contain_css('.to-do-list')
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
        course_with_teacher({:user => @user, :active_course => true, :active_enrollment => true})

        get "/"

        f('#global_nav_courses_link').click
        expect(fj('[aria-label="Global navigation tray"] a:contains("All Courses")')).to be_present
      end
    end
  end

  context 'as a teacher in an unpublished course' do
    before do
      course_with_teacher_logged_in(:active_course => false)
    end

    it 'should not show an unpublished assignment for an unpublished course', priority: "2", test_id: 56003 do
      name = 'venkman'
      due_date = Time.zone.now.utc + 2.days
      assignment = @course.assignments.create(name: name,
                                              submission_types: 'online',
                                              due_at: due_date,
                                              lock_at: 1.week.from_now,
                                              unlock_at: due_date)

      get '/'
      expect(f('.coming_up')).to include_text(name)

      assignment.unpublish
      get '/'
      expect(f('.coming_up')).not_to include_text(name)
    end
  end
end
