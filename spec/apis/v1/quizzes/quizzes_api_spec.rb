
# Copyright (C) 2012 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.dirname(__FILE__) + '/../../api_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../locked_spec')

describe Quizzes::QuizzesApiController, type: :request do
  context 'locked api item' do
    let(:item_type) { 'quiz' }

    let(:locked_item) do
      @course.quizzes.create!(:title => 'Locked Quiz')
    end

    def api_get_json
      api_call(
        :get,
        "/api/v1/courses/#{@course.id}/quizzes/#{locked_item.id}",
        {:controller=>'quizzes/quizzes_api', :action=>'show', :format=>'json', :course_id=>"#{@course.id}", :id => "#{locked_item.id}"},
      )
    end

    include_examples 'a locked api item'
  end

  describe "GET /courses/:course_id/quizzes (index)" do
    before(:once) { teacher_in_course(:active_all => true) }

    it "should return list of quizzes" do
      quizzes = (0..3).map{ |i| @course.quizzes.create! :title => "quiz_#{i}" }

      json = api_call(:get, "/api/v1/courses/#{@course.id}/quizzes",
                      :controller=>"quizzes/quizzes_api", :action=>"index", :format=>"json", :course_id=>"#{@course.id}")

      quiz_ids = json.collect { |quiz| quiz['id'] }
      quiz_ids.should == quizzes.map(&:id)
    end

    it "should search for quizzes by title" do
      2.times{ |i| @course.quizzes.create! :title => "first_#{i}" }
      ids = @course.quizzes.map(&:id)
      2.times{ |i| @course.quizzes.create! :title => "second_#{i}" }

      json = api_call(:get, "/api/v1/courses/#{@course.id}/quizzes?search_term=fir",
                      :controller=>"quizzes/quizzes_api", :action=>"index", :format=>"json", :course_id=>"#{@course.id}",
                      :search_term => 'fir')

      json.map{|h| h['id'] }.sort.should == ids.sort
    end

    it "should return unauthorized if the quiz tab is disabled" do
      @course.tab_configuration = [ { :id => Course::TAB_QUIZZES, :hidden => true } ]
      @course.save!
      student_in_course(:active_all => true, :course => @course)
      raw_api_call(:get, "/api/v1/courses/#{@course.id}/quizzes",
                   :controller => "quizzes/quizzes_api",
                   :action => "index",
                   :format => "json",
                   :course_id => "#{@course.id}")
      assert_status(404)
    end

    context "jsonapi style" do

      it "renders a jsonapi style response" do
        quizzes = (0..3).map{ |i| @course.quizzes.create! :title => "quiz_#{i}" }

        json = api_call(:get, "/api/v1/courses/#{@course.id}/quizzes",
                        {:controller=>"quizzes/quizzes_api", :action=>"index", :format=>"json", :course_id=>"#{@course.id}"},
                        {},
                        'Accept' => 'application/vnd.api+json')
        meta = json['meta']
        meta = json['meta']
        meta['permissions']['quizzes']['create'].should == true

        json = json['quizzes']
        quiz_ids = json.collect { |quiz| quiz['id'] }
        quiz_ids.should == quizzes.map(&:id).map(&:to_s)

      end

      it "limits student requests to available quizzes" do
        student_in_course(:active_all => true)
        quizzes = (0..3).map{ |i| @course.quizzes.create! :title => "quiz_#{i}" }
        available_quiz = quizzes.first
        available_quiz.workflow_state = 'available'
        available_quiz.save!

        json = api_call(:get, "/api/v1/courses/#{@course.id}/quizzes",
                        {:controller=>"quizzes/quizzes_api", :action=>"index", :format=>"json", :course_id=>"#{@course.id}"},
                        {},
                        'Accept' => 'application/vnd.api+json')
        json = json['quizzes']
        quiz_ids = json.collect { |quiz| quiz['id'] }
        quiz_ids.should == [ available_quiz.id.to_s ]
      end
    end
  end

  describe "GET /courses/:course_id/quizzes/:id (show)" do
    before(:once) { course_with_teacher(:active_all => true, :course => @course) }

    context "unpublished quiz" do
      before do
        @quiz = @course.quizzes.create! :title => 'title'
        @quiz.quiz_questions.create!(:question_data => { :name => "test 1" })
        @quiz.save!

        @json = api_call(:get, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}",
                        :controller=>"quizzes/quizzes_api", :action=>"show", :format=>"json", :course_id=>"#{@course.id}", :id => "#{@quiz.id}")
      end

      it "includes unpublished questions in question count" do
        @json['question_count'].should == 1
      end
    end

    context "jsonapi style request" do

      it "renders in a jsonapi style" do
        @quiz = @course.quizzes.create! title: 'Test Quiz'
        @json = api_call(:get, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}",
                         { :controller=>"quizzes/quizzes_api", :action=>"show", :format=>"json", :course_id=>"#{@course.id}", :id => "#{@quiz.id}"}, {},
                        'Accept' => 'application/vnd.api+json')
        @json = @json.fetch('quizzes').map { |q| q.with_indifferent_access }
        @json.should =~ [
          Quizzes::QuizSerializer.new(@quiz, scope: @user, controller: controller, session: session).
          as_json[:quiz].with_indifferent_access
        ]
      end
    end

    context "non-existent quiz" do
      before do
        @json = api_call(:get, "/api/v1/courses/#{@course.id}/quizzes/10101",
                        {:controller=>"quizzes/quizzes_api", :action=>"show", :format=>"json", :course_id=>"#{@course.id}", :id => "10101"},
                        {}, {}, {:expected_status => 404})
      end

      it "should return a not found error message" do
        @json.inspect.should include "does not exist"
      end
    end
  end

  describe "POST /courses/:course_id/quizzes (create)" do
    def api_create_quiz(quiz_params, opts={})
      api_call(:post, "/api/v1/courses/#{@course.id}/quizzes",
              {:controller=>"quizzes/quizzes_api", :action => "create", :format=>"json", :course_id=>"#{@course.id}"},
              {:quiz => quiz_params}, {}, opts)
    end

    before(:once) { teacher_in_course(:active_all => true) }

    let (:new_quiz) { @course.quizzes.first }

    context "jsonapi style request" do

      it "renders in a jsonapi style" do
        @json = api_call(:post, "/api/v1/courses/#{@course.id}/quizzes",
                         { :controller=>"quizzes/quizzes_api", :action=>"create", :format=>"json", :course_id=>"#{@course.id}" },
                         { quizzes: [{ 'title' => 'blah blah', 'published' => true }] },
                        'Accept' => 'application/vnd.api+json')
        @json = @json.fetch('quizzes').map { |q| q.with_indifferent_access }
        @quiz = Quizzes::Quiz.first
        @json.should =~ [
          Quizzes::QuizSerializer.new(@quiz, scope: @user, controller: controller, session: session).
          as_json[:quiz].with_indifferent_access
        ]
      end
    end

    it "creates a quiz for the course" do
      api_create_quiz({ 'title' => 'testing' })
      new_quiz.title.should == 'testing'
    end

    it "doesn't allow setting fields not in the whitelist" do
      api_create_quiz({ 'assignment_id' => 123 })
      new_quiz.assignment_id.should be_nil
    end

    it "allows creating a published quiz" do
      api_create_quiz('published' => true)
      new_quiz.should be_published
    end

    it "renders an error when the title is too long" do
      title = 'a' * ActiveRecord::Base.maximum_string_length + '!'
      json = api_create_quiz({ 'title' => title }, :expected_status => 400 )
      json.should have_key 'errors'
      new_quiz.should be_nil
    end

    describe "validations" do
      context "assignment_group_id" do
        let_once(:my_group) { @course.assignment_groups.create! :name => 'my group' }
        let_once(:other_course) { Course.create! :name => 'other course' }
        let_once(:other_group) { other_course.groups.create! :name => 'other group' }

        it "should put the quiz in a group owned by its course" do
          api_create_quiz({'title' => 'test quiz', 'assignment_group_id' => my_group.id})
          new_quiz.assignment_group_id.should == my_group.id
        end

        it "should not put the quiz in a group not owned by its course" do
          api_create_quiz({'title' => 'test quiz', 'assignment_group_id' => other_group.id})
          new_quiz.assignment_group_id.should_not == other_group.id
        end
      end

      context "hide_results" do
        it "should set hide_results='until_after_last_attempt' if allowed_attempts > 1" do
          api_create_quiz({'hide_results' => 'until_after_last_attempt', 'allowed_attempts' => 3})
          new_quiz.hide_results.should == 'until_after_last_attempt'
        end

        it "should not hide_results='until_after_last_attempt' if allowed_attempts == 1" do
          api_create_quiz({'hide_results' => 'until_after_last_attempt', 'allowed_attempts' => 1})
          new_quiz.hide_results.should_not == 'until_after_last_attempt'
        end

        it "should not hide_results='until_after_last_attempt' if allowed_attempts < 1" do
          api_create_quiz({'hide_results' => 'until_after_last_attempt', 'allowed_attempts' => -1})
          new_quiz.hide_results.should_not == 'until_after_last_attempt'
        end
      end

      context "show_correct_answers" do
        it "should be set if hide_results is disabled" do
          api_create_quiz({'show_correct_answers' => false, 'hide_results' => nil})
          new_quiz.show_correct_answers.should be_false
        end

        it "should be ignored if hide_results is enabled" do
          api_create_quiz({'show_correct_answers' => false, 'hide_results' => 'always'})
          new_quiz.show_correct_answers.should be_true
        end
      end

      context "scoring_policy" do
        it "should set scoring policy if allowed_attempts > 1" do
          api_create_quiz({'scoring_policy' => 'keep_latest', 'allowed_attempts' => 3})
          new_quiz.scoring_policy.should == 'keep_latest'
        end

        it "should not set scoring policy if allowed_attempts == 1" do
          api_create_quiz({'scoring_policy' => 'keep_latest', 'allowed_attempts' => 1})
          new_quiz.scoring_policy.should_not == 'keep_latest'
        end

        it "should not set scoring policy if allowed_attempts > 1" do
          api_create_quiz({'scoring_policy' => 'keep_latest', 'allowed_attempts' => -1})
          new_quiz.scoring_policy.should_not == 'keep_latest'
        end
      end

      context "cant_go_back" do
        it "should set cant_go_back if one_question_at_a_time is true" do
          api_create_quiz({'cant_go_back' => true, 'one_question_at_a_time' => true})
          new_quiz.cant_go_back.should be_true
        end

        it "should not set cant_go_back if one_question_at_a_time is not true" do
          api_create_quiz({'cant_go_back' => true, 'one_question_at_a_time' => false})
          new_quiz.cant_go_back.should_not be_true
        end
      end

      context 'time_limit' do
        it 'should discard negative values' do
          api_create_quiz({'time_limit' => -25})
          new_quiz.time_limit.should be_nil
        end
      end

      context 'allowed_attempts' do
        it 'should discard values less than -1' do
          api_create_quiz({'allowed_attempts' => -25})
          new_quiz.allowed_attempts.should == 1
        end
      end
    end
  end

  describe "DELETE /courses/:course_id/quizzes/id (destroy)" do
    it "deletes a quiz" do
      teacher_in_course active_all: true
      quiz = course_quiz !!:active
      api_call(:delete, "/api/v1/courses/#{@course.id}/quizzes/#{quiz.id}",
               {controller: 'quizzes/quizzes_api', action: 'destroy',
                format: 'json', course_id: @course.id.to_s,
                id: quiz.id.to_s})
      quiz.reload.should be_deleted
    end
  end

  describe "PUT /courses/:course_id/quizzes/:id (update)" do
    def api_update_quiz(quiz_params, api_params, opts={})
      @quiz ||= @course.quizzes.create!({:title => 'title'}.merge(quiz_params))
      api_call(:put, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}",
              {:controller=>"quizzes/quizzes_api", :action => "update", :format=>"json", :course_id=>"#{@course.id}", :id=>"#{@quiz.id}"},
              {:quiz => api_params}, {}, opts)
    end

    before { teacher_in_course(:active_all => true) }

    let (:updated_quiz) { @course.quizzes.first }
    let (:quiz_params) { {} }

    it "updates quiz attributes" do
      api_update_quiz({'title' => 'old title'}, {'title' => 'new title'})
      updated_quiz.title.should == 'new title'
    end
    context "jsonapi style request" do

      it "renders in a jsonapi style" do
        @quiz = @course.quizzes.create! title: 'Test Quiz'
        @json = raw_api_call(:put, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}",
                         { :controller=>"quizzes/quizzes_api", :action=>"update", :format=>"json", :course_id=>"#{@course.id}", :id => "#{@quiz.id}"},
                         { quizzes: [{ 'id' => @quiz.id, 'title' => 'blah blah' }] },
                        'Accept' => 'application/vnd.api+json')
        response.should be_success
      end
    end

    it "doesn't allow setting fields not in the whitelist" do
      api_update_quiz({}, {'assignment_id' => 123})
      updated_quiz.assignment_id.should_not == 123
    end

    it "renders an error when the title is too long" do
      long_title = 'a' * ActiveRecord::Base.maximum_string_length + '!'
      json = api_update_quiz({}, {'title' => long_title}, :expected_status => 400 )
      json.should have_key 'errors'
      updated_quiz.title.should == 'title'
    end

    context 'lockdown_browser' do
      before :once do
        # require_lockdown_browser, require_lockdown_browser_for_results and
        # require_lockdown_browser_monitor will only return true if the plugin is enabled,
        # so register and enable it for these test
        Canvas::Plugin.register(:example_spec_lockdown_browser, :lockdown_browser, {
                :settings => {:enabled => false}})
        setting = PluginSetting.find_or_create_by_name('example_spec_lockdown_browser')
        setting.settings = {:enabled => true}
        setting.save!
      end

      it 'should allow setting require_lockdown_browser' do
        api_update_quiz({'require_lockdown_browser' => false}, {'require_lockdown_browser' => true})
        updated_quiz.require_lockdown_browser.should be_true
      end

      it 'should allow setting require_lockdown_browser_for_results' do
        api_update_quiz({'require_lockdown_browser_for_results' => false}, {'require_lockdown_browser_for_results' => true})
        updated_quiz.require_lockdown_browser_for_results.should be_true
      end

      it 'should allow setting require_lockdown_browser_monitor' do
        api_update_quiz({'require_lockdown_browser_monitor' => false}, {'require_lockdown_browser_monitor' => true})
        updated_quiz.require_lockdown_browser_monitor.should be_true
      end

      it 'should allow setting lockdown_browser_monitor_data' do
        api_update_quiz({'lockdown_browser_monitor_data' => nil}, {'lockdown_browser_monitor_data' => 'VGVzdCBEYXRhCg=='})
        updated_quiz.lockdown_browser_monitor_data.should == 'VGVzdCBEYXRhCg=='
      end
    end

    context "draft state changes" do

      it "allows un/publishing an unpublished quiz" do
        api_update_quiz({},{})
        @quiz.reload.should_not be_published # in 'created' state by default
        json = api_update_quiz({}, {published: false})
        json['unpublishable'].should == true
        @quiz.reload.should be_unpublished
        json = api_update_quiz({}, {published: true})
        json['unpublishable'].should == true
        @quiz.reload.should be_published
        api_update_quiz({},{published: nil}) # nil shouldn't change published
        @quiz.reload.should be_published

        @quiz.any_instantiation.stubs(:has_student_submissions?).returns true
        json = api_update_quiz({},{}) # nil shouldn't change published
        json['unpublishable'].should == false

        json = api_update_quiz({}, {published: false}, {expected_status: 400})
        json['errors']['published'].should_not be_nil

        ActiveRecord::Base.reset_any_instantiation!
        @quiz.reload.should be_published
      end

      it "should not lose quiz question count when publishing with draft state" do
        Account.default.enable_feature!(:draft_state)

        @quiz ||= @course.quizzes.create!(:title => 'title')
        @qq1 = @quiz.quiz_questions.create!(
          question_data: multiple_choice_question_data
        )
        json = api_update_quiz({}, {published: true})
        @quiz.reload.should be_published
        @quiz.question_count.should == 1
      end
    end

    describe "validations" do
      context "hide_results" do
        it "should set hide_results='until_after_last_attempt' if allowed_attempts > 1" do
          api_update_quiz({'allowed_attempts' => 3}, {'hide_results' => 'until_after_last_attempt'})
          updated_quiz.hide_results.should == 'until_after_last_attempt'
        end

        it "should not hide_results='until_after_last_attempt' if allowed_attempts == 1" do
          api_update_quiz({'allowed_attempts' => 1}, {'hide_results' => 'until_after_last_attempt'})
          updated_quiz.hide_results.should_not == 'until_after_last_attempt'
        end

        it "should not hide_results='until_after_last_attempt' if allowed_attempts < 1" do
          api_update_quiz({'allowed_attempts' => -1}, {'hide_results' => 'until_after_last_attempt'})
          updated_quiz.hide_results.should_not == 'until_after_last_attempt'
        end
      end

      context "show_correct_answers" do
        it "should save show_correct_answers if hide_results is null" do
          api_update_quiz({'hide_results' => nil}, {'show_correct_answers' => false})
          updated_quiz.show_correct_answers.should be_false
        end

        it "should not save show_correct_answers if hide_results is not null" do
          api_update_quiz({'hide_results' => 'always'}, {'show_correct_answers' => false})
          updated_quiz.show_correct_answers.should be_true
        end
      end

      context "scoring_policy" do
        it "should set scoring policy if allowed_attempts > 1" do
          api_update_quiz({'allowed_attempts' => 3}, {'scoring_policy' => 'keep_latest'})
          updated_quiz.scoring_policy.should == 'keep_latest'
        end

        it "should not set scoring policy if allowed_attempts == 1" do
          api_update_quiz({'allowed_attempts' => 1}, {'scoring_policy' => 'keep_latest'})
          updated_quiz.scoring_policy.should_not == 'keep_latest'
        end

        it "should not set scoring policy if allowed_attempts > 1" do
          api_update_quiz({'allowed_attempts' => -1}, {'scoring_policy' => 'keep_latest'})
          updated_quiz.scoring_policy.should_not == 'keep_latest'
        end
      end

      context "cant_go_back" do
        it "should set cant_go_back if one_question_at_a_time is true" do
          api_update_quiz({'one_question_at_a_time' => true}, {'cant_go_back' => true})
          updated_quiz.cant_go_back.should be_true
        end

        it "should not set cant_go_back if one_question_at_a_time is not true" do
          api_update_quiz({'one_question_at_a_time' => false}, {'cant_go_back' => true})
          updated_quiz.cant_go_back.should_not be_true
        end
      end

      context 'time_limit' do
        it 'should discard negative values' do
          api_update_quiz({'time_limit' => 10}, {'time_limit' => -25})
          updated_quiz.time_limit.should == 10
        end
      end

      context 'allowed_attempts' do
        it 'should discard values less than -1' do
          api_update_quiz({'allowed_attempts' => -1}, {'allowed_attempts' => -25})
          updated_quiz.allowed_attempts.should == -1
        end
      end
    end
  end

  describe "POST /courses/:course_id/quizzes/:id/reorder (reorder)" do
    before :once do
      teacher_in_course(:active_all => true)
      @quiz  = @course.quizzes.create! :title => 'title'
      @question1 = @quiz.quiz_questions.create!(:question_data => {'name' => 'test question 1', 'answers' => [{'id' => 1}, {'id' => 2}], :position => 1})
      @question2 = @quiz.quiz_questions.create!(:question_data => {'name' => 'test question 2', 'answers' => [{'id' => 3}, {'id' => 4}], :position => 2})
      @question3 = @quiz.quiz_questions.create!(:question_data => {'name' => 'test question 3', 'answers' => [{'id' => 5}, {'id' => 6}], :position => 3})
    end

    it "should require authorization" do
      course_with_student_logged_in(:active_all => true)
      course_quiz

      raw_api_call(:post, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/reorder",
                  {:controller=>"quizzes/quizzes_api", :action => "reorder", :format => "json", :course_id => "#{@course.id}", :id => "#{@quiz.id}"},
                  {:order => [] },
                  {'Accept' => 'application/vnd.api+json'})

      # should be authorization error
      response.code.should == '401'
    end

    it "should reorder a quiz's questions" do
      raw_api_call(:post, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/reorder",
                  {:controller=>"quizzes/quizzes_api", :action => "reorder", :format => "json", :course_id => "#{@course.id}", :id => "#{@quiz.id}"},
                  {:order => [{"type" => "question", "id" => @question3.id},
                              {"type" => "question", "id" => @question1.id},
                              {"type" => "question", "id" => @question2.id}] },
                  {'Accept' => 'application/vnd.api+json'})

      # should reorder the quiz questions
      order = @quiz.reload.quiz_questions.active.sort_by{|q| q.position }.map {|q| q.id }
      order.should == [@question3.id, @question1.id, @question2.id]
    end

    it "should reorder a quiz's questions and groups" do
      @group = @quiz.quiz_groups.create :name => 'Test Group'

      raw_api_call(:post, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/reorder",
                  {:controller=>"quizzes/quizzes_api", :action => "reorder", :format => "json", :course_id => "#{@course.id}", :id => "#{@quiz.id}"},
                  {:order => [{"type" => "question", "id" => @question3.id},
                              {"type" => "group",    "id" => @group.id},
                              {"type" => "question", "id" => @question1.id},
                              {"type" => "question", "id" => @question2.id}] },
                  {'Accept' => 'application/vnd.api+json'})

      # should reorder group
      @question3.reload.position.should == 1
      @group.reload.position.should     == 2
      @question1.reload.position.should == 3
      @question2.reload.position.should == 4
    end

    it "should pull questions out of a group to the root quiz" do
      @group = @quiz.quiz_groups.create :name => 'Test Group'
      @group.quiz_questions = [@question1, @question2]

      raw_api_call(:post, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/reorder",
                  {:controller=>"quizzes/quizzes_api", :action => "reorder", :format => "json", :course_id => "#{@course.id}", :id => "#{@quiz.id}"},
                  {:order => [{"type" => "question", "id" => @question3.id},
                              {"type" => "question", "id" => @question2.id}] },
                  {'Accept' => 'application/vnd.api+json'})

      # should remove items from the group
      order = @group.reload.quiz_questions.active.sort_by{|q| q.position }.map {|q| q.id }
      order.should == [@question1.id]
    end
  end
end
