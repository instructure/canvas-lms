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

require 'spec_helper'

describe DocviewerAuditEventsController do
  before :once do
    @course = Course.create!(name: 'a course')
    @student = student_in_course(name: 'Student', course: @course, enrollment_state: :active).user
    @first_ta = ta_in_course(name: 'First Ta', course: @course, enrollment_state: :active).user
    @second_ta = ta_in_course(name: 'Second Ta', course: @course, enrollment_state: :active).user
    @teacher = teacher_in_course(name: 'teacher', course: @course, enrollment_state: :active).user
    @admin = account_admin_user
    @encoded64_secret = 'c2Vrcml0'
    @secret = Base64.decode64(@encoded64_secret)
    @attachment = @student.attachments.create!(course: @course, content_type: 'text/plain', filename: 'attachment.txt')
    Canvadoc.create!(document_id: "abc123#{@attachment.id}", attachment_id: @attachment.id)
  end

  before :each do
    # Assignment.create! will hit MultiCache, and if a default stub doesn't
    # exist, the stub with args will throw an error.
    allow(Canvas::DynamicSettings).to receive(:find).and_return({})
    allow(Canvas::DynamicSettings).to receive(:find).with(service: 'canvadoc', default_ttl: 5.minutes).and_return(
      {'secret' => @encoded64_secret}
    )
  end

  let(:default_params) do
    {
      docviewer_audit_event: {
        annotation_body: {
          color: '',
          content: '',
          created_at: '',
          modified_at: '',
          page: '',
          type: ''
        },
        event_type: 'highlight_created',
        related_annotation_id: 1
      },
      token: Canvas::Security.create_jwt({}, nil, @secret, :HS512),
      canvas_user_id: @teacher.id,
      document_id: @attachment.canvadoc.document_id,
      submission_id: @submission.id
    }
  end

  describe 'status codes' do
    it 'renders status unauthorized if not passed a correct jwt auth token' do
      assignment = Assignment.create!(course: @course, name: 'anonymous', anonymous_grading: true)
      @submission = assignment.submit_homework(@student, submission_type: 'online_upload', attachments: [@attachment])
      post :create, format: :json, params: default_params.merge(token: 'wrong token')
      expect(response).to have_http_status(:unauthorized)
    end

    it 'explains if not passed a correct jwt auth token' do
      assignment = Assignment.create!(course: @course, name: 'anonymous', anonymous_grading: true)
      @submission = assignment.submit_homework(@student, submission_type: 'online_upload', attachments: [@attachment])
      post :create, format: :json, params: default_params.merge(token: 'wrong token')
      expect(JSON.parse(response.body).fetch('message')).to eq 'JWT signature invalid'
    end

    it 'renders status bad_request if param values are missing' do
      assignment = Assignment.create!(course: @course, name: 'anonymous', anonymous_grading: true)
      @submission = assignment.submit_homework(@student, submission_type: 'online_upload', attachments: [@attachment])
      post :create, format: :json, params: default_params.except(:docviewer_audit_event)
      expect(response).to have_http_status(:bad_request)
    end

    it 'renders status not_acceptable for a non-moderated, non-anonymous assignment' do
      assignment = Assignment.create!(course: @course, name: 'non-moderated and non-anonymous')
      @submission = assignment.submit_homework(@student, submission_type: 'online_upload', attachments: [@attachment])
      post :create, format: :json, params: default_params
      expect(response).to have_http_status(:not_acceptable)
    end

    it 'explains why it rendered status not_acceptable' do
      assignment = Assignment.create!(course: @course, name: 'non-moderated and non-anonymous')
      @submission = assignment.submit_homework(@student, submission_type: 'online_upload', attachments: [@attachment])
      post :create, format: :json, params: default_params
      expect(JSON.parse(response.body).fetch('message')).to eq 'Assignment is neither anonymous nor moderated'
    end

    it 'renders status unprocessable_entity if passed an invalid event type' do
      assignment = Assignment.create!(course: @course, name: 'generally reasonable', anonymous_grading: true)
      @submission = assignment.submit_homework(@student, submission_type: 'online_upload', attachments: [@attachment])

      default_params[:docviewer_audit_event][:event_type] = 'miscellaneous_annotation_created'
      post :create, format: :json, params: default_params
      expect(response).to have_http_status(:unprocessable_entity)
    end

    context 'for a moderated assignment' do
      it 'renders status ok if assignment has an open slot for moderating' do
        assignment = Assignment.create!(
          course: @course,
          name: 'moderated',
          moderated_grading: true,
          grader_count: 2,
          final_grader: @teacher
        )
        @submission = assignment.submit_homework(@student, submission_type: 'online_upload', attachments: [@attachment])
        post :create, format: :json, params: default_params.merge(canvas_user_id: @first_ta.id)
        expect(response).to have_http_status(:ok)
      end

      it 'renders status ok if assignment does not have an open slot for moderating but user is final grader' do
        assignment = Assignment.create!(
          course: @course,
          name: 'moderated',
          moderated_grading: true,
          grader_count: 1,
          final_grader: @teacher
        )
        @submission = assignment.submit_homework(@student, submission_type: 'online_upload', attachments: [@attachment])
        assignment.grade_student(@student, grade: 10, grader: @first_ta, provisional: true)
        post :create, format: :json, params: default_params
        expect(response).to have_http_status(:ok)
      end

      it 'renders status forbidden if no open slot and user is not final grader' do
        assignment = Assignment.create!(
          course: @course,
          name: 'moderated',
          moderated_grading: true,
          grader_count: 1,
          final_grader: @teacher
        )
        @submission = assignment.submit_homework(@student, submission_type: 'online_upload', attachments: [@attachment])
        assignment.grade_student(@student, grade: 10, grader: @first_ta, provisional: true)
        post :create, format: :json, params: default_params.merge(canvas_user_id: @second_ta.id)
        expect(response).to have_http_status(:forbidden)
      end

      it 'explains that user cannot be a moderation grader, if so' do
        assignment = Assignment.create!(
          course: @course,
          name: 'moderated',
          moderated_grading: true,
          grader_count: 1,
          final_grader: @teacher
        )
        @submission = assignment.submit_homework(@student, submission_type: 'online_upload', attachments: [@attachment])
        assignment.grade_student(@student, grade: 10, grader: @first_ta, provisional: true)
        post :create, format: :json, params: default_params.merge(canvas_user_id: @second_ta.id)
        expect(JSON.parse(response.body).fetch('message')).to eq 'Reached maximum number of graders for assignment'
      end
    end

    context 'for an anonymous assignment' do
      it 'renders status ok' do
        assignment = Assignment.create!(course: @course, name: 'anonymous', anonymous_grading: true)
        @submission = assignment.submit_homework(@student, submission_type: 'online_upload', attachments: [@attachment])
        post :create, format: :json, params: default_params
        expect(response).to have_http_status(:ok)
      end
    end
  end

  it 'allows students to annotate, if assignment is anonymous or moderated' do
    assignment = Assignment.create!(course: @course, name: 'anonymous', anonymous_grading: true)
    @submission = assignment.submit_homework(@student, submission_type: 'online_upload', attachments: [@attachment])
    expect {
      post :create, format: :json, params: default_params.merge(canvas_user_id: @student.id)
    }.to change { AnonymousOrModerationEvent.where(assignment: assignment, submission: @submission).count }.by(1)
  end

  it 'allows fake students to annotate, if assignment is anonymous or moderated' do
    fake_student = course_with_user('StudentViewEnrollment', course: @course).user
    attachment = fake_student.attachments.create!(course: @course, content_type: 'text/plain', filename: 'attachment.txt')
    doc = Canvadoc.create!(document_id: "abc123#{attachment.id}", attachment_id: attachment.id)
    assignment = Assignment.create!(course: @course, name: 'anonymous', anonymous_grading: true)
    @submission = assignment.submit_homework(fake_student, submission_type: 'online_upload', attachments: [attachment])
    params = default_params.merge(canvas_user_id: fake_student.id, document_id: doc.document_id)
    expect {
      post :create, format: :json, params: params
    }.to change {
      AnonymousOrModerationEvent.where(assignment: assignment, submission: @submission).count
    }.by(1)
  end

  context "as an admin" do
    before(:once) do
      @assignment = Assignment.create!(
        course: @course,
        name: 'moderated',
        moderated_grading: true,
        grader_count: 2,
        final_grader: @teacher
      )
      @submission = @assignment.submit_homework(@student, submission_type: 'online_upload', attachments: [@attachment])
      @assignment.grade_student(@student, grade: 10, grader: @first_ta, provisional: true)
    end

    subject(:annotate_as_admin) do
      -> { post :create, format: :json, params: default_params.merge(canvas_user_id: account_admin_user.id) }
    end

    it "can annotate even if there are no slots available" do
      @assignment.update!(grader_count: 1)
      is_expected.to change {
        AnonymousOrModerationEvent.where(assignment: @assignment, submission: @submission).count
      }.by(1)
    end

    it "does not occupy a slot when annotating" do
      is_expected.not_to change { @assignment.provisional_moderation_graders.count }
    end
  end

  it 'updates an existing moderation grader to occupy slot, if it had not already' do
    assignment = Assignment.create!(
      course: @course,
      name: 'moderated',
      moderated_grading: true,
      grader_count: 2,
      final_grader: @teacher
    )
    existing_grader = assignment.moderation_graders.create!(user: @first_ta, anonymous_id: '12345', slot_taken: false)
    @submission = assignment.submit_homework(@student, submission_type: 'online_upload', attachments: [@attachment])
    post :create, format: :json, params: default_params.merge(canvas_user_id: @first_ta.id)
    expect(existing_grader.reload.slot_taken).to be true
  end

  it 'handles canvadocs on older version submissions' do
    second_attachment = @student.attachments.create!(course: @course, content_type: 'text/plain', filename: 'attachment.txt')
    Canvadoc.create!(document_id: "abc123#{second_attachment.id}", attachment_id: second_attachment.id)
    assignment = Assignment.create!(course: @course, name: 'anonymous', anonymous_grading: true)
    @submission = assignment.submit_homework(@student, submission_type: 'online_upload', attachments: [@attachment])
    @submission.update!(submitted_at: 1.hour.ago)
    @submission = assignment.submit_homework(@student, submission_type: 'online_upload', attachments: [second_attachment])
    expect {
      post :create, format: :json, params: default_params.merge(canvas_user_id: @teacher.id)
    }.to change {
      AnonymousOrModerationEvent.where(assignment: assignment, submission: @submission).count
    }.by(1)
  end

  it 'creates a moderation grader' do
    assignment = Assignment.create!(
      course: @course,
      name: 'moderated',
      moderated_grading: true,
      grader_count: 2,
      final_grader: @teacher
    )
    @submission = assignment.submit_homework(@student, submission_type: 'online_upload', attachments: [@attachment])
    post :create, format: :json, params: default_params.merge(canvas_user_id: @first_ta.id)
    expect(assignment.moderation_graders.pluck(:user_id)).to include @first_ta.id
  end

  it 'creates a moderation grader even if full, if user is final grader' do
    assignment = Assignment.create!(
      course: @course,
      name: 'moderated',
      moderated_grading: true,
      grader_count: 1,
      final_grader: @teacher
    )
    @submission = assignment.submit_homework(@student, submission_type: 'online_upload', attachments: [@attachment])
    assignment.grade_student(@student, grade: 10, grader: @first_ta, provisional: true)
    post :create, format: :json, params: default_params
    expect(assignment.moderation_graders.pluck(:user_id)).to include @teacher.id
  end

  it 'allows any grader to annotate a moderated assignment if grades have been posted' do
    assignment = Assignment.create!(
      course: @course,
      name: 'moderated',
      moderated_grading: true,
      grader_count: 1,
      final_grader: @teacher
    )
    @submission = assignment.submit_homework(@student, submission_type: 'online_upload', attachments: [@attachment])
    assignment.grade_student(@student, grade: 10, grader: @teacher, provisional: true)
    assignment.update!(grades_published_at: Time.zone.now)
    expect {
      post :create, format: :json, params: default_params.merge(canvas_user_id: @first_ta.id)
    }.to change {
      AnonymousOrModerationEvent.where(assignment: assignment, canvadoc: @attachment.canvadoc, submission: @submission).count
    }.by(1)
  end

  it 'creates an AnonymousOrModerationEvent' do
    assignment = Assignment.create!(course: @course, anonymous_grading: true, name: 'anonymous')
    @submission = assignment.submit_homework(@student, submission_type: 'online_upload', attachments: [@attachment])
    expect {
      post :create, format: :json, params: default_params
    }.to change {
      AnonymousOrModerationEvent.where(assignment: assignment, canvadoc: @attachment.canvadoc, submission: @submission).count
    }.by(1)
  end

  it 'saves a copy of the annotation_body in the payload' do
    assignment = Assignment.create!(course: @course, anonymous_grading: true, name: 'anonymous')
    @submission = assignment.submit_homework(@student, submission_type: 'online_upload', attachments: [@attachment])
    post :create, format: :json, params: default_params.deep_merge(docviewer_audit_event: { annotation_body: { type: 'a type' } })
    event = AnonymousOrModerationEvent.find_by!(assignment: assignment, canvadoc: @attachment.canvadoc, submission: @submission)
    type = event.payload.fetch('annotation_body').fetch('type')
    expect(type).to eq 'a type'
  end

  it "saves the annotation_id in the payload" do
    assignment = @course.assignments.create!(anonymous_grading: true, name: "anonymous")
    @submission = assignment.submit_homework(@student, submission_type: "online_upload", attachments: [@attachment])
    post :create, format: :json, params: default_params.deep_merge(docviewer_audit_event: { annotation_id: 23 })
    event = AnonymousOrModerationEvent.find_by!(assignment: assignment, submission: @submission)
    expect(event.payload.fetch("annotation_id")).to eq "23"
  end

  it "saves the context in the payload" do
    assignment = @course.assignments.create!(anonymous_grading: true, name: "anonymous")
    @submission = assignment.submit_homework(@student, submission_type: "online_upload", attachments: [@attachment])
    post :create, format: :json, params: default_params.deep_merge(docviewer_audit_event: { context: "a context" })
    event = AnonymousOrModerationEvent.find_by!(assignment: assignment, submission: @submission)
    expect(event.payload.fetch("context")).to eq "a context"
  end

  it 'saves the related_annotation_id in the payload' do
    assignment = Assignment.create!(course: @course, anonymous_grading: true, name: 'anonymous')
    @submission = assignment.submit_homework(@student, submission_type: 'online_upload', attachments: [@attachment])
    post :create, format: :json, params: default_params.deep_merge(docviewer_audit_event: { related_annotation_id: 23 })
    event = AnonymousOrModerationEvent.find_by!(assignment: assignment, canvadoc: @attachment.canvadoc, submission: @submission)
    expect(event.payload['related_annotation_id']).to eq '23'
  end

  it 'renders a json representation of the event on successful creation' do
    assignment = Assignment.create!(course: @course, anonymous_grading: true, name: 'anonymous')
    @submission = assignment.submit_homework(@student, submission_type: 'online_upload', attachments: [@attachment])
    post :create, format: :json, params: default_params
    event = AnonymousOrModerationEvent.find_by!(assignment: assignment, canvadoc: @attachment.canvadoc, submission: @submission)
    expect(JSON.parse(response.body).fetch('anonymous_or_moderation_event').fetch('id')).to eq event.id
  end

  it "is okay if related_annotation_id is not passed" do
    assignment = Assignment.create!(course: @course, anonymous_grading: true, name: 'anonymous')
    @submission = assignment.submit_homework(@student, submission_type: 'online_upload', attachments: [@attachment])
    post :create, format: :json, params: default_params.except(:related_annotation_id)
    expect(response).to have_http_status(:ok)
  end

  it "creates an event with 'docviewer_' prepended to the supplied event type" do
    assignment = Assignment.create!(course: @course, anonymous_grading: true, name: 'zzzzz')
    @submission = assignment.submit_homework(@student, submission_type: 'online_upload', attachments: [@attachment])

    expect {
      post :create, format: :json, params: default_params
    }.to change {
      AnonymousOrModerationEvent.where(
        assignment: assignment,
        submission: @submission,
        event_type: 'docviewer_highlight_created'
      ).count
    }.by 1
  end
end
