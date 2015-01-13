require 'spec_helper'

shared_examples_for 'QuizReportSerializer Associations' do

  it 'should embed its attachment as :file when present' do
    statistics.generate_csv
    statistics.reload

    serializer = Quizzes::QuizReportSerializer.new(statistics, {
      controller: controller,
      scope: user,
      session: session,
      includes: [ 'file' ]
    })

    json = serializer.as_json[:quiz_report].stringify_keys
    expect(json).to have_key 'file'
    expect(json['file']['id']).to be_present
  end

  it 'should embed its progress when present' do
    statistics.generate_csv_in_background

    serializer = Quizzes::QuizReportSerializer.new(statistics, {
      controller: controller,
      scope: user,
      session: session,
      includes: [ 'progress' ]
    })

    json = serializer.as_json[:quiz_report].stringify_keys
    expect(json).to have_key 'progress'
    expect(json['progress'][:id]).to be_present
  end
end

describe Quizzes::QuizReportSerializer do
  let :context do
    Course.new.tap do |course|
      course.id = 1
      course.save!
    end
  end
  let :quiz do
    context.quizzes.build(title: 'banana split').tap do |quiz|
      quiz.id = 2
      quiz.save!
    end
  end

  let :statistics do
    quiz.current_statistics_for('student_analysis')
  end

  let(:user) { User.new }
  let(:session) { stub }
  let(:host_name) { 'example.com' }

  let :controller do
    ActiveModel::FakeController.new({}).tap do |controller|
      controller.stubs(:session).returns session
      controller.stubs(:context).returns context
    end
  end

  subject do
    Quizzes::QuizReportSerializer.new(statistics, {
      controller: controller,
      scope: user,
      session: session
    })
  end

  let :json do
    @json ||= subject.as_json[:quiz_report].stringify_keys
  end

  context 'format independent' do
    %w[
      report_type readable_type includes_all_versions anonymous
      created_at updated_at
    ].each do |attr|
      it "serializes #{attr}" do
        expect(json[attr]).to eq statistics.send(attr)
      end
    end

    it 'should expose whether the report is generatable' do
      expect(json['generatable']).to eq statistics.report.generatable?
    end

    it 'should link to itself' do
      expect(json['url']).to eq(
        "http://example.com/api/v1/courses/1/quizzes/2/reports/#{statistics.id}"
      )
    end
  end

  context 'JSON-API' do
    before do
      controller.expects(:accepts_jsonapi?).at_least_once.returns true
    end

    it 'serializes id' do
      expect(json['id']).to eq "#{statistics.id}"
    end

    context 'associations' do
      include_examples 'QuizReportSerializer Associations'

      it 'should link to the quiz' do
        expect(json['links']).to be_present
        expect(json['links']['quiz']).to eq 'http://example.com/api/v1/courses/1/quizzes/2'
      end
    end
  end

  context 'legacy JSON' do
    before do
      controller.expects(:accepts_jsonapi?).at_least_once.returns false
    end

    it 'serializes id' do
      expect(json['id']).to eq statistics.id
    end

    it 'should include quiz_id' do
      expect(json['quiz_id']).to eq quiz.id
    end

    it 'should include the progress_url' do
      statistics.generate_csv_in_background

      expect(json['progress_url']).to eq(
        "http://example.com/api/v1/progress/#{statistics.progress.id}"
      )
    end

    context 'associations' do
      include_examples 'QuizReportSerializer Associations'
    end
  end
end
