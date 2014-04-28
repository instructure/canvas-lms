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
        @course.polls.create!(title: "Example Poll #{n+1}")
      end
    end

    def get_index(raw = false, data = {})
      helper = method(raw ? :raw_api_call : :api_call)
      helper.call(:get,
                  "/api/v1/courses/#{@course.id}/polls",
                  { controller: 'polling/polls', action: 'index', format: 'json',
                    course_id: @course.id.to_s
                  }, data)
    end

    it "returns all existing polls" do
      json = get_index
      json.size.should == 5

      json.each_with_index do |poll, i|
        poll['title'].should == "Example Poll #{5-i}"
      end
    end

  end

  describe 'GET show' do
    before(:each) do
      @poll = @course.polls.create!(title: 'An Example Poll')
      5.times do |n|
        @poll.poll_choices.create!(text: "Poll Choice #{n+1}", is_correct: false)
      end
    end

    def get_show(raw = false, data = {})
      helper = method(raw ? :raw_api_call : :api_call)
      helper.call(:get,
                  "/api/v1/courses/#{@course.id}/polls/#{@poll.id}",
                  { controller: 'polling/polls', action: 'show', format: 'json',
                    course_id: @course.id.to_s,
                    id: @poll.id.to_s
                  }, data)
    end


    it "retrieves the poll specified" do
      json = get_show
      json['title'].should == 'An Example Poll'
    end

  end

  describe 'POST create' do
    def post_create(params, raw=false)
      helper = method(raw ? :raw_api_call : :api_call)
      helper.call(:post,
                  "/api/v1/courses/#{@course.id}/polls",
                  { controller: 'polling/polls', action: 'create', format: 'json', course_id: @course.id.to_s },
                  { poll: params }, {}, {})
    end

    context "as a teacher" do
      it "creates a poll successfully" do
        post_create(title: 'A Test Poll')
        @course.polls.first.title.should == 'A Test Poll'
      end
    end

    context "as a student" do
      it "is unauthorized" do
        student_in_course(:active_all => true, :course => @course)
        json = post_create({title: 'New Title'}, true)
        response.code.should == '401'
      end
    end

  end

  describe 'PUT update' do
    before(:each) do
      @poll = @course.polls.create!(title: 'An Old Title')
    end

    def put_update(params, raw=false)
      helper = method(raw ? :raw_api_call : :api_call)

      helper.call(:put,
               "/api/v1/courses/#{@course.id}/polls/#{@poll.id}",
               { controller: 'polling/polls', action: 'update', format: 'json',
                 course_id: @course.id.to_s,
                 id: @poll.id.to_s },
               { poll: params }, {}, {})

    end

    context "as a teacher" do
      it "updates a poll successfully" do
        put_update(title: 'A New Title')
        @poll.reload.title.should == 'A New Title'
      end
    end

    context "as a student" do
      it "is unauthorized" do
        student_in_course(:active_all => true, :course => @course)
        put_update({title: 'New Title'}, true)
        response.code.should == '401'
      end
    end
  end
end
