#
# Copyright (C) 2014 Instructure, Inc.
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

describe Polling::PollsController, type: :request do
  before(:each) do
    course_with_teacher_logged_in active_all: true
  end

  describe 'GET index' do
    before(:each) do
      5.times do |n|
        @teacher.polls.create!(question: "Example Poll #{n+1}")
      end
    end

    def get_index(raw = false, data = {}, headers = {})
      helper = method(raw ? :raw_api_call : :api_call)
      helper.call(:get,
                  "/api/v1/polls",
                  { controller: 'polling/polls', action: 'index', format: 'json' },
                  data,
                  headers)
    end

    it "returns all existing polls" do
      json = get_index
      poll_json = json['polls']
      poll_json.size.should == 5

      poll_json.each_with_index do |poll, i|
        poll['question'].should == "Example Poll #{5-i}"
      end
    end

    it "paginates to the jsonapi standard if requested" do
      json = get_index(false, {}, 'Accept' => 'application/vnd.api+json')
      poll_json = json['polls']
      poll_json.size.should == 5

      poll_json.each_with_index do |poll, i|
        poll['question'].should == "Example Poll #{5-i}"
      end

      json.should have_key('meta')
      json['meta'].should have_key('pagination')
      json['meta']['primaryCollection'].should == 'polls'
    end

    context "as a site admin" do
      it "you can view polls you have created" do
        Account.site_admin.account_users.create!(user: @teacher)

        json = get_index
        poll_json = json['polls']
        poll_json.size.should == 5

        poll_json.each_with_index do |poll, i|
          poll['question'].should == "Example Poll #{5-i}"
        end
      end
    end
  end

  describe 'GET show' do
    before(:each) do
      @poll = @teacher.polls.create!(question: 'An Example Poll')
    end

    def get_show(raw = false, data = {})
      helper = method(raw ? :raw_api_call : :api_call)
      helper.call(:get,
                  "/api/v1/polls/#{@poll.id}",
                  { controller: 'polling/polls', action: 'show', format: 'json',
                    id: @poll.id.to_s
                  }, data)
    end


    it "retrieves the poll specified" do
      json = get_show
      poll_json = json['polls'].first
      poll_json['question'].should == 'An Example Poll'
    end

    context "as a teacher" do
      it "displays the total results of all sessions" do
        json = get_show
        poll_json = json['polls'].first
        poll_json.should have_key("total_results")
      end

      it "returns the id of the user that created the poll" do
        json = get_show
        poll_json = json['polls'].first
        poll_json.should have_key("user_id")
        poll_json['user_id'].should == @teacher.id.to_s
      end
    end

    context "as a student" do
      it "doesn't display the total results of all sessions" do
        student_in_course(:active_all => true, :course => @course)
        @poll.poll_sessions.create!(course: @course)

        json = get_show
        poll_json = json['polls'].first
        poll_json.should_not have_key("total_results")
      end

      it "shouldn't return the id of the user that created the poll" do
        student_in_course(:active_all => true, :course => @course)
        session = @poll.poll_sessions.create!(course: @course)
        session.publish!

        json = get_show
        poll_json = json['polls'].first
        poll_json.should_not have_key("user_id")
      end

      it "is authorized if there are sessions that belong to a course or course section the user is enrolled in" do
        student_in_course(:active_all => true, :course => @course)
        @poll.poll_sessions.create!(course: @course)

        get_show(true)
        response.code.should == '200'
      end

      it "is unauthorized if there are no sessions that belong to a course or course section the user is enrolled in" do
        student_in_course(:active_all => true, :course => @course)
        unenrolled = Course.create!(name: 'Unenrolled Course')
        @poll.poll_sessions.create!(course: unenrolled)
        get_show(true)
        response.code.should == '401'
      end

    end
  end

  describe 'POST create' do
    def post_create(params, raw=false)
      helper = method(raw ? :raw_api_call : :api_call)
      helper.call(:post,
                  "/api/v1/polls",
                  { controller: 'polling/polls', action: 'create', format: 'json' },
                  { polls: [params] }, {}, {})
    end

    context "as a teacher" do
      it "creates a poll successfully" do
        post_create(question: 'A Test Poll', description: 'A test description.')
        @teacher.polls.first.question.should == 'A Test Poll'
        @teacher.polls.first.description.should == 'A test description.'
      end
    end

    context "as a student" do
      it "is unauthorized" do
        student_in_course(:active_all => true, :course => @course)
        post_create({question: 'New Title'}, true)
        response.code.should == '401'
      end
    end

  end

  describe 'PUT update' do
    before(:each) do
      @poll = @teacher.polls.create!(question: 'An Old Title')
    end

    def put_update(params, raw=false)
      helper = method(raw ? :raw_api_call : :api_call)

      helper.call(:put,
               "/api/v1/polls/#{@poll.id}",
               { controller: 'polling/polls', action: 'update', format: 'json',
                 id: @poll.id.to_s },
               { polls: [params] }, {}, {})

    end

    context "as a teacher" do
      it "updates a poll successfully" do
        put_update(question: 'A New Title')
        @poll.reload.question.should == 'A New Title'
      end
    end

    context "as a student" do
      it "is unauthorized" do
        student_in_course(:active_all => true, :course => @course)
        put_update({question: 'New Title'}, true)
        response.code.should == '401'
      end
    end

  end

  describe 'DELETE destroy' do
    before(:each) do
      @poll = @teacher.polls.create!(question: 'An Old Title')
      @choice = @poll.poll_choices.create!(text: 'Blah')
      @session = @poll.poll_sessions.create!(course: @course)
      @session.publish!

      @student = student_in_course(active_user: true).user
      @submission = @session.poll_submissions.create!(
        user: @student,
        poll: @poll,
        poll_choice: @choice
      )
    end

    def delete_destroy
      raw_api_call(:delete,
               "/api/v1/polls/#{@poll.id}",
               { controller: 'polling/polls', action: 'destroy', format: 'json',
                 id: @poll.id.to_s },
               {}, {}, {})

    end

    context "as a teacher" do
      it "deletes a poll successfully" do
        @user = @teacher
        delete_destroy

        response.code.should == '204'
        Polling::Poll.find_by_id(@poll.id).should be_nil
      end

      it "deletes all associated poll choices" do
        choice_a = @poll.poll_choices.create!(text: 'choice a')
        choice_b = @poll.poll_choices.create!(text: 'choice b')

        @user = @teacher
        delete_destroy
        response.code.should == '204'
        Polling::PollChoice.find_by_id(choice_a.id).should be_nil
        Polling::PollChoice.find_by_id(choice_b.id).should be_nil
      end
    end

    context "as a student" do
      it "is unauthorized" do
        student_in_course(:active_all => true, :course => @course)
        delete_destroy
        response.code.should == '401'
        Polling::Poll.find_by_id(@poll.id).should == @poll
      end
    end
  end
end
