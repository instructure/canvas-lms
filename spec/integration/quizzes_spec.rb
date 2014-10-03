require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Quizzes::QuizzesController do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  def create_section_override(section, due_at)
    override = assignment_override_model(:quiz => @quiz)
    override.set = section
    override.override_due_at(due_at)
    override.save!
  end

  context "#show" do
    before :each do
      course_with_teacher_logged_in(:active_all => true)
      assignment_model(:course => @course)
      quiz_model(:course => @course, :assignment_id => @assignment.id)
      @quiz.update_attribute :due_at, 5.days.from_now
      @cs1 = @course.default_section
      @cs2 = @course.course_sections.create!
    end

    context "with overridden due dates" do
      include TextHelper

      context "with no overrides" do
        it "should show a due date for 'Everyone'" do
          get "courses/#{@course.id}/quizzes/#{@quiz.id}"

          doc = Nokogiri::HTML(response.body)
          doc.css(".assignment_dates").text.should include "Everyone"
          doc.css(".assignment_dates").text.should_not include "Everyone else"
        end
      end

      context "with some sections overridden" do
        before do
          @due_at = 3.days.from_now
          create_section_override(@cs1, @due_at)
        end

        it "should show an overridden due date for student" do
          @course.enroll_user(user, 'StudentEnrollment')
          user_session(@user)

          get "courses/#{@course.id}/quizzes/#{@quiz.id}"

          doc = Nokogiri::HTML(response.body)
          doc.css("#quiz_student_details .value").first.text.should include(datetime_string(@due_at))
        end

        it "should show 'Everyone else' when some sections have a due date override" do
          get "courses/#{@course.id}/quizzes/#{@quiz.id}"

          doc = Nokogiri::HTML(response.body)
          doc.css(".assignment_dates").text.should include "Everyone else"
        end
      end

      context "with all sections overridden" do
        before do
          @due_at1, @due_at2 = 3.days.from_now, 4.days.from_now
          create_section_override(@cs1, @due_at1)
          create_section_override(@cs2, @due_at2)
        end

        it "should show multiple due dates to teachers" do
          get "courses/#{@course.id}/quizzes/#{@quiz.id}"

          doc = Nokogiri::HTML(response.body)
          doc.css(".assignment_dates tbody tr").count.should be 2
          doc.css(".assignment_dates tbody tr > td:first-child").text.
            should include(datetime_string(@due_at1), datetime_string(@due_at2))
        end

        it "should not show a date for 'Everyone else'" do
          get "courses/#{@course.id}/quizzes/#{@quiz.id}"

          doc = Nokogiri::HTML(response.body)
          doc.css(".assignment_dates").text.should_not include "Everyone"
        end
      end
    end

    context "SpeedGrader" do
      it "should link to SpeedGrader when not large_roster" do
        @course.large_roster = false
        @course.save!
        get "courses/#{@course.id}/quizzes/#{@quiz.id}"
        response.body.should match(%r{SpeedGrader})
      end

      it "should not link to SpeedGrader when large_roster" do
        @course.large_roster = true
        @course.save!
        get "courses/#{@course.id}/quizzes/#{@quiz.id}"
        response.body.should_not match(%r{SpeedGrader})
      end
    end
  end

  context "show_student" do
    before :each do
      course_with_student_logged_in(:active_all => true)
      course_quiz true
      post "courses/#{@course.id}/quizzes/#{@quiz.id}/take?user_id=#{@student.id}"

      get "courses/#{@course.id}/quizzes/#{@quiz.id}/take"
    end

    context "Show Center resume button" do
      it "should show resume button in the center" do
        get "courses/#{@course.id}/quizzes/#{@quiz.id}"

        doc = Nokogiri::HTML(response.body)
        doc.css("#not_right_side .take_quiz_button").text.should include "Resume Quiz"
      end
    end

    context "Not show right_side resume button" do
      it "should not show resume button on right_side" do
        get "courses/#{@course.id}/quizzes/#{@quiz.id}"

        doc = Nokogiri::HTML(response.body)
        doc.css("#right-side .rs-margin-top").text.should_not include "Resume Quiz"
      end
    end
  end

  context "#history" do
    context "pending_review" do
      def mkquiz
        quiz_with_graded_submission([{:question_data => {:name => 'question 1', :points_possible => 1, 'question_type' => 'essay_question'}},
                                   {:question_data => {:name => 'question 2', :points_possible => 1, 'question_type' => 'essay_question'}}])
        course_with_teacher_logged_in(:active_all => true, :course => @course)
      end

      def mksurvey
        survey_with_submission([{:question_data => {:name => 'question 1', :points_possible => 1, 'question_type' => 'essay_question'}},
                                   {:question_data => {:name => 'question 2', :points_possible => 1, 'question_type' => 'essay_question'}}])
        course_with_teacher_logged_in(:active_all => true, :course => @course)
      end

      it "should list the questions needing review" do
        mkquiz
        get "courses/#{@course.id}/quizzes/#{@quiz.id}/history?quiz_submission_id=#{@quiz_submission.id}"
        response.body.should match(%r{The following questions need review})
        response.body.should_not match(%r{The quiz has changed significantly since this submission was made})
        doc = Nokogiri::HTML(response.body)
        needing_review = doc.at_css('#questions_needing_review')
        needing_review.should be_present
        needing_review.children.css('li a').map { |n| n.text }.should == @quiz.quiz_data.map { |qq| qq['name'] }
      end

      it "should display message about the quiz changing significantly" do
        Quizzes::Quiz.any_instance.stubs(:changed_significantly_since?).returns(true)
        mkquiz
        @quiz_submission.update_if_needs_review
        @quiz_submission.submission_data.each { |q| q[:correct] = "false" }
        @quiz_submission.save
        get "courses/#{@course.id}/quizzes/#{@quiz.id}/history?quiz_submission_id=#{@quiz_submission.id}"
        response.body.should_not match(%r{The following questions need review})
        response.body.should match(%r{The quiz has changed significantly since this submission was made})
      end

      it "should display both messages" do
        Quizzes::Quiz.any_instance.stubs(:changed_significantly_since?).returns(true)
        mkquiz
        get "courses/#{@course.id}/quizzes/#{@quiz.id}/history?quiz_submission_id=#{@quiz_submission.id}"
        response.body.should match(%r{The following questions need review})
        response.body.should match(%r{The quiz has changed significantly since this submission was made})
        doc = Nokogiri::HTML(response.body)
        needing_review = doc.at_css('#questions_needing_review')
        needing_review.should be_present
        needing_review.children.css('li a').map { |n| n.text }.should == @quiz.quiz_data.map { |qq| qq['name'] }
      end

      it "shoudn't show the user's name/email when it's an anonymous submission" do
        mksurvey

        # add some crazy names and email address that are unlikely to be matched accidentally
        crazy_unlikely_to_be_matched_name = "1p3h5Yns[y>s^*:]zi^1|h,M"
        @student.name = crazy_unlikely_to_be_matched_name
        @student.sortable_name = crazy_unlikely_to_be_matched_name
        pseudonym @student, :username => '1p3h5Ynsyszi1hM@1p3h5Ynsyszi1hM.com'
        @student.save!
        @student.reload
        get "courses/#{@course.id}/quizzes/#{@quiz.id}/history?quiz_submission_id=#{@quiz_submission.id}"
        response.body.should_not match @student.name
        response.body.should_not match @student.sortable_name
        response.body.should_not match @student.email
      end
    end
  end

  def course_quiz(active=false)
    @quiz = @course.quizzes.create
    @quiz.workflow_state = "available" if active
    @quiz.save!
    @quiz
  end
end
