# frozen_string_literal: true

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

require_relative "../api_spec_helper"
require_relative "../file_uploads_spec_helper"

describe "Submissions Comment API", type: :request do
  def submission_with_comment
    course_with_student(active_all: true)
    teacher_in_course(course: @course, active_all: true)
    @assignment = @course.assignments.create!(
      title: "Test Assignment",
      description: "public stuff"
    )
    @student = @course.students.first
    @submission = @assignment.submissions.find_by(
      user: @student
    )
    @comment = @submission.submission_comments.create!(
      comment: "Hello world!",
      author: @teacher
    )
  end

  describe "#create_file" do
    before :once do
      teacher_in_course active_all: true
      student_in_course active_all: true
      @assignment = @course.assignments.create! name: "blah",
                                                submission_types: "online_upload"
    end

    include_examples "file uploads api"
    def has_query_exemption?
      true
    end

    def preflight(preflight_params)
      api_call :post,
               "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}/comments/files",
               { controller: "submission_comments_api",
                 action: "create_file",
                 format: "json",
                 course_id: @course.to_param,
                 assignment_id: @assignment.to_param,
                 user_id: @student.to_param },
               preflight_params
    end

    it "checks permissions" do
      orig_course = @course
      course_with_student active_all: true
      @course = orig_course
      raw_api_call :post,
                   "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}/comments/files",
                   { controller: "submission_comments_api",
                     action: "create_file",
                     format: "json",
                     course_id: @course.to_param,
                     assignment_id: @assignment.to_param,
                     user_id: @student.to_param },
                   name: "whatever"
      expect(response).not_to be_successful
    end

    it "checks permissions for an assignment with a type of no submission and with the Assignment Enhancement - Student flag enabled" do
      @assignment = @course.assignments.create! name: "Hello",
                                                submission_types: "none"
      @course.enable_feature!(:assignments_2_student)
      preflight(name: "Hello World")
      expect(response).to be_successful
    end

    it "checks permissions for an assignment with a type of not_graded submission and with the Assignment Enhancement - Student flag enabled" do
      @assignment = @course.assignments.create! name: "Hello",
                                                submission_types: "not_graded"
      @course.enable_feature!(:assignments_2_student)
      preflight(name: "Hello World")
      expect(response).to be_successful
    end

    it "creates an attachment with the right the user_id" do
      preflight(name: "blah blah blah")
      expect(response).to be_successful
      a = @assignment.attachments.first
      expect(a).not_to be_nil
      expect(a.user_id).to eq @user.id
    end
  end

  describe "annotation_notification" do
    before :once do
      Notification.create!(name: "Annotation Teacher Notification", category: "TestImmediately")
      Notification.create!(name: "Annotation Notification", category: "TestImmediately")
      student_in_course(active_all: true)
      site_admin_user(active_all: true)
    end

    let(:auto_post_assignment) do
      assignment = @course.assignments.create! name: "blah", submission_types: "online_upload"
      assignment.ensure_post_policy(post_manually: false)
      assignment
    end

    let(:manual_post_assignment) do
      assignment = @course.assignments.create!(name: "unposted assignment, post_manually: true")
      assignment.ensure_post_policy(post_manually: true)
      assignment
    end

    let(:teacher_notification) { BroadcastPolicy.notification_finder.by_name("Annotation Teacher Notification") }
    let(:student_notification) { BroadcastPolicy.notification_finder.by_name("Annotation Notification") }
    let(:teacher_args) { [instance_of(Submission), "Annotation Teacher Notification", teacher_notification, any_args] }
    let(:student_args) { [instance_of(Submission), "Annotation Notification", student_notification, any_args] }

    let(:second_teacher) do
      second_teacher = User.create!(name: "mr two", workflow_state: "registered")
      @course.enroll_user(second_teacher, "TeacherEnrollment", enrollment_state: "active")
    end

    let(:group_assignment_with_submission) do
      gc = @course.group_categories.create!(name: "all groups")
      g1 = gc.groups.create!(context: @course, name: "group 1")
      g1.add_user(@student)
      u2 = User.create!(name: "mr two", workflow_state: "registered")
      @course.enroll_user(u2, "StudentEnrollment", enrollment_state: "active")
      g1.add_user(u2)
      ga = @course.assignments.create!(grade_group_students_individually: false, group_category: gc, name: "group assignment")
      ga.ensure_post_policy(post_manually: true)
      ga.submit_homework(@student, body: "hello")
      ga
    end

    def annotation_notification_call(author_id: @student.to_param, assignment_id: auto_post_assignment.to_param)
      raw_api_call(:post,
                   "/api/v1/courses/#{@course.id}/assignments/#{assignment_id}/submissions/#{@student.to_param}/annotation_notification",
                   { controller: "submission_comments_api",
                     action: "annotation_notification",
                     format: "json",
                     course_id: @course.to_param,
                     assignment_id:,
                     user_id: @student.to_param },
                   { author_id: })
    end

    it "sends notification to teacher for student annotation" do
      expect(BroadcastPolicy.notifier).to receive(:send_notification).with(*teacher_args)
      annotation_notification_call(author_id: @student.to_param)
      expect(response).to have_http_status :ok
    end

    it "sends notification for admin annotation" do
      expect(BroadcastPolicy.notifier).to receive(:send_notification).twice
      annotation_notification_call(author_id: @admin.to_param)
      expect(response).to have_http_status :ok
    end

    it "sends notification to student for teacher annotation when assignment post_manually is false" do
      expect(BroadcastPolicy.notifier).to receive(:send_notification).with(*student_args)
      annotation_notification_call(author_id: @teacher.to_param)
      expect(response).to have_http_status :ok

      submission = auto_post_assignment.submission_for_student(@student)
      expect(@student.reload.unread_submission_annotations?(submission)).to be true
    end

    it "works for group submission annotation" do
      # there was a bug where submissions were not scoped to the correct
      # assignment and not sure of a great way to test that it getting the
      # correct submission for a user, but if the user has two assignments it
      # would make this a flaky spec, where this will always pass with the fix.
      auto_post_assignment
      group_assignment_with_submission.post_submissions
      expect(BroadcastPolicy.notifier).to receive(:send_notification).with(*student_args).twice
      annotation_notification_call(author_id: @teacher.to_param, assignment_id: group_assignment_with_submission.to_param)
      expect(response).to have_http_status :ok
    end

    it "does not send to other teachers for teacher annotation" do
      second_teacher
      expect(BroadcastPolicy.notifier).not_to receive(:send_notification).with(*teacher_args)
      annotation_notification_call(author_id: @teacher.to_param)
      expect(response).to have_http_status :ok
    end

    it "does not send to students when assignment is post_manually" do
      expect(BroadcastPolicy.notifier).not_to receive(:send_notification).with(*student_args)
      annotation_notification_call(author_id: @teacher.to_param, assignment_id: manual_post_assignment.to_param)
      expect(response).to have_http_status :ok
    end

    it "does send to students when assignment is post_manually and posted" do
      manual_post_assignment.post_submissions
      expect(BroadcastPolicy.notifier).to receive(:send_notification).with(*student_args).once
      annotation_notification_call(author_id: @teacher.to_param, assignment_id: manual_post_assignment.to_param)
      expect(response).to have_http_status :ok
    end

    it "does not send to students when submission is not posted and author is teacher" do
      expect(BroadcastPolicy.notifier).not_to receive(:send_notification).with(*student_args)
      expect(BroadcastPolicy.notifier).not_to receive(:send_notification).with(*teacher_args)
      annotation_notification_call(author_id: @teacher.to_param, assignment_id: group_assignment_with_submission.to_param)
      expect(response).to have_http_status :ok
    end

    it "does notify other group members of annotations" do
      expect(BroadcastPolicy.notifier).to receive(:send_notification).with(*student_args).once
      expect(BroadcastPolicy.notifier).to receive(:send_notification).with(*teacher_args).once
      annotation_notification_call(author_id: @student.to_param, assignment_id: group_assignment_with_submission.to_param)
      expect(response).to have_http_status :ok
    end

    it "checks permission of caller" do
      @user = @teacher
      annotation_notification_call(author_id: @student.to_param)
      expect(response).to have_http_status :unauthorized
    end

    it "checks that the assignment exists" do
      annotation_notification_call(author_id: @student.to_param, assignment_id: "invalid")
      expect(response).to have_http_status :not_found
    end

    it "checks that the author is a member of the course" do
      @course = @course.root_account.courses.create!(workflow_state: "available")
      annotation_notification_call(author_id: @student.to_param)
      expect(response).to have_http_status :not_found
    end
  end

  describe "#update" do
    before :once do
      submission_with_comment
    end

    context "user does not have the permission to edit the comment" do
      it "does not edit the submission comment" do
        @user = @student
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}/comments/#{@comment.id}",
                 {
                   controller: "submission_comments_api",
                   action: "update",
                   format: "json",
                   course_id: @course.id.to_s,
                   assignment_id: @assignment.id.to_s,
                   user_id: @student.id.to_s,
                   id: @comment.to_param
                 },
                 {
                   comment: "Goodbye world!"
                 },
                 {},
                 { expected_status: 401 })
        expect(@comment.reload.comment).to eq("Hello world!")
      end
    end

    context "user has permission to edit the comment" do
      it "edits the submission comment" do
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}/comments/#{@comment.id}",
                 {
                   controller: "submission_comments_api",
                   action: "update",
                   format: "json",
                   course_id: @course.id.to_s,
                   assignment_id: @assignment.id.to_s,
                   user_id: @student.id.to_s,
                   id: @comment.to_param
                 },
                 {
                   comment: "Goodbye world!"
                 },
                 {},
                 { expected_status: 200 })
        expect(@comment.reload.comment).to eq("Goodbye world!")
      end
    end
  end

  describe "#destroy" do
    before :once do
      submission_with_comment
    end

    context "user does not have the permission to delete the comment" do
      it "does not delete the submission comment" do
        @user = @student
        api_call(:delete,
                 "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}/comments/#{@comment.id}",
                 {
                   controller: "submission_comments_api",
                   action: "destroy",
                   format: "json",
                   course_id: @course.id.to_s,
                   assignment_id: @assignment.id.to_s,
                   user_id: @student.id.to_s,
                   id: @comment.to_param
                 },
                 {},
                 {},
                 { expected_status: 401 })
        expect(@submission.reload.submission_comments.length).to eq(1)
      end
    end

    context "user has permission to delete the comment" do
      it "deletes the submission comment" do
        api_call(:delete,
                 "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}/comments/#{@comment.id}",
                 {
                   controller: "submission_comments_api",
                   action: "destroy",
                   format: "json",
                   course_id: @course.id.to_s,
                   assignment_id: @assignment.id.to_s,
                   user_id: @student.id.to_s,
                   id: @comment.to_param
                 },
                 {},
                 {},
                 { expected_status: 200 })
        expect(@submission.reload.submission_comments).to be_empty
      end
    end
  end
end
