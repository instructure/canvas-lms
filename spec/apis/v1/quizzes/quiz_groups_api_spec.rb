
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

describe Quizzes::QuizGroupsController, type: :request do
  before :once do
    teacher_in_course(:active_all => true)
    @quiz = @course.quizzes.create! :title => 'title'
    @bank = @course.assessment_question_banks.create! :title => 'Test Bank'
  end

  describe "POST /api/v1/courses/:course_id/quizzes/:quiz_id/groups (create)" do

    def api_create_quiz_group(quiz_group_params, opts={})
      api_call(:post, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/groups",
              {:controller=>"quizzes/quiz_groups", :action => "create", :format => "json", :course_id => "#{@course.id}", :quiz_id => "#{@quiz.id}"},
              {:quiz_groups => [quiz_group_params]},
              {'Accept' => 'application/vnd.api+json'}, opts)
    end

    let (:new_quiz_group) { @quiz.quiz_groups.all[0] }

    it "creates a question group for a quiz" do
      api_create_quiz_group('name' => 'testing')
      new_quiz_group.name.should == 'testing'
    end

    it "pulls questions from an assessment bank for a group" do
      api_create_quiz_group('assessment_question_bank_id' => @bank.id)
      new_quiz_group.assessment_question_bank_id.should == @bank.id
    end

    it "doesn't assign assessment bank if bank doesn't exist" do
      api_create_quiz_group('assessment_question_bank_id' => 999)
      new_quiz_group.assessment_question_bank_id.should be_nil
    end

    it "doesn't allow setting fields not in the whitelist" do
      api_create_quiz_group('migration_id' => 123)
      new_quiz_group.migration_id.should be_nil
    end

    it "renders a validation error when the name is too long" do
      name = 'a' * ActiveRecord::Base.maximum_string_length + '!'
      json = api_create_quiz_group({'name' => name}, :expected_status => 422)
      json.should have_key 'errors'
      json["errors"].should have_key "name"
      new_quiz_group.should be_nil
    end

    it "renders a validation error when pick_count isn't a number" do
      name = 'A Group'
      pick_count = 'NaN'
      json = api_create_quiz_group({name: name, pick_count: pick_count}, expected_status: 422)
      json.should have_key 'errors'
      json["errors"].should have_key "pick_count"
      new_quiz_group.should be_nil
    end

    it "renders a validation error when question_points isn't a number" do
      name = 'A Group'
      question_points = 'NaN'
      json = api_create_quiz_group({name: name, question_points: question_points}, expected_status: 422)
      json.should have_key 'errors'
      json["errors"].should have_key "question_points"
      new_quiz_group.should be_nil
    end
  end

  describe "PUT /api/v1/courses/:course_id/quizzes/:quiz_id/groups/:id (update)" do

    def api_update_quiz_group(quiz_group_params, opts={})

      api_call(:put, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/groups/#{@group.id}",
              {:controller=>"quizzes/quiz_groups", :action => "update", :format => "json", :course_id => "#{@course.id}", :quiz_id => "#{@quiz.id}", :id => "#{@group.id}"},
              {:quiz_groups => [quiz_group_params]},
              {'Accept' => 'application/vnd.api+json'}, opts)
    end

    before :once do
      @group = @quiz.quiz_groups.create :name => 'Test Group'
    end

    it "updates group attributes" do
      api_update_quiz_group(:name => 'testing')
      @group.reload.name.should == 'testing'
    end

    it "won't allow update of assessment bank for a group" do
      api_update_quiz_group('assessment_question_bank_id' => @bank.id)
      @group.reload.assessment_question_bank_id.should be_nil
    end

    it "doesn't allow setting fields not in the whitelist" do
      api_update_quiz_group('migration_id' => 123)
      @group.reload.migration_id.should be_nil
    end

    it "renders a validation error when the name is too long" do
      name = 'a' * ActiveRecord::Base.maximum_string_length + '!'
      json = api_update_quiz_group({'name' => name}, :expected_status => 422)
      json.should have_key 'errors'
      @group.reload.name.should == 'Test Group'
    end

    it "renders a validation error when pick_count isn't a number" do
      pick_count = "NaN"
      json = api_update_quiz_group({pick_count: pick_count}, expected_status: 422)
      json.should have_key 'errors'
      json["errors"].should have_key "pick_count"
    end

    it "renders a validation error when question_points isn't a number" do
      question_points = "NaN"
      json = api_update_quiz_group({question_points: question_points}, expected_status: 422)
      json.should have_key 'errors'
      json["errors"].should have_key "question_points"
    end
  end

  describe "DELETE /courses/:course_id/quizzes/:quiz_id/groups/:id (destroy)" do
    before do
      @group = @quiz.quiz_groups.create :name => 'Test Group'
    end

    it "deletes a quiz group" do
      raw_api_call(:delete, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/groups/#{@group.id}",
                  {:controller=>"quizzes/quiz_groups", :action => "destroy", :format => "json", :course_id => "#{@course.id}", :quiz_id => "#{@quiz.id}", :id => "#{@group.id}"},
                  {}, {'Accept' => 'application/vnd.api+json'})
      Group.exists?(@group.id).should be_false
    end
  end

  describe "POST /courses/:course_id/quizzes/:quiz_id/groups/:id/reorder" do
    before do
      @question1 = @quiz.quiz_questions.create!(:question_data => {'name' => 'test question 1', 'answers' => [{'id' => 1}, {'id' => 2}], :position => 1})
      @question2 = @quiz.quiz_questions.create!(:question_data => {'name' => 'test question 2', 'answers' => [{'id' => 3}, {'id' => 4}], :position => 2})
      @question3 = @quiz.quiz_questions.create!(:question_data => {'name' => 'test question 3', 'answers' => [{'id' => 5}, {'id' => 6}], :position => 3})

      @group = @quiz.quiz_groups.create :name => 'Test Group'
      @group.quiz_questions = [@question1, @question2, @question3]
    end

    it "reorders a quiz group's questions" do
      raw_api_call(:post, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/groups/#{@group.id}/reorder",
                  {:controller=>"quizzes/quiz_groups", :action => "reorder", :format => "json", :course_id => "#{@course.id}", :quiz_id => "#{@quiz.id}", :id => "#{@group.id}"},
                  {:order => [{"type" => "question", "id" => @question3.id},
                              {"type" => "question", "id" => @question1.id},
                              {"type" => "question", "id" => @question2.id}] },
                  {'Accept' => 'application/vnd.api+json'})

      order = @group.reload.quiz_questions.active.sort_by{|q| q.position }.map {|q| q.id }
      order.should == [@question3.id, @question1.id, @question2.id]
    end
  end
end
