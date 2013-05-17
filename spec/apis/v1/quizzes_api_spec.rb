
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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe QuizzesApiController, :type => :integration do

  describe "GET /courses/:course_id/quizzes (index)" do
    before { teacher_in_course(:active_all => true) }

    it "should return list of quizzes" do
      quizzes = (0..3).map{ |i| @course.quizzes.create! :title => "quiz_#{i}" }

      json = api_call(:get, "/api/v1/courses/#{@course.id}/quizzes",
                      :controller=>"quizzes_api", :action=>"index", :format=>"json", :course_id=>"#{@course.id}")
      
      quiz_ids = json.collect { |quiz| quiz['id'] }
      quiz_ids.should == quizzes.map(&:id)
    end

    it "should return unauthorized if the quiz tab is disabled" do
      @course.tab_configuration = [ { :id => Course::TAB_QUIZZES, :hidden => true } ]
      student_in_course(:active_all => true, :course => @course)
      raw_api_call(:get, "/api/v1/courses/#{@course.id}/quizzes",
                   :controller => "quizzes_api",
                   :action => "index",
                   :format => "json",
                   :course_id => "#{@course.id}")
      response.status.to_i.should == 404
    end
  end

  describe "GET /courses/:course_id/quizzes/:id (show)" do
    before { teacher_in_course(:active_all => true) }

    context "valid quiz" do
      before do
        @quiz = @course.quizzes.create! :title => 'title'
        @json = api_call(:get, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}",
                        :controller=>"quizzes_api", :action=>"show", :format=>"json", :course_id=>"#{@course.id}", :id => "#{@quiz.id}")
      end

      Api::V1::Quiz::API_ALLOWED_QUIZ_OUTPUT_FIELDS[:only].each do |field|
        it "includes #{field}" do
          @json.should have_key field.to_s
          @json[field.to_s].should == @quiz.send(field)
        end
      end

      it "includes html_url" do
        @json['html_url'].should == polymorphic_url([@course, @quiz])
      end

      it "includes mobile_url" do
        @json['mobile_url'].should == polymorphic_url([@course, @quiz], :persist_headless => 1, :force_user => 1)
      end
    end

    context "non-existent quiz" do
      before do
        @json = api_call(:get, "/api/v1/courses/#{@course.id}/quizzes/10101",
                        {:controller=>"quizzes_api", :action=>"show", :format=>"json", :course_id=>"#{@course.id}", :id => "10101"},
                        {}, {}, {:expected_status => 404})
      end

      it "should return a not found error message" do
        @json.should contain /not found/
      end
    end
  end

  describe "POST /courses/:course_id/quizzes (create)" do
    def api_create_quiz(quiz_params, opts={})
      api_call(:post, "/api/v1/courses/#{@course.id}/quizzes",
              {:controller=>"quizzes_api", :action => "create", :format=>"json", :course_id=>"#{@course.id}"},
              {:quiz => quiz_params}, {}, opts)
    end

    before { teacher_in_course(:active_all => true) }

    let (:new_quiz) { @course.quizzes.first }

    it "creates a quiz for the course" do
      api_create_quiz({ 'title' => 'testing' })
      new_quiz.title.should == 'testing'
    end

    it "doesn't allow setting fields not in the whitelist" do
      api_create_quiz({ 'assignment_id' => 123 })
      new_quiz.assignment_id.should be_nil
    end

    it "renders an error when the title is too long" do
      title = 'a' * ActiveRecord::Base.maximum_string_length + '!'
      json = api_create_quiz({ 'title' => title }, :expected_status => 400 )
      json.should have_key 'errors'
      new_quiz.should be_nil
    end

    describe "validations" do
      context "assignment_group_id" do
        let!(:my_group) { @course.assignment_groups.create! :name => 'my group' }
        let (:other_course) { Course.create! :name => 'other course' }
        let!(:other_group) { other_course.groups.create! :name => 'other group' }

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
        it "should save show_correct_answers if hide_results is null" do
          api_create_quiz({'show_correct_answers' => false, 'hide_results' => nil})
          new_quiz.show_correct_answers.should be_false
        end

        it "should not save show_correct_answers if hide_results is not null" do
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
    end
  end

  describe "PUT /courses/:course_id/quizzes/:id (update)" do
    def api_update_quiz(quiz_params, api_params, opts={})
      @quiz = @course.quizzes.create!({:title => 'title'}.merge(quiz_params))
      api_call(:put, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}",
              {:controller=>"quizzes_api", :action => "update", :format=>"json", :course_id=>"#{@course.id}", :id=>"#{@quiz.id}"},
              {:quiz => api_params}, {}, opts)
    end

    before { teacher_in_course(:active_all => true) }

    let (:updated_quiz) { @course.quizzes.first }
    let (:quiz_params) { {} }

    it "updates quiz attributes" do
      api_update_quiz({'title' => 'old title'}, {'title' => 'new title'})
      updated_quiz.title.should == 'new title'
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
    end
  end
end
