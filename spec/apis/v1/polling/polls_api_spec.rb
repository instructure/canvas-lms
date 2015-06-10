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
  before :once do
    course_with_teacher active_all: true
  end

  describe 'GET index' do
    before :once do
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
      expect(poll_json.size).to eq 5

      poll_json.each_with_index do |poll, i|
        expect(poll['question']).to eq "Example Poll #{5-i}"
      end
    end

    it "paginates to the jsonapi standard if requested" do
      json = get_index(false, {}, 'Accept' => 'application/vnd.api+json')
      poll_json = json['polls']
      expect(poll_json.size).to eq 5

      poll_json.each_with_index do |poll, i|
        expect(poll['question']).to eq "Example Poll #{5-i}"
      end

      expect(json).to have_key('meta')
      expect(json['meta']).to have_key('pagination')
      expect(json['meta']['primaryCollection']).to eq 'polls'
    end

    context "as a site admin" do
      it "you can view polls you have created" do
        Account.site_admin.account_users.create!(user: @teacher)

        json = get_index
        poll_json = json['polls']
        expect(poll_json.size).to eq 5

        poll_json.each_with_index do |poll, i|
          expect(poll['question']).to eq "Example Poll #{5-i}"
        end
      end
    end
  end

  describe 'GET show' do
    before :once do
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
      expect(poll_json['question']).to eq 'An Example Poll'
    end

    context "as a teacher" do
      it "displays the total results of all sessions" do
        json = get_show
        poll_json = json['polls'].first
        expect(poll_json).to have_key("total_results")
      end

      it "returns the id of the user that created the poll" do
        json = get_show
        poll_json = json['polls'].first
        expect(poll_json).to have_key("user_id")
        expect(poll_json['user_id']).to eq @teacher.id.to_s
      end
    end

    context "as a student" do
      it "doesn't display the total results of all sessions" do
        student_in_course(:active_all => true, :course => @course)
        @poll.poll_sessions.create!(course: @course)

        json = get_show
        poll_json = json['polls'].first
        expect(poll_json).not_to have_key("total_results")
      end

      it "shouldn't return the id of the user that created the poll" do
        student_in_course(:active_all => true, :course => @course)
        session = @poll.poll_sessions.create!(course: @course)
        session.publish!

        json = get_show
        poll_json = json['polls'].first
        expect(poll_json).not_to have_key("user_id")
      end

      it "is authorized if there are sessions that belong to a course or course section the user is enrolled in" do
        student_in_course(:active_all => true, :course => @course)
        @poll.poll_sessions.create!(course: @course)

        get_show(true)
        expect(response.code).to eq '200'
      end

      it "is unauthorized if there are no sessions that belong to a course or course section the user is enrolled in" do
        student_in_course(:active_all => true, :course => @course)
        unenrolled = Course.create!(name: 'Unenrolled Course')
        @poll.poll_sessions.create!(course: unenrolled)
        get_show(true)
        expect(response.code).to eq '401'
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
        expect(@teacher.polls.first.question).to eq 'A Test Poll'
        expect(@teacher.polls.first.description).to eq 'A test description.'
      end
    end

    context "as a student" do
      it "is unauthorized" do
        student_in_course(:active_all => true, :course => @course)
        post_create({question: 'New Title'}, true)
        expect(response.code).to eq '401'
      end
    end

  end

  describe 'PUT update' do
    before :once do
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
        expect(@poll.reload.question).to eq 'A New Title'
      end
    end

    context "as a student" do
      it "is unauthorized" do
        student_in_course(:active_all => true, :course => @course)
        put_update({question: 'New Title'}, true)
        expect(response.code).to eq '401'
      end
    end

  end

  describe 'DELETE destroy' do
    before :once do
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

        expect(response.code).to eq '204'
        expect(Polling::Poll.where(id: @poll)).not_to be_exists
      end

      it "deletes all associated poll choices" do
        choice_a = @poll.poll_choices.create!(text: 'choice a')
        choice_b = @poll.poll_choices.create!(text: 'choice b')

        @user = @teacher
        delete_destroy
        expect(response.code).to eq '204'
        expect(Polling::PollChoice.where(id: choice_a)).not_to be_exists
        expect(Polling::PollChoice.where(id: choice_b)).not_to be_exists
      end
    end

    context "as a student" do
      it "is unauthorized" do
        student_in_course(:active_all => true, :course => @course)
        delete_destroy
        expect(response.code).to eq '401'
        expect(Polling::Poll.where(id: @poll).first).to eq @poll
      end
    end
  end
end
