require File.expand_path(File.dirname(__FILE__) + '/../../api_spec_helper')

describe Quizzes::QuizAssignmentOverridesController, type: :request do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  describe '[GET] /courses/:course_id/quizzes/assignment_overrides' do
    before do
      course_with_teacher(:active_all => true)
      @quiz  = @course.quizzes.create! title: 'title'
      @quiz.workflow_state = 'available'
      @quiz.build_assignment
      @quiz.publish!
      @quiz.reload
    end

    it "should require authorization" do
      user(active_all: true) # not enrolled

      raw_api_call(:get, "/api/v1/courses/#{@course.id}/quizzes/assignment_overrides",
                  {:controller=>"quizzes/quiz_assignment_overrides", :action => "index", :format => "json", :course_id => "#{@course.id}"},
                  {:quiz_assignment_overrides => [{ :quiz_ids => [@quiz.id] }] })

      response.code.should == '401'
    end

    it "should include visible overrides" do
      due_at = 5.minutes.ago

      assignment_override_model({
        set: @course.default_section,
        quiz: @quiz,
        due_at: due_at
      })

      @quiz.reload.assignment_overrides.count.should == 1

      json = api_call(:get, "/api/v1/courses/#{@course.id}/quizzes/assignment_overrides", {
        :controller => 'quizzes/quiz_assignment_overrides',
        :action => 'index',
        :format => 'json',
        :course_id => @course.id.to_s
      }, {
        quiz_assignment_overrides: [{
          quiz_ids: [@quiz].map(&:id).map(&:to_s)
        }]
      })

      json.should have_key('quiz_assignment_overrides')
      json['quiz_assignment_overrides'].size.should == 1
      json['quiz_assignment_overrides'][0].tap do |override|
        override.keys.sort.should == %w[ all_dates due_dates quiz_id ]
        override['quiz_id'].should == @quiz.id
        override['due_dates'].length.should == 1
        override['due_dates'][0]['due_at'].should == due_at.iso8601
      end
    end
  end
end
