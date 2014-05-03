shared_examples_for "Quizzes::QuizStatistics::Report" do
  # let(:report_type) - report_type to test

  before(:each) do
    student_in_course(:active_all => true)
    @quiz = @course.quizzes.create!
    @quiz.quiz_questions.create!(:question_data => { :name => "test 1" })
    @quiz.generate_quiz_data
    @quiz.published_at = Time.now
    @quiz.save!
  end

  it 'provides progress updates' do
    @quiz.statistics_csv(report_type, :async => true)
    run_jobs
    progress = @quiz.quiz_statistics.first.progress
    progress.completion.should == 100
    progress.should be_completed
  end

end
