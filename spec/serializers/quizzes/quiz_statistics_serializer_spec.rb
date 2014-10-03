require 'spec_helper'

describe Quizzes::QuizStatisticsSerializer do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  let :context do
    Course.new.tap do |course|
      course.id = 1
      course.save!
    end
  end

  let :quiz do
    context.quizzes.build(title: 'banana split').tap do |quiz|
      quiz.id = 1
      quiz.save!
    end
  end

  let :statistics do
    analyses = [
      quiz.current_statistics_for('student_analysis'),
      quiz.current_statistics_for('item_analysis')
    ]

    analyses.each do |analysis|
      analysis.quiz = quiz
    end

    Quizzes::QuizStatisticsSerializer::Input.new(quiz, *analyses)
  end

  let(:user) { User.new }
  let(:session) { stub }
  let(:host_name) { 'example.com' }

  let :controller do
    options = {
      accepts_jsonapi: true,
      stringify_json_ids: false
    }

    ActiveModel::FakeController.new(options).tap do |controller|
      controller.stubs(:session).returns session
      controller.stubs(:context).returns context
    end
  end

  subject do
    Quizzes::QuizStatisticsSerializer.new(statistics, {
      controller: controller,
      scope: user,
      session: session
    })
  end

  before do
    @json = subject.as_json[:quiz_statistics].stringify_keys
  end

  %w[
    question_statistics submission_statistics multiple_attempts_exist
    includes_all_versions generated_at
  ].each do |attr|
    it "serializes #{attr}" do
      @json.should have_key(attr)
    end
  end

  it 'serializes generated_at to point to the earliest report date' do
    oldest = 5.days.ago

    statistics.student_analysis.stubs(created_at: oldest)
    statistics.item_analysis.stubs(created_at: oldest + 1.days)

    @json = subject.as_json[:quiz_statistics].stringify_keys
    @json['generated_at'].should == oldest
  end

  it 'de-scopifies submission statistic keys' do
    keys = %w[
      correct_count_average
      duration_average
      incorrect_count_average
      logged_out_users
      score_average
      score_high
      score_low
      score_stdev
      unique_count
      user_ids
    ]

    (@json['submission_statistics'].keys.map(&:to_s).sort & keys).should == keys
  end

  it 'serializes url' do
    @json['url'].should == 'http://example.com/api/v1/courses/1/quizzes/1/statistics'
  end

  it 'serializes quiz url' do
    @json['links'].should be_present
    @json['links']['quiz'].should == 'http://example.com/api/v1/courses/1/quizzes/1'
  end

  it 'stringifies question_statistics ids' do
    subject.stubs(student_analysis_report: {
      questions: [ ['question', { id: 5 }] ]
    })

    json = subject.as_json[:quiz_statistics]
    json[:question_statistics].should be_present
    json[:question_statistics][0][:id].should == "5"
  end

  it 'munges item_analysis with question_statistics' do
    subject.stubs(student_analysis_report: {
      questions: [ ['question', { id: 5 }] ]
    })

    subject.stubs(item_analysis_report: [
      { question_id: 5, foo: 'bar' }
    ])

    json = subject.as_json[:quiz_statistics]
    json[:question_statistics].should be_present
    json[:question_statistics][0][:foo].should == "bar"
  end
end
