require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe QuizzesController do
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
        Quiz.any_instance.stubs(:changed_significantly_since?).returns(true)
        mkquiz
        @quiz_submission.update_if_needs_review
        @quiz_submission.submission_data.each { |q| q[:correct] = "false" }
        @quiz_submission.save
        get "courses/#{@course.id}/quizzes/#{@quiz.id}/history?quiz_submission_id=#{@quiz_submission.id}"
        response.body.should_not match(%r{The following questions need review})
        response.body.should match(%r{The quiz has changed significantly since this submission was made})
      end

      it "should display both messages" do
        Quiz.any_instance.stubs(:changed_significantly_since?).returns(true)
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
end
