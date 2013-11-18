
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
require File.expand_path(File.dirname(__FILE__) + '/../locked_spec')

describe QuizGroupsController, :type => :integration do

  describe "POST /api/v1/courses/:course_id/quizzes/:quiz_id/groups (create)" do

    def api_create_quiz_group(quiz_group_params, opts={})
      api_call(:post, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/groups",
              {:controller=>"quiz_groups", :action => "create", :format => "json", :course_id => "#{@course.id}", :quiz_id => "#{@quiz.id}"},
              {:quiz_group => quiz_group_params}, {}, opts)
    end

    before do
      teacher_in_course(:active_all => true)
      @quiz = @course.quizzes.create! :title => 'title'
      @bank = @course.assessment_question_banks.create! :title => 'Test Bank'
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

    it "renders an error when the name is too long" do
      name = 'a' * ActiveRecord::Base.maximum_string_length + '!'
      json = api_create_quiz_group({'name' => name}, :expected_status => 400)
      json.should have_key 'errors'
      new_quiz_group.should be_nil
    end
  end

  describe "PUT /api/v1/courses/:course_id/quizzes/:quiz_id/groups/:id (update)" do

    def api_update_quiz_group(quiz_group_params, opts={})

      api_call(:put, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/groups/#{@group.id}",
              {:controller=>"quiz_groups", :action => "update", :format => "json", :course_id => "#{@course.id}", :quiz_id => "#{@quiz.id}", :id => "#{@group.id}"},
              {:quiz_group => quiz_group_params}, {}, opts)
    end

    before do
      teacher_in_course(:active_all => true)

      @quiz  = @course.quizzes.create! :title => 'title'
      @group = @quiz.quiz_groups.create :name => 'Test Group'
      @bank  = @course.assessment_question_banks.create! :title => 'Test Bank'
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

    it "renders an error when the name is too long" do
      name = 'a' * ActiveRecord::Base.maximum_string_length + '!'
      json = api_update_quiz_group({'name' => name}, :expected_status => 400)
      json.should have_key 'errors'
      @group.reload.name.should == 'Test Group'
    end

  end
end
