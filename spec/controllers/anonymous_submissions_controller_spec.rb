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
      @course.account.enable_service(:avatars)
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
      @course.account.enable_service(:avatars)
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

  context 'originality report' do
    let(:account) { Account.default }
    let(:course) do
      course = account.courses.create!
      course.account.enable_service(:avatars)
      course.enroll_teacher(teacher, enrollment_state: 'active')
      course.enroll_student(student, enrollment_state: 'active')
      course
    end

    let(:teacher) { User.create! }
    let(:student) { User.create! }
    let(:assignment) { course.assignments.create!(title: 'test assignment') }
    let(:attachment) { student.attachments.create!(filename: "submission.doc", uploaded_data: default_uploaded_data) }
    let(:submission) { assignment.submit_homework(student, attachments: [attachment]) }
    let!(:originality_report) do
      OriginalityReport.create!(
        attachment: attachment,
        submission: submission,
        originality_score: 0.5,
        originality_report_url: 'http://www.instructure.com'
      )
    end

    before { user_session(teacher) }

    describe 'GET originality_report' do
      it 'redirects to the originality report URL if it exists' do
        get 'originality_report', params: {
          course_id: assignment.context_id,
          assignment_id: assignment.id,
          anonymous_id: submission.anonymous_id,
          asset_string: attachment.asset_string
        }
        expect(response).to redirect_to originality_report.originality_report_url
      end

      it 'shows a notice if no URL is present for the OriginalityReport' do
        originality_report.update!(originality_report_url: nil)
        get 'originality_report', params: {
          course_id: assignment.context_id,
          assignment_id: assignment.id,
          anonymous_id: submission.anonymous_id,
          asset_string: attachment.asset_string
        }
        expect(flash[:error]).to be_present
      end

      it 'redirects to SpeedGrader if no URL is present for the OriginalityReport' do
        originality_report.update!(originality_report_url: nil)
        get 'originality_report', params: {
          course_id: assignment.context_id,
          assignment_id: assignment.id,
          anonymous_id: submission.anonymous_id,
          asset_string: attachment.asset_string
        }

        redirect_url = speed_grader_course_gradebook_url(
          assignment.course,
          assignment_id: assignment.id,
          anchor: "{\"anonymous_id\":\"#{submission.anonymous_id}\"}"
        )
        expect(response).to redirect_to(redirect_url)
      end

      it 'returns an error if the assignment does not exist' do
        get 'originality_report', params: {
          course_id: assignment.context_id,
          assignment_id: -1,
          anonymous_id: '{ user_id }',
          asset_string: attachment.asset_string
        }
        expect(response).to have_http_status(:not_found)
      end

      it 'returns an error if anonymous_id is not valid' do
        get 'originality_report', params: {
          course_id: assignment.context_id,
          assignment_id: assignment.id,
          anonymous_id: '{ user_id }',
          asset_string: attachment.asset_string
        }
        expect(response).to have_http_status(:bad_request)
      end

      it "returns unauthorized for users who can't read submission" do
        unauthorized_user = User.create
        user_session(unauthorized_user)
        get 'originality_report', params: {
          course_id: assignment.context_id,
          assignment_id: assignment.id,
          anonymous_id: submission.anonymous_id,
          asset_string: attachment.asset_string
        }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe 'POST resubmit_to_turnitin' do
      it 'returns an error if assignment_id is not an integer' do
        post 'resubmit_to_turnitin', params: {
          course_id: assignment.context_id,
          assignment_id: 'assignment-id',
          anonymous_id: submission.anonymous_id
        }
        expect(response).to have_http_status(:bad_request)
      end

      it "returns an error if the assignment does not exist" do
        post 'resubmit_to_turnitin', params: {
          course_id: assignment.context_id,
          assignment_id: -1,
          anonymous_id: submission.anonymous_id,
        }
        expect(response).to have_http_status(:not_found)
      end

      it "returns an error if the anonymous_id does not exist" do
        post 'resubmit_to_turnitin', params: {
          course_id: assignment.context_id,
          assignment_id: assignment.id,
          anonymous_id: '!?!?!',
        }
        expect(response).to have_http_status(:bad_request)
      end

      it "emits a 'plagiarism_resubmit' live event if originality report exists" do
        expect(Canvas::LiveEvents).to receive(:plagiarism_resubmit)
        post 'resubmit_to_turnitin', params: {
          course_id: assignment.context_id,
          assignment_id: assignment.id,
          anonymous_id: submission.anonymous_id
        }
      end

      it "emits a 'plagiarism_resubmit' live event if originality report does not exist" do
        originality_report.destroy!
        expect(Canvas::LiveEvents).to receive(:plagiarism_resubmit)
        post 'resubmit_to_turnitin', params: {
          course_id: assignment.context_id,
          assignment_id: assignment.id,
          anonymous_id: submission.anonymous_id
        }
      end
    end
  end

  describe 'GET turnitin_report' do
    let(:course) { Course.create! }
    let(:student) { course.enroll_student(User.create!).user }
    let(:teacher) { course.enroll_teacher(User.create!).user }
    let(:assignment) do
      course.assignments.create!(
        anonymous_grading: true,
        submission_types: 'online_text_entry',
        title: 'hi'
      )
    end
    let(:submission) { assignment.submit_homework(student, body: 'zzzzzzzzzz') }
    let(:asset_string) { submission.id.to_s }

    before { user_session(teacher) }

    it 'returns bad_request if anonymous_id is not valid' do
      get 'turnitin_report', params: {
        course_id: assignment.context_id,
        assignment_id: assignment.id,
        anonymous_id: '{ anonymous_id }',
        asset_string: asset_string
      }
      expect(response).to have_http_status(:bad_request)
    end

    context "when the submission's turnitin data contains a report URL" do
      before(:each) do
        submission.update!(turnitin_data: {asset_string => {report_url: 'MY_GREAT_REPORT'}})
      end

      it "redirects to the course tool retrieval URL" do
        get 'turnitin_report', params: {
          course_id: assignment.context_id,
          assignment_id: assignment.id,
          anonymous_id: submission.anonymous_id,
          asset_string: asset_string
        }
        expect(response).to redirect_to(/#{retrieve_course_external_tools_url(course.id)}/)
      end

      it "includes the report URL in the redirect" do
        get 'turnitin_report', params: {
          course_id: assignment.context_id,
          assignment_id: assignment.id,
          anonymous_id: submission.anonymous_id,
          asset_string: asset_string
        }
        expect(response).to redirect_to(/MY_GREAT_REPORT/)
      end
    end

    it "redirects the user to SpeedGrader if no turnitin URL exists" do
      get 'turnitin_report', params: {
        course_id: assignment.context_id,
        assignment_id: assignment.id,
        anonymous_id: submission.anonymous_id,
        asset_string: asset_string
      }

      speed_grader_url = speed_grader_course_gradebook_url(
        course,
        assignment_id: assignment.id,
        anchor: "{\"anonymous_id\":\"#{submission.anonymous_id}\"}"
      )
      expect(response).to redirect_to(speed_grader_url)
    end

    it "displays a flash error if no turnitin URL exists" do
      get 'turnitin_report', params: {
        course_id: assignment.context_id,
        assignment_id: assignment.id,
        anonymous_id: submission.anonymous_id,
        asset_string: asset_string
      }

      expect(flash[:error]).to be_present
    end
  end
end
