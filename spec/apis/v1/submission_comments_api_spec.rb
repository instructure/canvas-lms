#
# Copyright (C) 2011 - 2013 Instructure, Inc.
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
require File.expand_path(File.dirname(__FILE__) + '/../file_uploads_spec_helper')

describe 'Submissions Comment API', type: :request do

  describe '#create_file' do
    before :once do
      teacher_in_course active_all: true
      student_in_course active_all: true
      @assignment = @course.assignments.create! name: "blah",
        submission_types: "online_upload"
    end

    include_examples "file uploads api"
    def has_query_exemption?; true; end

    def preflight(preflight_params)
      api_call :post,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}/comments/files",
      {controller: "submission_comments_api", action: "create_file",
       format: "json", course_id: @course.to_param,
       assignment_id: @assignment.to_param, user_id: @student.to_param},
       preflight_params
    end

    it "checks permissions" do
      orig_course = @course
      course_with_student active_all: true
      @course = orig_course
      raw_api_call :post,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}/comments/files",
      {controller: "submission_comments_api", action: "create_file",
       format: "json", course_id: @course.to_param,
       assignment_id: @assignment.to_param, user_id: @student.to_param},
      name: "whatever"
      expect(response).not_to be_success
    end

    it "creates an attachment with the right the user_id" do
      preflight(name: "blah blah blah")
      expect(response).to be_successful
      a = @assignment.attachments.first
      expect(a).not_to be_nil
      expect(a.user_id).to eq @user.id
    end
  end

  describe 'annotation_notification' do
    before :once do
      Notification.create!(name: 'Annotation Teacher Notification', category: "TestImmediately")
      Notification.create!(name: 'Annotation Notification', category: "TestImmediately")
      student_in_course(active_all: true)
      site_admin_user(active_all: true)
    end

    let(:assignment) { @course.assignments.create! name: "blah", submission_types: "online_upload" }
    let(:teacher_notification) { BroadcastPolicy.notification_finder.by_name("Annotation Teacher Notification") }
    let(:notification) { BroadcastPolicy.notification_finder.by_name("Annotation Notification") }

    def annotation_notification_call(author_id: @student.to_param, assignment_id: assignment.to_param)
      raw_api_call(:post,
                   "/api/v1/courses/#{@course.id}/assignments/#{assignment_id}/submissions/#{@student.to_param}/annotation_notification",
                   {controller: "submission_comments_api", action: "annotation_notification",
                    format: "json", course_id: @course.to_param,
                    assignment_id: assignment_id, user_id: @student.to_param},
                   {author_id: author_id})
    end

    it 'sends notification to teacher for student annotation' do
      expect(BroadcastPolicy.notifier).to receive(:send_notification).with(
        instance_of(Submission),
        "Annotation Teacher Notification",
        teacher_notification,
        any_args
      )
      annotation_notification_call(author_id: @student.to_param)
      expect(response.status).to eq 200
      expect(JSON.parse(response.body)).to eq({"status"=>"queued"})
    end

    it 'sends notification to student for teacher annotation' do
      expect(BroadcastPolicy.notifier).to receive(:send_notification).with(
        instance_of(Submission),
        "Annotation Notification",
        notification,
        any_args
      )
      annotation_notification_call(author_id: @teacher.to_param)
      expect(response.status).to eq 200
      expect(JSON.parse(response.body)).to eq({"status"=>"queued"})
    end

    it 'works for group submission annotation' do
      og_student = @student
      student_in_course(active_all: true)
      all_groups = @course.group_categories.create!(name: "all groups")
      g1 = all_groups.groups.create!(context: @course, name: "group 1")
      g1.add_user(og_student)
      g1.add_user(@student)
      assignment = @course.assignments.create!(grade_group_students_individually: false, group_category: all_groups, name: "group assignment")
      assignment.submit_homework(@student, body: 'hello')
      expect(BroadcastPolicy.notifier).to receive(:send_notification).with(
        instance_of(Submission),
        "Annotation Notification",
        notification,
        any_args
      ).twice
      @user = @admin
      annotation_notification_call(author_id: @teacher.to_param, assignment_id: assignment.to_param)
      expect(response.status).to eq 200
      expect(JSON.parse(response.body)).to eq({"status"=>"queued"})
    end

    it 'does not send to other teachers for teacher annotation' do
      expect(BroadcastPolicy.notifier).to receive(:send_notification).with(
        instance_of(Submission),
        "Annotation Teacher Notification",
        teacher_notification,
        any_args
      ).never
      admin = @admin
      teacher1 = @teacher
      teacher_in_course(active_all: true).user
      @user = admin
      annotation_notification_call(author_id: teacher1.to_param)
      expect(response.status).to eq 200
      expect(JSON.parse(response.body)).to eq({"status"=>"queued"})
    end

    it 'checks permission of caller' do
      @user = @teacher
      annotation_notification_call(author_id: @student.to_param)
      expect(response.status).to eq 401
    end

    it 'checks that the assignment exists' do
      annotation_notification_call(author_id: @student.to_param, assignment_id: 'invalid')
      expect(response.status).to eq 404
    end

    it 'checks that the author is a member of the course' do
      @course = @course.root_account.courses.create!(workflow_state: 'available')
      annotation_notification_call(author_id: @student.to_param)
      expect(response.status).to eq 404
    end
  end

end
