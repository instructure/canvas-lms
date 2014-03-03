require File.expand_path(File.dirname(__FILE__) + '/../../api_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../../models/quizzes/quiz_statistics/item_analysis/common')

describe Quizzes::QuizStatisticsController, type: :request do
  def api_index(options={}, params={})
    helper = method(options[:raw] ? :raw_api_call : :api_call)
    helper.call(:get,
      "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/statistics", {
        controller: 'quizzes/quiz_statistics',
        action: 'index',
        format: 'json',
        course_id: @course.id.to_s,
        quiz_id: @quiz.id.to_s
      }, params, { 'Accept' => 'application/vnd.api+json' })
  end

  before :each do
    course_with_teacher_logged_in :active_all => true

    teacher = @user

    simple_quiz_with_submissions %w{T T T}, %w{T T T}, %w{T F F}, %w{T F T},
      :user => @user,
      :course => @course

    @user = teacher
  end

  describe 'GET /courses/:course_id/quizzes/:quiz_id/statistics [index]' do
    it 'should generate statistics implicitly, never return an empty list' do
      Quizzes::QuizStatistics.destroy_all
      json = api_index
      json['quiz_statistics'].should_not == {}
    end

    it 'should deny unauthorized access' do
      student_in_course
      api_index raw: true
      assert_status(401)
    end

    it 'should respect the all_versions parameter' do
      json1 = api_index({}, { all_versions: true })
      json2 = api_index({}, { all_versions: false })

      [ json1, json2 ].each_with_index do |json, index|
        json['quiz_statistics'].should be_present
        json['quiz_statistics'][0]['includes_all_versions'].should == (index == 0)
      end
    end

    it 'should render' do
      json = api_index
      json.has_key?('quiz_statistics').should be_true
      json['quiz_statistics'].size.should == 1
      json['quiz_statistics'][0].keys.should_not == []
      json['quiz_statistics'][0].should have_key('links')
      json['quiz_statistics'][0].should_not have_key('quiz_id')
    end

    context 'JSON-API compliance' do
      it 'should conform to the JSON-API spec when returning the object' do
        json = api_index
        assert_jsonapi_compliance(json, 'quiz_statistics')
      end
    end
  end
end