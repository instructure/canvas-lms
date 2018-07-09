#
# Copyright (C) 2018 - present Instructure, Inc.
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

require_relative '../spec_helper'

RSpec.describe AnonymousSubmissionsController do
  it_behaves_like 'a submission update action', :anonymous_submissions

  describe "GET show" do
    before do
      course_with_student_and_submitted_homework
      @context = @course
      @assignment.update!(anonymous_grading: true)
      @submission.update!(score: 10)
      @assignment.unmute!
    end

    let(:body) { JSON.parse(response.body)['submission'] }

    it "renders show template" do
      get :show, params: {course_id: @context.id, assignment_id: @assignment.id, anonymous_id: @submission.anonymous_id }
      expect(response).to render_template('submissions/show')
    end

    it "renders json with scores for teachers" do
      request.accept = Mime[:json].to_s
      get :show, params: {course_id: @context.id, assignment_id: @assignment.id, anonymous_id: @submission.anonymous_id}, format: :json
      expect(body['anonymous_id']).to eq @submission.anonymous_id
      expect(body['score']).to eq 10
      expect(body['grade']).to eq '10'
      expect(body['published_grade']).to eq '10'
      expect(body['published_score']).to eq 10
    end

    it "renders json with scores for students" do
      user_session(@student)
      request.accept = Mime[:json].to_s
      get :show, params: {course_id: @context.id, assignment_id: @assignment.id, anonymous_id: @submission.anonymous_id}, format: :json
      expect(body['anonymous_id']).to eq @submission.anonymous_id
      expect(body['score']).to eq 10
      expect(body['grade']).to eq '10'
      expect(body['published_grade']).to eq '10'
      expect(body['published_score']).to eq 10
    end

    it "mark read if reading one's own submission" do
      user_session(@student)
      request.accept = Mime[:json].to_s
      @submission.mark_unread(@student)
      @submission.save!
      get :show, params: {course_id: @context.id, assignment_id: @assignment.id, anonymous_id: @submission.anonymous_id}, format: :json
      expect(response).to be_successful
      submission = Submission.find(@submission.id)
      expect(submission.read?(@student)).to be_truthy
    end

    it "don't mark read if reading someone else's submission" do
      user_session(@teacher)
      request.accept = Mime[:json].to_s
      @submission.mark_unread(@student)
      @submission.mark_unread(@teacher)
      @submission.save!
      get :show, params: {course_id: @context.id, assignment_id: @assignment.id, anonymous_id: @submission.anonymous_id}, format: :json
      expect(response).to be_successful
      submission = Submission.find(@submission.id)
      expect(submission.read?(@student)).to be_falsey
      expect(submission.read?(@teacher)).to be_falsey
    end

    it "renders json with scores for teachers on muted assignments" do
      @assignment.update!(muted: true)
      request.accept = Mime[:json].to_s
      get :show, params: {course_id: @context.id, assignment_id: @assignment.id, anonymous_id: @submission.anonymous_id}, format: :json
      expect(body['anonymous_id']).to eq @submission.anonymous_id
      expect(body['score']).to eq 10
      expect(body['grade']).to eq '10'
      expect(body['published_grade']).to eq '10'
      expect(body['published_score']).to eq 10
    end

    it "renders json without scores for students on muted assignments" do
      user_session(@student)
      @assignment.update!(muted: true)
      request.accept = Mime[:json].to_s
      get :show, params: {course_id: @context.id, assignment_id: @assignment.id, anonymous_id: @submission.anonymous_id}, format: :json
      expect(body['anonymous_id']).to eq @submission.anonymous_id
      expect(body['score']).to be nil
      expect(body['grade']).to be nil
      expect(body['published_grade']).to be nil
      expect(body['published_score']).to be nil
    end

    it "should show rubric assessments to peer reviewers" do
      course_with_student(active_all: true)
      @assessor = @student
      outcome_with_rubric
      @association = @rubric.associate_with @assignment, @context, :purpose => 'grading'
      @assignment.peer_reviews = true
      @assignment.save!
      @assignment.assign_peer_review(@assessor, @submission.user)
      @assessment = @association.assess(:assessor => @assessor, :user => @submission.user, :artifact => @submission, :assessment => { :assessment_type => 'grading'})
      user_session(@assessor)

      get :show, params: {course_id: @context.id, assignment_id: @assignment.id, anonymous_id: @submission.anonymous_id}

      expect(response).to be_successful
      expect(assigns[:visible_rubric_assessments]).to eq [@assessment]
    end
  end
end
