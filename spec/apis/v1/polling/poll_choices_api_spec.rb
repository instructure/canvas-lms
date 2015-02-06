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

describe Polling::PollChoicesController, type: :request do
  before :once do
    course_with_teacher active_all: true
  end

  describe 'GET index' do
    before :once do
      @poll = @teacher.polls.create!(question: "Example Poll")
      @poll.poll_choices.create!(text: "Poll Choice 1", is_correct:false, position: 1)
      @poll.poll_choices.create!(text: "Poll Choice 3", is_correct:false, position: 3)
      @poll.poll_choices.create!(text: "Poll Choice 4", is_correct:false, position: 4)
      @poll.poll_choices.create!(text: "Poll Choice 2", is_correct:false, position: 2)
      @poll.poll_choices.create!(text: "Poll Choice 5", is_correct:false, position: 5)
    end

    def get_index(raw = false, data = {}, headers = {})
      helper = method(raw ? :raw_api_call : :api_call)
      helper.call(:get,
                  "/api/v1/polls/#{@poll.id}/poll_choices",
                  { controller: 'polling/poll_choices', action: 'index', format: 'json',
                    poll_id: @poll.id.to_s
                  }, data, headers)
    end

    it "returns all existing poll choices" do
      json = get_index
      poll_choices_json = json['poll_choices']
      expect(poll_choices_json.size).to eq 5

      poll_choices_json.each_with_index do |pc, i|
        expect(pc['text']).to eq "Poll Choice #{i+1}"
      end
    end

    it "returns the poll choices in the correct order" do
      json = get_index
      poll_choices_json = json['poll_choices']

      poll_choices_json.each_with_index do |pc, i|
        expect(pc['position']).to eq i+1
      end
    end


    it "paginates to the jsonapi standard if requested" do
      json = get_index(false, {}, 'Accept' => 'application/vnd.api+json')
      poll_choices_json = json['poll_choices']
      expect(poll_choices_json.size).to eq 5

      poll_choices_json.each_with_index do |pc, i|
        expect(pc['text']).to eq "Poll Choice #{i+1}"
      end

      expect(json).to have_key('meta')
      expect(json['meta']).to have_key('pagination')
      expect(json['meta']['primaryCollection']).to eq 'poll_choices'
    end

    context "as a student" do
      before :once do
        student_in_course(:active_all => true, :course => @course)
      end

      it "is unauthorized if there are no open sessions" do
        get_index(true)
        expect(response.code).to eq '401'
      end

      it "doesn't display is_correct within the poll choices" do
        session = Polling::PollSession.create!(course: @course, poll: @poll)
        session.publish!

        json = get_index
        poll_choices_json = json['poll_choices']

        poll_choices_json.each do |poll_choice|
          expect(poll_choice).not_to have_key('is_correct')
        end
      end
    end
  end

  describe 'GET show' do
    before :once do
      @poll = @teacher.polls.create!(question: 'An Example Poll')
      @poll_choice = @poll.poll_choices.create!(text: 'A Poll Choice', is_correct: true)
    end

    def get_show(raw = false, data = {})
      helper = method(raw ? :raw_api_call : :api_call)
      helper.call(:get,
                  "/api/v1/polls/#{@poll.id}/poll_choices/#{@poll_choice.id}",
                  { controller: 'polling/poll_choices', action: 'show', format: 'json',
                    poll_id: @poll.id.to_s,
                    id: @poll_choice.id.to_s
                  }, data)
    end

    it "retrieves the poll specified" do
      json = get_show
      poll_choice_json = json['poll_choices'].first

      expect(poll_choice_json['text']).to eq 'A Poll Choice'
      expect(poll_choice_json['is_correct']).to be_truthy
    end

    context "as a student" do
      before :once do
        student_in_course(:active_all => true, :course => @course)
      end

      it "is unauthorized if there are no existing sessions" do
        get_show(true)
        expect(response.code).to eq '401'
      end

      it "is authorized if there are existing sessions" do
        Polling::PollSession.create!(course: @course, poll: @poll)
        get_show(true)
        expect(response.code).to eq '200'
      end

      context "with opened sessions" do
        it "doesn't display is_correct within poll choices" do
          Polling::PollSession.create!(course: @course, poll: @poll).publish!

          json = get_show
          poll_choice_json = json['poll_choices'].first

          expect(poll_choice_json).not_to have_key('is_correct')
        end
      end

      context "with closed, available sessions" do
        it "displays is_correct within poll choices" do
          session = Polling::PollSession.create!(course: @course, poll: @poll)
          session.publish!
          session.poll_submissions.create!(user: @student, poll: @poll, poll_choice: @poll_choice)
          session.close!

          json = get_show
          poll_choice_json = json['poll_choices'].first

          expect(poll_choice_json).to have_key('is_correct')
        end
      end

    end
  end

  describe 'POST create' do
    before :once do
      @poll = @teacher.polls.create!(question: 'An Example Poll')
    end

    def post_create(params, raw=false)
      helper = method(raw ? :raw_api_call : :api_call)
      helper.call(:post,
                  "/api/v1/polls/#{@poll.id}/poll_choices",
                  { controller: 'polling/poll_choices', action: 'create', format: 'json',
                    poll_id: @poll.id.to_s
                  },
                  { poll_choices: [params] }, {}, {})
    end

    context "as a teacher" do
      it "creates a poll choice successfully" do
        post_create(text: 'Poll Choice 1', is_correct: false, position: 1)
        expect(@poll.poll_choices.first.text).to eq 'Poll Choice 1'
        expect(@poll.poll_choices.first.position).to eq 1
      end

      it "sets is_correct to false if is_correct is provided but blank" do
        post_create(text: 'is correct poll choice', is_correct: '', position: 1)
        expect(@poll.poll_choices.first.text).to eq 'is correct poll choice'
        expect(@poll.poll_choices.first.is_correct).to be_falsey
      end
    end

    context "as a student" do
      it "is unauthorized" do
        student_in_course(:active_all => true, :course => @course)
        post_create({text: 'Poll Choice 1'}, true)
        expect(response.code).to eq '401'
      end
    end
  end

  describe 'PUT update' do
    before :once do
      @poll = @teacher.polls.create!(question: 'An Old Title')
      @poll_choice = @poll.poll_choices.create!(text: 'Old Poll Choice', is_correct: true)
    end

    def put_update(params, raw=false)
      helper = method(raw ? :raw_api_call : :api_call)

      helper.call(:put,
               "/api/v1/polls/#{@poll.id}/poll_choices/#{@poll_choice.id}",
               { controller: 'polling/poll_choices', action: 'update', format: 'json',
                 poll_id: @poll.id.to_s,
                 id: @poll_choice.id.to_s
               },
               { poll_choices: [params] }, {}, {})
    end

    context "as a teacher" do
      it "updates a poll choice successfully" do
        put_update(text: 'New Poll Choice Text')
        expect(@poll_choice.reload.text).to eq 'New Poll Choice Text'
      end

      it "sets is_correct to the poll choice's original value if is_correct is provided but blank" do
        original = @poll_choice.is_correct

        put_update(is_correct: '')
        @poll_choice.reload
        expect(@poll_choice.is_correct).to eq original
      end
    end

    context "as a student" do
      it "is unauthorized" do
        student_in_course(:active_all => true, :course => @course)
        put_update({text: 'New Text'}, true)
        expect(response.code).to eq '401'
      end
    end
  end

  describe 'DELETE destroy' do
    before :once do
      @poll = @teacher.polls.create!(question: 'A Poll Title')
      @poll_choice = @poll.poll_choices.create!(text: 'Poll Choice', is_correct: true)
    end

    def delete_destroy
      raw_api_call(:delete,
                  "/api/v1/polls/#{@poll.id}/poll_choices/#{@poll_choice.id}",
      { controller: 'polling/poll_choices', action: 'destroy', format: 'json',
        poll_id: @poll.id.to_s,
        id: @poll_choice.id.to_s
      },
      {}, {}, {})

    end

    context "as a teacher" do
      it "deletes a poll choice successfully" do
        delete_destroy

        expect(response.code).to eq '204'
        expect(Polling::PollChoice.where(id: @poll_choice)).not_to be_exists
      end
    end

    context "as a student" do
      it "is unauthorized" do
        student_in_course(:active_all => true, :course => @course)
        delete_destroy

        expect(response.code).to eq '401'
        expect(Polling::PollChoice.where(id: @poll_choice).first).to eq @poll_choice
      end
    end
  end

end
