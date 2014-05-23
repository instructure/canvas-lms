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

describe Polling::PollSubmissionsController, type: :request do
  before(:each) do
    course_with_teacher_logged_in active_all: true
    @section = @course.course_sections.first
    @poll = @teacher.polls.create!(question: "What is your favorite color?")

    ["Red", "Blue", "Green"].each do |choice|
      correct = choice == "Green" ? true : false
      @poll.poll_choices.create!(text: choice, is_correct: correct)
    end

    @session = @poll.poll_sessions.create!(
      course: @course
    )

    @session.publish!
  end

  describe 'GET show' do
    before(:each) do
      @student = student_in_course(active_user: true).user

      @selected = @poll.poll_choices.where(text: "Green").first
      @submission = @session.poll_submissions.create!(
        user: @student,
        poll: @poll,
        poll_choice: @selected
      )
    end

    def get_show(raw = false, data = {})
      helper = method(raw ? :raw_api_call : :api_call)
      helper.call(:get,
                  "/api/v1/polls/#{@poll.id}/poll_sessions/#{@session.id}/poll_submissions/#{@submission.id}",
                  { controller: 'polling/poll_submissions', action: 'show', format: 'json',
                    poll_id: @poll.id.to_s,
                    poll_session_id: @session.id.to_s,
                    id: @submission.id.to_s
                  }, data)
    end

    it "retrieves the poll submission specified" do
      user_session(@student)
      json = get_show
      poll_submission_json = json['poll_submissions'].first
      poll_submission_json['id'].should == @submission.id.to_s
      poll_submission_json['poll_choice_id'].should == @selected.id.to_s
    end
  end

  describe 'POST create' do
    before(:each) do
      @selected = @poll.poll_choices.where(text: "Green").first
    end

    def post_create(params, raw=false)
      helper = method(raw ? :raw_api_call : :api_call)
      helper.call(:post,
                  "/api/v1/polls/#{@poll.id}/poll_sessions/#{@session.id}/poll_submissions",
                  { controller: 'polling/poll_submissions', action: 'create', format: 'json',
                    poll_id: @poll.id.to_s,
                    poll_session_id: @session.id.to_s
                  },
                  { poll_submissions: [params] }, {}, {})
    end

    context "as a student" do
      it "creates a poll submission successfully" do
        student_in_course(active_all: true, course: @course)
        post_create(poll_choice_id: @selected.id)

        @session.reload
        @session.poll_submissions.size.should == 1
        submission = @session.poll_submissions.first
        submission.user.should == @student
        submission.poll_choice.should == @selected
      end

      it "doesn't submit if the student isn't enrolled in the specified section" do
        section = @course.course_sections.create!(name: 'Some Course Section')
        @session.course_section = section
        @session.save

        student_in_course(active_all: true, course: @course)

        post_create({poll_choice_id: @selected.id}, true)

        response.code.should == '401'
        @session.reload
        @session.poll_submissions.size.should be_zero
      end

      it "allows submission if the student is enrolled in the specified section" do
        student_in_course(active_all: true, course: @course)
        @session.course_section = @section
        @session.save

        post_create(poll_choice_id: @selected.id)

        @session.reload
        @session.poll_submissions.size.should == 1
        submission = @session.poll_submissions.first
        submission.user.should == @student
        submission.poll_choice.should == @selected
      end
    end
  end

end
