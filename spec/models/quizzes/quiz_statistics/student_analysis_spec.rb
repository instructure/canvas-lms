require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/common.rb')

require 'csv'

describe Quizzes::QuizStatistics::StudentAnalysis do
  let(:report_type) { 'student_analysis' }
  include_examples "Quizzes::QuizStatistics::Report"
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
    question = q.quiz_questions.create!({
      question_data: {
        name: 'q1',
        points_possible: 30,
        question_type: 'essay_question',
        question_text: 'ohai mark'
      }
    })
    q.generate_quiz_data
    q.save!

    @user1 = User.create! :name => "some_user 1"
    @user2 = User.create! :name => "some_user 2"
    @user3 = User.create! :name => "some_user 2"
    student_in_course :course => @course, :user => @user1
    student_in_course :course => @course, :user => @user2
    student_in_course :course => @course, :user => @user3
    sub = q.generate_submission(@user1)
    sub.workflow_state = 'complete'
    sub.submission_data = [{ :points => 15, :text => "", :correct => "undefined", :question_id => question.id }]
    sub.score = 15
    sub.with_versioning(true, &:save!)
    stats = q.statistics
    stats[:submission_score_average].should == 15
    stats[:submission_score_high].should == 15
    stats[:submission_score_low].should == 15
    stats[:submission_score_stdev].should == 0
    stats[:submission_scores].should == { 50 => 1 }
    sub = q.generate_submission(@user2)
    sub.workflow_state = 'complete'
    sub.submission_data = [{ :points => 17, :text => "", :correct => "undefined", :question_id => question.id }]
    sub.score = 17
    sub.with_versioning(true, &:save!)
    stats = q.statistics
    stats[:submission_score_average].should == 16
    stats[:submission_score_high].should == 17
    stats[:submission_score_low].should == 15
    stats[:submission_score_stdev].should == 1
    stats[:submission_scores].should == { 50 => 1, 57 => 1 }
    sub = q.generate_submission(@user3)
    sub.workflow_state = 'complete'
    sub.submission_data = [{ :points => 20, :text => "", :correct => "undefined", :question_id => question.id }]
    sub.score = 20
    sub.with_versioning(true, &:save!)
    stats = q.statistics
    stats[:submission_score_average].should be_close(17 + 1.0/3, 0.0000000001)
    stats[:submission_score_high].should == 20
    stats[:submission_score_low].should == 15
    stats[:submission_score_stdev].should be_close(Math::sqrt(4 + 2.0/9), 0.0000000001)
    stats[:submission_scores].should == { 50 => 1, 57 => 1, 67 => 1 }
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
      @quiz = Quizzes::Quiz.find_by_assignment_id(@assignment.id)
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
      Quizzes::SubmissionGrader.new(@quiz_submission).grade_submission
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
      Quizzes::SubmissionGrader.new(qs).grade_submission

      # and one in progress
      @quiz.generate_submission(@student)
      stats = CSV.parse(csv(:include_all_versions => true))
      stats.last.length.should == 9
      stats.first.first == "section"
    end

    it 'should succeed with logged-out user submissions' do
      survey_with_logged_out_submission
      stats = CSV.parse(csv(:include_all_versions => true))
      stats.last[0].should == ''
      stats.last[1].should == ''
      stats.last[2].should == ''
    end

    it 'should have sections in quiz statistics_csv' do
      #enroll user in multiple sections
      pseudonym(@student)
      @student.pseudonym.sis_user_id = "user_sis_id_01"
      @student.pseudonym.save!
      section1 = @course.course_sections.first
      section1.sis_source_id = 'SISSection01'
      section1.save!
      section2 = CourseSection.new(:course => @course, :name => "section2")
      section2.sis_source_id = 'SISSection02'
      section2.save!
      @course.enroll_user(@student, "StudentEnrollment", :enrollment_state => 'active', :allow_multiple_enrollments => true, :section => section2)
      @student.save!
      # one complete submission
      qs = @quiz.generate_submission(@student)
      Quizzes::SubmissionGrader.new(qs).grade_submission

      stats = CSV.parse(csv(:include_all_versions => true))
      stats.last[0].should == "nobody@example.com"
      stats.last[1].should == @student.id.to_s
      stats.last[2].should == "user_sis_id_01"

      splitter = lambda { |str| str.split(",").map(&:strip) }
      sections = splitter.call(stats.last[3])
      sections.should include("section2")
      sections.should include("Unnamed Course")

      section_ids = splitter.call(stats.last[4])
      section_ids.should include(section2.id.to_s)
      section_ids.should include(section1.id.to_s)

      section_sis_ids = splitter.call(stats.last[5])
      section_sis_ids.should include("SISSection02")
      section_sis_ids.should include("SISSection01")
    end

    it 'should deal with incomplete fill-in-multiple-blanks questions' do
      @quiz.quiz_questions.create!(:question_data => { :name => "test 2",
        :question_type => 'fill_in_multiple_blanks_question',
        :question_text => "[ans0]",
        :answers =>
          [{'answer_text' => 'foo', 'blank_id' => 'ans0', 'answer_weight' => '100'}]})
      @quiz.quiz_questions.create!(:question_data => { :name => "test 3",
        :question_type => 'fill_in_multiple_blanks_question',
        :question_text => "[ans0] [ans1]",
        :answers =>
           [{'answer_text' => 'bar', 'blank_id' => 'ans0', 'answer_weight' => '100'},
            {'answer_text' => 'baz', 'blank_id' => 'ans1', 'answer_weight' => '100'}]})
      @quiz.generate_quiz_data
      @quiz.save!
      @quiz.quiz_questions.size.should == 3
      qs = @quiz.generate_submission(@student)
      # submission will not answer question 2 and will partially answer question 3
      qs.submission_data = {
          "question_#{@quiz.quiz_questions[2].id}_#{AssessmentQuestion.variable_id('ans1')}" => 'baz'
      }
      Quizzes::SubmissionGrader.new(qs).grade_submission
      stats = CSV.parse(csv)
      stats.last.size.should == 16 # 3 questions * 2 lines + ten more (name, id, sis_id, section, section_id, section_sis_id, submitted, correct, incorrect, score)
      stats.last[11].should == ',baz'
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
      Quizzes::SubmissionGrader.new(qs).grade_submission

      stats = CSV.parse(csv)
      stats.last[9].should == '5'
    end

    it 'should include primary domain if trust exists' do
      account2 = Account.create!
      HostUrl.stubs(:context_host).returns('school')
      HostUrl.expects(:context_host).with(account2).returns('school1')
      @student.pseudonyms.scoped.delete_all
      account2.pseudonyms.create!(user: @student, unique_id: 'user') { |p| p.sis_user_id = 'sisid' }
      @quiz.context.root_account.any_instantiation.stubs(:trust_exists?).returns(true)
      @quiz.context.root_account.any_instantiation.stubs(:trusted_account_ids).returns([account2.id])

      qs = @quiz.generate_submission(@student)
      qs.grade_submission
      stats = CSV.parse(csv(:include_all_versions => true))
      stats[1][3].should == 'school1'
    end
  end

  it "includes attachment display names for quiz file upload questions" do
    require 'action_controller_test_process'
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
    io = fixture_file_upload('scribd_docs/doc.doc', 'application/msword', true)
    attach = qs.attachments.create! :filename => "doc.doc",
      :display_name => "attachment.png", :user => student,
      :uploaded_data => io
    qs.submission_data["question_#{question.id}".to_sym] = [ attach.id.to_s ]
    qs.save!
    Quizzes::SubmissionGrader.new(qs).grade_submission
    qs = q.generate_submission student2
    qs.submission_data["question_#{question.id}".to_sym] = nil
    qs.save!
    Quizzes::SubmissionGrader.new(qs).grade_submission
    # make student2's submission first
    qs.updated_at = 3.days.ago
    qs.save!
    stats = CSV.parse(csv({:include_all_versions => true},q.reload))
    stats = stats.sort_by {|s| s[1] } # sort by the id
    stats.first[7].should == attach.display_name
  end

  it 'should strip tags from html multiple-choice/multiple-answers' do
    student_in_course(:active_all => true)
    q = @course.quizzes.create!(:title => "new quiz")
    q.update_attribute(:published_at, Time.now)
    q.quiz_questions.create!(:question_data => {:name => 'q1', :points_possible => 1, 'question_type' => 'multiple_choice_question', 'answers' => [{'answer_text' => '', 'answer_html' => '<em>zero</em>', 'answer_weight' => '100'}, {'answer_text' => "", 'answer_html' => "<p>one</p>", 'answer_weight' => '0'}]})
    q.quiz_questions.create!(:question_data => {:name => 'q2', :points_possible => 1, 'question_type' => 'multiple_answers_question', 'answers' => [{'answer_text' => '', 'answer_html' => "<a href='http://example.com/caturday.gif'>lolcats</a>", 'answer_weight' => '100'}, {'answer_text' => 'lolrus', 'answer_weight' => '100'}]})
    q.generate_quiz_data
    q.save
    qs = q.generate_submission(@student)
    qs.submission_data = {
        "question_#{q.quiz_data[0][:id]}" => "#{q.quiz_data[0][:answers][0][:id]}",
        "question_#{q.quiz_data[1][:id]}_answer_#{q.quiz_data[1][:answers][0][:id]}" => "1",
        "question_#{q.quiz_data[1][:id]}_answer_#{q.quiz_data[1][:answers][1][:id]}" => "1"
    }
    Quizzes::SubmissionGrader.new(qs).grade_submission

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
    stats.last[7].should == "zero"
    stats.last[9].should == "lolcats,lolrus"
  end

  it 'should not count teacher preview submissions' do
    teacher_in_course(:active_all => true)
    q = @course.quizzes.create!
    q.update_attribute(:published_at, Time.now)
    q.quiz_questions.create!(:question_data => {:name => 'q1', :points_possible => 1, 'question_type' => 'multiple_choice_question', 'answers' => [{'answer_text' => '', 'answer_html' => '<em>zero</em>', 'answer_weight' => '100'}, {'answer_text' => "", 'answer_html' => "<p>one</p>", 'answer_weight' => '0'}]})
    q.quiz_questions.create!(:question_data => {:name => 'q2', :points_possible => 1, 'question_type' => 'multiple_answers_question', 'answers' => [{'answer_text' => '', 'answer_html' => "<a href='http://example.com/caturday.gif'>lolcats</a>", 'answer_weight' => '100'}, {'answer_text' => 'lolrus', 'answer_weight' => '100'}]})
    q.generate_quiz_data
    q.save
    qs = q.generate_submission(@teacher, true)
    qs.submission_data = {
        "question_#{q.quiz_data[0][:id]}" => "#{q.quiz_data[0][:answers][0][:id]}",
        "question_#{q.quiz_data[1][:id]}_answer_#{q.quiz_data[1][:answers][0][:id]}" => "1",
        "question_#{q.quiz_data[1][:id]}_answer_#{q.quiz_data[1][:answers][1][:id]}" => "1"
    }
    Quizzes::SubmissionGrader.new(qs).grade_submission

    stats = q.statistics
    stats[:unique_submission_count].should == 0
  end

  describe 'question statistics' do
    subject { Quizzes::QuizStatistics::StudentAnalysis.new({}) }

    it 'should proxy to CanvasQuizStatistics for supported questions' do
      question_data = { question_type: 'essay_question' }
      responses = []

      CanvasQuizStatistics.
        expects(:analyze).
          with(question_data, responses).
          returns({ some_metric: 5 })

      output = subject.send(:stats_for_question, question_data, responses, false)
      output.should == {
        question_type: 'essay_question',
        some_metric: 5
      }
    end

    it "shouldn't proxy if the legacy flag is on" do
      question_data = {
        question_type: 'essay_question',
        answers: []
      }

      CanvasQuizStatistics.expects(:analyze).never

      subject.send(:stats_for_question, question_data, [])
    end
  end
end
