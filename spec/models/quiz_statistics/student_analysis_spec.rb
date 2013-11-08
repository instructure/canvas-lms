require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/common.rb')

describe QuizStatistics::StudentAnalysis do
  let(:report_type) { 'student_analysis' }
  it_should_behave_like "QuizStatistics::Report"
end

describe QuizStatistics::StudentAnalysis do
  before { course }

  def csv(opts = {}, quiz = @quiz)
    stats = quiz.statistics_csv('student_analysis', opts)
    run_jobs
    stats.csv_attachment(true).open.read
  end

  it 'should calculate mean/stddev as expected with no submissions' do
    q = @course.quizzes.create!
    stats = q.statistics
    stats[:submission_score_average].should be_nil
    stats[:submission_score_high].should be_nil
    stats[:submission_score_low].should be_nil
    stats[:submission_score_stdev].should be_nil
  end

  it 'should calculate mean/stddev as expected with a few submissions' do
    q = @course.quizzes.create!
    q.save!
    @user1 = User.create! :name => "some_user 1"
    @user2 = User.create! :name => "some_user 2"
    @user3 = User.create! :name => "some_user 2"
    student_in_course :course => @course, :user => @user1
    student_in_course :course => @course, :user => @user2
    student_in_course :course => @course, :user => @user3
    sub = q.generate_submission(@user1)
    sub.workflow_state = 'complete'
    sub.submission_data = [{ :points => 15, :text => "", :correct => "undefined", :question_id => -1 }]
    sub.with_versioning(true, &:save!)
    stats = q.statistics
    stats[:submission_score_average].should == 15
    stats[:submission_score_high].should == 15
    stats[:submission_score_low].should == 15
    stats[:submission_score_stdev].should == 0
    sub = q.generate_submission(@user2)
    sub.workflow_state = 'complete'
    sub.submission_data = [{ :points => 17, :text => "", :correct => "undefined", :question_id => -1 }]
    sub.with_versioning(true, &:save!)
    stats = q.statistics
    stats[:submission_score_average].should == 16
    stats[:submission_score_high].should == 17
    stats[:submission_score_low].should == 15
    stats[:submission_score_stdev].should == 1
    sub = q.generate_submission(@user3)
    sub.workflow_state = 'complete'
    sub.submission_data = [{ :points => 20, :text => "", :correct => "undefined", :question_id => -1 }]
    sub.with_versioning(true, &:save!)
    stats = q.statistics
    stats[:submission_score_average].should be_close(17 + 1.0/3, 0.0000000001)
    stats[:submission_score_high].should == 20
    stats[:submission_score_low].should == 15
    stats[:submission_score_stdev].should be_close(Math::sqrt(4 + 2.0/9), 0.0000000001)
  end

  context "csv" do

    def temporary_user_code
      "tmp_#{Digest::MD5.hexdigest("#{Time.now.to_i.to_s}_#{rand.to_s}")}"
    end

    def survey_with_logged_out_submission
      course_with_teacher_logged_in(:active_all => true)

      @assignment = @course.assignments.create(:title => "Test Assignment")
      @assignment.workflow_state = "available"
      @assignment.submission_types = "online_quiz"
      @assignment.save
      @quiz = Quiz.find_by_assignment_id(@assignment.id)
      @quiz.anonymous_submissions = false
      @quiz.quiz_type = "survey"

      #make questions
      questions = [{:question_data => { :name => "test 1" }},
        {:question_data => { :name => "test 2" }},
        {:question_data => { :name => "test 3" }},
        {:question_data => { :name => "test 4" }}]

      @questions = questions.map { |q| @quiz.quiz_questions.create!(q) }
      @quiz.generate_quiz_data
      @quiz.save!

      @quiz_submission = @quiz.generate_submission(temporary_user_code)
      @quiz_submission.mark_completed
      @quiz_submission.grade_submission
      @quiz_submission.save!
    end

    before(:each) do
      student_in_course(:active_all => true)
      @quiz = @course.quizzes.create!
      @quiz.quiz_questions.create!(:question_data => { :name => "test 1" })
      @quiz.generate_quiz_data
      @quiz.published_at = Time.now
      @quiz.save!
    end

    it 'should not include user data for anonymous surveys' do
      @quiz.update_attribute :anonymous_submissions, true
      # one complete submission
      qs = @quiz.generate_submission(@student)
      qs.grade_submission

      # and one in progress
      @quiz.generate_submission(@student)

      stats = CSV.parse(csv(:include_all_versions => true))
      # format for row is row_name, '', data1, data2, ...
      stats.first.length.should == 3
      stats[0][0].should == "section"
    end

    it 'should succeed with logged-out user submissions' do
      survey_with_logged_out_submission
      stats = CSV.parse(csv(:include_all_versions => true))
      stats[0][1].should == ''
      stats[1][1].should == ''
      stats[2][1].should == ''
    end

    it 'should have sections in quiz statistics_csv' do
      #enroll user in multiple sections
      pseudonym = pseudonym(@student)
      @student.pseudonym.sis_user_id = "user_sis_id_01"
      @student.pseudonym.save!
      section1 = @course.course_sections.first
      section1.sis_source_id = 'SISSection01'
      section1.save!
      section2 = CourseSection.new(:course => @course, :name => "section2")
      section2.sis_source_id = 'SISSection02'
      section2.save!
      @course.enroll_user(@student, "StudentEnrollment", :enrollment_state => 'active', :allow_multiple_enrollments => true, :section => section2)
      # one complete submission
      qs = @quiz.generate_submission(@student)
      qs.grade_submission

      stats = CSV.parse(csv(:include_all_versions => true))
      # format for row is row_name, '', data1, data2, ...
      stats[0].should == ["name", "", "nobody@example.com"]
      stats[1].should == ["id", "", @student.id.to_s]
      stats[2].should == ["sis_id", "", "user_sis_id_01"]
      expect_multi_value_row(stats[3], "section", ["section2", "Unnamed Course"])
      expect_multi_value_row(stats[4], "section_id", [section1.id, section2.id])
      expect_multi_value_row(stats[5], "section_sis_id", ["SISSection02", "SISSection01"])
      stats.first.length.should == 3
    end

    def expect_multi_value_row(row, expected_name, expected_values)
      row[0..1].should == [expected_name, ""]
      row[2].split(', ').sort.should == expected_values.map(&:to_s).sort
    end

    it 'should deal with incomplete fill-in-multiple-blanks questions' do
      @quiz.quiz_questions.create!(:question_data => { :name => "test 2",
        :question_type => 'fill_in_multiple_blanks_question',
        :question_text => "[ans0]",
        :answers =>
          {'answer_0' => {'answer_text' => 'foo', 'blank_id' => 'ans0', 'answer_weight' => '100'}}})
      @quiz.quiz_questions.create!(:question_data => { :name => "test 3",
        :question_type => 'fill_in_multiple_blanks_question',
        :question_text => "[ans0] [ans1]",
        :answers =>
           {'answer_0' => {'answer_text' => 'bar', 'blank_id' => 'ans0', 'answer_weight' => '100'},
            'answer_1' => {'answer_text' => 'baz', 'blank_id' => 'ans1', 'answer_weight' => '100'}}})
      @quiz.generate_quiz_data
      @quiz.save!
      @quiz.quiz_questions.size.should == 3
      qs = @quiz.generate_submission(@student)
      # submission will not answer question 2 and will partially answer question 3
      qs.submission_data = {
          "question_#{@quiz.quiz_questions[2].id}_#{AssessmentQuestion.variable_id('ans1')}" => 'baz'
      }
      qs.grade_submission
      stats = CSV.parse(csv)
      stats.size.should == 16 # 3 questions * 2 lines + ten more (name, id, sis_id, section, section_id, section_sis_id, submitted, correct, incorrect, score)
      stats[11].size.should == 3
      stats[11][2].should == ',baz'
    end

    it 'should contain answers to numerical questions' do
      @quiz.quiz_questions.create!(:question_data => { :name => "numerical_question",
        :question_type => 'numerical_question',
        :question_text => "[num1]",
        :answers => {'answer_0' => {:numerical_answer_type => 'exact_answer'}}})

      @quiz.quiz_questions.last.question_data[:answers].first[:exact] = 5

      @quiz.generate_quiz_data
      @quiz.save!

      qs = @quiz.generate_submission(@student)
      qs.submission_data = {
        "question_#{@quiz.quiz_questions[1].id}" => 5
      }
      qs.grade_submission

      stats = CSV.parse(csv)
      stats[9][2].should == '5'
    end

  end

  it "includes attachment display names for quiz file upload questions" do
    require 'action_controller'
    require 'action_controller/test_process.rb'
    student_in_course(:active_all => true)
    student = @student
    student.name = "Not Steve"
    student.save!
    student2 = User.create!(:name => "Stevie Jeebie")
    @course.enroll_user(student2,'StudentEnrollment', :enrollment_state => :active)
    q = @course.quizzes.create!(:title => "new quiz")
    q.update_attribute :published_at, Time.now
    question = q.quiz_questions.create! :question_data => {
      :name => 'q1', :points_possible => 1,
      :question_type => 'file_upload_question',
      :question_text => 'ohai mark'
    }
    q.generate_quiz_data
    q.save!
    qs = q.generate_submission student
    io = ActionController::TestUploadedFile.new(
      File.expand_path(File.dirname(__FILE__) +
                       '/../../fixtures/scribd_docs/doc.doc'),
                       'application/msword', true)
    attach = qs.attachments.create! :filename => "doc.doc",
      :display_name => "attachment.png", :user => student,
      :uploaded_data => io
    qs.submission_data["question_#{question.id}".to_sym] = [ attach.id.to_s ]
    qs.save!
    qs.grade_submission
    qs = q.generate_submission student2
    qs.submission_data["question_#{question.id}".to_sym] = nil
    qs.save!
    qs.grade_submission
    # make student2's submission first
    qs.updated_at = 3.days.ago
    qs.save!
    stats = CSV.parse(csv({:include_all_versions => true},q.reload))
    stats[7][2].should == "" # student2
    stats[7][3].should == attach.display_name # student
  end

  it 'should strip tags from html multiple-choice/multiple-answers' do
    student_in_course(:active_all => true)
    q = @course.quizzes.create!(:title => "new quiz")
    q.update_attribute(:published_at, Time.now)
    q.quiz_questions.create!(:question_data => {:name => 'q1', :points_possible => 1, 'question_type' => 'multiple_choice_question', 'answers' => {'answer_0' => {'answer_text' => '', 'answer_html' => '<em>zero</em>', 'answer_weight' => '100'}, 'answer_1' => {'answer_text' => "", 'answer_html' => "<p>one</p>", 'answer_weight' => '0'}}})
    q.quiz_questions.create!(:question_data => {:name => 'q2', :points_possible => 1, 'question_type' => 'multiple_answers_question', 'answers' => {'answer_0' => {'answer_text' => '', 'answer_html' => "<a href='http://example.com/caturday.gif'>lolcats</a>", 'answer_weight' => '100'}, 'answer_1' => {'answer_text' => 'lolrus', 'answer_weight' => '100'}}})
    q.generate_quiz_data
    q.save
    qs = q.generate_submission(@student)
    qs.submission_data = {
        "question_#{q.quiz_data[0][:id]}" => "#{q.quiz_data[0][:answers][0][:id]}",
        "question_#{q.quiz_data[1][:id]}_answer_#{q.quiz_data[1][:answers][0][:id]}" => "1",
        "question_#{q.quiz_data[1][:id]}_answer_#{q.quiz_data[1][:answers][1][:id]}" => "1"
    }
    qs.grade_submission

    # visual statistics
    stats = q.statistics
    stats[:questions].length.should == 2
    stats[:questions][0].length.should == 2
    stats[:questions][0][0].should == "question"
    stats[:questions][0][1][:answers].length.should == 2
    stats[:questions][0][1][:answers][0][:responses].should == 1
    stats[:questions][0][1][:answers][0][:text].should == "zero"
    stats[:questions][0][1][:answers][1][:responses].should == 0
    stats[:questions][0][1][:answers][1][:text].should == "one"
    stats[:questions][1].length.should == 2
    stats[:questions][1][0].should == "question"
    stats[:questions][1][1][:answers].length.should == 2
    stats[:questions][1][1][:answers][0][:responses].should == 1
    stats[:questions][1][1][:answers][0][:text].should == "lolcats"
    stats[:questions][1][1][:answers][1][:responses].should == 1
    stats[:questions][1][1][:answers][1][:text].should == "lolrus"

    # csv statistics
    stats = CSV.parse(csv({}, q))
    stats[7][2].should == "zero"
    stats[9][2].should == "lolcats,lolrus"
  end

end
