require File.expand_path(File.dirname(__FILE__) + '/helpers/quizzes_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/assignment_overrides.rb')

describe "quizzes section hierarchy" do

  include_examples 'in-process server selenium tests'

  before :each do
    course_with_teacher_logged_in
    @new_section = @course.course_sections.create!(name: 'New Section')
    @student = student_in_section(@new_section)
    @course.start_at = Time.zone.now.advance(days: -30)
    @course.conclude_at = Time.zone.now.advance(days: -10)
    @course.restrict_enrollments_to_course_dates = true
    @course.save!
    @new_section.start_at = Time.zone.now.advance(days: -30)
    @new_section.end_at = Time.zone.now.advance(days: 10)
    @new_section.restrict_enrollments_to_section_dates = true
    @new_section.save!

    # create a quiz and assign it to the section with due dae after course end date
    @quiz = quiz_with_multiple_type_questions(!:goto_edit)
    @override = @quiz.assignment_overrides.build
    @override.set = @new_section
    @override.due_at = Time.zone.now.advance(days:3)
    @override.due_at_overridden = true
    @override.save!
  end

  def take_quiz
    get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
    expect_new_page_load{f('#take_quiz_link').click}
    # make sure it does not create a blank submissions
    expect(f(' .quiz_score')).not_to be_present
    expect(f(' .quiz_duration')).not_to be_present
    # take and submit the quiz
    answer_questions_and_submit(@quiz, 3)
  end

  def verify_quiz_accessible
    get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
    expect_new_page_load{f('#take_quiz_link').click}
    # make sure it does not create a blank submissions
    expect(f(' .quiz_score')).not_to be_present
    expect(f(' .quiz_duration')).not_to be_present
  end

  context "section overrides course and term hierarchy" do
    context "course end date in past" do
      it "should allow the student to take the quiz", priority: "1", test_id: 282619 do
        # ensure student is able to take the quiz and it does not create a blank submission
        user_session(@student)
        take_quiz
      end

      it "should allow the teacher to preview the quiz", priority: "1", test_id: 282838 do
        get "/courses/#{@course.id}/quizzes"
        keep_trying_until { fln('Test Quiz').click }
        expect_new_page_load{f('#preview_quiz_button').click}
        keep_trying_until do
         expect(f(' .quiz-header').text).to include('This is a preview of the published version of the quiz')
        end
      end

    it "should work with lock and unlock dates set up", priority: "1", test_id: 323086 do
      @override.unlock_at = Time.zone.now.advance(days:-1)
      @override.lock_at = Time.zone.now.advance(days:4)
      user_session(@student)
      take_quiz
    end
    end

    context "term end date in past" do
      before :each do
        term = EnrollmentTerm.find(@course.enrollment_term_id)
        term.start_at = Time.zone.now.advance(days: -60)
        term.end_at = Time.zone.now.advance(days: -15)
        term.save!
      end

      it "should still be accessible for student in the section after term end date", priority: "1", test_id: 323087 do
        user_session(@student)
        take_quiz
      end

      it "should be accessible for teachers enrolled in section after term end date", priority: "1", test_id: 323089 do
        teacher_in_section(@new_section, user: @teacher)
        take_quiz
      end

      it "should work with lock and unlock dates set up", priority: "1", test_id: 323090 do
        @override.unlock_at = Time.zone.now.advance(days:-1)
        @override.lock_at = Time.zone.now.advance(days:4)
        user_session(@student)
        take_quiz
      end
    end
  end

  context "course overrides hierarchy when restrict to section dates is not checked" do
    before :each do
      @new_section.restrict_enrollments_to_section_dates = false
      @new_section.save!
    end

    context "course ends in past" do
      it "should disallow student to view quiz", priority: "1", test_id: 323323 do
        user_session(@student)
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
        expect(f('#quiz_show .quiz-header .lock_explanation').text).
                                        to include('This quiz is no longer available as the course has been concluded')
      end

      it "should still allow teachers to take the quiz", priority: "1", test_id: 323324 do
        verify_quiz_accessible
      end
    end

    context "course ends in future" do
      before :each do
        @course.conclude_at = Time.zone.now.advance(days: 10)
        @course.save!
      end

      it "should allow student in section to take quiz", priority: "1", test_id: 323321 do
        user_session(@student)
        verify_quiz_accessible
      end

      it "should allow teachers to take the quiz", priority: "1", test_id: 323322 do
        verify_quiz_accessible
      end
    end
  end

  context "term overrides hierarchy when restrict to course and section dates are not checked" do
    context "course ends in past" do
      before :each do
        @course.restrict_enrollments_to_course_dates = false
        @course.save!
        @new_section.restrict_enrollments_to_section_dates = false
        @new_section.save!
      end

      it "should allow student to take quiz", priority: "1", test_id: 323326 do
        user_session(@student)
        verify_quiz_accessible
      end

      it "should still allow teachers to take the quiz", priority: "1", test_id: 323328 do
        verify_quiz_accessible
      end
    end
  end
end