require File.expand_path(File.dirname(__FILE__) + '/../helpers/quizzes_common')

describe "canvas_quizzes" do
  include_context 'in-process server selenium tests'

  USING_NEW_CLIENT_APP = File.exist?(Rails.root.join("client_apps", "canvas_quizzes"))

  before do
    Account.default.tap do |account|
      account.enable_feature! :quiz_stats
      account.save!
    end

    quiz_with_graded_submission([
      {:question_data => {:name => 'question 1', :points_possible => 1, 'question_type' => 'true_false_question'}},
      {:question_data => {:name => 'question 2', :points_possible => 1, 'question_type' => 'true_false_question'}}
    ])

    course_with_teacher_logged_in(:active_all => true, :course => @course)
  end

  # TODO: remove once https://gerrit.instructure.com/#/c/44576 hits master
  if !USING_NEW_CLIENT_APP
    it 'should mount' do
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}/statistics"

      status = driver.execute_script <<-JS
        var mountStatus = document.body.appendChild(document.createElement('div'));

        require([ 'jquery', 'canvas_quiz_statistics' ], function($, app) {
          if (app.isMounted()) {
            $(mountStatus).text('success');
          } else {
            $(mountStatus).text('error');
          }
        });

        return mountStatus;
      JS

      wait = Selenium::WebDriver::Wait.new(timeout: 5)
      wait.until { status.text.present? } # require call is async

      expect(status.text).to match('success')
    end
  end

  if USING_NEW_CLIENT_APP
    describe 'statistics app' do
      it 'should mount' do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/statistics"

        status = driver.execute_script <<-JS
          var mountStatus = document.body.appendChild(document.createElement('div'));

          require([ 'jquery', 'canvas_quizzes/apps/statistics' ], function($, app) {
            if (app.isMounted()) {
              $(mountStatus).text('success');
            } else {
              $(mountStatus).text('error');
            }
          });

          return mountStatus;
        JS

        wait = Selenium::WebDriver::Wait.new(timeout: 5)
        wait.until { status.text.present? } # require call is async

        expect(status.text).to match('success')
      end
    end

    describe 'events app' do
      it 'should mount' do
        Account.default.enable_feature!(:quiz_log_auditing)

        sub = @quiz.quiz_submissions.first
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/submissions/#{sub.id}/log"

        status = driver.execute_script <<-JS
          var mountStatus = document.body.appendChild(document.createElement('div'));

          require([ 'jquery', 'canvas_quizzes/apps/events' ], function($, app) {
            if (app.isMounted()) {
              $(mountStatus).text('success');
            } else {
              $(mountStatus).text('error');
            }
          });

          return mountStatus;
        JS

        wait = Selenium::WebDriver::Wait.new(timeout: 5)
        wait.until { status.text.present? } # require call is async

        expect(status.text).to match('success')
      end
    end
  end
end