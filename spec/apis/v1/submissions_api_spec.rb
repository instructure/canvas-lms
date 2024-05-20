# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe "Submissions API", type: :request do
  include Api::V1::User

  let(:params) { {} }

  before do
    allow(HostUrl).to receive(:file_host_with_shard).and_return(["www.example.com", Shard.default])
  end

  def submit_homework(assignment, student, opts = { body: "test!" })
    @submit_homework_time ||= Time.zone.at(0)
    @submit_homework_time += 1.hour # each submission in a test is separated by an hour
    sub = assignment.find_or_create_submission(student)
    if sub.versions.size == 1
      Version.where(id: sub.versions.first).update_all(created_at: @submit_homework_time)
    end
    sub.workflow_state = "submitted"
    yield(sub) if block_given?
    sub.with_versioning(explicit: true) do
      update_with_protected_attributes!(sub, { submitted_at: @submit_homework_time, created_at: @submit_homework_time }.merge(opts))
    end
    sub.versions.reload.each { |v| Version.where(id: v).update_all(created_at: v.model.created_at) }
    sub
  end

  describe "using section ids" do
    before :once do
      @student1 = user_factory(active_all: true)
      course_with_teacher(active_all: true)
      @default_section = @course.default_section
      @section = factory_with_protected_attributes(@course.course_sections, sis_source_id: "my-section-sis-id", name: "section2")
      @course.enroll_user(@student1, "StudentEnrollment", section: @section).accept!

      quiz = Quizzes::Quiz.create!(title: "quiz1", context: @course)
      quiz.did_edit!
      quiz.offer!
      @a1 = quiz.assignment
      sub = @a1.find_or_create_submission(@student1)
      sub.submission_type = "online_quiz"
      sub.workflow_state = "submitted"
      sub.save!
    end

    it "lists submissions" do
      json = api_call(:get,
                      "/api/v1/sections/#{@default_section.id}/assignments/#{@a1.id}/submissions.json",
                      { controller: "submissions_api",
                        action: "index",
                        format: "json",
                        section_id: @default_section.id.to_s,
                        assignment_id: @a1.id.to_s },
                      { include: %w[submission_history submission_comments rubric_assessment] })
      expect(json.size).to eq 0

      json = api_call(:get,
                      "/api/v1/sections/sis_section_id:my-section-sis-id/assignments/#{@a1.id}/submissions.json",
                      { controller: "submissions_api",
                        action: "index",
                        format: "json",
                        section_id: "sis_section_id:my-section-sis-id",
                        assignment_id: @a1.id.to_s },
                      { include: %w[submission_history submission_comments rubric_assessment] })
      expect(json.size).to eq 1
      expect(json.first["user_id"]).to eq @student1.id

      api_call(:get,
               "/api/v1/sections/#{@default_section.id}/students/submissions",
               { controller: "submissions_api",
                 action: "for_students",
                 format: "json",
                 section_id: @default_section.id.to_s },
               { student_ids: [@student1.id] },
               {},
               expected_status: 401)

      json = api_call(:get,
                      "/api/v1/sections/sis_section_id:my-section-sis-id/students/submissions",
                      { controller: "submissions_api",
                        action: "for_students",
                        format: "json",
                        section_id: "sis_section_id:my-section-sis-id" },
                      student_ids: [@student1.id])
      expect(json.size).to eq 1
    end

    it "returns submissions based on workflow_state" do
      json = api_call(:get,
                      "/api/v1/sections/sis_section_id:my-section-sis-id/students/submissions",
                      { controller: "submissions_api",
                        action: "for_students",
                        format: "json",
                        section_id: "sis_section_id:my-section-sis-id" },
                      workflow_state: "submitted",
                      student_ids: [@student1.id])
      expect(json.size).to eq 1

      json = api_call(:get,
                      "/api/v1/sections/sis_section_id:my-section-sis-id/students/submissions",
                      { controller: "submissions_api",
                        action: "for_students",
                        format: "json",
                        section_id: "sis_section_id:my-section-sis-id" },
                      workflow_state: "unsubmitted",
                      student_ids: [@student1.id])
      expect(json.size).to eq 0
    end

    shared_examples_for "enrollment_state" do
      it "scopes call to enrollment_state" do
        e = @section.enrollments.where(user_id: @student1.id).take
        json = api_call(:get,
                        "/api/v1/sections/sis_section_id:my-section-sis-id/students/submissions",
                        { controller: "submissions_api",
                          action: "for_students",
                          format: "json",
                          section_id: "sis_section_id:my-section-sis-id" },
                        enrollment_state: @enrollment_state,
                        student_ids: [@student1.id],
                        state_based_on_date: @state_based_on_date)
        expect(json.size).to eq @active_count

        e.workflow_state = "completed"
        e.save!
        json = api_call(:get,
                        "/api/v1/sections/sis_section_id:my-section-sis-id/students/submissions",
                        { controller: "submissions_api",
                          action: "for_students",
                          format: "json",
                          section_id: "sis_section_id:my-section-sis-id" },
                        enrollment_state: @enrollment_state,
                        student_ids: [@student1.id],
                        state_based_on_date: @state_based_on_date)
        expect(json.size).to eq @concluded_count
      end
    end

    context "active enrollment_state with active and concluded enrollments" do
      include_examples "enrollment_state"
      before do
        e = @course.enroll_user(@student1, "StudentEnrollment", section: @default_section)
        e.conclude
        @enrollment_state = "concluded"
        @active_count = 1
        @concluded_count = 1
      end
    end

    context "active enrollment_state" do
      include_examples "enrollment_state"
      before do
        @enrollment_state = "active"
        @active_count = 1
        @concluded_count = 0
      end
    end

    context "active enrollment_state state_based_on_date=false" do
      include_examples "enrollment_state"
      before do
        @course.start_at = 10.days.ago
        @course.conclude_at = 2.days.ago
        @course.restrict_enrollments_to_course_dates = true
        @course.save!

        @state_based_on_date = false
        @enrollment_state = "active"
        @active_count = 1
        @concluded_count = 0
      end
    end

    context "conclude enrollment_state" do
      include_examples "enrollment_state"
      before do
        @state_based_on_date = true
        @enrollment_state = "concluded"
        @active_count = 0
        @concluded_count = 1
      end
    end

    context "conclude enrollment_state state_based_on_date=false" do
      include_examples "enrollment_state"
      before do
        @course.start_at = 10.days.ago
        @course.conclude_at = 2.days.ago
        @course.restrict_enrollments_to_course_dates = true
        @course.save!

        @state_based_on_date = false
        @enrollment_state = "concluded"
        @active_count = 0
        @concluded_count = 1
      end
    end

    context "empty enrollment_state" do
      include_examples "enrollment_state"
      before do
        @enrollment_state = ""
        @active_count = 1
        @concluded_count = 1
      end
    end

    it "raises on invalid enrollment_state" do
      json = api_call(:get,
                      "/api/v1/sections/sis_section_id:my-section-sis-id/students/submissions",
                      { controller: "submissions_api",
                        action: "for_students",
                        format: "json",
                        section_id: "sis_section_id:my-section-sis-id" },
                      { enrollment_state: "invalid", student_ids: [@student1.id] },
                      {},
                      expected_status: 400)
      expect(json["error"]).to eq "invalid enrollment_state"
    end

    it "returns submissions based on assignments.post_to_sis" do
      batch = @course.root_account.sis_batches.create
      @course.enrollments.where(user_id: @student1).update_all(sis_batch_id: batch.id)

      json = api_call(:get,
                      "/api/v1/sections/sis_section_id:my-section-sis-id/students/submissions",
                      { controller: "submissions_api",
                        action: "for_students",
                        format: "json",
                        section_id: "sis_section_id:my-section-sis-id" },
                      post_to_sis: "true",
                      student_ids: "all")
      expect(json.size).to eq 0

      @a1.post_to_sis = true
      @a1.save!
      json = api_call(:get,
                      "/api/v1/sections/sis_section_id:my-section-sis-id/students/submissions",
                      { controller: "submissions_api",
                        action: "for_students",
                        format: "json",
                        section_id: "sis_section_id:my-section-sis-id" },
                      post_to_sis: "true",
                      student_ids: "all")
      expect(json.size).to eq 1
    end

    it "returns submissions based on submitted_since" do
      assignment = Assignment.create!(course: @course)
      @submit_homework_time = 12.hours.ago
      submit_homework(assignment, @student1)
      json = api_call(:get,
                      "/api/v1/sections/sis_section_id:my-section-sis-id/students/submissions",
                      { controller: "submissions_api",
                        action: "for_students",
                        format: "json",
                        section_id: "sis_section_id:my-section-sis-id" },
                      submitted_since: 1.day.ago.iso8601,
                      student_ids: "all")
      expect(json.size).to eq 2

      json = api_call(:get,
                      "/api/v1/sections/sis_section_id:my-section-sis-id/students/submissions",
                      { controller: "submissions_api",
                        action: "for_students",
                        format: "json",
                        section_id: "sis_section_id:my-section-sis-id" },
                      submitted_since: 6.hours.ago.iso8601,
                      student_ids: "all")
      expect(json.size).to eq 1

      json = api_call(:get,
                      "/api/v1/sections/sis_section_id:my-section-sis-id/students/submissions",
                      { controller: "submissions_api",
                        action: "for_students",
                        format: "json",
                        section_id: "sis_section_id:my-section-sis-id" },
                      submitted_since: Time.zone.now.iso8601,
                      student_ids: "all")
      expect(json.size).to eq 0
    end

    it "returns submissions based on graded_since" do
      assignment = Assignment.create!(course: @course)
      assignment.grade_student(@student1, grade: "10", grader: @teacher)

      json = api_call(:get,
                      "/api/v1/sections/sis_section_id:my-section-sis-id/students/submissions",
                      { controller: "submissions_api",
                        action: "for_students",
                        format: "json",
                        section_id: "sis_section_id:my-section-sis-id" },
                      graded_since: 1.day.ago.iso8601,
                      student_ids: "all")
      expect(json.size).to eq 1
    end

    it "does not returns submissions based on graded_since" do
      assignment = Assignment.create!(course: @course)
      assignment.grade_student(@student1, grade: "10", grader: @teacher)
      Submission.where(user_id: @student1, assignment_id: assignment).update_all(graded_at: 2.days.ago)

      json = api_call(:get,
                      "/api/v1/sections/sis_section_id:my-section-sis-id/students/submissions",
                      { controller: "submissions_api",
                        action: "for_students",
                        format: "json",
                        section_id: "sis_section_id:my-section-sis-id" },
                      graded_since: 1.day.ago.iso8601,
                      student_ids: "all")
      expect(json.size).to eq 0
    end

    it "scopes call to enrollment_state with post_to_sis" do
      @a1.post_to_sis = true
      @a1.save!
      batch = @course.root_account.sis_batches.create
      @course.enrollments.where(user_id: @student1).update_all(sis_batch_id: batch.id)

      json = api_call(:get,
                      "/api/v1/sections/sis_section_id:my-section-sis-id/students/submissions",
                      { controller: "submissions_api",
                        action: "for_students",
                        format: "json",
                        section_id: "sis_section_id:my-section-sis-id" },
                      enrollment_state: "active",
                      student_ids: "all",
                      post_to_sis: "true")
      expect(json.size).to eq 1
    end

    it "returns filter submissions to enrollments from sis for post_to_sis" do
      @a1.post_to_sis = true
      @a1.save!

      json = api_call(:get,
                      "/api/v1/sections/sis_section_id:my-section-sis-id/students/submissions",
                      { controller: "submissions_api",
                        action: "for_students",
                        format: "json",
                        section_id: "sis_section_id:my-section-sis-id" },
                      post_to_sis: "true",
                      student_ids: "all")
      expect(json.size).to eq 0

      batch = @course.root_account.sis_batches.create
      @course.enrollments.where(user_id: @student1).update_all(sis_batch_id: batch.id)

      json = api_call(:get,
                      "/api/v1/sections/sis_section_id:my-section-sis-id/students/submissions",
                      { controller: "submissions_api",
                        action: "for_students",
                        format: "json",
                        section_id: "sis_section_id:my-section-sis-id" },
                      post_to_sis: "true",
                      student_ids: "all")
      expect(json.size).to eq 1
    end

    it "includes user" do
      json = api_call(:get,
                      "/api/v1/sections/#{@section.id}/assignments/#{@a1.id}/submissions.json",
                      { controller: "submissions_api",
                        action: "index",
                        format: "json",
                        section_id: @section.id.to_s,
                        assignment_id: @a1.id.to_s },
                      { include: %w[user] })
      expect(json.size).to eq 1
      expect(json[0]["user"]).not_to be_nil
      expect(json[0]["user"]["id"]).to eq(@student1.id)
      expect(response.headers["Link"]).to include("/api/v1/sections/#{@section.id}")
    end

    it "returns assignment_visible" do
      json = api_call(:get,
                      "/api/v1/sections/#{@section.id}/assignments/#{@a1.id}/submissions.json",
                      { controller: "submissions_api",
                        action: "index",
                        format: "json",
                        section_id: @section.id.to_s,
                        assignment_id: @a1.id.to_s },
                      { include: %w[visibility], student_ids: [@student1.id] })
      expect(json[0]["assignment_visible"]).to be true
    end

    it "posts to submissions" do
      @a1 = @course.assignments.create!({ title: "assignment1", grading_type: "percent", points_possible: 10 })
      json = raw_api_call(:put,
                          "/api/v1/sections/#{@default_section.id}/assignments/#{@a1.id}/submissions/#{@student1.id}",
                          { controller: "submissions_api",
                            action: "update",
                            format: "json",
                            section_id: @default_section.id.to_s,
                            assignment_id: @a1.id.to_s,
                            user_id: @student1.id.to_s },
                          { submission: { posted_grade: "75%" } })
      assert_status(404)

      expect do
        json = api_call(:put,
                        "/api/v1/sections/sis_section_id:my-section-sis-id/assignments/#{@a1.id}/submissions/#{@student1.id}",
                        { controller: "submissions_api",
                          action: "update",
                          format: "json",
                          section_id: "sis_section_id:my-section-sis-id",
                          assignment_id: @a1.id.to_s,
                          user_id: @student1.id.to_s },
                        { submission: { posted_grade: "75%" } })
        # never more than 1 job added, because it's in a Delayed::Batch
      end.to change { Delayed::Job.jobs_count(:current) }.by(1)

      expect(Submission.count).to eq 2
      @submission = Submission.order(:id).last
      expect(@submission.grader).to eq @teacher

      expect(json["score"]).to eq 7.5
      expect(json["grade"]).to eq "75%"
    end

    it "returns assignment_visible after posting to submissions" do
      json = api_call(:put,
                      "/api/v1/sections/#{@section.id}/assignments/#{@a1.id}/submissions/#{@student1.id}",
                      { controller: "submissions_api",
                        action: "update",
                        format: "json",
                        section_id: @section.id.to_s,
                        assignment_id: @a1.id.to_s,
                        user_id: @student1.id.to_s },
                      { submission: { posted_grade: "75%" }, include: %w[visibility] })
      expect(json["assignment_visible"]).to be true
      expect(json["all_submissions"][0]["assignment_visible"]).to be true
    end

    it "is able to handle an update without visibility when DA is on" do
      json = api_call(:put,
                      "/api/v1/sections/#{@section.id}/assignments/#{@a1.id}/submissions/#{@student1.id}",
                      { controller: "submissions_api",
                        action: "update",
                        format: "json",
                        section_id: @section.id.to_s,
                        assignment_id: @a1.id.to_s,
                        user_id: @student1.id.to_s },
                      { submission: { posted_grade: "75%" } })
      expect(json["assignment_visible"]).to be_nil
      expect(json["all_submissions"][0]["assignment_visible"]).to be_nil
      expect(json["assignment_id"]).to eq @a1.id
    end

    it "returns submissions for a section" do
      json = api_call(:get,
                      "/api/v1/sections/sis_section_id:my-section-sis-id/assignments/#{@a1.id}/submissions/#{@student1.id}",
                      { controller: "submissions_api",
                        action: "show",
                        format: "json",
                        section_id: "sis_section_id:my-section-sis-id",
                        assignment_id: @a1.id.to_s,
                        user_id: @student1.id.to_s },
                      { include: %w[submission_history submission_comments rubric_assessment] })
      expect(json["user_id"]).to eq @student1.id
    end

    it "does not show grades or hidden comments to students when grades have not posted" do
      @a1.ensure_post_policy(post_manually: true)
      @a1.grade_student(@student1, grade: 5, grader: @teacher)

      @a1.update_submission(@student1, hidden: false, comment: "visible comment")
      @a1.update_submission(@student1, hidden: true, comment: "hidden comment")

      @user = @student1
      json = api_call(:get,
                      "/api/v1/sections/sis_section_id:my-section-sis-id/assignments/#{@a1.id}/submissions/#{@student1.id}",
                      { controller: "submissions_api",
                        action: "show",
                        format: "json",
                        section_id: "sis_section_id:my-section-sis-id",
                        assignment_id: @a1.id.to_s,
                        user_id: @student1.id.to_s },
                      { include: %w[submission_comments rubric_assessment] })

      %w[score published_grade published_score grade].each do |a|
        expect(json[a]).to be_nil
      end

      expect(json["submission_comments"].size).to eq 1
      expect(json["submission_comments"][0]["comment"]).to eq "visible comment"

      # should still show this stuff to the teacher
      @user = @teacher
      json = api_call(:get,
                      "/api/v1/sections/sis_section_id:my-section-sis-id/assignments/#{@a1.id}/submissions/#{@student1.id}",
                      { controller: "submissions_api",
                        action: "show",
                        format: "json",
                        section_id: "sis_section_id:my-section-sis-id",
                        assignment_id: @a1.id.to_s,
                        user_id: @student1.id.to_s },
                      { include: %w[submission_comments rubric_assessment] })
      expect(json["submission_comments"].size).to eq 2
      expect(json["grade"]).to eq "5"

      # should show for an admin with no enrollments in the course
      account_admin_user
      expect(@user.enrollments).to be_empty
      json = api_call(:get,
                      "/api/v1/sections/sis_section_id:my-section-sis-id/assignments/#{@a1.id}/submissions/#{@student1.id}",
                      { controller: "submissions_api",
                        action: "show",
                        format: "json",
                        section_id: "sis_section_id:my-section-sis-id",
                        assignment_id: @a1.id.to_s,
                        user_id: @student1.id.to_s },
                      { include: %w[submission_comments rubric_assessment] })
      expect(json["submission_comments"].size).to eq 2
      expect(json["grade"]).to eq "5"
    end

    context "for a submission with a draft comment and a published comment" do
      before(:once) do
        @a1.update_submission(@student1, draft_comment: true, comment: "Draft Answer: forty-one")
        @a1.update_submission(@student1, comment: "Answer: forty-two")
      end

      before do
        @user = @student1

        @json = api_call(:get,
                         "/api/v1/sections/sis_section_id:my-section-sis-id/assignments/#{@a1.id}/submissions/#{@student1.id}",
                         { controller: "submissions_api",
                           action: "show",
                           format: "json",
                           section_id: "sis_section_id:my-section-sis-id",
                           assignment_id: @a1.id.to_s,
                           user_id: @student1.id.to_s },
                         { include: %w[submission_comments] })
      end

      it "returns only published comments" do
        expect(@json["submission_comments"].size).to eq(1)

        published_comments = @json["submission_comments"].select do |c|
          c["comment"] == "Answer: forty-two"
        end

        expect(published_comments[0]["comment"]).to eq("Answer: forty-two")
      end
    end

    it "does not show rubric assessments to students when grades have not posted" do
      @a1.ensure_post_policy(post_manually: true)
      sub = @a1.grade_student(@student1, grade: 5, grader: @teacher).first

      rubric = rubric_model(
        user: @teacher,
        context: @course,
        data: larger_rubric_data
      )
      @a1.create_rubric_association(
        rubric:,
        purpose: "grading",
        use_for_grading: true,
        context: @course
      )
      @a1.rubric_association.assess(
        assessor: @teacher,
        user: @student1,
        artifact: sub,
        assessment: {
          assessment_type: "grading",
          criterion_crit1: { points: 3 },
          criterion_crit2: { points: 2, comments: "Hmm" }
        }
      )

      @user = @student1
      json = api_call(:get,
                      "/api/v1/sections/sis_section_id:my-section-sis-id/assignments/#{@a1.id}/submissions/#{@student1.id}",
                      { controller: "submissions_api",
                        action: "show",
                        format: "json",
                        section_id: "sis_section_id:my-section-sis-id",
                        assignment_id: @a1.id.to_s,
                        user_id: @student1.id.to_s },
                      { include: %w[submission_comments rubric_assessment] })

      expect(json["rubric_assessment"]).to be_nil
    end

    it "does not find sections in other root accounts" do
      acct = account_model(name: "other root")
      @first_course = @course
      course_factory(active_all: true, account: acct)
      @course.default_section.update_attribute("sis_source_id", "my-section-sis-id")
      json = api_call(:get,
                      "/api/v1/sections/sis_section_id:my-section-sis-id/assignments/#{@a1.id}/submissions",
                      { controller: "submissions_api",
                        action: "index",
                        format: "json",
                        section_id: "sis_section_id:my-section-sis-id",
                        assignment_id: @a1.id.to_s })
      expect(json.size).to eq 1 # should find the submission for @first_course
      @course.default_section.update_attribute("sis_source_id", "section-2")
      raw_api_call(:get,
                   "/api/v1/sections/sis_section_id:section-2/assignments/#{@a1.id}/submissions",
                   { controller: "submissions_api",
                     action: "index",
                     format: "json",
                     section_id: "sis_section_id:section-2",
                     assignment_id: @a1.id.to_s })
      assert_status(404) # rather than 401 unauthorized
    end

    context "submission comment attachments" do
      before :once do
        course_with_student(active_all: true)
        @assignment = @course.assignments.create! name: "blah",
                                                  submission_types: "online_upload"
        @attachment = Attachment.create! context: @assignment,
                                         user: @student,
                                         filename: "cats.jpg",
                                         uploaded_data: StringIO.new("meow?")
      end

      def put_comment_attachment
        raw_api_call :put,
                     "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}/",
                     { controller: "submissions_api",
                       action: "update",
                       format: "json",
                       course_id: @course.to_param,
                       assignment_id: @assignment.to_param,
                       user_id: @student.to_param },
                     comment: { file_ids: [@attachment.id] }
      end

      it "doesn't let you attach files you don't have permission for" do
        course_with_student_logged_in(course: @course, active_all: true)
        put_comment_attachment
        assert_status(401)
      end

      it "works" do
        put_comment_attachment
        expect(response).to be_successful
        expect(@assignment.submission_for_student(@student)
        .submission_comments.first
        .attachment_ids).to eq @attachment.id.to_s
      end
    end
  end

  it "returns student discussion entries for discussion_topic assignments" do
    @student = user_factory(active_all: true)
    course_with_teacher(active_all: true)
    @course.enroll_student(@student).accept!
    @context = @course
    @assignment = factory_with_protected_attributes(@course.assignments, { title: "assignment1", submission_types: "discussion_topic", discussion_topic: discussion_topic_model })

    e1 = @topic.discussion_entries.create!(message: "main entry", user: @user)
    se1 = @topic.discussion_entries.create!(message: "sub 1", user: @student, parent_entry: e1)
    @assignment.submit_homework(@student, submission_type: "discussion_topic")
    se2 = @topic.discussion_entries.create!(message: "student 1", user: @student)
    @assignment.submit_homework(@student, submission_type: "discussion_topic")
    @topic.discussion_entries.create!(message: "another entry", user: @user)

    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
                    { controller: "submissions_api",
                      action: "show",
                      format: "json",
                      course_id: @course.id.to_s,
                      assignment_id: @assignment.id.to_s,
                      user_id: @student.id.to_s })

    expect(json["discussion_entries"].sort_by { |h| h["user_id"] }).to eq(
      [{
        "id" => se1.id,
        "message" => "sub 1",
        "user_id" => @student.id,
        "read_state" => "unread",
        "forced_read_state" => false,
        "parent_id" => e1.id,
        "created_at" => se1.created_at.as_json,
        "updated_at" => se1.updated_at.as_json,
        "user_name" => "User",
        "user" => user_display_json(@student, @course).stringify_keys!,
        "rating_sum" => nil,
        "rating_count" => nil,
      },
       {
         "id" => se2.id,
         "message" => "student 1",
         "user_id" => @student.id,
         "read_state" => "unread",
         "forced_read_state" => false,
         "parent_id" => nil,
         "created_at" => se2.created_at.as_json,
         "updated_at" => se2.updated_at.as_json,
         "user_name" => "User",
         "user" => user_display_json(@student, @course).stringify_keys!,
         "rating_sum" => nil,
         "rating_count" => nil,
       }].sort_by { |h| h["user_id"] }
    )

    # don't include discussion entries if response_fields limits the response
    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}",
                    { controller: "submissions_api",
                      action: "show",
                      format: "json",
                      course_id: @course.id.to_s,
                      assignment_id: @assignment.id.to_s,
                      user_id: @student.id.to_s },
                    { response_fields: SubmissionsApiController::SUBMISSION_JSON_FIELDS })
    expect(json["discussion_entries"]).to be_nil

    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}",
                    { controller: "submissions_api",
                      action: "show",
                      format: "json",
                      course_id: @course.id.to_s,
                      assignment_id: @assignment.id.to_s,
                      user_id: @student.id.to_s },
                    { exclude_response_fields: %w[discussion_entries] })
    expect(json["discussion_entries"]).to be_nil
  end

  it "returns student discussion entries from child topics for group discussion_topic assignments" do
    @student = user_factory(active_all: true)
    course_with_teacher(active_all: true)
    @course.enroll_student(@student).accept!
    group_category = @course.group_categories.create(name: "Category")
    @group = @course.groups.create(name: "Group", group_category:)
    @group.add_user(@student)
    @context = @course
    @assignment = factory_with_protected_attributes(@course.assignments, { title: "assignment1", submission_types: "discussion_topic", discussion_topic: discussion_topic_model(group_category: @group.group_category) })
    @topic.refresh_subtopics # since the DJ won't happen in time
    @child_topic = @group.discussion_topics.where(root_topic_id: @topic).first

    e1 = @child_topic.discussion_entries.create!(message: "main entry", user: @user)
    se1 = @child_topic.discussion_entries.create!(message: "sub 1", user: @student, parent_entry: e1)
    @assignment.submit_homework(@student, submission_type: "discussion_topic")
    se2 = @child_topic.discussion_entries.create!(message: "student 1", user: @student)
    @assignment.submit_homework(@student, submission_type: "discussion_topic")
    @child_topic.discussion_entries.create!(message: "another entry", user: @user)

    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
                    { controller: "submissions_api",
                      action: "show",
                      format: "json",
                      course_id: @course.id.to_s,
                      assignment_id: @assignment.id.to_s,
                      user_id: @student.id.to_s })

    expect(json["discussion_entries"].sort_by { |h| h["user_id"] }).to eq(
      [{
        "id" => se1.id,
        "message" => "sub 1",
        "user_id" => @student.id,
        "user_name" => "User",
        "user" => user_display_json(@student, @course).stringify_keys!,
        "read_state" => "unread",
        "forced_read_state" => false,
        "parent_id" => e1.id,
        "created_at" => se1.created_at.as_json,
        "updated_at" => se1.updated_at.as_json,
        "rating_sum" => nil,
        "rating_count" => nil,
      },
       {
         "id" => se2.id,
         "message" => "student 1",
         "user_id" => @student.id,
         "user_name" => "User",
         "user" => user_display_json(@student, @course).stringify_keys!,
         "read_state" => "unread",
         "forced_read_state" => false,
         "parent_id" => nil,
         "created_at" => se2.created_at.as_json,
         "updated_at" => se2.updated_at.as_json,
         "rating_sum" => nil,
         "rating_count" => nil,
       }].sort_by { |h| h["user_id"] }
    )
  end

  def submission_with_comment
    @student = user_factory(active_all: true)
    course_with_teacher(active_all: true)
    @course.enroll_student(@student).accept!
    @quiz = Quizzes::Quiz.create!(title: "quiz1", context: @course)
    @quiz.did_edit!
    @quiz.offer!
    @assignment = @quiz.assignment
    @submission = @assignment.find_or_create_submission(@student)
    @submission.submission_type = "online_quiz"
    @submission.workflow_state = "submitted"
    @submission.save!
    @assignment.update_submission(@student, comment: "i am a comment")
  end

  it "returns user display info along with submission comments" do
    submission_with_comment

    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions.json",
                    { controller: "submissions_api",
                      action: "index",
                      format: "json",
                      course_id: @course.id.to_s,
                      assignment_id: @assignment.id.to_s },
                    { include: %w[submission_comments] })

    expect(json.first["submission_comments"].size).to eq 1
    comment = json.first["submission_comments"].first
    expect(comment).to have_key("author")
    expect(comment["author"]).to eq({
                                      "id" => @student.id,
                                      "anonymous_id" => @student.id.to_s(36),
                                      "display_name" => "User",
                                      "html_url" => "http://www.example.com/courses/#{@course.id}/users/#{@student.id}",
                                      "avatar_image_url" => User.avatar_fallback_url(nil, request),
                                      "pronouns" => nil
                                    })
  end

  it "does not return user display info with anonymous submission comments" do
    reviewed = student_in_course({
                                   active_all: true
                                 }).user
    reviewer = student_in_course({
                                   active_all: true,
                                   course: @course
                                 }).user
    assignment = assignment_model(course: @course)
    assignment.update_attribute(:anonymous_peer_reviews, true)
    expect(assignment.reload.anonymous_peer_reviews?).to be_truthy, "precondition"

    submission = assignment.submit_homework(reviewed, body: "My Submission")
    submission_comment = submission.add_comment({
                                                  author: reviewer,
                                                  comment: "My comment"
                                                })
    expect(submission_comment.grants_right?(reviewed, :read_author)).to be_falsey,
                                                                        "precondition"

    @user = reviewed
    url = "/api/v1/courses/#{@course.id}/students/submissions.json"
    json = api_call(:get,
                    url,
                    {
                      controller: "submissions_api",
                      action: "for_students",
                      format: "json",
                      course_id: @course.to_param,
                      assignment_ids: [@assignment.to_param],
                      student_ids: [reviewed.to_param]
                    },
                    {
                      include: %w[submission_comments]
                    })

    comment_json = json.first["submission_comments"].first
    expect(comment_json["author_id"]).to be_nil
    expect(comment_json["author_name"]).to match(/Anonymous/)
    expect(comment_json["author"]).to be_empty
  end

  it "does not return submitter info when anonymous grading is on" do
    submitter = student_in_course({ active_all: true }).user

    assignment = assignment_model(course: @course)
    assignment.update_attribute(:anonymous_grading, true)
    expect(assignment.reload.anonymous_grading?).to be_truthy

    submission = assignment.submit_homework(submitter, body: "Anon Submission")
    submission.add_comment({
                             author: submitter,
                             comment: "Anon Comment"
                           })

    @user = teacher_in_course({ active_all: true }).user
    url = "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}/submissions"
    json = api_call(:get,
                    url,
                    {
                      controller: "submissions_api",
                      action: "index",
                      format: "json",
                      course_id: @course.to_param,
                      assignment_id: assignment.to_param
                    },
                    {
                      include: %w[user submission_comments]
                    })

    expect(json.first["user"]).to be_nil
    comment_json = json.first["submission_comments"].first
    expect(comment_json["author_id"]).to be_nil
    expect(comment_json["author_name"]).to match(/Anonymous/)
    expect(comment_json["author"]).to be_empty
  end

  it "loads discussion entry data" do
    @student = user_factory(active_all: true)
    course_with_teacher(active_all: true)
    @course.enroll_student(@student).accept!
    @context = @course
    @assignment = factory_with_protected_attributes(@course.assignments, { title: "assignment1", submission_types: "discussion_topic", discussion_topic: discussion_topic_model })

    e1 = @topic.discussion_entries.create!(message: "main entry", user: @user)
    @topic.discussion_entries.create!(message: "sub 1", user: @student, parent_entry: e1)
    @assignment.submit_homework(@student, submission_type: "discussion_topic")
    @topic.discussion_entries.create!(message: "student 1", user: @student)
    @assignment.submit_homework(@student, submission_type: "discussion_topic")
    @topic.discussion_entries.create!(message: "another entry", user: @user)

    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/students/submissions.json",
                    { controller: "submissions_api",
                      action: "for_students",
                      format: "json",
                      course_id: @course.to_param },
                    { student_ids: [@student.to_param] })
    expect(json.first["discussion_entries"]).to be_present
  end

  it "loads quiz submission data" do
    course_with_teacher(active_all: true)
    quiz_with_submission
    @user = @teacher

    # grouped
    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/students/submissions.json",
                    { controller: "submissions_api",
                      action: "for_students",
                      format: "json",
                      course_id: @course.to_param },
                    { student_ids: [@student.to_param], include: %w[submission_history], grouped: 1 })
    expect(json.first["submissions"].first["submission_history"]).to be_present

    # ungrouped
    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/students/submissions.json",
                    { controller: "submissions_api",
                      action: "for_students",
                      format: "json",
                      course_id: @course.to_param },
                    { student_ids: [@student.to_param], include: %w[submission_history] })

    expect(json.first["submission_history"]).to be_present
  end

  it "loads attachment data" do
    @student = user_factory(active_all: true)
    course_with_teacher(active_all: true)
    @course.enroll_student(@student).accept!
    a1 = @course.assignments.create!(title: "assignment1", grading_type: "letter_grade", points_possible: 15)
    submit_homework(a1, @student) { |s| s.attachments = [attachment_model(uploaded_data: stub_png_data, content_type: "image/png", context: @student)] }

    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/students/submissions.json",
                    { controller: "submissions_api",
                      action: "for_students",
                      format: "json",
                      course_id: @course.to_param },
                    { student_ids: [@student.to_param] })

    expect(json.first["attachments"]).to be_present
  end

  it "returns comment id along with submission comments" do
    submission_with_comment

    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions.json",
                    { controller: "submissions_api",
                      action: "index",
                      format: "json",
                      course_id: @course.id.to_s,
                      assignment_id: @assignment.id.to_s },
                    { include: %w[submission_comments] })

    expect(json.first["submission_comments"].size).to eq 1
    comment = json.first["submission_comments"].first
    expect(comment).to have_key("id")
    expect(comment["id"]).to eq @submission.submission_comments.first.id
  end

  it "returns attempt along with submission comments" do
    submission_with_comment

    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions.json",
                    { controller: "submissions_api",
                      action: "index",
                      format: "json",
                      course_id: @course.id.to_s,
                      assignment_id: @assignment.id.to_s },
                    { include: %w[submission_comments] })

    expect(json.first["submission_comments"].size).to eq 1
    comment = json.first["submission_comments"].first
    expect(comment).to have_key("attempt")
  end

  it "returns a valid preview url for quiz submissions" do
    @student = student1 = user_factory(active_all: true)
    course_with_teacher_logged_in(active_all: true) # need to be logged in to view the preview url below
    @course.enroll_student(student1).accept!
    quiz_with_submission
    a1 = @quiz.assignment
    sub = @quiz.assignment.submissions.where(user_id: student1).first

    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions.json",
                    { controller: "submissions_api",
                      action: "index",
                      format: "json",
                      course_id: @course.id.to_s,
                      assignment_id: a1.id.to_s },
                    { include: %w[submission_history submission_comments rubric_assessment] })

    preview_url = json.first["preview_url"]
    expect(Rack::Utils.parse_query(URI(preview_url).query)["version"].to_i).to eq sub.quiz_submission_version
    get preview_url
    follow_redirect! while response.redirect?
    expect(response).to be_successful
    expect(response.body).to match(/#{@quiz.quiz_title} Results/)
  end

  it "returns a correct submission_history for quiz submissions" do
    student1 = user_factory(active_all: true)
    course_with_teacher_logged_in(active_all: true) # need to be logged in to view the preview url below
    @course.enroll_student(student1).accept!
    quiz = Quizzes::Quiz.create!(title: "quiz1", context: @course)
    quiz.did_edit!
    quiz.offer!
    qs = quiz.generate_submission(student1)
    qs.mark_completed
    Quizzes::SubmissionGrader.new(qs).grade_submission
    qs.reload
    qs.attempt = 2
    qs.with_versioning(true, &:save)

    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/assignments/#{quiz.assignment.id}/submissions.json",
                    { controller: "submissions_api",
                      action: "index",
                      format: "json",
                      course_id: @course.id.to_s,
                      assignment_id: quiz.assignment.id.to_s },
                    { include: %w[submission_history] })
    expect(json.first["submission_history"].count).to eq 2
    expect(json.first["submission_history"].first.include?("submission_data")).to be_truthy
    expect(json.first["submission_history"][0]["preview_url"]).to include "&version=2"
    expect(json.first["submission_history"][1]["preview_url"]).to include "&version=1"
  end

  it "returns the correct submitted_at date for each quiz submission" do
    course_with_student(course: @course, active_all: true)
    quiz_with_graded_submission([multiple_answers_question_data], { user: @student })
    Timecop.travel(15.minutes.ago) do
      qs = @quiz.generate_submission(@student)
      qs.mark_completed
      Quizzes::SubmissionGrader.new(qs).grade_submission
    end
    course_with_teacher_logged_in(course: @course, active_all: true)
    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/assignments/#{@quiz.assignment.id}/submissions.json",
                    { controller: "submissions_api",
                      action: "index",
                      format: "json",
                      course_id: @course.id.to_s,
                      assignment_id: @quiz.assignment.id.to_s },
                    { include: %w[submission_history] })
    submission_dates = json.first["submission_history"].pluck("submitted_at")
    expect(submission_dates.first).not_to eq(submission_dates.last)
  end

  it "allows students to retrieve their own submission" do
    student1 = user_factory(active_all: true)
    student2 = user_factory(active_all: true)

    course_with_teacher(active_all: true)

    @course.enroll_student(student1).accept!
    @course.enroll_student(student2).accept!

    a1 = @course.assignments.create!(title: "assignment1", grading_type: "letter_grade", points_possible: 15)
    submit_homework(a1, student1)
    media_object(media_id: "3232", media_type: "audio")
    a1.update_submission(student1, { comment: "Well here's the thing...", media_comment_id: "3232", media_comment_type: "audio", commenter: @teacher })
    sub1 = a1.grade_student(student1, { grade: "90%", grader: @teacher }).first
    comment = sub1.submission_comments.first

    @user = student1
    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student1.id}.json",
                    { controller: "submissions_api",
                      action: "show",
                      format: "json",
                      course_id: @course.id.to_s,
                      assignment_id: a1.id.to_s,
                      user_id: student1.id.to_s },
                    { include: %w[submission_comments] })

    expect(json).to eql({
                          "id" => sub1.id,
                          "grade" => "A-",
                          "entered_grade" => "A-",
                          "grading_period_id" => sub1.grading_period_id,
                          "excused" => sub1.excused,
                          "grader_id" => @teacher.id,
                          "graded_at" => sub1.graded_at.as_json,
                          "posted_at" => sub1.posted_at.as_json,
                          "body" => "test!",
                          "assignment_id" => a1.id,
                          "cached_due_date" => nil,
                          "submitted_at" => "1970-01-01T01:00:00Z",
                          "preview_url" => "http://www.example.com/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student1.id}?preview=1&version=1",
                          "grade_matches_current_submission" => true,
                          "redo_request" => false,
                          "attempt" => 1,
                          "url" => nil,
                          "submission_type" => "online_text_entry",
                          "user_id" => student1.id,
                          "custom_grade_status_id" => nil,
                          "submission_comments" =>
         [{ "comment" => "Well here's the thing...",
            "attempt" => 1,
            "media_comment" => {
              "media_id" => "3232",
              "media_type" => "audio",
              "content-type" => "audio/mp4",
              "url" => "http://www.example.com/users/#{@user.id}/media_download?entryId=3232&redirect=1&type=mp4",
              "display_name" => nil
            },
            "created_at" => comment.created_at.as_json,
            "edited_at" => nil,
            "author" => {
              "id" => @teacher.id,
              "anonymous_id" => @teacher.id.to_s(36),
              "display_name" => "User",
              "html_url" => "http://www.example.com/courses/#{@course.id}/users/#{@teacher.id}",
              "avatar_image_url" => User.avatar_fallback_url(nil, request),
              "pronouns" => nil
            },
            "author_name" => "User",
            "id" => comment.id,
            "author_id" => @teacher.id }],
                          "score" => 13.5,
                          "entered_score" => 13.5,
                          "workflow_state" => "graded",
                          "late" => false,
                          "missing" => false,
                          "late_policy_status" => nil,
                          "seconds_late" => 0,
                          "sticker" => nil,
                          "points_deducted" => nil,
                          "extra_attempts" => nil
                        })

    # can't access other students' submissions
    @user = student2
    raw_api_call(:get,
                 "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student1.id}.json",
                 { controller: "submissions_api",
                   action: "show",
                   format: "json",
                   course_id: @course.id.to_s,
                   assignment_id: a1.id.to_s,
                   user_id: student1.id.to_s },
                 { include: %w[submission_comments] })
    assert_status(401)
  end

  it "returns grading information for observers" do
    @student = user_factory(active_all: true)
    e = course_with_observer(active_all: true)
    e.associated_user_id = @student.id
    e.save!
    @course.enroll_student(@student).accept!
    a1 = @course.assignments.create!(title: "assignment1", points_possible: 15)
    submit_homework(a1, @student)
    a1.grade_student(@student, grade: 15, grader: @teacher)
    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{@student.id}.json",
                    { controller: "submissions_api",
                      action: "show",
                      format: "json",
                      course_id: @course.id.to_s,
                      assignment_id: a1.id.to_s,
                      user_id: @student.id.to_s })
    expect(json["score"]).to eq 15
  end

  it "apis translate online_text_entry submissions" do
    student1 = user_factory(active_all: true)
    course_with_teacher(active_all: true)
    @course.enroll_student(student1).accept!
    a1 = @course.assignments.create!(title: "assignment1", grading_type: "letter_grade", points_possible: 15)
    should_translate_user_content(@course) do |content|
      submit_homework(a1, student1, body: content)
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student1.id}.json",
                      { controller: "submissions_api",
                        action: "show",
                        format: "json",
                        course_id: @course.id.to_s,
                        assignment_id: a1.id.to_s,
                        user_id: student1.id.to_s })
      json["body"]
    end
  end

  it "allows retrieving attachments without a session" do
    local_storage!

    student1 = user_factory(active_all: true)
    course_with_teacher(active_all: true)
    @course.enroll_student(student1).accept!
    a1 = @course.assignments.create!(title: "assignment1", grading_type: "letter_grade", points_possible: 15)
    submit_homework(a1, student1) { |s| s.attachments = [attachment_model(uploaded_data: stub_png_data, content_type: "image/png", context: student1)] }
    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions.json",
                    { controller: "submissions_api",
                      action: "index",
                      format: "json",
                      course_id: @course.id.to_s,
                      assignment_id: a1.id.to_s },
                    { include: %w[submission_history submission_comments rubric_assessment] })
    url = json[0]["attachments"][0]["url"]
    get(url)
    follow_redirect! while response.redirect?
    expect(response).to be_successful
    expect(response[content_type_key]).to eq "image/png"
  end

  it "allows retrieving media comments without a session" do
    student1 = user_factory(active_all: true)
    course_with_teacher(active_all: true)
    @course.enroll_student(student1).accept!
    a1 = @course.assignments.create!(title: "assignment1", grading_type: "letter_grade", points_possible: 15)
    media_object(media_id: "54321", context: student1, user: student1)
    mock_kaltura = double("CanvasKaltura::ClientV3")
    allow(CanvasKaltura::ClientV3).to receive(:new).and_return(mock_kaltura)
    expect(mock_kaltura).to receive(:media_sources).and_return([{ height: "240",
                                                                  bitrate: "382",
                                                                  isOriginal: "0",
                                                                  width: "336",
                                                                  content_type: "video/mp4",
                                                                  containerFormat: "isom",
                                                                  url: "https://kaltura.example.com/some/url",
                                                                  size: "204",
                                                                  fileExt: "mp4" }])

    submit_homework(a1, student1, submission_type: "online_text_entry", media_comment_id: 54_321, media_comment_type: "video")
    stub_kaltura
    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions.json",
                    { controller: "submissions_api",
                      action: "index",
                      format: "json",
                      course_id: @course.id.to_s,
                      assignment_id: a1.id.to_s },
                    { include: %w[submission_history submission_comments rubric_assessment] })
    url = json[0]["media_comment"]["url"]
    get(url)
    expect(response).to be_redirect
    expect(response["Location"]).to match(%r{https://kaltura.example.com/some/url})
  end

  it "returns all submissions for an assignment" do
    student1 = user_factory(active_all: true)
    student2 = user_factory(active_all: true)

    course_with_teacher(active_all: true)

    @course.enroll_student(student1).accept!
    @course.enroll_student(student2).accept!

    a1 = @course.assignments.create!(title: "assignment1", grading_type: "letter_grade", points_possible: 15)
    rubric = rubric_model(user: @user,
                          context: @course,
                          data: larger_rubric_data)
    a1.create_rubric_association(rubric:, purpose: "grading", use_for_grading: true, context: @course)

    submit_homework(a1, student1)
    media_object(media_id: "54321", context: student1, user: student1)
    submit_homework(a1, student1, media_comment_id: "54321", media_comment_type: "video")
    sub1 = submit_homework(a1, student1) { |s| s.attachments = [attachment_model(context: student1, folder: nil)] }
    sub1.update!(sticker: "trophy")

    sub2a1 = attachment_model(context: student2, filename: "snapshot.png", content_type: "image/png")
    sub2 = submit_homework(a1, student2, url: "http://www.instructure.com") do |s|
      s.attachment = sub2a1
    end

    media_object(media_id: "3232", context: student1, user: student1, media_type: "audio")
    a1.grade_student(student1, { grade: "90%", grader: @teacher })
    a1.update_submission(student1, { comment: "Well here's the thing...", media_comment_id: "3232", media_comment_type: "audio", commenter: @teacher })
    sub1.reload
    expect(sub1.submission_comments.size).to eq 1
    comment = sub1.submission_comments.first
    a1.rubric_association.assess(
      assessor: @user,
      user: student2,
      artifact: sub2,
      assessment: { assessment_type: "grading", criterion_crit1: { points: 7 }, criterion_crit2: { points: 2, comments: "Hmm" } }
    )

    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions.json",
                    { controller: "submissions_api",
                      action: "index",
                      format: "json",
                      course_id: @course.id.to_s,
                      assignment_id: a1.id.to_s },
                    { include: %w[submission_history submission_comments rubric_assessment] })

    sub1.reload
    sub2.reload

    res =
      [{ "id" => sub1.id,
         "grade" => "A-",
         "entered_grade" => "A-",
         "grading_period_id" => nil,
         "excused" => sub1.excused,
         "grader_id" => @teacher.id,
         "graded_at" => sub1.graded_at.as_json,
         "posted_at" => sub1.posted_at.as_json,
         "body" => "test!",
         "assignment_id" => a1.id,
         "submitted_at" => "1970-01-01T03:00:00Z",
         "cached_due_date" => nil,
         "custom_grade_status_id" => nil,
         "preview_url" => "http://www.example.com/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student1.id}?preview=1&version=3",
         "redo_request" => false,
         "grade_matches_current_submission" => true,
         "extra_attempts" => nil,
         "attachments" =>
         [
           { "content-type" => "application/unknown",
             "url" => "http://www.example.com/files/#{sub1.attachments.first.id}/download?download_frd=1&verifier=#{sub1.attachments.first.uuid}",
             "filename" => "unknown.example",
             "display_name" => "unknown.example",
             "upload_status" => "success",
             "id" => sub1.attachments.first.id,
             "uuid" => sub1.attachments.first.uuid,
             "folder_id" => sub1.attachments.first.folder_id,
             "size" => sub1.attachments.first.size,
             "unlock_at" => nil,
             "locked" => false,
             "hidden" => false,
             "lock_at" => nil,
             "locked_for_user" => false,
             "hidden_for_user" => false,
             "created_at" => sub1.attachments.first.reload.created_at.as_json,
             "updated_at" => sub1.attachments.first.updated_at.as_json,
             "preview_url" => nil,
             "modified_at" => sub1.attachments.first.modified_at.as_json,
             "mime_class" => sub1.attachments.first.mime_class,
             "media_entry_id" => sub1.attachments.first.media_entry_id,
             "thumbnail_url" => nil,
             "category" => "uncategorized" },
         ],
         "submission_history" =>
         [{ "id" => sub1.id,
            "grade" => nil,
            "entered_grade" => nil,
            "grading_period_id" => nil,
            "excused" => nil,
            "grader_id" => nil,
            "graded_at" => nil,
            "posted_at" => nil,
            "body" => "test!",
            "assignment_id" => a1.id,
            "submitted_at" => "1970-01-01T01:00:00Z",
            "cached_due_date" => nil,
            "custom_grade_status_id" => nil,
            "attempt" => 1,
            "url" => nil,
            "submission_type" => "online_text_entry",
            "user_id" => student1.id,
            "preview_url" => "http://www.example.com/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student1.id}?preview=1&version=1",
            "redo_request" => false,
            "grade_matches_current_submission" => true,
            "score" => nil,
            "entered_score" => nil,
            "workflow_state" => "submitted",
            "late" => false,
            "missing" => false,
            "late_policy_status" => nil,
            "seconds_late" => 0,
            "sticker" => nil,
            "points_deducted" => nil,
            "extra_attempts" => nil },
          { "id" => sub1.id,
            "grade" => nil,
            "entered_grade" => nil,
            "grading_period_id" => nil,
            "excused" => nil,
            "grader_id" => nil,
            "graded_at" => nil,
            "posted_at" => nil,
            "assignment_id" => a1.id,
            "media_comment" =>
            { "media_type" => "video",
              "media_id" => "54321",
              "content-type" => "video/mp4",
              "url" => "http://www.example.com/users/#{@user.id}/media_download?entryId=54321&redirect=1&type=mp4",
              "display_name" => nil },
            "body" => "test!",
            "submitted_at" => "1970-01-01T02:00:00Z",
            "cached_due_date" => nil,
            "custom_grade_status_id" => nil,
            "attempt" => 2,
            "url" => nil,
            "submission_type" => "online_text_entry",
            "user_id" => student1.id,
            "preview_url" => "http://www.example.com/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student1.id}?preview=1&version=2",
            "grade_matches_current_submission" => true,
            "redo_request" => false,
            "score" => nil,
            "entered_score" => nil,
            "workflow_state" => "submitted",
            "late" => false,
            "missing" => false,
            "late_policy_status" => nil,
            "seconds_late" => 0,
            "sticker" => nil,
            "points_deducted" => nil,
            "extra_attempts" => nil },
          { "id" => sub1.id,
            "grade" => "A-",
            "entered_grade" => "A-",
            "grading_period_id" => nil,
            "excused" => false,
            "grader_id" => @teacher.id,
            "graded_at" => sub1.graded_at.as_json,
            "posted_at" => sub1.posted_at.as_json,
            "assignment_id" => a1.id,
            "media_comment" =>
            { "media_type" => "video",
              "media_id" => "54321",
              "content-type" => "video/mp4",
              "url" => "http://www.example.com/users/#{@user.id}/media_download?entryId=54321&redirect=1&type=mp4",
              "display_name" => nil },
            "attachments" =>
            [
              { "content-type" => "application/unknown",
                "url" => "http://www.example.com/files/#{sub1.attachments.first.id}/download?download_frd=1&verifier=#{sub1.attachments.first.uuid}",
                "filename" => "unknown.example",
                "display_name" => "unknown.example",
                "upload_status" => "success",
                "id" => sub1.attachments.first.id,
                "uuid" => sub1.attachments.first.uuid,
                "folder_id" => sub1.attachments.first.folder_id,
                "size" => sub1.attachments.first.size,
                "unlock_at" => nil,
                "locked" => false,
                "hidden" => false,
                "lock_at" => nil,
                "locked_for_user" => false,
                "hidden_for_user" => false,
                "created_at" => sub1.attachments.first.created_at.as_json,
                "updated_at" => sub1.attachments.first.updated_at.as_json,
                "preview_url" => nil,
                "modified_at" => sub1.attachments.first.modified_at.as_json,
                "mime_class" => sub1.attachments.first.mime_class,
                "media_entry_id" => sub1.attachments.first.media_entry_id,
                "thumbnail_url" => nil,
                "category" => "uncategorized" },
            ],
            "body" => "test!",
            "submitted_at" => "1970-01-01T03:00:00Z",
            "cached_due_date" => nil,
            "custom_grade_status_id" => nil,
            "attempt" => 3,
            "url" => nil,
            "submission_type" => "online_text_entry",
            "user_id" => student1.id,
            "preview_url" => "http://www.example.com/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student1.id}?preview=1&version=3",
            "grade_matches_current_submission" => true,
            "redo_request" => false,
            "score" => 13.5,
            "entered_score" => 13.5,
            "workflow_state" => "graded",
            "late" => false,
            "missing" => false,
            "late_policy_status" => nil,
            "seconds_late" => 0,
            "sticker" => "trophy",
            "points_deducted" => nil,
            "extra_attempts" => nil }],
         "attempt" => 3,
         "url" => nil,
         "submission_type" => "online_text_entry",
         "user_id" => student1.id,
         "submission_comments" =>
         [{ "comment" => "Well here's the thing...",
            "attempt" => 3,
            "media_comment" => {
              "media_type" => "audio",
              "media_id" => "3232",
              "content-type" => "audio/mp4",
              "url" => "http://www.example.com/users/#{@user.id}/media_download?entryId=3232&redirect=1&type=mp4",
              "display_name" => nil
            },
            "created_at" => comment.reload.created_at.as_json,
            "edited_at" => nil,
            "author" => {
              "id" => @teacher.id,
              "anonymous_id" => @teacher.id.to_s(36),
              "display_name" => "User",
              "html_url" => "http://www.example.com/courses/#{@course.id}/users/#{@teacher.id}",
              "avatar_image_url" => User.avatar_fallback_url(nil, request),
              "pronouns" => nil
            },
            "author_name" => "User",
            "id" => comment.id,
            "author_id" => @teacher.id }],
         "media_comment" =>
         { "media_type" => "video",
           "media_id" => "54321",
           "content-type" => "video/mp4",
           "url" => "http://www.example.com/users/#{@user.id}/media_download?entryId=54321&redirect=1&type=mp4",
           "display_name" => nil },
         "score" => 13.5,
         "entered_score" => 13.5,
         "workflow_state" => "graded",
         "late" => false,
         "missing" => false,
         "late_policy_status" => nil,
         "seconds_late" => 0,
         "sticker" => "trophy",
         "points_deducted" => nil },
       { "id" => sub2.id,
         "grade" => "F",
         "entered_grade" => "F",
         "grading_period_id" => nil,
         "excused" => sub2.excused,
         "grader_id" => @teacher.id,
         "cached_due_date" => nil,
         "custom_grade_status_id" => nil,
         "graded_at" => sub2.graded_at.as_json,
         "posted_at" => sub2.posted_at.as_json,
         "assignment_id" => a1.id,
         "body" => nil,
         "preview_url" => "http://www.example.com/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student2.id}?preview=1&version=1",
         "grade_matches_current_submission" => true,
         "submitted_at" => "1970-01-01T04:00:00Z",
         "extra_attempts" => nil,
         "submission_history" =>
         [{ "id" => sub2.id,
            "grade" => "F",
            "entered_grade" => "F",
            "grading_period_id" => nil,
            "excused" => false,
            "grader_id" => @teacher.id,
            "graded_at" => sub2.graded_at.as_json,
            "posted_at" => sub2.posted_at.as_json,
            "assignment_id" => a1.id,
            "body" => nil,
            "submitted_at" => "1970-01-01T04:00:00Z",
            "cached_due_date" => nil,
            "custom_grade_status_id" => nil,
            "attempt" => 1,
            "url" => "http://www.instructure.com",
            "submission_type" => "online_url",
            "user_id" => student2.id,
            "preview_url" => "http://www.example.com/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student2.id}?preview=1&version=1",
            "grade_matches_current_submission" => true,
            "attachments" =>
            [
              { "content-type" => "image/png",
                "display_name" => "snapshot.png",
                "filename" => "snapshot.png",
                "upload_status" => "success",
                "url" => "http://www.example.com/files/#{sub2a1.id}/download?download_frd=1&verifier=#{sub2a1.uuid}",
                "id" => sub2a1.id,
                "uuid" => sub2a1.uuid,
                "folder_id" => sub2a1.folder_id,
                "size" => sub2a1.size,
                "unlock_at" => nil,
                "locked" => false,
                "hidden" => false,
                "lock_at" => nil,
                "locked_for_user" => false,
                "hidden_for_user" => false,
                "created_at" => sub2a1.created_at.as_json,
                "updated_at" => sub2a1.updated_at.as_json,
                "preview_url" => nil,
                "thumbnail_url" => thumbnail_image_url(sub2a1, sub2a1.uuid, host: "www.example.com"),
                "modified_at" => sub2a1.modified_at.as_json,
                "mime_class" => sub2a1.mime_class,
                "media_entry_id" => sub2a1.media_entry_id,
                "category" => "uncategorized" },
            ],
            "redo_request" => false,
            "score" => 9.0,
            "entered_score" => 9.0,
            "workflow_state" => "graded",
            "late" => false,
            "missing" => false,
            "late_policy_status" => nil,
            "seconds_late" => 0,
            "sticker" => nil,
            "points_deducted" => nil,
            "extra_attempts" => nil }],
         "attempt" => 1,
         "url" => "http://www.instructure.com",
         "submission_type" => "online_url",
         "user_id" => student2.id,
         "attachments" =>
         [{ "content-type" => "image/png",
            "display_name" => "snapshot.png",
            "filename" => "snapshot.png",
            "upload_status" => "success",
            "url" => "http://www.example.com/files/#{sub2a1.id}/download?download_frd=1&verifier=#{sub2a1.uuid}",
            "id" => sub2a1.id,
            "uuid" => sub2a1.uuid,
            "folder_id" => sub2a1.folder_id,
            "size" => sub2a1.size,
            "unlock_at" => nil,
            "locked" => false,
            "hidden" => false,
            "lock_at" => nil,
            "locked_for_user" => false,
            "hidden_for_user" => false,
            "created_at" => sub2a1.created_at.as_json,
            "updated_at" => sub2a1.updated_at.as_json,
            "preview_url" => nil,
            "thumbnail_url" => thumbnail_image_url(sub2a1, sub2a1.uuid, host: "www.example.com"),
            "modified_at" => sub2a1.modified_at.as_json,
            "mime_class" => sub2a1.mime_class,
            "media_entry_id" => sub2a1.media_entry_id,
            "category" => "uncategorized" },],
         "redo_request" => false,
         "submission_comments" => [],
         "score" => 9.0,
         "entered_score" => 9.0,
         "rubric_assessment" =>
         { "crit2" => { "comments" => "Hmm", "points" => 2.0, "rating_id" => "rat1" },
           "crit1" => { "comments" => nil, "points" => 7.0, "rating_id" => "rat2" } },
         "workflow_state" => "graded",
         "late" => false,
         "missing" => false,
         "late_policy_status" => nil,
         "seconds_late" => 0,
         "sticker" => nil,
         "points_deducted" => nil }]
    expect(json.sort_by { |h| h["user_id"] }).to eql(res.sort_by { |h| h["user_id"] })
  end

  it "paginates submissions" do
    student = user_factory(active_all: true)
    course_with_teacher(active_all: true)
    @course.enroll_student(student).accept!
    @assignment = @course.assignments.create!({
                                                title: "assignment1",
                                                grading_type: "points",
                                                points_possible: 12
                                              })
    api_call(:get, "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions.json", {
               controller: "submissions_api",
               action: "index",
               format: "json",
               course_id: @course.to_param,
               assignment_id: @assignment.id
             })
    expect(response.header).to have_key("Link")
  end

  it "returns nothing if no assignments in the course" do
    student1 = user_factory(active_all: true)
    student2 = user_with_pseudonym(active_all: true)
    student2.pseudonym.update_attribute(:sis_user_id, "my-student-id")

    course_with_teacher(active_all: true)

    enrollment1 = @course.enroll_student(student1)
    enrollment1.accept!
    enrollment2 = @course.enroll_student(student2)
    enrollment2.accept!

    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/students/submissions.json",
                    { controller: "submissions_api",
                      action: "for_students",
                      format: "json",
                      course_id: @course.to_param },
                    { student_ids: [student1.to_param, student2.to_param], grouped: 1 })
    expect(json.sort_by { |h| h["user_id"] }).to eq [
      {
        "user_id" => student1.id,
        "section_id" => enrollment1.course_section_id,
        "submissions" => [],
      },
      {
        "user_id" => student2.id,
        "section_id" => enrollment2.course_section_id,
        "integration_id" => nil,
        "sis_user_id" => "my-student-id",
        "submissions" => [],
      },
    ]

    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/students/submissions.json",
                    { controller: "submissions_api",
                      action: "for_students",
                      format: "json",
                      course_id: @course.to_param },
                    { student_ids: [student1.to_param, student2.to_param] })
    expect(json).to eq []
  end

  it "returns sis_user_id for user when grouped" do
    student = user_with_pseudonym(active_all: true)
    batch = SisBatch.create(account_id: Account.default.id, workflow_state: "imported")
    student.pseudonym.update_attribute(:sis_user_id, "my-student-id")
    student.pseudonym.update_attribute(:sis_batch_id, batch.id)

    course_with_teacher(active_all: true)
    @course.update_attribute(:sis_batch_id, batch.id)

    @course.enroll_student(student).accept!

    account_admin_user
    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/students/submissions.json",
                    { controller: "submissions_api",
                      action: "for_students",
                      format: "json",
                      course_id: @course.to_param },
                    { student_ids: "all", grouped: "true" })
    expect(json.first["sis_user_id"]).to eq "my-student-id"
  end

  it "returns integration_id for the user when grouped" do
    student = user_with_pseudonym(active_all: true)
    batch = SisBatch.create(account_id: Account.default.id, workflow_state: "imported")
    student.pseudonym.update_attribute(:integration_id, "xyz")
    student.pseudonym.update_attribute(:sis_user_id, "my-student-id")
    student.pseudonym.update_attribute(:sis_batch_id, batch.id)

    course_with_teacher(active_all: true)
    @course.update_attribute(:sis_batch_id, batch.id)
    @course.enroll_student(student).accept!

    account_admin_user
    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/students/submissions.json",
                    { controller: "submissions_api",
                      action: "for_students",
                      format: "json",
                      course_id: @course.to_param },
                    { student_ids: "all", grouped: "true" })
    expect(json.first["integration_id"]).to eq "xyz"
  end

  context "with plagiarism data" do
    before :once do
      @student = user_factory(active_all: true)
      course_with_teacher(active_all: true)
      @course.enroll_student(@student).accept!
      @a1 = @course.assignments.create!(title: "assignment1", grading_type: "letter_grade", points_possible: 15, turnitin_enabled: true)
      @a2 = @course.assignments.create!(title: "assignment2", grading_type: "letter_grade", points_possible: 15, vericite_enabled: true)
      @a1.update(turnitin_settings: { originality_report_visibility: "after_grading" })
      @submission = submit_homework(@a1, @student)
      @submission2 = submit_homework(@a2, @student)
    end

    it "returns vericite data if present and vericite is enabled for the assignment" do
      sample_vericite_data = {
        :last_processed_attempt => 1,
        "attachment_504177" => {
          web_overlap: 73,
          publication_overlap: 0,
          error: true,
          student_overlap: 100,
          state: "failure",
          similarity_score: 100,
          object_id: "123345"
        },
        :provider => "vericite"
      }
      @submission2.update(turnitin_data: sample_vericite_data)

      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/assignments/#{@a2.id}/submissions/#{@student.id}.json",
                      { controller: "submissions_api",
                        action: "show",
                        format: "json",
                        course_id: @course.id.to_s,
                        assignment_id: @a2.id.to_s,
                        user_id: @student.id.to_s })
      expect(json).to have_key "vericite_data"
      sample_vericite_data.delete :last_processed_attempt
      expect(json["vericite_data"]).to eq sample_vericite_data.with_indifferent_access
    end

    it "returns turnitin data if present and turnitin is enabled for the assignment" do
      sample_turnitin_data = {
        :last_processed_attempt => 1,
        "attachment_504177" => {
          web_overlap: 73,
          publication_overlap: 0,
          error: true,
          student_overlap: 100,
          state: "failure",
          similarity_score: 100,
          object_id: "123345"
        }
      }
      @submission.update(turnitin_data: sample_turnitin_data)

      # as teacher
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/assignments/#{@a1.id}/submissions/#{@student.id}.json",
                      { controller: "submissions_api",
                        action: "show",
                        format: "json",
                        course_id: @course.id.to_s,
                        assignment_id: @a1.id.to_s,
                        user_id: @student.id.to_s })
      expect(json).to have_key "turnitin_data"
      sample_turnitin_data.delete :last_processed_attempt
      expect(json["turnitin_data"]).to eq sample_turnitin_data.with_indifferent_access

      # as student before graded
      @user = @student
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/assignments/#{@a1.id}/submissions/#{@student.id}.json",
                      { controller: "submissions_api",
                        action: "show",
                        format: "json",
                        course_id: @course.id.to_s,
                        assignment_id: @a1.id.to_s,
                        user_id: @student.id.to_s })
      expect(json).not_to have_key "turnitin_data"

      # as student after grading
      @a1.grade_student(@student, grade: 11, grader: @teacher)
      @user = @student
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/assignments/#{@a1.id}/submissions/#{@student.id}.json",
                      { controller: "submissions_api",
                        action: "show",
                        format: "json",
                        course_id: @course.id.to_s,
                        assignment_id: @a1.id.to_s,
                        user_id: @student.id.to_s })
      expect(json).to have_key "turnitin_data"
      expect(json["turnitin_data"]).to eq sample_turnitin_data.with_indifferent_access
    end

    it "shows webhook_info with ?include[]=webhook_info" do
      webhook_data = {
        "product_code" => "product_code",
        "vendor_code" => "vendor_code",
        "resource_type_code" => "code",
        "tool_proxy_id" => "tool_proxy_id",
        "tool_proxy_created_at" => "date",
        "tool_proxy_updated_at" => "date",
        "tool_proxy_name" => "tool_proxy_name",
        "tool_proxy_context_type" => "Account",
        "tool_proxy_context_id" => 1,
        "subscription_id" => "2a1cbf1c-cacb-4ebe-a418-c7463b34fca2",
      }
      @submission.update(turnitin_data: { webhook_info: webhook_data })
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/assignments/#{@a1.id}/submissions/#{@student.id}.json",
                      { controller: "submissions_api",
                        action: "show",
                        format: "json",
                        course_id: @course.id.to_s,
                        assignment_id: @a1.id.to_s,
                        user_id: @student.id.to_s,
                        include: ["webhook_info"] })
      expect(json.dig("turnitin_data", "webhook_info")).to eq(webhook_data)
    end
  end

  describe "#for_students" do
    before(:once) do
      @student1 = user_factory(active_all: true)
      @student2 = user_with_pseudonym(active_all: true)
      @student2.pseudonym.update_attribute(:sis_user_id, "my-student-id")

      course_with_teacher(active_all: true)

      @course.enroll_student(@student1).accept!
      @course.enroll_student(@student2).accept!

      @a1 = @course.assignments.create!(title: "assignment1", grading_type: "letter_grade", points_possible: 15)
      @a2 = @course.assignments.create!(title: "assignment2", grading_type: "letter_grade", points_possible: 25)

      submit_homework(@a1, @student1)
      submit_homework(@a2, @student1)
      submit_homework(@a1, @student2)
    end

    it "returns all submissions for a student", priority: "1" do
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/students/submissions.json",
                      { controller: "submissions_api",
                        action: "for_students",
                        format: "json",
                        course_id: @course.to_param },
                      { student_ids: [@student1.to_param] })

      expect(json.size).to eq 2
      json.each { |submission| expect(submission["user_id"]).to eq @student1.id }

      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/students/submissions.json",
                      { controller: "submissions_api",
                        action: "for_students",
                        format: "json",
                        course_id: @course.to_param },
                      { student_ids: [@student1.to_param, @student2.to_param] })

      expect(json.size).to eq 4

      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/students/submissions.json",
                      { controller: "submissions_api",
                        action: "for_students",
                        format: "json",
                        course_id: @course.to_param },
                      { student_ids: [@student1.to_param, @student2.to_param],
                        assignment_ids: [@a1.to_param] })

      expect(json.size).to eq 2
      expect(json.all? { |submission| expect(submission["assignment_id"]).to eq @a1.id }).to be_truthy

      # by sis user id!
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/students/submissions.json",
                      { controller: "submissions_api",
                        action: "for_students",
                        format: "json",
                        course_id: @course.to_param },
                      { student_ids: [@student1.to_param, "sis_user_id:my-student-id"],
                        assignment_ids: [@a1.to_param] })

      expect(json.size).to eq 2
      expect(json.all? { |submission| expect(submission["assignment_id"]).to eq @a1.id }).to be_truthy

      # by sis login id!
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/students/submissions.json",
                      { controller: "submissions_api",
                        action: "for_students",
                        format: "json",
                        course_id: @course.to_param },
                      { student_ids: [@student1.to_param, "sis_login_id:#{@student2.pseudonym.unique_id}"],
                        assignment_ids: [@a1.to_param] })

      expect(json.size).to eq 2
      expect(json.all? { |submission| expect(submission["assignment_id"]).to eq @a1.id }).to be_truthy

      # concluded enrollments!
      @student2.enrollments.first.conclude
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/students/submissions.json",
                      { controller: "submissions_api",
                        action: "for_students",
                        format: "json",
                        course_id: @course.to_param },
                      { student_ids: [@student1.to_param, "sis_login_id:#{@student2.pseudonym.unique_id}"],
                        assignment_ids: [@a1.to_param] })

      expect(json.size).to eq 2
      expect(json.all? { |submission| expect(submission["assignment_id"]).to eq @a1.id }).to be_truthy
    end

    it "can return assignments based on graded_at time", priority: "1" do
      @a2.grade_student @student1, grade: 10, grader: @teacher
      @a1.grade_student @student1, grade: 5, grader: @teacher
      @a3 = @course.assignments.create! title: "a3"
      @a3.submit_homework @student1, body: "hello"
      Submission.where(assignment_id: @a2).update_all(graded_at: 1.hour.from_now)
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/students/submissions.json",
                      { controller: "submissions_api",
                        action: "for_students",
                        format: "json",
                        course_id: @course.to_param },
                      { student_ids: [@student1.to_param],
                        order: "graded_at",
                        order_direction: "descending" })
      expect(json.pluck("assignment_id")).to eq [@a2.id, @a1.id, @a3.id]
    end

    it "errors when asking for assignments in other courses" do
      # second course
      course_with_teacher(active_all: true)
      @course.enroll_student(@student1).accept!
      @course.enroll_student(@student2).accept!

      # call the api on the new course, passing assignment ids from the old course
      api_call(:get,
               "/api/v1/courses/#{@course.id}/students/submissions.json",
               { controller: "submissions_api",
                 action: "for_students",
                 format: "json",
                 course_id: @course.to_param },
               { student_ids: "all",
                 assignment_ids: [@a1.id, @a2.id],
                 grouped: true,
                 total_scores: true })
      expect(response).to be_forbidden
    end

    describe "has_postable_comments" do
      let(:assignment) { @course.assignments.create! }
      let(:student1_sub) { assignment.submissions.find_by(user: @student1) }

      before do
        assignment.ensure_post_policy(post_manually: true)
      end

      def student_json(params = { grouped: true, student_ids: [@student1.to_param] })
        api_call(
          :get,
          "/api/v1/courses/#{@course.id}/students/submissions.json",
          {
            controller: "submissions_api",
            action: "for_students",
            format: "json",
            course_id: @course.to_param
          },
          params
        ).first
      end

      it "is not included when params[:grouped] is not present" do
        submission_json = student_json({ student_ids: [@student1.to_param] })
        expect(submission_json).not_to have_key "has_postable_comments"
      end

      it "is true when unposted and hidden comments exist" do
        student1_sub.add_comment(author: @teacher, comment: "good job!", hidden: true)
        submission_json = student_json.fetch("submissions").find { |s| s.fetch("id") == student1_sub.id }
        expect(submission_json.fetch("has_postable_comments")).to be true
      end

      it "is false when unposted and only non-hidden comments exist" do
        student1_sub.add_comment(author: @student, comment: "fun assignment!", hidden: false)
        submission_json = student_json.fetch("submissions").find { |s| s.fetch("id") == student1_sub.id }
        expect(submission_json.fetch("has_postable_comments")).to be false
      end

      it "is false when unposted and only draft comments exist" do
        student1_sub.add_comment(
          author: @teacher,
          comment: "maybe bad job but not sure, let me think about it",
          hidden: true,
          draft_comment: true
        )
        submission_json = student_json.fetch("submissions").find { |s| s.fetch("id") == student1_sub.id }
        expect(submission_json.fetch("has_postable_comments")).to be false
      end
    end

    context "OriginalityReport" do
      it "includes has_originality_report if the submission has an originality_report" do
        attachment_model
        course_factory active_all: true
        student_in_course active_all: true
        teacher_in_course active_all: true
        @assignment = @course.assignments.create!(title: "some assignment",
                                                  assignment_group: @group,
                                                  points_possible: 12,
                                                  tool_settings_tool: @tool)
        @attachment.context = @student
        @attachment.save!
        submission = @assignment.submit_homework(@student, attachments: [@attachment])
        OriginalityReport.create!(attachment: @attachment,
                                  submission:,
                                  workflow_state: "pending",
                                  originality_score: 0.1)

        user_session(@teacher)
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/students/submissions.json",
                        { controller: "submissions_api",
                          action: "for_students",
                          format: "json",
                          course_id: @course.to_param },
                        { student_ids: [@student.to_param] })

        expect(json.first).to have_key "has_originality_report"
      end

      it "does not include has_originality_report if the submission has no originality_report" do
        attachment_model
        course_factory active_all: true
        student_in_course active_all: true
        teacher_in_course active_all: true
        @assignment = @course.assignments.create!(title: "some assignment",
                                                  assignment_group: @group,
                                                  points_possible: 12,
                                                  tool_settings_tool: @tool)
        @attachment.context = @student
        @attachment.save!
        @assignment.submit_homework(@student, attachments: [@attachment])

        user_session(@teacher)
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/students/submissions.json",
                        { controller: "submissions_api",
                          action: "for_students",
                          format: "json",
                          course_id: @course.to_param },
                        { student_ids: [@student.to_param] })
        expect(json.first).not_to have_key "has_originality_report"
      end
    end
  end

  context "moderated assignments" do
    before do
      student_in_course(active_all: true)
      course_with_teacher_logged_in(course: @course)
      @assignment = @course.assignments.create!(
        title: "an assignment",
        grading_type: "letter_grade",
        points_possible: 10
      )
      @assignment.update_attribute(:moderated_grading, true)
      @assignment.update_attribute(:grader_count, 2)
      submission = @assignment.submit_homework(@student, body: "nice work")
      @provisional_grade = submission.provisional_grades.build do |grade|
        grade.scorer = @teacher
      end
      @provisional_grade.save!
    end

    context "when teacher can view provisional grades" do
      it "displays grades" do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions.json",
                        {
                          controller: "submissions_api",
                          action: "index",
                          format: "json",
                          course_id: @course.id,
                          assignment_id: @assignment.id
                        },
                        {
                          include: ["provisional_grades"]
                        })

        expect(json.first["provisional_grades"]).to_not be_empty
        speedgrader_url = URI.parse(json.first["provisional_grades"].first["speedgrader_url"])
        expect(speedgrader_url).to match_path("/courses/#{@course.id}/gradebook/speed_grader")
          .and_query({ assignment_id: @assignment.id, student_id: @student.id })
      end

      it "can include users" do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions.json",
                        {
                          controller: "submissions_api",
                          action: "index",
                          format: "json",
                          course_id: @course.id,
                          assignment_id: @assignment.id,
                        },
                        {
                          include: ["user_summary"]
                        })

        user = json.first["user"]
        expect(user["display_name"]).to eql @student.name
        expect(user["avatar_image_url"]).to eql "http://www.example.com/images/messages/avatar-50.png"
        expect(user["html_url"]).to eql polymorphic_url([@course, @student])
      end
    end

    context "when a TA cannot view provisional grades" do
      before do
        course_with_ta(course: @course)
        user_session(@ta)
      end

      it "only shows caller's provisional grade" do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions.json",
                        {
                          controller: "submissions_api",
                          action: "index",
                          format: "json",
                          course_id: @course.id,
                          assignment_id: @assignment.id
                        },
                        {
                          include: ["provisional_grades"]
                        })

        expect(json.first["provisional_grades"]).to be_empty
      end
    end
  end

  context "for_students (differentiated_assignments)" do
    before do
      # set up course with DA and submit homework for an assignment
      # that is only visible to overrides for @section1
      @student = user_factory(active_all: true)
      course_with_teacher(active_all: true)
      @section1 = @course.course_sections.create!(name: "test section")
      @section2 = @course.course_sections.create!(name: "test section")
      student_in_section(@section1, user: @student)
      @assignment = @course.assignments.create!(title: "assignment1", grading_type: "letter_grade", points_possible: 15, only_visible_to_overrides: true)
      create_section_override_for_assignment(@assignment, course_section: @section1)
      submit_homework(@assignment, @student)

      user_session(@student)
    end

    def call_to_for_students(opts = {})
      helper_method = if opts[:as_student]
                        [:api_call_as_user, @student]
                      elsif opts[:as_observer]
                        [:api_call_as_user, @observer]
                      else
                        [:api_call]
                      end
      args = helper_method + [:get,
                              "/api/v1/courses/#{@course.id}/students/submissions.json",
                              { controller: "submissions_api",
                                action: "for_students",
                                format: "json",
                                course_id: @course.to_param },
                              { student_ids: [@student.to_param] }]
      send(*args)
    end

    context "as student" do
      context "differentiated_assignments" do
        it "returns the submissons if the student is in the overriden section" do
          json = call_to_for_students(as_student: true)

          expect(json.size).to eq 1
          json.each { |submission| expect(submission["user_id"]).to eq @student.id }
        end

        it "does not return the submissons if the student is not in the overriden section and has a submission with no grade" do
          Score.where(enrollment_id: @student.enrollments).each(&:destroy_permanently!)
          @student.enrollments.each(&:destroy_permanently!)
          student_in_section(@section2, user: @student)
          @assignment.grade_student(@student, grade: nil, grader: @teacher)

          json = call_to_for_students(as_student: true)

          expect(json.size).to eq 0
        end

        it "does not return the submissons if the student is not in the overriden section and has a graded submission" do
          Score.where(enrollment_id: @student.enrollments).each(&:destroy_permanently!)
          @student.enrollments.each(&:destroy_permanently!)
          student_in_section(@section2, user: @student)
          @assignment.grade_student(@student, grade: 5, grader: @teacher)

          json = call_to_for_students(as_student: true)

          expect(json.size).to eq 0
        end
      end
    end

    context "as an observer" do
      before do
        @observer = User.create
        observer_enrollment = @course.enroll_user(@observer, "ObserverEnrollment", section: @section2, enrollment_state: "active")
        observer_enrollment.update_attribute(:associated_user_id, @student.id)
      end

      context "differentiated_assignments on" do
        it "returns the submissons if the observed student is in the overriden section" do
          json = call_to_for_students(as_observer: true)

          expect(json.size).to eq 1
          json.each { |submission| expect(submission["user_id"]).to eq @student.id }
        end

        it "does not return the submissons if the observed student is not in the overridden section and has a submission with no grade" do
          Score.where(enrollment_id: @student.enrollments).each(&:destroy_permanently!)
          @student.enrollments.each(&:destroy_permanently!)
          student_in_section(@section2, user: @student)
          @assignment.grade_student(@student, grade: nil, grader: @teacher)

          json = call_to_for_students(as_observer: true)

          expect(json.size).to eq 0
        end

        it "does not return the submissons if the observed student is not in the overridden section and has a graded submission" do
          Score.where(enrollment_id: @student.enrollments).each(&:destroy_permanently!)
          @student.enrollments.each(&:destroy_permanently!)
          student_in_section(@section2, user: @student)
          @assignment.grade_student(@student, grade: 5, grader: @teacher)

          json = call_to_for_students(as_observer: true)

          expect(json.size).to eq 0
        end
      end
    end

    context "as teacher" do
      context "differentiated_assignments on" do
        it "returns the submissons if the student is in the overriden section" do
          json = call_to_for_students(as_student: false)

          expect(json.size).to eq 1
          json.each { |submission| expect(submission["user_id"]).to eq @student.id }
        end

        it "does not return the submisson if the student is not in the overriden section" do
          Score.where(enrollment_id: @student.enrollments).each(&:destroy_permanently!)
          @student.enrollments.each(&:destroy_permanently!)
          student_in_section(@section2, user: @student)

          json = call_to_for_students(as_student: false)

          expect(json.size).to eq 0
        end
      end
    end
  end

  context "for_students grouped pagination" do
    before(:once) do
      @student1 = user_factory(active_all: true)
      @student2 = user_factory(active_all: true)
      course_with_teacher(active_all: true)
      @section1 = @course.course_sections.create!(name: "test section")
      @section2 = @course.course_sections.create!(name: "test section")
      student_in_section(@section1, user: @student1, allow_multiple_enrollments: true)
      student_in_section(@section2, user: @student1, allow_multiple_enrollments: true)
      student_in_section(@section1, user: @student2, allow_multiple_enrollments: true)
      @assignment = @course.assignments.create!(title: "assignment1", grading_type: "letter_grade", points_possible: 15, only_visible_to_overrides: true)
      submit_homework(@assignment, @student1)
      submit_homework(@assignment, @student2)
    end

    before do
      user_session(@teacher)
    end

    it "fills a page when a student has multiple enrollments" do
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/students/submissions.json",
                      { controller: "submissions_api", action: "for_students", format: "json", course_id: @course.to_param },
                      { student_ids: "all", grouped: true, per_page: 2, page: 1 })
      expect(json.pluck("user_id")).to eq [@student1.id, @student2.id]
    end

    it "does not duplicate a student with multiple enrollments when paging" do
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/students/submissions.json",
                      { controller: "submissions_api", action: "for_students", format: "json", course_id: @course.to_param },
                      { student_ids: "all", grouped: true, per_page: 1, page: 1 })
      expect(json.pluck("user_id")).to eq [@student1.id]
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/students/submissions.json",
                      { controller: "submissions_api", action: "for_students", format: "json", course_id: @course.to_param },
                      { student_ids: "all", grouped: true, per_page: 1, page: 2 })
      expect(json.pluck("user_id")).to eq [@student2.id]
    end

    it "prefers an active enrollment when a student has more than one" do
      enrollments = @student1.enrollments
      enrollments.first.complete
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/students/submissions.json",
                      { controller: "submissions_api", action: "for_students", format: "json", course_id: @course.to_param },
                      { student_ids: [@student1.id], assignment_ids: [@assignment.id], grouped: true })
      row = json.detect { |r| r["user_id"] == @student1.id }
      expect(row["section_id"]).to eq enrollments.last.course_section_id
    end

    it "filters by section" do
      json = api_call(:get,
                      "/api/v1/sections/#{@section2.id}/students/submissions.json",
                      { controller: "submissions_api", action: "for_students", format: "json", section_id: @section2.to_param },
                      { student_ids: "all", grouped: true })
      expect(json.pluck("user_id")).to eq [@student1.id]
    end

    it "rejects an out-of-context user" do
      api_call(:get,
               "/api/v1/sections/#{@section2.id}/students/submissions.json",
               { controller: "submissions_api", action: "for_students", format: "json", section_id: @section2.to_param },
               { student_ids: [@student1.id, @student2.id], grouped: true },
               {},
               { expected_status: 401 })
    end
  end

  describe "#show_anonymous" do
    before do
      @student = user_factory(active_all: true)
      course_with_teacher(active_all: true)
      section = @course.course_sections.create!(name: "test section")
      student_in_section(section, user: @student)
      @assignment = @course.assignments.create!(anonymous_grading: true)
    end

    it "fetches the submission using the provided anonymous_id" do
      submission = @assignment.submissions.find_by(user: @student)

      api_call(
        :get,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/anonymous_submissions/#{submission.anonymous_id}.json",
        {
          controller: "submissions_api",
          action: "show_anonymous",
          format: "json",
          course_id: @course.to_param,
          assignment_id: @assignment.id.to_s,
          anonymous_id: submission.anonymous_id.to_s
        },
        {},
        {},
        { expected_status: 200 }
      )
    end

    it "anonymizes the results" do
      submission = @assignment.submissions.find_by(user: @student)
      submission.submission_comments.create!(author: @student, comment: "hi")

      json = api_call(
        :get,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/anonymous_submissions/#{submission.anonymous_id}.json",
        {
          controller: "submissions_api",
          action: "show_anonymous",
          format: "json",
          course_id: @course.to_param,
          assignment_id: @assignment.id.to_s,
          anonymous_id: submission.anonymous_id.to_s
        },
        { include: ["submission_comments", "submission_history"], anonymize_user_id: true }
      )

      aggregate_failures do
        expect(json).not_to have_key "user_id"
        expect(json["anonymous_id"]).to eq submission.anonymous_id
        expect(json.dig("submission_history", 0)).not_to have_key "user_id"
        expect(json.dig("submission_history", 0, "anonymous_id")).to eq submission.anonymous_id
        expect(json.dig("submission_comments", 0, "author_id")).to be_nil
        expect(json.dig("submission_comments", 0, "author_name")).to eq "Anonymous User"
      end
    end
  end

  describe "#show" do
    before do
      @student = user_factory(active_all: true)
      course_with_teacher(active_all: true)
      @section = @course.course_sections.create!(name: "test section")
      student_in_section(@section, user: @student)
    end

    context "differentiated assignments" do
      before do
        # set up course with DA and submit homework for an assignment
        # that is only visible to overrides for @section
        # move student to a section that cannot see assignment by default
        @section2 = @course.course_sections.create!(name: "test section")
        @assignment = @course.assignments.create!(title: "assignment1", grading_type: "letter_grade", points_possible: 15, only_visible_to_overrides: true)
        create_section_override_for_assignment(@assignment, course_section: @section)
        submit_homework(@assignment, @student)
        Score.where(enrollment_id: @student.enrollments).each(&:destroy_permanently!)
        @student.enrollments.each(&:destroy_permanently!)
        student_in_section(@section2, user: @student)

        user_session(@student)
      end

      def call_to_submissions_show(opts = {})
        includes = %w[submission_comments rubric_assessment]
        includes.concat(opts[:includes]) if opts[:includes]
        helper_method = opts[:as_student] ? [:api_call_as_user, @student] : [:api_call]
        args = helper_method + [:get,
                                "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
                                { controller: "submissions_api",
                                  action: "show",
                                  format: "json",
                                  course_id: @course.to_param,
                                  assignment_id: @assignment.id.to_s,
                                  user_id: @student.id.to_s },
                                { include: includes }]
        send(*args)
      end

      context "as teacher" do
        context "with differentiated_assignments" do
          it "returns the assignment" do
            json = call_to_submissions_show(as_student: false)

            expect(json["assignment_id"]).not_to be_nil
          end

          it "returns assignment_visible" do
            json = call_to_submissions_show(as_student: false, includes: ["visibility"])
            expect(json["assignment_visible"]).not_to be_nil
          end
        end
      end

      context "as student in a section without an override" do
        context "with differentiated_assignments" do
          it "returns an unauthorized error" do
            api_call_as_user(@student,
                             :get,
                             "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
                             { controller: "submissions_api",
                               action: "show",
                               format: "json",
                               course_id: @course.to_param,
                               assignment_id: @assignment.id.to_s,
                               user_id: @student.id.to_s },
                             { include: %w[submission_comments rubric_assessment] },
                             {},
                             expected_status: 401)
          end

          it "does not return the submission, even if it is graded" do
            @assignment.grade_student(@student, grade: 5, grader: @teacher)
            json = call_to_submissions_show(as_student: true)

            expect(json["assignment_id"]).to be_nil
          end

          it "returns assignment_visible false" do
            json = call_to_submissions_show(as_student: false, includes: ["visibility"])
            expect(json["assignment_visible"]).to be(false)
          end
        end
      end
    end

    context "full rubric assessments" do
      before do
        @assignment1 = assignment_model(context: @course)
        submit_homework(@assignment1, @student)
      end

      it "fails when no rubric assessment is present" do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/assignments/#{@assignment1.id}/submissions/#{@student.id}.json",
                        { controller: "submissions_api",
                          action: "show",
                          format: "json",
                          course_id: @course.id.to_s,
                          assignment_id: @assignment1.id.to_s,
                          user_id: @student.id.to_s },
                        { include: %w[full_rubric_assessment] })
        expect(json).not_to have_key "full_rubric_assessment"
      end

      context "if present" do
        before do
          @assignment2 = assignment_model(context: @course)
          rubric_assessment_model({ purpose: "grading",
                                    association_object: @assignment2,
                                    user: @student,
                                    assessment_type: "grading" })
        end

        it "returns the correct data" do
          json = api_call_as_user(@teacher,
                                  :get,
                                  "/api/v1/courses/#{@course.id}/assignments/#{@assignment2.id}/submissions/#{@student.id}.json",
                                  { controller: "submissions_api",
                                    action: "show",
                                    format: "json",
                                    course_id: @course.id.to_s,
                                    assignment_id: @assignment2.id.to_s,
                                    user_id: @student.id.to_s },
                                  { include: %w[full_rubric_assessment] })
          expect(json).to have_key "full_rubric_assessment"
          expect(json["full_rubric_assessment"]).to have_key "data"
          expect(json["full_rubric_assessment"]).to have_key "assessor_name"
          expect(json["full_rubric_assessment"]).to have_key "assessor_avatar_url"
        end

        it "is visible to student owning the assignment" do
          json = api_call_as_user(@student,
                                  :get,
                                  "/api/v1/courses/#{@course.id}/assignments/#{@assignment2.id}/submissions/#{@student.id}.json",
                                  { controller: "submissions_api",
                                    action: "show",
                                    format: "json",
                                    course_id: @course.id.to_s,
                                    assignment_id: @assignment2.id.to_s,
                                    user_id: @student.id.to_s },
                                  { include: %w[full_rubric_assessment] })
          expect(json["full_rubric_assessment"]).not_to be_nil
        end

        it "is not visible to students that are not the owner of the assignment" do
          @other_student = user_factory(active_all: true)
          student_in_section(@section, user: @other_student)
          api_call_as_user(@other_student,
                           :get,
                           "/api/v1/courses/#{@course.id}/assignments/#{@assignment2.id}/submissions/#{@student.id}.json",
                           { controller: "submissions_api",
                             action: "show",
                             format: "json",
                             course_id: @course.id.to_s,
                             assignment_id: @assignment2.id.to_s,
                             user_id: @student.id.to_s },
                           { include: %w[full_rubric_assessment] },
                           {},
                           expected_status: 401)
        end
      end
    end
  end

  context "grouped submissions" do
    before :once do
      @student1 = user_factory(active_all: true)
      @student2 = user_with_pseudonym(active_all: true)

      course_with_teacher(active_all: true)
      ta_in_course

      @course.enroll_student(@student1).accept!
      @course.enroll_student(@student2).accept!

      @a1 = @course.assignments.create!(
        title: "assignment1",
        grading_type: "letter_grade",
        points_possible: 15
      )
      @a2 = @course.assignments.create!(
        title: "assignment2",
        grading_type: "letter_grade",
        points_possible: 25
      )
      @a1.unmute! # automatically post grades for assignment 1
      @a2.ensure_post_policy(post_manually: true)

      @a1.grade_student(@student1, grader: @teacher, grade: 15)
      @a2.grade_student(@student1, grader: @teacher, grade: 5)
      @a1.grade_student(@student2, grader: @teacher, excused: true)
    end

    it "returns student submissions grouped by student" do
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/students/submissions.json",
                      { controller: "submissions_api",
                        action: "for_students",
                        format: "json",
                        course_id: @course.to_param },
                      { student_ids: [@student1.to_param], grouped: "1" })

      expect(json.size).to eq 1
      expect(json.first["submissions"].size).to eq 2
      json.each { |user| expect(user["user_id"]).to eq @student1.id }

      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/students/submissions.json",
                      { controller: "submissions_api",
                        action: "for_students",
                        format: "json",
                        course_id: @course.to_param },
                      { student_ids: [@student1.to_param, @student2.to_param], grouped: "1" })

      expect(json.size).to eq 2
      expect(json.pluck("submissions").flatten.size).to eq 4

      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/students/submissions.json",
                      { controller: "submissions_api",
                        action: "for_students",
                        format: "json",
                        course_id: @course.to_param },
                      { student_ids: [@student1.to_param, @student2.to_param],
                        assignment_ids: [@a1.to_param],
                        grouped: "1" })

      expect(json.size).to eq 2
      json.each { |user| user["submissions"].each { |s| expect(s["assignment_id"]).to eq @a1.id } }
    end

    it "paginates" do
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/students/submissions.json",
                      { controller: "submissions_api",
                        action: "for_students",
                        format: "json",
                        course_id: @course.to_param },
                      { student_ids: ["all"], grouped: "1", per_page: "1" })
      expect(json.size).to eq 1

      json2 = api_call(:get,
                       "/api/v1/courses/#{@course.id}/students/submissions.json",
                       { controller: "submissions_api",
                         action: "for_students",
                         format: "json",
                         course_id: @course.to_param },
                       { student_ids: ["all"], grouped: "1", per_page: "1", page: 2 })
      expect(json2.size).to eq 1
      expect((json + json2).pluck("user_id")).to match_array([@student1.id, @student2.id])
    end

    describe "current and final scores" do
      context "when accessing as a teacher with default permissions" do
        let(:json) do
          api_call(:get,
                   "/api/v1/courses/#{@course.id}/students/submissions.json",
                   { controller: "submissions_api",
                     action: "for_students",
                     format: "json",
                     course_id: @course.to_param },
                   { student_ids: [@student1.to_param], include: ["total_scores"], grouped: "1" })
        end

        it "returns a single record" do
          expect(json.size).to eq 1
        end

        it "returns the computed_current_score" do
          expect(json[0]["computed_current_score"]).to eq 100
        end

        it "returns the unposted_current_score" do
          expect(json[0]["unposted_current_score"]).to eq 50
        end

        it "returns the computed_final_score" do
          expect(json[0]["computed_final_score"]).to eq 37.5
        end

        it "returns the unposted_final_score" do
          expect(json[0]["unposted_final_score"]).to eq 50
        end
      end

      context "when the requester does not have permissions to see unposted scores" do
        let(:json) do
          api_call_as_user(@student1,
                           :get,
                           "/api/v1/courses/#{@course.id}/students/submissions.json",
                           { controller: "submissions_api",
                             action: "for_students",
                             format: "json",
                             course_id: @course.to_param },
                           { student_ids: [@student1.to_param], include: ["total_scores"], grouped: "1" })
        end

        it "returns a single record" do
          expect(json.size).to eq 1
        end

        it "returns the computed_current_score" do
          expect(json[0]["computed_current_score"]).to eq 100
        end

        it "omits the unposted_current_score" do
          expect(json[0]).not_to include "unposted_current_score"
        end

        it "returns the computed_final_score" do
          expect(json[0]["computed_final_score"]).to eq 37.5
        end

        it "omits the unposted_final_score" do
          expect(json[0]).not_to include "unposted_final_score"
        end
      end

      context "when the requester can manage grades" do
        before(:once) do
          @course.root_account.role_overrides.create!(permission: "view_all_grades", role: ta_role, enabled: false)
          @course.root_account.role_overrides.create!(permission: "manage_grades", role: ta_role, enabled: true)
        end

        let(:json) do
          api_call_as_user(@ta,
                           :get,
                           "/api/v1/courses/#{@course.id}/students/submissions.json",
                           { controller: "submissions_api",
                             action: "for_students",
                             format: "json",
                             course_id: @course.to_param },
                           { student_ids: [@student1.to_param], include: ["total_scores"], grouped: "1" })
        end

        it "returns a single record" do
          expect(json.size).to eq 1
        end

        it "returns the computed_current_score" do
          expect(json[0]["computed_current_score"]).to eq 100
        end

        it "returns the unposted_current_score" do
          expect(json[0]["unposted_current_score"]).to eq 50
        end

        it "returns the computed_final_score" do
          expect(json[0]["computed_final_score"]).to eq 37.5
        end

        it "returns the unposted_final_score" do
          expect(json[0]["unposted_final_score"]).to eq 50
        end
      end

      context "when the requester can view all grades" do
        before(:once) do
          @course.root_account.role_overrides.create!(permission: "view_all_grades", role: designer_role, enabled: true)
          @course.root_account.role_overrides.create!(permission: "manage_grades", role: designer_role, enabled: false)

          course_with_designer(course: @course)
        end

        let(:json) do
          api_call_as_user(@designer,
                           :get,
                           "/api/v1/courses/#{@course.id}/students/submissions.json",
                           { controller: "submissions_api",
                             action: "for_students",
                             format: "json",
                             course_id: @course.to_param },
                           { student_ids: [@student1.to_param], include: ["total_scores"], grouped: "1" })
        end

        it "returns a single record" do
          expect(json.size).to eq 1
        end

        it "returns the computed_current_score" do
          expect(json[0]["computed_current_score"]).to eq 100
        end

        it "returns the unposted_current_score" do
          expect(json[0]["unposted_current_score"]).to eq 50
        end

        it "returns the computed_final_score" do
          expect(json[0]["computed_final_score"]).to eq 37.5
        end

        it "returns the unposted_final_score" do
          expect(json[0]["unposted_final_score"]).to eq 50
        end
      end
    end
  end

  context "with grading periods" do
    before :once do
      @student1 = user_factory(active_all: true)
      @student2 = user_with_pseudonym(active_all: true)

      course_with_teacher(active_all: true)

      @course.enroll_student(@student1).accept!
      @course.enroll_student(@student2).accept!

      gpg = Factories::GradingPeriodGroupHelper.new.legacy_create_for_course(@course)
      @gp1 = gpg.grading_periods.create!(
        title: "first",
        weight: 50,
        start_date: 2.days.ago,
        end_date: 1.day.from_now
      )
      @gp2 = gpg.grading_periods.create!(
        title: "second",
        weight: 50,
        start_date: 2.days.from_now,
        end_date: 1.month.from_now
      )
      a1 = @course.assignments.create!(due_at: 1.minute.from_now, submission_types: "online_text_entry")
      a2 = @course.assignments.create!(due_at: 1.week.from_now, submission_types: "online_text_entry")

      submit_homework(a1, @student1)
      submit_homework(a2, @student1) # only one in current grading period
      submit_homework(a1, @student2)
    end

    it "filters by grading period" do
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/students/submissions.json",
                      { controller: "submissions_api",
                        action: "for_students",
                        format: "json",
                        course_id: @course.to_param },
                      { student_ids: [@student1.to_param, @student2.to_param],
                        grouped: "1",
                        grading_period_id: @gp2.to_param })
      expect(json.detect { |u| u["user_id"] == @student1.id }["submissions"].size).to eq 1
      expect(json.detect { |u| u["user_id"] == @student2.id }["submissions"].size).to eq 1
    end

    it "does not return an error when no grading_period_id is provided" do
      api_call(:get,
               "/api/v1/courses/#{@course.id}/students/submissions.json",
               { controller: "submissions_api",
                 action: "for_students",
                 format: "json",
                 course_id: @course.to_param },
               { student_ids: [@student1.to_param, @student2.to_param], grouped: "1" })
      expect(response).to be_ok
    end
  end

  context "with late policies" do
    before :once do
      student_in_course(active_all: true)
      teacher_in_course(active_all: true)
      @late_policy = late_policy_factory(course: @course, deduct: 10, every: :day, down_to: 30)
      @late_assignment = @course.assignments.create!(
        title: "assignment1",
        due_at: 47.hours.ago,
        points_possible: 10,
        submission_types: "online_text_entry"
      )
    end

    let(:late_submission_api_header) do
      {
        controller: "submissions_api",
        action: "update",
        format: "json",
        course_id: @course.id.to_s,
        assignment_id: @late_assignment.id.to_s,
        user_id: @student.id.to_s
      }
    end

    it "applies late policy when grading the submission twice with the same raw score" do
      @late_assignment.submit_homework(@student, submission_type: "online_text_entry")
      2.times do
        json = api_call(
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{@late_assignment.id}/submissions/#{@student.id}.json",
          late_submission_api_header,
          {
            submission: {
              posted_grade: "10"
            }
          }
        )
        expect(json["grade"]).to eq "8"
        expect(json["score"]).to eq 8
      end
    end
  end

  describe "for_students non-admin" do
    before :once do
      course_with_student active_all: true
      @student1 = @student
      @student2 = student_in_course(active_all: true).user
      @student3 = student_in_course(active_all: true).user
      @assignment1 = @course.assignments.create! title: "assignment1", grading_type: "points", points_possible: 15
      @assignment2 = @course.assignments.create! title: "assignment2", grading_type: "points", points_possible: 25

      @assignment1.unmute!
      @assignment2.unmute!

      bare_submission_model @assignment1, @student1, grade: 15, grader_id: @teacher.id, score: 15
      bare_submission_model @assignment2, @student1, grade: 25, grader_id: @teacher.id, score: 25
      bare_submission_model @assignment1, @student2, grade: 10, grader_id: @teacher.id, score: 10
      bare_submission_model @assignment2, @student2, grade: 20, grader_id: @teacher.id, score: 20
      bare_submission_model @assignment1, @student3, grade: 20, grader_id: @teacher.id, score: 20
    end

    context "teacher" do
      it "shows all submissions" do
        @user = @teacher
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/students/submissions",
                        { controller: "submissions_api",
                          action: "for_students",
                          format: "json",
                          course_id: @course.to_param },
                        { student_ids: ["all"] })
        expect(json.map { |entry| entry.slice("user_id", "assignment_id", "score") }.sort_by { |entry| [entry["user_id"], entry["assignment_id"]] }).to eq [
          { "user_id" => @student1.id, "assignment_id" => @assignment1.id, "score" => 15 },
          { "user_id" => @student1.id, "assignment_id" => @assignment2.id, "score" => 25 },
          { "user_id" => @student2.id, "assignment_id" => @assignment1.id, "score" => 10 },
          { "user_id" => @student2.id, "assignment_id" => @assignment2.id, "score" => 20 },
          { "user_id" => @student3.id, "assignment_id" => @assignment1.id, "score" => 20 },
          { "user_id" => @student3.id, "assignment_id" => @assignment2.id, "score" => nil },
        ]
      end

      it "does not show submissions for a user outside the course" do
        rando = user_factory
        api_call_as_user(@teacher,
                         :get,
                         "/api/v1/courses/#{@course.id}/students/submissions",
                         { controller: "submissions_api",
                           action: "for_students",
                           format: "json",
                           course_id: @course.to_param },
                         { student_ids: [rando.id] },
                         {},
                         { expected_status: 401 })
      end
    end

    context "students" do
      it "allows a student to view his own submissions" do
        @user = @student1
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/students/submissions.json",
                        { controller: "submissions_api",
                          action: "for_students",
                          format: "json",
                          course_id: @course.to_param },
                        { student_ids: [@student1.to_param] })
        sub_json = json.map { |entry| entry.slice("user_id", "assignment_id", "score") }
                       .sort_by { |entry| entry["assignment_id"] }
        expect(sub_json).to eq [
          { "user_id" => @student1.id, "assignment_id" => @assignment1.id, "score" => 15 },
          { "user_id" => @student1.id, "assignment_id" => @assignment2.id, "score" => 25 }
        ]
      end

      it "assumes the calling user if student_ids is not provided" do
        @user = @student2
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/students/submissions.json",
                        { controller: "submissions_api",
                          action: "for_students",
                          format: "json",
                          course_id: @course.to_param })
        sub_json = json.map { |entry| entry.slice("user_id", "assignment_id", "score") }
                       .sort_by { |entry| entry["assignment_id"] }
        expect(sub_json).to eq [
          { "user_id" => @student2.id, "assignment_id" => @assignment1.id, "score" => 10 },
          { "user_id" => @student2.id, "assignment_id" => @assignment2.id, "score" => 20 }
        ]
      end

      it "shows all possible if student_ids is ['all']" do
        @user = @student2
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/students/submissions.json",
                        { controller: "submissions_api",
                          action: "for_students",
                          format: "json",
                          course_id: @course.to_param },
                        { student_ids: ["all"] })
        sub_json = json.map { |entry| entry.slice("user_id", "assignment_id", "score") }
                       .sort_by { |entry| entry["assignment_id"] }
        expect(sub_json).to eq [
          { "user_id" => @student2.id, "assignment_id" => @assignment1.id, "score" => 10 },
          { "user_id" => @student2.id, "assignment_id" => @assignment2.id, "score" => 20 }
        ]
      end

      it "supports the 'grouped' argument" do
        @user = @student1
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/students/submissions.json?grouped=1",
                        { controller: "submissions_api",
                          action: "for_students",
                          format: "json",
                          course_id: @course.to_param,
                          grouped: "1" })
        expect(json.size).to eq 1
        expect(json[0]["user_id"]).to eq @student1.id
        expect(json[0]["submissions"].map { |sub| sub.slice("assignment_id", "score") }.sort_by { |entry| entry["assignment_id"] }).to eq [
          { "assignment_id" => @assignment1.id, "score" => 15 },
          { "assignment_id" => @assignment2.id, "score" => 25 }
        ]
      end

      it "does not allow a student to view another student's submissions" do
        @user = @student1
        api_call(:get,
                 "/api/v1/courses/#{@course.id}/students/submissions.json?student_ids[]=#{@student1.id}&student_ids[]=#{@student2.id}",
                 { controller: "submissions_api",
                   action: "for_students",
                   format: "json",
                   course_id: @course.to_param,
                   student_ids: [@student1.to_param, @student2.to_param] },
                 {},
                 {},
                 expected_status: 401)
      end

      it "errors if too many students requested" do
        stub_const("Api::MAX_PER_PAGE", 0)
        @user = @student1
        api_call(:get,
                 "/api/v1/courses/#{@course.id}/students/submissions.json",
                 { controller: "submissions_api",
                   action: "for_students",
                   format: "json",
                   course_id: @course.to_param },
                 { student_ids: [@student1.to_param] },
                 {},
                 expected_status: 400)
      end

      it "allows concluded students to view their submission" do
        one_week_prior = 1.week.ago
        @assignment1.due_at = one_week_prior
        @assignment1.save!
        @assignment2.due_at = one_week_prior
        @assignment2.save!

        enrollment = @course.student_enrollments.where(user_id: @student1).first
        enrollment.conclude

        @user = @student1
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/students/submissions.json",
                        { controller: "submissions_api",
                          action: "for_students",
                          format: "json",
                          course_id: @course.to_param },
                        { student_ids: [@student1.to_param] })
        sub_json = json.map { |entry| entry.slice("user_id", "assignment_id", "score") }
                       .sort_by { |entry| entry["assignment_id"] }
        expect(sub_json).to eq [
          { "user_id" => @student1.id, "assignment_id" => @assignment1.id, "score" => 15 },
          { "user_id" => @student1.id, "assignment_id" => @assignment2.id, "score" => 25 }
        ]
      end
    end

    context "observers" do
      before :once do
        @observer = user_factory active_all: true
        @course.enroll_user(@observer, "ObserverEnrollment", associated_user_id: @student1.id)
        @course.enroll_user(@observer, "ObserverEnrollment", allow_multiple_enrollments: true, associated_user_id: @student2.id)
      end

      it "allows an observer to view observed students' submissions" do
        @user = @observer
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/students/submissions",
                        { controller: "submissions_api",
                          action: "for_students",
                          format: "json",
                          course_id: @course.to_param },
                        { student_ids: [@student1.id, @student2.id] })
        expect(json.map { |entry| entry.slice("user_id", "assignment_id", "score") }.sort_by { |entry| [entry["user_id"], entry["assignment_id"]] }).to eq [
          { "user_id" => @student1.id, "assignment_id" => @assignment1.id, "score" => 15 },
          { "user_id" => @student1.id, "assignment_id" => @assignment2.id, "score" => 25 },
          { "user_id" => @student2.id, "assignment_id" => @assignment1.id, "score" => 10 },
          { "user_id" => @student2.id, "assignment_id" => @assignment2.id, "score" => 20 }
        ]
      end

      it "allows an observer to view all observed students' submissions via student_ids[]=all" do
        @user = @observer
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/students/submissions",
                        { controller: "submissions_api",
                          action: "for_students",
                          format: "json",
                          course_id: @course.to_param },
                        { student_ids: ["all"] })
        expect(json.map { |entry| entry.slice("user_id", "assignment_id", "score") }.sort_by { |entry| [entry["user_id"], entry["assignment_id"]] }).to eq [
          { "user_id" => @student1.id, "assignment_id" => @assignment1.id, "score" => 15 },
          { "user_id" => @student1.id, "assignment_id" => @assignment2.id, "score" => 25 },
          { "user_id" => @student2.id, "assignment_id" => @assignment1.id, "score" => 10 },
          { "user_id" => @student2.id, "assignment_id" => @assignment2.id, "score" => 20 }
        ]
      end

      context "observer that is a student" do
        before :once do
          @course.enroll_student(@observer, allow_multiple_enrollments: true).accept!
          submit_homework(@assignment1, @observer)
          @assignment1.grade_student(@observer, grade: 5, grader: @teacher)
        end

        it "allows an observer that is a student to view his own and his observees submissions" do
          @user = @observer
          json = api_call(:get,
                          "/api/v1/courses/#{@course.id}/students/submissions",
                          { controller: "submissions_api",
                            action: "for_students",
                            format: "json",
                            course_id: @course.to_param },
                          { student_ids: [@student1.id, @observer.id] })
          expect(json.map { |entry| entry.slice("user_id", "assignment_id", "score") }.sort_by { |entry| [entry["user_id"], entry["assignment_id"]] }).to eq [
            { "user_id" => @student1.id, "assignment_id" => @assignment1.id, "score" => 15 },
            { "user_id" => @student1.id, "assignment_id" => @assignment2.id, "score" => 25 },
            { "user_id" => @observer.id, "assignment_id" => @assignment1.id, "score" => 5 },
            { "user_id" => @observer.id, "assignment_id" => @assignment2.id, "score" => nil }
          ]
        end

        it "allows an observer that is a student to view his own and his observees submissions via student_ids[]=all" do
          @user = @observer
          json = api_call(:get,
                          "/api/v1/courses/#{@course.id}/students/submissions",
                          { controller: "submissions_api",
                            action: "for_students",
                            format: "json",
                            course_id: @course.to_param },
                          { student_ids: ["all"] })
          expect(json.map { |entry| entry.slice("user_id", "assignment_id", "score") }.sort_by { |entry| [entry["user_id"], entry["assignment_id"]] }).to eq [
            { "user_id" => @student1.id, "assignment_id" => @assignment1.id, "score" => 15 },
            { "user_id" => @student1.id, "assignment_id" => @assignment2.id, "score" => 25 },
            { "user_id" => @student2.id, "assignment_id" => @assignment1.id, "score" => 10 },
            { "user_id" => @student2.id, "assignment_id" => @assignment2.id, "score" => 20 },
            { "user_id" => @observer.id, "assignment_id" => @assignment1.id, "score" => 5 },
            { "user_id" => @observer.id, "assignment_id" => @assignment2.id, "score" => nil }
          ]
        end
      end

      it "allows an observer to view observed students' submissions (grouped)" do
        @user = @observer
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/students/submissions.json?student_ids[]=#{@student1.id}&student_ids[]=#{@student2.id}&grouped=1",
                        { controller: "submissions_api",
                          action: "for_students",
                          format: "json",
                          course_id: @course.to_param,
                          student_ids: [@student1.to_param, @student2.to_param],
                          grouped: "1" })
        expect(json.size).to eq 2
        expect(json.pluck("user_id").sort).to eq [@student1.id, @student2.id]
      end

      it "does not allow an observer to view non-observed students' submissions" do
        student3 = student_in_course(active_all: true).user
        @user = @observer
        api_call(:get,
                 "/api/v1/courses/#{@course.id}/students/submissions",
                 { controller: "submissions_api",
                   action: "for_students",
                   format: "json",
                   course_id: @course.to_param },
                 { student_ids: [@student1.id, @student2.id, student3.id] },
                 {},
                 { expected_status: 401 })
      end

      it "does not work with a non-active ObserverEnrollment" do
        @observer.enrollments.first.conclude
        @user = @observer
        api_call(:get,
                 "/api/v1/courses/#{@course.id}/students/submissions",
                 { controller: "submissions_api",
                   action: "for_students",
                   format: "json",
                   course_id: @course.to_param },
                 { student_ids: [@student1.id, @student2.id] },
                 {},
                 { expected_status: 401 })
      end
    end

    context "logged out user" do
      it "renders api unauthenticated" do
        @user = nil
        api_call(:get,
                 "/api/v1/courses/#{@course.id}/students/submissions",
                 { controller: "submissions_api",
                   action: "for_students",
                   format: "json",
                   course_id: @course.to_param },
                 { student_ids: [@student1.id, @student2.id] },
                 {},
                 { expected_status: 401 })
      end
    end
  end

  describe "#update_anonymous" do
    before :once do
      student_in_course(active_all: true)
      teacher_in_course(active_all: true)
      @assignment = @course.assignments.create!(
        title: "assignment1",
        anonymous_grading: true,
        grading_type: "letter_grade",
        points_possible: 15
      )
    end

    it "fetches the submission using the provided anonymous_id" do
      submission = @assignment.submission_for_student(@student)

      expect do
        api_call(
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/anonymous_submissions/#{submission.anonymous_id}.json",
          {
            controller: "submissions_api",
            action: "update_anonymous",
            format: "json",
            course_id: @course.id.to_s,
            assignment_id: @assignment.id.to_s,
            anonymous_id: submission.anonymous_id.to_s
          },
          {
            submission: { posted_grade: "B" }
          }
        )
      end.to change {
        submission.reload.grade
      }.from(nil).to("B")
    end

    it "anonymizes the results" do
      submission = @assignment.submission_for_student(@student)
      submission.submission_comments.create!(author: @student, comment: "hi")

      json = api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/anonymous_submissions/#{submission.anonymous_id}.json",
        {
          controller: "submissions_api",
          action: "update_anonymous",
          format: "json",
          course_id: @course.id.to_s,
          assignment_id: @assignment.id.to_s,
          anonymous_id: submission.anonymous_id.to_s
        },
        {
          submission: { posted_grade: "B" }
        }
      )

      aggregate_failures do
        expect(json).not_to have_key "user_id"
        expect(json["anonymous_id"]).to eq submission.anonymous_id
        expect(json.dig("all_submissions", 0)).not_to have_key "user_id"
        expect(json.dig("all_submissions", 0, "anonymous_id")).to eq submission.anonymous_id
        expect(json.dig("submission_comments", 0, "author_id")).to be_nil
        expect(json.dig("submission_comments", 0, "author_name")).to eq "Anonymous User"
      end
    end

    it "handles updating the submission sticker" do
      submission = @assignment.submission_for_student(@student)
      expect do
        api_call(
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/anonymous_submissions/#{submission.anonymous_id}.json",
          {
            controller: "submissions_api",
            action: "update_anonymous",
            format: "json",
            course_id: @course.id.to_s,
            assignment_id: @assignment.id.to_s,
            anonymous_id: submission.anonymous_id.to_s
          },
          {
            submission: { sticker: "trophy" }
          }
        )
      end.to change {
        submission.reload.sticker
      }.from(nil).to("trophy")
    end
  end

  describe "#update" do
    before :once do
      student_in_course(active_all: true)
      teacher_in_course(active_all: true)
      @assignment = @course.assignments.create!(
        title: "assignment1",
        grading_type: "letter_grade",
        points_possible: 15
      )
    end

    it "allows grading a student that has not submitted" do
      json = api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
        {
          controller: "submissions_api",
          action: "update",
          format: "json",
          course_id: @course.id.to_s,
          assignment_id: @assignment.id.to_s,
          user_id: @student.id.to_s
        },
        {
          submission: {
            posted_grade: "B"
          },
        }
      )

      expect(Submission.count).to eq 1
      expect(json["grade"]).to eq "B"
      expect(json["score"]).to eq 12.9
    end

    it "allows grading an assigned student whose placeholder submission object has not yet been created" do
      # This simulates a scenario where the delayed job to create the
      # assigned student's submission has not yet completed
      @assignment.submissions.find_by(user: @student).destroy
      json = api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
        {
          controller: "submissions_api",
          action: "update",
          format: "json",
          course_id: @course.id.to_s,
          assignment_id: @assignment.id.to_s,
          user_id: @student.id.to_s
        },
        {
          submission: {
            posted_grade: "B"
          },
        }
      )
      expect(@assignment.reload.submissions.where(user: @student).exists?).to be true
      expect(json["grade"]).to eq "B"
      expect(json["score"]).to eq 12.9
    end

    it "allows grading an assigned student without visibility" do
      @course.enrollments.find_by(user: @student).deactivate
      json = api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
        {
          controller: "submissions_api",
          action: "update",
          format: "json",
          course_id: @course.id.to_s,
          assignment_id: @assignment.id.to_s,
          user_id: @student.id.to_s
        },
        {
          submission: {
            posted_grade: "B"
          },
        }
      )
      expect(json["grade"]).to eq "B"
      expect(json["score"]).to eq 12.9
    end

    it "doesn't allow grading a deleted submission" do
      submission = @assignment.submissions.find_by(user: @student)
      submission.destroy

      api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
        {
          controller: "submissions_api",
          action: "update",
          format: "json",
          course_id: @course.id.to_s,
          assignment_id: @assignment.id.to_s,
          user_id: @student.id.to_s
        },
        {
          submission: {
            posted_grade: "B"
          },
        },
        {
          expected_status: :unauthorized
        }
      )

      expect(submission.score).to be_nil
      expect(submission.grade).to be_nil
    end

    it "can excuse assignments" do
      json = api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
        {
          controller: "submissions_api",
          action: "update",
          format: "json",
          course_id: @course.id.to_s,
          assignment_id: @assignment.id.to_s,
          user_id: @student.id.to_s
        },
        {
          submission: {
            excuse: "1"
          }
        }
      )

      submission = @assignment.submission_for_student(@student)
      expect(submission).to be_excused
      expect(json["excused"]).to be true
    end

    it "can unexcuse assignments" do
      @assignment.grade_student(@student, excuse: true, grader: @teacher)
      submission = @assignment.submission_for_student(@student)
      expect(submission).to be_excused

      json = api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
        {
          controller: "submissions_api",
          action: "update",
          format: "json",
          course_id: @course.id.to_s,
          assignment_id: @assignment.id.to_s,
          user_id: @student.id.to_s
        },
        {
          submission: { excuse: "0" }
        }
      )

      expect(submission.reload).not_to be_excused
      expect(json["excused"]).to be false
    end

    it "sets the submission grader to the current user when setting late_policy_status" do
      submission = @assignment.submission_for_student(@student)
      submission.update!(grader: nil)

      api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
        {
          controller: "submissions_api",
          action: "update",
          format: "json",
          course_id: @course.id.to_s,
          assignment_id: @assignment.id.to_s,
          user_id: @student.id.to_s
        },
        {
          submission: { late_policy_status: "missing" }
        }
      )

      expect(submission.reload.grader_id).to be @teacher.id
    end

    it "creates a new submission version when setting late_policy_status results in a different grade" do
      submission = @assignment.submission_for_student(@student)
      # The first grade given to a submission doesn't result in a new version.
      @assignment.grade_student(@student, score: 1, grader: @teacher)

      expect do
        api_call(
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
          {
            controller: "submissions_api",
            action: "update",
            format: "json",
            course_id: @course.id.to_s,
            assignment_id: @assignment.id.to_s,
            user_id: @student.id.to_s
          },
          {
            submission: { late_policy_status: "missing" }
          }
        )
      end.to change {
        submission.reload.versions.count
      }.by(1)
    end

    it "setting late_policy_status and grade in same request do not create two versions" do
      submission = @assignment.submission_for_student(@student)
      # The first grade given to a submission doesn't result in a new version.
      @assignment.grade_student(@student, score: 1, grader: @teacher)

      expect do
        api_call(
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
          {
            controller: "submissions_api",
            action: "update",
            format: "json",
            course_id: @course.id.to_s,
            assignment_id: @assignment.id.to_s,
            user_id: @student.id.to_s
          },
          {
            submission: { late_policy_status: "missing", posted_grade: "1" }
          }
        )
      end.to change {
        submission.reload.versions.count
      }.by(1)
    end

    describe "checkpointed discussions" do
      before do
        @course.root_account.enable_feature!(:discussion_checkpoints)
        assignment = @course.assignments.create!(has_sub_assignments: true)
        assignment.sub_assignments.create!(context: @course, sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC, due_at: 2.days.from_now)
        assignment.sub_assignments.create!(context: @course, sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY, due_at: 3.days.from_now)
        @topic = @course.discussion_topics.create!(assignment:, reply_to_entry_required_count: 1)
      end

      let(:api_call_args) do
        [
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{@topic.assignment_id}/submissions/#{@student.id}.json",
          {
            controller: "submissions_api",
            action: "update",
            format: "json",
            course_id: @course.id.to_s,
            assignment_id: @topic.assignment_id.to_s,
            user_id: @student.id.to_s
          }
        ]
      end

      let(:reply_to_topic_submission) do
        @topic.reply_to_topic_checkpoint.submissions.find_by(user: @student)
      end

      it "supports grading checkpoints" do
        api_call(
          *api_call_args,
          submission: { posted_grade: 10 },
          sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC
        )
        expect(response).to be_successful
        expect(reply_to_topic_submission.score).to eq 10
      end

      it "raises an error if no sub assignment tag is provided" do
        api_call(
          *api_call_args,
          submission: { posted_grade: 10 }
        )
        expect(response).to have_http_status :bad_request
        expect(json_parse.fetch("error")).to eq "Must provide a valid sub assignment tag when grading checkpointed discussions"
      end

      it "ignores checkpoints when the feature flag is disabled" do
        @course.root_account.disable_feature!(:discussion_checkpoints)
        api_call(
          *api_call_args,
          submission: { posted_grade: 10 },
          sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC
        )
        expect(response).to be_successful
        expect(reply_to_topic_submission.score).to be_nil
        expect(@topic.assignment.submissions.find_by(user: @student).score).to eq 10
      end
    end

    describe "stickers" do
      let(:update_sticker_api_call) do
        api_call(
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
          {
            controller: "submissions_api",
            action: "update",
            format: "json",
            course_id: @course.id.to_s,
            assignment_id: @assignment.id.to_s,
            user_id: @student.id.to_s
          },
          {
            submission: { sticker: "trophy" }
          }
        )
      end

      it "handles updating the submission sticker" do
        submission = @assignment.submission_for_student(@student)
        expect { update_sticker_api_call }.to change {
          submission.reload.sticker
        }.from(nil).to("trophy")
      end

      it "does not update the grader when the sticker is set" do
        submission = @assignment.submission_for_student(@student)
        expect { update_sticker_api_call }.not_to change {
          submission.reload.grader
        }.from(nil)
      end

      context "group assignments" do
        before do
          @student2 = @course.enroll_student(User.create!, enrollment_state: :active).user
          group_category = @course.group_categories.create!(name: "Category")
          group = @course.groups.create!(name: "Group", group_category:)
          group.add_user(@student, "accepted")
          group.add_user(@student2, "accepted")
          @assignment.update!(group_category:, grade_group_students_individually: false)
        end

        let(:student_submissions) do
          @assignment.submissions.where(user: [@student, @student2])
        end

        it "assigns the sticker to all group members" do
          expect { update_sticker_api_call }.to change {
            student_submissions.pluck(:user_id, :sticker).to_h
          }
            .from({ @student.id => nil, @student2.id => nil })
            .to({ @student.id => "trophy", @student2.id => "trophy" })
        end

        it "assigns the sticker to only one student if 'grade group students individually' is set" do
          @assignment.update!(grade_group_students_individually: true)
          expect { update_sticker_api_call }.to change {
            student_submissions.pluck(:user_id, :sticker).to_h
          }
            .from({ @student.id => nil, @student2.id => nil })
            .to({ @student.id => "trophy", @student2.id => nil })
        end
      end
    end

    context "grading scheme with numerics in names" do
      before do
        @standard = @course.grading_standards.create!(title: "course standard", standard_data: { a: { name: "5", value: "90" }, b: { name: "4", value: "70" }, c: { name: "3", value: "50" }, d: { name: "Revision required/Komplettering", value: "25" }, e: { name: "U", value: "0" } })
        @assignment.update_attribute :grading_standard, @standard
        api_call(:put,
                 "/api/v1/courses/#{@course.id}",
                 { controller: "courses", action: "update", format: "json", id: @course.to_param },
                 course: { grading_standard_id: @standard.id })
        @course.reload
      end

      it "can grade when it matches grading name and enter grades is set to points" do
        json = api_call(
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
          {
            controller: "submissions_api",
            action: "update",
            format: "json",
            course_id: @course.id.to_s,
            assignment_id: @assignment.id.to_s,
            user_id: @student.id.to_s
          },
          {
            submission: {
              posted_grade: 5
            },
            prefer_points_over_scheme: true
          }
        )

        expect(json["grade"]).to eq "Revision required/Komplettering"
        expect(json["score"]).to eq 5.0
      end

      it "can grade when it matches grading scheme name" do
        json = api_call(
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
          {
            controller: "submissions_api",
            action: "update",
            format: "json",
            course_id: @course.id.to_s,
            assignment_id: @assignment.id.to_s,
            user_id: @student.id.to_s
          },
          {
            submission: {
              posted_grade: 5
            }
          }
        )

        expect(json["grade"]).to eq "5"
        expect(json["score"]).to eq @assignment.points_possible
      end

      it "can grade when it does not match grading scheme name" do
        # grading_type = "letter_grade"
        json = api_call(
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
          {
            controller: "submissions_api",
            action: "update",
            format: "json",
            course_id: @course.id.to_s,
            assignment_id: @assignment.id.to_s,
            user_id: @student.id.to_s
          },
          {
            submission: {
              posted_grade: 9
            }
          }
        )

        expect(json["grade"]).to eq "3"
        expect(json["score"]).to eq 9.0
      end
    end

    context "group assignments" do
      before do
        @admin = account_admin_user(account: @course.root_account)
        @custom_status = @course.root_account.custom_grade_statuses.create!(
          color: "#BBB",
          created_by: @admin,
          name: "yolo"
        )
        @student2 = @course.enroll_student(User.create!, enrollment_state: :active).user
        group_category = @course.group_categories.create!(name: "Category")
        group = @course.groups.create!(name: "Group", group_category:)
        group.users = [@student, @student2]
        @assignment.update!(group_category:, grade_group_students_individually: false)
      end

      it "can set late policy status on a group member's submission" do
        api_call(
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
          {
            controller: "submissions_api",
            action: "update",
            format: "json",
            course_id: @course.id.to_s,
            assignment_id: @assignment.id.to_s,
            user_id: @student.id.to_s
          },
          {
            submission: {
              late_policy_status: "missing"
            }
          }
        )

        submission = @assignment.submission_for_student(@student2)
        expect(submission.late_policy_status).to eq "missing"
      end

      it "can set a custom status on a group member's submission" do
        api_call(
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
          {
            controller: "submissions_api",
            action: "update",
            format: "json",
            course_id: @course.id.to_s,
            assignment_id: @assignment.id.to_s,
            user_id: @student.id.to_s
          },
          {
            submission: {
              custom_grade_status_id: @custom_status.id.to_s
            }
          }
        )

        submission = @assignment.submission_for_student(@student2)
        expect(submission.custom_grade_status_id).to eq @custom_status.id
      end

      it "does not set a custom status for the whole group when assignment is graded individually" do
        @assignment.update!(grade_group_students_individually: true)
        api_call(
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
          {
            controller: "submissions_api",
            action: "update",
            format: "json",
            course_id: @course.id.to_s,
            assignment_id: @assignment.id.to_s,
            user_id: @student.id.to_s
          },
          {
            submission: {
              custom_grade_status_id: @custom_status.id.to_s
            }
          }
        )

        first_submission = @assignment.submission_for_student(@student)
        expect(first_submission.custom_grade_status_id).to eq @custom_status.id
        second_submission = @assignment.submission_for_student(@student2)
        expect(second_submission.custom_grade_status_id).to be_nil
      end

      it "can set seconds_late_override on a group member's submission" do
        seconds_late_override = 3.days
        api_call(
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
          {
            controller: "submissions_api",
            action: "update",
            format: "json",
            course_id: @course.id.to_s,
            assignment_id: @assignment.id.to_s,
            user_id: @student.id.to_s
          },
          {
            submission: {
              late_policy_status: "late",
              seconds_late_override:
            }
          }
        )

        submission = @assignment.submission_for_student(@student2)
        expect(submission.seconds_late).to eq seconds_late_override.to_i
      end

      it "does not excuse the whole group when excusing one group member" do
        api_call(
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
          {
            controller: "submissions_api",
            action: "update",
            format: "json",
            course_id: @course.id.to_s,
            assignment_id: @assignment.id.to_s,
            user_id: @student.id.to_s
          },
          {
            submission: {
              excuse: "1",
              late_policy_status: "missing"
            }
          }
        )

        submission = @assignment.submission_for_student(@student2)
        expect(submission).not_to be_excused
      end

      it "does not set late policy status for the whole group when assignment grades individually" do
        @assignment.update!(grade_group_students_individually: true)
        api_call(
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
          {
            controller: "submissions_api",
            action: "update",
            format: "json",
            course_id: @course.id.to_s,
            assignment_id: @assignment.id.to_s,
            user_id: @student.id.to_s
          },
          {
            submission: {
              late_policy_status: "missing"
            }
          }
        )

        submission = @assignment.submission_for_student(@student2)
        expect(submission.late_policy_status).not_to eq "missing"
      end
    end

    it "can set late policy status on a submission" do
      json = api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
        {
          controller: "submissions_api",
          action: "update",
          format: "json",
          course_id: @course.id.to_s,
          assignment_id: @assignment.id.to_s,
          user_id: @student.id.to_s
        },
        {
          submission: {
            late_policy_status: "missing"
          }
        }
      )

      submission = @assignment.submission_for_student(@student)
      expect(submission.late_policy_status).to eq "missing"
      expect(json["late_policy_status"]).to eq "missing"
    end

    it "can set a custom status on a submission" do
      admin = account_admin_user(account: @course.root_account)
      custom_status = @course.root_account.custom_grade_statuses.create!(
        color: "#BBB",
        created_by: admin,
        name: "yolo"
      )
      submission = @assignment.submission_for_student(@student)
      submission.update!(late_policy_status: "missing")
      api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
        {
          controller: "submissions_api",
          action: "update",
          format: "json",
          course_id: @course.id.to_s,
          assignment_id: @assignment.id.to_s,
          user_id: @student.id.to_s
        },
        {
          submission: {
            custom_grade_status_id: custom_status.id.to_s
          }
        }
      )

      submission.reload
      expect(submission.late_policy_status).to be_nil
      expect(submission.custom_grade_status_id).to eq custom_status.id
    end

    it "can set seconds_late_override on a submission along with the late_policy_status of late" do
      seconds_late_override = 3.days
      json = api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
        {
          controller: "submissions_api",
          action: "update",
          format: "json",
          course_id: @course.id.to_s,
          assignment_id: @assignment.id.to_s,
          user_id: @student.id.to_s
        },
        {
          submission: {
            late_policy_status: "late",
            seconds_late_override:
          }
        }
      )

      submission = @assignment.submission_for_student(@student)
      expect(submission.late_policy_status).to eq "late"
      expect(submission.seconds_late).to eql seconds_late_override.to_i
      expect(json["late_policy_status"]).to eq "late"
      expect(json["seconds_late"]).to eql seconds_late_override.to_i
    end

    it "can set seconds_late_override on a submission that has a late_policy_status of 'late'" do
      @assignment.grade_student(@student, grade: 5, grader: @teacher)
      @assignment.submission_for_student(@student).update!(late_policy_status: "late")
      seconds_late_override = 3.days
      json = api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
        {
          controller: "submissions_api",
          action: "update",
          format: "json",
          course_id: @course.id.to_s,
          assignment_id: @assignment.id.to_s,
          user_id: @student.id.to_s
        },
        {
          submission: { seconds_late_override: }
        }
      )

      expect(json["seconds_late"]).to eql seconds_late_override.to_i
    end

    it "ignores seconds_late_override if late_policy_status is not late" do
      seconds_late_override = 3.days
      json = api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
        {
          controller: "submissions_api",
          action: "update",
          format: "json",
          course_id: @course.id.to_s,
          assignment_id: @assignment.id.to_s,
          user_id: @student.id.to_s
        },
        {
          submission: {
            late_policy_status: "missing",
            seconds_late_override:
          }
        }
      )

      submission = @assignment.submission_for_student(@student)
      expect(submission.late_policy_status).to eq "missing"
      expect(submission.seconds_late).to be 0
      expect(json["late_policy_status"]).to eq "missing"
      expect(json["seconds_late"]).to be 0
    end

    it "can clear late_policy_status on a submission" do
      @assignment.submissions.find_or_create_by!(user: @student).update!(
        late_policy_status: "late",
        seconds_late_override: 3.days
      )
      json = api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
        {
          controller: "submissions_api",
          action: "update",
          format: "json",
          course_id: @course.id.to_s,
          assignment_id: @assignment.id.to_s,
          user_id: @student.id.to_s
        },
        {
          submission: {
            late_policy_status: nil
          }
        }
      )

      submission = @assignment.submission_for_student(@student)
      expect(submission.late_policy_status).to be_nil
      expect(submission.seconds_late).to be 0
      expect(json["late_policy_status"]).to be_nil
      expect(json["seconds_late"]).to be 0
    end

    it "creates a provisional grade and comment" do
      @assignment.moderated_grading = true
      @assignment.grader_count = 2
      @assignment.final_grader = @teacher
      @assignment.save!
      submission = @assignment.submit_homework(@student, body: "what")

      json = api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
        {
          controller: "submissions_api",
          action: "update",
          format: "json",
          course_id: @course.id.to_s,
          assignment_id: @assignment.id.to_s,
          user_id: @student.id.to_s
        },
        {
          submission: {
            posted_grade: "100",
            provisional: true
          },
          comment: {
            text_comment: "strong work"
          }
        }
      )

      submission.reload
      expect(submission.workflow_state).to eq "submitted"
      expect(submission.score).to be_nil
      expect(submission.grade).to be_nil
      expect(submission.submission_comments.count).to eq 0

      pg = submission.provisional_grades.last
      expect(pg.score).to eq 100
      expect(pg.submission_comments.first.comment).to eq "strong work"

      expect(json["provisional_grades"].first["score"]).to eq 100
    end

    it "creates a provisional grade and comment when no submission exists" do
      @assignment.moderated_grading = true
      @assignment.grader_count = 2
      @assignment.final_grader = @teacher
      @assignment.save!

      json = api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
        {
          controller: "submissions_api",
          action: "update",
          format: "json",
          course_id: @course.id.to_s,
          assignment_id: @assignment.id.to_s,
          user_id: @student.id.to_s
        },
        {
          submission: {
            posted_grade: "0",
            provisional: true
          },
          comment: {
            text_comment: "you slacker"
          }
        }
      )

      sub = @assignment.submissions.where(user_id: @student).last
      expect(sub.workflow_state).to eq "unsubmitted"
      expect(sub.score).to be_nil
      expect(sub.grade).to be_nil
      expect(sub.submission_comments.count).to eq 0

      pg = sub.provisional_grades.last
      expect(pg.score).to eq 0
      expect(pg.submission_comments.first.comment).to eq "you slacker"

      expect(json["provisional_grades"].first["score"]).to eq 0
    end

    it "returns an error trying to grade a student not enrolled in the course" do
      @student.enrollments.first.conclude
      a1 = @course.assignments.create!(
        title: "assignment1",
        grading_type: "points",
        points_possible: 15
      )
      json = api_call(:put,
                      "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{@student.id}.json",
                      { controller: "submissions_api",
                        action: "update",
                        format: "json",
                        course_id: @course.id.to_s,
                        assignment_id: a1.id.to_s,
                        user_id: @student.id.to_s },
                      { submission: { posted_grade: 10 } },
                      {},
                      { expected_status: 400 })
      expect(json["error"]).not_to be_nil
    end

    it "allows a LTI launch URL to be assigned" do
      json = api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
        {
          controller: "submissions_api",
          action: "update",
          format: "json",
          course_id: @course.id.to_s,
          assignment_id: @assignment.id.to_s,
          user_id: @student.id.to_s
        },
        {
          submission: {
            posted_grade: "B",
            submission_type: "basic_lti_launch",
            url: "http://example.test"
          },
        }
      )

      expected_url = "http://www.example.com/courses/#{@course.id}/external_tools/retrieve?assignment_id=#{@assignment.id}&url=http%3A%2F%2Fexample.test"
      expect(Submission.count).to eq 1
      expect(json["submission_type"]).to eql "basic_lti_launch"
      expect(json["url"]).to eq expected_url
    end

    it "does not allow a submission to be overwritten if type is a non-lti type" do
      @assignment.submit_homework(@student, body: "what")
      json = api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
        {
          controller: "submissions_api",
          action: "update",
          format: "json",
          course_id: @course.id.to_s,
          assignment_id: @assignment.id.to_s,
          user_id: @student.id.to_s
        },
        {
          submission: {
            posted_grade: "B",
            submission_type: "basic_lti_launch",
            url: "http://example.test"
          },
        }
      )

      expect(Submission.count).to eq 1
      expect(json["submission_type"]).to eql "online_text_entry"
      expect(json["url"]).to be_nil
    end
  end

  it "allows posting grade by sis id" do
    student = user_with_pseudonym(active_all: true)
    course_with_teacher(active_all: true)
    @course.enroll_student(student).accept!
    @course.update_attribute(:sis_source_id, "my-course-id")
    student.pseudonym.update_attribute(:sis_user_id, "my-user-id")
    a1 = @course.assignments.create!(title: "assignment1", grading_type: "letter_grade", points_possible: 15)

    json = api_call(:put,
                    "/api/v1/courses/sis_course_id:my-course-id/assignments/#{a1.id}/submissions/sis_user_id:my-user-id.json",
                    { controller: "submissions_api",
                      action: "update",
                      format: "json",
                      course_id: "sis_course_id:my-course-id",
                      assignment_id: a1.id.to_s,
                      user_id: "sis_user_id:my-user-id" },
                    { submission: { posted_grade: "B" } })

    expect(Submission.count).to eq 1
    @submission = Submission.first

    expect(json["grade"]).to eq "B"
    expect(json["score"]).to eq 12.9
  end

  it "allows commenting by a student without trying to grade" do
    course_with_teacher(active_all: true)
    student = user_factory(active_all: true)
    @course.enroll_student(student).accept!
    a1 = @course.assignments.create!(title: "assignment1", grading_type: "letter_grade", points_possible: 15)

    # since student is the most recently created user, @user = student, so this
    # call will happen as student
    api_call(:put,
             "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student.id}.json",
             { controller: "submissions_api",
               action: "update",
               format: "json",
               course_id: @course.id.to_s,
               assignment_id: a1.id.to_s,
               user_id: student.id.to_s },
             { comment: { text_comment: "witty remark" } })

    expect(Submission.count).to eq 1
    @submission = Submission.first
    expect(@submission.submission_comments.size).to eq 1
    comment = @submission.submission_comments.first
    expect(comment.comment).to eq "witty remark"
    expect(comment.author).to eq student
  end

  it "does not allow grading by a student" do
    course_with_teacher(active_all: true)
    student = user_factory(active_all: true)
    @course.enroll_student(student).accept!
    a1 = @course.assignments.create!(title: "assignment1", grading_type: "letter_grade", points_possible: 15)

    # since student is the most recently created user, @user = student, so this
    # call will happen as student
    raw_api_call(:put,
                 "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student.id}.json",
                 { controller: "submissions_api",
                   action: "update",
                   format: "json",
                   course_id: @course.id.to_s,
                   assignment_id: a1.id.to_s,
                   user_id: student.id.to_s },
                 { comment: { text_comment: "witty remark" },
                   submission: { posted_grade: "B" } })
    assert_status(401)
  end

  it "does not allow grading of a student not assigned to the assignment" do
    student = user_factory(active_all: true)
    student2 = user_factory(active_all: true)
    course_with_teacher(active_all: true)
    @course.enroll_student(student).accept!
    @course.enroll_student(student2).accept!
    a1 = @course.assignments.create!(only_visible_to_overrides: true, points_possible: 10)
    create_adhoc_override_for_assignment(a1, student, due_at: 1.day.from_now)

    raw_api_call(:put,
                 "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student2.id}.json",
                 { controller: "submissions_api",
                   action: "update",
                   format: "json",
                   course_id: @course.id.to_s,
                   assignment_id: a1.id.to_s,
                   user_id: student2.id.to_s },
                 { comment: { text_comment: "witty remark" },
                   submission: { posted_grade: "B" } })
    assert_status(401)
  end

  it "does not allow rubricking by a student" do
    course_with_teacher(active_all: true)
    student = user_factory(active_all: true)
    @course.enroll_student(student).accept!
    a1 = @course.assignments.create!(title: "assignment1", grading_type: "letter_grade", points_possible: 15)

    # since student is the most recently created user, @user = student, so this
    # call will happen as student
    raw_api_call(:put,
                 "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student.id}.json",
                 { controller: "submissions_api",
                   action: "update",
                   format: "json",
                   course_id: @course.id.to_s,
                   assignment_id: a1.id.to_s,
                   user_id: student.id.to_s },
                 { comment: { text_comment: "witty remark" },
                   rubric_assessment: { criteria: { points: 5 } } })
    assert_status(401)
  end

  context "moderated grading" do
    before do
      student_in_course(active_all: true)
      teacher_in_course(active_all: true)
      @assignment = @course.assignments.create!(
        title: "assignment1",
        moderated_grading: true,
        grades_published_at: nil,
        grader_count: 2,
        final_grader: @teacher
      )
    end

    it "allows posting grades of a non moderated assignment" do
      @assignment.update_attribute(:moderated_grading, false)
      api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
        {
          controller: "submissions_api",
          action: "update",
          format: "json",
          course_id: @course.id.to_s,
          assignment_id: @assignment.id.to_s,
          user_id: @student.id.to_s
        },
        {
          submission: {
            posted_grade: "B"
          },
        }
      )
      assert_status(200)
    end

    it "allows posting grades of an assignment whose grades have been published" do
      @assignment.update_attribute(:grades_published_at, Time.zone.now)
      api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
        {
          controller: "submissions_api",
          action: "update",
          format: "json",
          course_id: @course.id.to_s,
          assignment_id: @assignment.id.to_s,
          user_id: @student.id.to_s
        },
        {
          submission: {
            posted_grade: "B"
          },
        }
      )
      assert_status(200)
    end

    it "does not allow posting grades of a moderated assignment whose grades have not been published" do
      api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
        {
          controller: "submissions_api",
          action: "update",
          format: "json",
          course_id: @course.id.to_s,
          assignment_id: @assignment.id.to_s,
          user_id: @student.id.to_s
        },
        {
          submission: {
            posted_grade: "B"
          },
        }
      )
      assert_status(401)
    end

    it "allows posting provisional grades of a moderated assignment whose grades have not been published" do
      api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
        {
          controller: "submissions_api",
          action: "update",
          format: "json",
          course_id: @course.id.to_s,
          assignment_id: @assignment.id.to_s,
          user_id: @student.id.to_s
        },
        {
          submission: {
            posted_grade: "100",
            provisional: true
          }
        }
      )
      assert_status(200)
    end
  end

  it "does not return submissions for no-longer-enrolled students" do
    student = user_factory(active_all: true)
    course_with_teacher(active_all: true)
    enrollment = @course.enroll_student(student)
    enrollment.accept!
    assignment = @course.assignments.create!(title: "assignment1", grading_type: "letter_grade", points_possible: 15)
    submit_homework(assignment, student)

    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}/submissions.json",
                    { controller: "submissions_api",
                      action: "index",
                      format: "json",
                      course_id: @course.id.to_s,
                      assignment_id: assignment.id.to_s })
    expect(json.length).to eq 1

    enrollment.destroy

    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}/submissions.json",
                    { controller: "submissions_api",
                      action: "index",
                      format: "json",
                      course_id: @course.id.to_s,
                      assignment_id: assignment.id.to_s })
    expect(json.length).to eq 0
  end

  it "allows updating the grade for an existing submission" do
    student = user_factory(active_all: true)
    course_with_teacher(active_all: true)
    @course.enroll_student(student).accept!
    a1 = @course.assignments.create!(title: "assignment1", grading_type: "letter_grade", points_possible: 15)
    submission = a1.find_or_create_submission(student)
    expect(submission).not_to be_new_record
    submission.grade = "A"
    submission.grader = @teacher
    submission.save!

    json = api_call(:put,
                    "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student.id}.json",
                    { controller: "submissions_api",
                      action: "update",
                      format: "json",
                      course_id: @course.id.to_s,
                      assignment_id: a1.id.to_s,
                      user_id: student.id.to_s },
                    { submission: { posted_grade: "B" } })

    expect(Submission.count).to eq 1
    @submission = Submission.first
    expect(submission.id).to eq @submission.id

    expect(json["grade"]).to eq "B"
    expect(json["score"]).to eq 12.9
  end

  it "hides comments when the assignment posts manually and submission is not posted" do
    course = Course.create!
    assignment = course.assignments.create!
    student = course.enroll_student(User.create!, enrollment_state: :active).user
    teacher = course.enroll_teacher(User.create!, enrollment_state: :active).user
    submission = assignment.submissions.find_by!(user: student)
    @user = teacher

    assignment.ensure_post_policy(post_manually: true)
    api_call(
      :put,
      "/api/v1/courses/#{course.id}/assignments/#{assignment.id}/submissions/#{student.id}",
      {
        controller: "submissions_api",
        action: "update",
        format: "json",
        course_id: course.to_param,
        assignment_id: assignment.to_param,
        user_id: student.to_param
      },
      { comment: { text_comment: "a comment!" } }
    )
    expect(submission.submission_comments.order("id DESC").first).to be_hidden
  end

  it "does not hide comments when the submission is already posted" do
    course = Course.create!
    assignment = course.assignments.create!
    student = course.enroll_student(User.create!, enrollment_state: :active).user
    teacher = course.enroll_teacher(User.create!, enrollment_state: :active).user
    submission = assignment.submissions.find_by!(user: student)
    @user = teacher

    submission.update!(posted_at: Time.zone.now)
    api_call(
      :put,
      "/api/v1/courses/#{course.id}/assignments/#{assignment.id}/submissions/#{student.id}",
      {
        controller: "submissions_api",
        action: "update",
        format: "json",
        course_id: course.to_param,
        assignment_id: assignment.to_param,
        user_id: student.to_param
      },
      { comment: { text_comment: "a comment!" } }
    )
    expect(submission.submission_comments.order("id DESC").first).not_to be_hidden
  end

  it "does not hide student comments on muted assignments" do
    course_with_teacher(active_all: true)
    student    = user_factory(active_all: true)
    assignment = @course.assignments.create!(title: "assignment")
    assignment.update_attribute(:muted, true)
    @user = student
    @course.enroll_student(student).accept!
    submission = assignment.find_or_create_submission(student)
    api_call(:put,
             "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}/submissions/#{student.id}",
             { controller: "submissions_api",
               action: "update",
               format: "json",
               course_id: @course.to_param,
               assignment_id: assignment.to_param,
               user_id: student.to_param },
             { comment: { text_comment: "hidden comment" } })
    expect(submission.submission_comments.order("id DESC").first).not_to be_hidden
  end

  it "allows submitting points" do
    submit_with_grade({ grading_type: "points", points_possible: 15 }, "13.2", 13.2, "13.2")
  end

  it "allows submitting points above points_possible (for extra credit)" do
    submit_with_grade({ grading_type: "points", points_possible: 15 }, "16", 16, "16")
  end

  it "allows submitting percent to a points assignment" do
    submit_with_grade({ grading_type: "points", points_possible: 15 }, "50%", 7.5, "7.5")
  end

  it "allows submitting percent" do
    submit_with_grade({ grading_type: "percent", points_possible: 10 }, "75%", 7.5, "75%")
  end

  it "allows submitting points to a percent assignment" do
    submit_with_grade({ grading_type: "percent", points_possible: 10 }, "5", 5, "50%")
  end

  it "allows submitting percent above points_possible (for extra credit)" do
    submit_with_grade({ grading_type: "percent", points_possible: 10 }, "105%", 10.5, "105%")
  end

  it "allows submitting letter_grade as a letter score" do
    submit_with_grade({ grading_type: "letter_grade", points_possible: 15 }, "B", 12.9, "B")
  end

  it "allows submitting letter_grade as a numeric score" do
    submit_with_grade({ grading_type: "letter_grade", points_possible: 15 }, "11.9", 11.9, "C+")
  end

  it "allows submitting letter_grade as a percentage score" do
    submit_with_grade({ grading_type: "letter_grade", points_possible: 15 }, "70%", 10.5, "C-")
  end

  it "rejects letter grades sent to a points assignment" do
    submit_with_grade({ grading_type: "points", points_possible: 15 }, "B-", nil, nil)
  end

  it "allows submitting pass_fail (pass)" do
    submit_with_grade({ grading_type: "pass_fail", points_possible: 12 }, "pass", 12, "complete")
  end

  it "allows submitting pass_fail (fail)" do
    submit_with_grade({ grading_type: "pass_fail", points_possible: 12 }, "fail", 0, "incomplete")
  end

  it "allows a points score for pass_fail, at full points" do
    submit_with_grade({ grading_type: "pass_fail", points_possible: 12 }, "12", 12, "complete")
  end

  it "allows a points score for pass_fail, at zero points" do
    submit_with_grade({ grading_type: "pass_fail", points_possible: 12 }, "0", 0, "incomplete")
  end

  it "allows a percentage score for pass_fail, at full points" do
    submit_with_grade({ grading_type: "pass_fail", points_possible: 12 }, "100%", 12, "complete")
  end

  it "rejects any other type of score for a pass_fail assignment" do
    submit_with_grade({ grading_type: "pass_fail", points_possible: 12 }, "50%", nil, nil)
  end

  it "sets complete for zero point assignments" do
    submit_with_grade({ grading_type: "pass_fail", points_possible: 0 }, "pass", 0, "complete")
  end

  def submit_with_grade(assignment_opts, param, score, grade)
    student = user_factory(active_all: true)
    course_with_teacher(active_all: true)
    @course.enroll_student(student).accept!
    a1 = @course.assignments.create!({ title: "assignment1" }.merge(assignment_opts))

    json = api_call(:put,
                    "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student.id}.json",
                    { controller: "submissions_api",
                      action: "update",
                      format: "json",
                      course_id: @course.id.to_s,
                      assignment_id: a1.id.to_s,
                      user_id: student.id.to_s },
                    { submission: { posted_grade: param } })

    expect(Submission.count).to eq 1
    @submission = Submission.first

    expect(json["score"]).to eq score
    expect(json["grade"]).to eq grade
  end

  context "posting rubric assessments" do
    before(:once) do
      @student = user_factory(active_all: true)
      course_with_teacher(active_all: true)
      @course.enroll_student(@student).accept!
      @a1 = @course.assignments.create!(title: "assignment1", grading_type: "points", points_possible: 12)
      rubric = rubric_model(user: @user, context: @course, data: larger_rubric_data)
      @rubric_association = @a1.create_rubric_association(
        rubric:,
        purpose: "grading",
        use_for_grading: true,
        context: @course
      )
    end

    it "allows posting a rubric assessment" do
      api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@a1.id}/submissions/#{@student.id}.json",
        { controller: "submissions_api",
          action: "update",
          format: "json",
          course_id: @course.id.to_s,
          assignment_id: @a1.id.to_s,
          user_id: @student.id.to_s },
        { rubric_assessment: { crit1: { points: 7 },
                               crit2: { points: 2, comments: "Rock on" } } }
      )

      expect(Submission.count).to eq 1
      @submission = Submission.first
      expect(@submission.user_id).to eq @student.id
      expect(@submission.score).to eq 9
      expect(@submission.rubric_assessment).not_to be_nil
      expect(@submission.rubric_assessment.data).to eq(
        [{ description: "B",
           criterion_id: "crit1",
           comments_enabled: true,
           points: 7,
           learning_outcome_id: nil,
           id: "rat2",
           comments: nil },
         { description: "Pass",
           criterion_id: "crit2",
           comments_enabled: true,
           points: 2,
           learning_outcome_id: nil,
           id: "rat1",
           comments: "Rock on",
           comments_html: "Rock on" }]
      )
    end

    it "does not allow posting a rubric assessment when the rubric association is soft-deleted" do
      @rubric_association.destroy
      api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@a1.id}/submissions/#{@student.id}.json",
        { controller: "submissions_api",
          action: "update",
          format: "json",
          course_id: @course.id.to_s,
          assignment_id: @a1.id.to_s,
          user_id: @student.id.to_s },
        { rubric_assessment: { crit1: { points: 7 },
                               crit2: { points: 2, comments: "Rock on" } } }
      )

      @submission = Submission.first
      expect(@submission.rubric_assessment).to be_nil
    end
  end

  it "validates the rubric assessment" do
    student = user_factory(active_all: true)
    course_with_teacher(active_all: true)
    @course.enroll_student(student).accept!
    a1 = @course.assignments.create!(title: "assignment1", grading_type: "points", points_possible: 12)
    rubric = rubric_model(user: @user,
                          context: @course,
                          data: larger_rubric_data)
    a1.create_rubric_association(rubric:, purpose: "grading", context: @course)

    json = api_call(:put,
                    "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student.id}.json",
                    { controller: "submissions_api",
                      action: "update",
                      format: "json",
                      course_id: @course.id.to_s,
                      assignment_id: a1.id.to_s,
                      user_id: student.id.to_s },
                    { rubric_assessment: { crit42: { points: 7 } } },
                    {},
                    { expected_status: 400 })

    expect(json["message"]).to eq "invalid rubric_assessment"
  end

  context "posting comments" do
    before do
      @student = user_factory(active_all: true)
      course_with_teacher(active_all: true)
      @course.enroll_student(@student).accept!
      @assignment = @course.assignments.create!(title: "assignment1", grading_type: "points", points_possible: 12)
      submit_homework(@assignment, @student)
    end

    it "allows posting a comment on a submission" do
      json = api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
        {
          controller: "submissions_api",
          action: "update",
          format: "json",
          course_id: @course.id.to_s,
          assignment_id: @assignment.id.to_s,
          user_id: @student.id.to_s
        },
        { comment: { text_comment: "ohai!" } }
      )

      expect(Submission.count).to eq 1
      @submission = Submission.first
      expect(json["submission_comments"].size).to eq 1
      expect(json["submission_comments"].first["comment"]).to eq "ohai!"
    end

    it "allows a comment to be associated with a submission attempt" do
      api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
        {
          controller: "submissions_api",
          action: "update",
          format: "json",
          course_id: @course.id.to_s,
          assignment_id: @assignment.id.to_s,
          user_id: @student.id.to_s
        },
        { comment: { text_comment: "ohai!", attempt: 1 } }
      )

      comment = SubmissionComment.find_by(author: @teacher, comment: "ohai!")
      expect(comment.attempt).to eq 1
    end
  end

  it "allows posting a group comment on a submission" do
    student1 = user_factory(active_all: true)
    student2 = user_factory(active_all: true)
    course_with_teacher(active_all: true)
    @course.enroll_student(student1).accept!
    @course.enroll_student(student2).accept!
    group_category = @course.group_categories.create(name: "Category")
    @group = @course.groups.create(name: "Group", group_category:, context: @course)
    @group.users = [student1, student2]
    @assignment = @course.assignments.create!(title: "assignment1", grading_type: "points", points_possible: 12, group_category:)
    submit_homework(@assignment, student1)

    json = api_call(:put,
                    "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{student1.id}.json",
                    { controller: "submissions_api",
                      action: "update",
                      format: "json",
                      course_id: @course.id.to_s,
                      assignment_id: @assignment.id.to_s,
                      user_id: student1.id.to_s },
                    { comment: { text_comment: "ohai!", group_comment: "1" } })
    expect(json["submission_comments"].size).to eq 1
    expect(json["submission_comments"].first["comment"]).to eq "ohai!"

    expect(Submission.count).to eq 2
    Submission.all.each do |submission|
      expect(submission.submission_comments.size).to be 1
      expect(submission.submission_comments.first.comment).to eql "ohai!"
    end
  end

  it "allows posting a media comment on a submission, given a kaltura id" do
    student = user_factory(active_all: true)
    course_with_teacher(active_all: true)
    @course.enroll_student(student).accept!
    @assignment = @course.assignments.create!(title: "assignment1", grading_type: "points", points_possible: 12)
    media_object(media_id: "1234", media_type: "audio")

    json = api_call(:put,
                    "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{student.id}.json",
                    { controller: "submissions_api",
                      action: "update",
                      format: "json",
                      course_id: @course.id.to_s,
                      assignment_id: @assignment.id.to_s,
                      user_id: student.id.to_s },
                    { comment: { media_comment_id: "1234", media_comment_type: "audio" } })

    expect(Submission.count).to eq 1
    @submission = Submission.first
    expect(json["submission_comments"].size).to eq 1
    comment = json["submission_comments"].first
    expect(comment["comment"]).to eq ""
    expect(comment["media_comment"]["url"]).to eq "http://www.example.com/users/#{@user.id}/media_download?entryId=1234&redirect=1&type=mp4"
    expect(comment["media_comment"]["content-type"]).to eq "audio/mp4"
  end

  it "allows commenting on an uncreated submission" do
    student = user_factory(active_all: true)
    course_with_teacher(active_all: true)
    @course.enroll_student(student).accept!
    a1 = @course.assignments.create!(title: "assignment1", grading_type: "letter_grade", points_possible: 15)

    api_call(:put,
             "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student.id}.json",
             { controller: "submissions_api",
               action: "update",
               format: "json",
               course_id: @course.id.to_s,
               assignment_id: a1.id.to_s,
               user_id: student.id.to_s },
             { comment: { text_comment: "Why U no submit" } })

    expect(Submission.count).to eq 1
    @submission = Submission.first

    comment = @submission.submission_comments.first
    expect(comment.comment).to eq "Why U no submit"
  end

  it "allows clearing out the current grade with a blank grade" do
    student = user_factory(active_all: true)
    course_with_teacher(active_all: true)
    @course.enroll_student(student).accept!
    @assignment = @course.assignments.create!(title: "assignment1", grading_type: "points", points_possible: 12)
    @assignment.grade_student(student, grade: "10", grader: @teacher)
    expect(Submission.count).to eq 1
    @submission = Submission.first
    expect(@submission.grade).to eq "10"
    expect(@submission.score).to eq 10
    expect(@submission.workflow_state).to eq "graded"

    api_call(:put,
             "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{student.id}.json",
             { controller: "submissions_api",
               action: "update",
               format: "json",
               course_id: @course.id.to_s,
               assignment_id: @assignment.id.to_s,
               user_id: student.id.to_s },
             { submission: { posted_grade: "" } })
    expect(Submission.count).to eq 1
    @submission = Submission.first
    expect(@submission.grade).to be_nil
    expect(@submission.score).to be_nil
  end

  it "allows repeated changes to a submission to accumulate" do
    student = user_factory(active_all: true)
    course_with_teacher(active_all: true)
    @course.enroll_student(student).accept!
    @assignment = @course.assignments.create!(title: "assignment1", grading_type: "points", points_possible: 12)
    submit_homework(@assignment, student)

    # post a comment
    api_call(:put,
             "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{student.id}.json",
             { controller: "submissions_api",
               action: "update",
               format: "json",
               course_id: @course.id.to_s,
               assignment_id: @assignment.id.to_s,
               user_id: student.id.to_s },
             { comment: { text_comment: "This works" } })
    expect(Submission.count).to eq 1
    @submission = Submission.first

    # grade the submission
    api_call(:put,
             "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{student.id}.json",
             { controller: "submissions_api",
               action: "update",
               format: "json",
               course_id: @course.id.to_s,
               assignment_id: @assignment.id.to_s,
               user_id: student.id.to_s },
             { submission: { posted_grade: "10" } })
    expect(Submission.count).to eq 1
    @submission = Submission.first

    # post another comment
    json = api_call(:put,
                    "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{student.id}.json",
                    { controller: "submissions_api",
                      action: "update",
                      format: "json",
                      course_id: @course.id.to_s,
                      assignment_id: @assignment.id.to_s,
                      user_id: student.id.to_s },
                    { comment: { text_comment: "10/12 ain't bad" } })
    expect(Submission.count).to eq 1
    @submission = Submission.first

    expect(json["grade"]).to eq "10"
    expect(@submission.grade).to eq "10"
    expect(@submission.score).to eq 10
    expect(json["body"]).to eq "test!"
    expect(@submission.body).to eq "test!"
    expect(json["submission_comments"].size).to eq 2
    expect(json["submission_comments"].first["comment"]).to eq "This works"
    expect(json["submission_comments"].last["comment"]).to eq "10/12 ain't bad"
    expect(@submission.user_id).to eq student.id

    # post another grade
    json = api_call(:put,
                    "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{student.id}.json",
                    { controller: "submissions_api",
                      action: "update",
                      format: "json",
                      course_id: @course.id.to_s,
                      assignment_id: @assignment.id.to_s,
                      user_id: student.id.to_s },
                    { submission: { posted_grade: "12" } })
    expect(Submission.count).to eq 1
    @submission = Submission.first

    expect(json["grade"]).to eq "12"
    expect(@submission.grade).to eq "12"
    expect(@submission.score).to eq 12
    expect(json["body"]).to eq "test!"
    expect(@submission.body).to eq "test!"
    expect(json["submission_comments"].size).to eq 2
    expect(json["submission_comments"].first["comment"]).to eq "This works"
    expect(json["submission_comments"].last["comment"]).to eq "10/12 ain't bad"
    expect(@submission.user_id).to eq student.id
  end

  it "does not allow accessing other sections when limited" do
    course_with_teacher(active_all: true)
    @enrollment.update_attribute(:limit_privileges_to_course_section, true)
    @teacher = @user
    s1 = submission_model(course: @course)
    s1.update!(submission_type: "online_text_entry")
    section2 = @course.course_sections.create(name: "another section")
    s2 = submission_model(course: @course, username: "otherstudent@example.com", section: section2, assignment: @assignment)
    @user = @teacher

    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions",
                    { controller: "submissions_api",
                      action: "index",
                      format: "json",
                      course_id: @course.id.to_s,
                      assignment_id: @assignment.id.to_s })
    expect(json.pluck("user_id")).to eq [s1.user_id]

    # try querying the other section directly
    json = api_call(:get,
                    "/api/v1/sections/#{section2.id}/assignments/#{@assignment.id}/submissions",
                    { controller: "submissions_api",
                      action: "index",
                      format: "json",
                      section_id: section2.id.to_s,
                      assignment_id: @assignment.id.to_s })
    expect(json.size).to eq 0

    raw_api_call(:get,
                 "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{s2.user_id}",
                 { controller: "submissions_api",
                   action: "show",
                   format: "json",
                   course_id: @course.id.to_s,
                   assignment_id: @assignment.id.to_s,
                   user_id: s2.user_id.to_s })
    assert_status(404)

    # try querying the other section directly
    raw_api_call(:get,
                 "/api/v1/sections/#{section2.id}/assignments/#{@assignment.id}/submissions/#{s2.user_id}",
                 { controller: "submissions_api",
                   action: "show",
                   format: "json",
                   section_id: section2.id.to_s,
                   assignment_id: @assignment.id.to_s,
                   user_id: s2.user_id.to_s })
    assert_status(404)

    api_call(:get,
             "/api/v1/courses/#{@course.id}/students/submissions",
             { controller: "submissions_api",
               action: "for_students",
               format: "json",
               course_id: @course.id.to_s },
             { student_ids: [s1.user_id, s2.user_id], grouped: 1 },
             {},
             expected_status: 401)

    # try querying the other section directly
    api_call(:get,
             "/api/v1/sections/#{section2.id}/students/submissions",
             { controller: "submissions_api",
               action: "for_students",
               format: "json",
               section_id: section2.id.to_s },
             { student_ids: [s1.user_id, s2.user_id], grouped: 1 },
             {},
             expected_status: 401)

    # grade the s1 submission, succeeds because the section is the same
    api_call(:put,
             "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{s1.user_id}",
             { controller: "submissions_api",
               action: "update",
               format: "json",
               course_id: @course.id.to_s,
               assignment_id: @assignment.id.to_s,
               user_id: s1.user_id.to_s },
             { submission: { posted_grade: "10" } })
    @submission = @assignment.submission_for_student(s1.user)
    expect(@submission.grade).to eq "10"

    # grading s2 will fail because the teacher can't manipulate this student's section
    raw_api_call(:put,
                 "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{s2.user_id}",
                 { controller: "submissions_api",
                   action: "update",
                   format: "json",
                   course_id: @course.id.to_s,
                   assignment_id: @assignment.id.to_s,
                   user_id: s2.user_id.to_s },
                 { submission: { posted_grade: "10" } })
    assert_status(404)

    # try querying the other section directly
    raw_api_call(:put,
                 "/api/v1/sections/#{section2.id}/assignments/#{@assignment.id}/submissions/#{s2.user_id}",
                 { controller: "submissions_api",
                   action: "update",
                   format: "json",
                   section_id: section2.id.to_s,
                   assignment_id: @assignment.id.to_s,
                   user_id: s2.user_id.to_s },
                 { submission: { posted_grade: "10" } })
    assert_status(404)
  end

  context "map_user_ids" do
    before do
      @controller = SubmissionsApiController.new
      @controller.instance_variable_set :@domain_root_account, Account.default
    end

    it "maps an empty list" do
      expect(@controller.map_user_ids([])).to eq []
    end

    it "maps a list of AR ids" do
      expect(@controller.map_user_ids([1, 2, "3", "4"]).sort).to eq [1, 2, 3, 4]
    end

    it "bails on ids it can't figure out" do
      expect(@controller.map_user_ids(["nonexistentcolumn:5"])).to eq []
    end

    it "filters out sis ids that don't exist, but not filter out AR ids" do
      expect(@controller.map_user_ids(["sis_user_id:1", "2"])).to eq [2]
    end

    it "finds sis ids that exist" do
      user_with_pseudonym
      @pseudonym.sis_user_id = "sisuser1"
      @pseudonym.save!
      @user1 = @user
      user_with_pseudonym username: "sisuser2@example.com"
      @user2 = @user
      user_with_pseudonym username: "sisuser3@example.com"
      @user3 = @user
      expect(@controller.map_user_ids(["sis_user_id:sisuser1",
                                       "sis_login_id:sisuser2@example.com",
                                       "hex:sis_login_id:7369737573657233406578616d706c652e636f6d",
                                       "sis_user_id:sisuser4",
                                       "5123"]).sort).to eq [
                                         @user1.id, @user2.id, @user3.id, 5123
                                       ].sort
    end

    it "does not find sis ids in other accounts" do
      account1 = account_model
      account2 = account_model
      @controller.instance_variable_set :@domain_root_account, account1
      user1 = user_with_pseudonym username: "sisuser1@example.com", account: account1
      user_with_pseudonym username: "sisuser2@example.com", account: account2
      user3 = user_with_pseudonym username: "sisuser3@example.com", account: account1
      user_with_pseudonym username: "sisuser3@example.com", account: account2
      user5 = user_factory account: account1
      user6 = user_factory account: account2
      expect(@controller.map_user_ids(["sis_login_id:sisuser1@example.com", "sis_login_id:sisuser2@example.com", "sis_login_id:sisuser3@example.com", user5.id, user6.id]).sort).to eq [user1.id, user3.id, user5.id, user6.id].sort
    end
  end

  context "create" do
    before :once do
      course_with_student(active_all: true)
      assignment_model(course: @course, submission_types: "online_url", points_possible: 12)
      @url = "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions"
      @args = { controller: "submissions", action: "create", format: "json", course_id: @course.id.to_s, assignment_id: @assignment.id.to_s }
    end

    it "rejects a submission by a non-student" do
      @user = course_with_teacher(course: @course).user
      api_call(:post, @url, @args, { submission: { submission_type: "online_url", url: "www.example.com" } }, {}, expected_status: 401)
    end

    it "rejects a request with an invalid submission_type" do
      json = api_call(:post, @url, @args, { submission: { submission_type: "blergh" } }, {}, expected_status: 400)
      expect(json["message"]).to eq "Invalid submission[submission_type] given"
    end

    it "rejects a submission_type not allowed by the assignment" do
      json = api_call(:post, @url, @args, { submission: { submission_type: "media_recording" } }, {}, expected_status: 400)
      expect(json["message"]).to eq "Invalid submission[submission_type] given"
    end

    it "rejects mismatched submission_type and params" do
      json = api_call(:post, @url, @args, { submission: { submission_type: "online_url", body: "some html text" } }, {}, expected_status: 400)
      expect(json["message"]).to eq "Invalid parameters for submission_type online_url. Required: submission[url]"
    end

    it "works with section ids" do
      @section = @course.default_section
      api_call(:post, "/api/v1/sections/#{@section.id}/assignments/#{@assignment.id}/submissions", { controller: "submissions", action: "create", format: "json", section_id: @section.id.to_s, assignment_id: @assignment.id.to_s }, { submission: { submission_type: "online_url", url: "www.example.com/a/b?q=1" } }, {}, expected_status: 201)
      @submission = @assignment.submissions.find_by!(user: @user)
      expect(@submission.url).to eq "http://www.example.com/a/b?q=1"
    end

    describe "valid submissions" do
      def do_submit(opts)
        json = api_call(:post, @url, @args, { submission: opts })
        expect(response["Location"]).to eq "http://www.example.com/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@user.id}"
        @submission = @assignment.submissions.find_by!(user: @user)
        expect(json.slice("user_id", "assignment_id", "score", "grade")).to eq({
                                                                                 "user_id" => @user.id,
                                                                                 "assignment_id" => @assignment.id,
                                                                                 "score" => nil,
                                                                                 "grade" => nil,
                                                                               })
        json
      end

      it "creates a url submission" do
        json = do_submit(submission_type: "online_url", url: "www.example.com/a/b?q=1")
        expect(@submission.url).to eq "http://www.example.com/a/b?q=1"
        expect(json["url"]).to eq @submission.url
      end

      it "creates with an initial comment" do
        json = api_call(:post, @url, @args, { comment: { text_comment: "ohai teacher" }, submission: { submission_type: "online_url", url: "http://www.example.com/a/b" } })
        @submission = @assignment.submissions.where(user: @user).first
        expect(@submission.submission_comments.size).to eq 1
        expect(@submission.submission_comments.first.attributes.slice("author_id", "comment")).to eq({
                                                                                                       "author_id" => @user.id,
                                                                                                       "comment" => "ohai teacher",
                                                                                                     })
        expect(json["url"]).to eq "http://www.example.com/a/b"
      end

      it "creates a online text submission" do
        @assignment.update(submission_types: "online_text_entry")
        json = do_submit(submission_type: "online_text_entry", body: <<~HTML)
          <p>
            This is <i>some</i> text. The <script src='evil.com'></script> sanitization will take effect.
          </p>
        HTML
        expect(json["body"]).to eq <<~HTML
          <p>
            This is <i>some</i> text. The  sanitization will take effect.
          </p>
        HTML
        expect(json["body"]).to eq @submission.body
      end

      it "creates a student annotation submission" do
        a1 = attachment_model(context: @course)
        @assignment.update(submission_types: "student_annotation", annotatable_attachment_id: a1.id)
        json = api_call(:post, @url, @args, { submission: { submission_type: "student_annotation", annotatable_attachment_id: a1.id } }, {}, expected_status: 201)
        expect(json["workflow_state"]).to eq "submitted"
      end

      it "processs html content in body" do
        @assignment.update(submission_types: "online_text_entry")
        should_process_incoming_user_content(@course) do |content|
          do_submit(submission_type: "online_text_entry", body: content)
          @submission.body
        end
      end

      it "creates a file upload submission" do
        @assignment.update(submission_types: "online_upload")
        a1 = attachment_model(context: @user)
        a2 = attachment_model(context: @user)
        json = do_submit(submission_type: "online_upload", file_ids: [a1.id, a2.id])
        sub_a1 = Attachment.where(root_attachment_id: a1).first
        sub_a2 = Attachment.where(root_attachment_id: a2).first
        expect(json["attachments"].pluck("url")).to eq [file_download_url(sub_a1, verifier: sub_a1.uuid, download: "1", download_frd: "1"),
                                                        file_download_url(sub_a2, verifier: sub_a2.uuid, download: "1", download_frd: "1")]
      end

      it "creates a media comment submission" do
        @assignment.update(submission_types: "media_recording")
        media_object(media_id: "3232", media_type: "audio")
        json = do_submit(submission_type: "media_recording", media_comment_id: "3232", media_comment_type: "audio")
        expect(json["media_comment"].slice("media_id", "media_type")).to eq({
                                                                              "media_id" => "3232",
                                                                              "media_type" => "audio",
                                                                            })
      end

      it "copies files to the submissions folder if they're not there already" do
        @assignment.update(submission_types: "online_upload")
        a1 = attachment_model(context: @user, folder: @user.submissions_folder)
        a2 = attachment_model(context: @user)
        json = do_submit(submission_type: "online_upload", file_ids: [a1.id, a2.id])
        submission_attachment_ids = json["attachments"].pluck("id")
        expect(submission_attachment_ids.size).to eq 2
        expect(submission_attachment_ids.delete(a1.id)).not_to be_nil
        copy = Attachment.find(submission_attachment_ids.last)
        expect(copy.folder).to eq @user.submissions_folder(@course)
        expect(copy.root_attachment).to eq a2
      end
    end

    context "submission file uploads" do
      before :once do
        @assignment.update(submission_types: "online_upload")
        @student1 = @student
        course_with_student(course: @course)
        @context = @course
        @student2 = @student
        @user = @student1
      end

      include_examples "file uploads api"
      include_examples "file uploads api without quotas"

      # preflight_params has to be first and nameless to keep backwards compat with the include_examples
      def preflight(preflight_params, request_params: {}, api_url: nil)
        api_url ||= "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student1.id}/files"

        api_call(
          :post,
          api_url,
          {
            controller: "submissions_api",
            action: "create_file",
            format: "json",
            course_id: @course.to_param,
            assignment_id: @assignment.to_param,
            user_id: @student1.to_param,
          }.merge(request_params),
          preflight_params
        )
      end

      def has_query_exemption?
        true
      end

      it "rejects uploading files to other students' submissions" do
        preflight(
          {},
          api_url: "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student2.id}/files",
          request_params: { user_id: @student2.to_param }
        )
        assert_status(401)
      end

      it "allows a teacher to upload files for a student" do
        @user = @teacher
        preflight({ name: "test.txt", size: 12_345, content_type: "text/plain" })
        assert_status(200)
      end

      it "allows any filetype when there are no restrictions on type" do
        preflight({ name: "test.txt", size: 12_345, content_type: "text/plain" })
        assert_status(200)
      end

      it "rejects uploading files when file extension is not given" do
        @assignment.update(allowed_extensions: ["jpg"])
        preflight({ name: "name", size: 12_345 })
        assert_status(400)
      end

      it "rejects uploading files when filetype is not allowed" do
        @assignment.update(allowed_extensions: ["doc"])
        preflight({ name: "test.txt", size: 12_345, content_type: "text/plain" })
        assert_status(400)
      end

      it "allows filetype when restricted and is correct filetype" do
        @assignment.update(allowed_extensions: ["txt"])
        preflight({ name: "test.txt", size: 12_345, content_type: "text/plain" })
        assert_status(200)
      end

      it "falls back to parsing the extension when an unknown type" do
        @assignment.update(allowed_extensions: ["beepboop"])
        preflight({ name: "test.beepboop", size: 12_345 })
        assert_status(200)
      end

      it "uploads to a student's Submissions folder" do
        preflight({ name: "test.txt", size: 12_345, content_type: "text/plain" })
        f = Attachment.last.folder
        expect(f.submission_context_code).to eq @course.asset_string
      end

      context "for url upload using InstFS" do
        let(:json_response) do
          preflight({ url: "http://example.com/test", comment: "my comment" })
          JSON.parse(response.body)
        end

        before { allow(InstFS).to receive(:enabled?).and_return(true) }

        context "returns an upload_url with a token" do
          let(:token) { json_response["upload_url"].match(/\?token=(.+)&?/)[1] }
          let(:jwt) { Canvas::Security.decode_jwt(token) }

          it "encodes capture_params in the token" do
            capture_params = {
              "eula_agreement_timestamp" => nil,
              "comment" => "my comment",
              "context_type" => "User",
              "context_id" => @student1.id.to_s,
              "user_id" => @student1.id.to_s,
              "quota_exempt" => true,
              "on_duplicate" => "overwrite",
              "include" => nil
            }
            expect(jwt["capture_params"]).to include capture_params
          end

          it "returns a valid upload url" do
            expect(json_response["upload_url"]).to match(/files\?token=.+&?/)
          end
        end

        it "returns upload_params infering the filename from the URL" do
          upload_json = {
            "filename" => "test",
            "content_type" => "unknown/unknown",
            "target_url" => "http://example.com/test"
          }
          expect(json_response["upload_params"]).to eq upload_json
        end

        it "returns progress json" do
          progress_json = {
            "context_id" => @assignment.id,
            "context_type" => "Assignment",
            "user_id" => @student1.id,
            "tag" => "upload_via_url"
          }
          expect(json_response["progress"]).to include progress_json
        end
      end

      context "for url upload using DelayedJob" do
        let(:json_response) do
          preflight({ url: "http://example.com/test", filename: "test.txt", comment: "hello comment" })
          JSON.parse(response.body)
        end

        before { allow(InstFS).to receive(:enabled?).and_return(false) }

        it "returns progress json" do
          progress_json = {
            "context_id" => @assignment.id,
            "context_type" => "Assignment",
            "user_id" => @student1.id,
            "tag" => "upload_via_url"
          }
          expect(json_response["progress"]).to include progress_json
        end

        it "enqueues the submit job" do
          json_response
          job = Delayed::Job.order(:id).last
          expect(job.handler).to include Services::SubmitHomeworkService::SubmitWorker.name
          expect(job.handler).to include "hello comment"
        end

        it "enqueues the copy job when the submit_assignment parameter is false" do
          preflight({ url: "http://example.com/test", filename: "test.txt", submit_assignment: false })
          JSON.parse(response.body)
          job = Delayed::Job.order(:id).last
          expect(job.handler).to include Services::SubmitHomeworkService::CopyWorker.name
        end
      end
    end

    it "rejects invalid urls" do
      api_call(:post, @url, @args, { submission: { submission_type: "online_url", url: "ftp://ftp.example.com/a/b" } }, {}, expected_status: 400)
    end

    it "rejects attachment ids not belonging to the user" do
      @assignment.update(submission_types: "online_upload")
      a1 = attachment_model(context: @course)
      json = api_call(:post, @url, @args, { submission: { submission_type: "online_upload", file_ids: [a1.id] } }, {}, expected_status: 400)
      expect(json["message"]).to eq "No valid file ids given"
    end

    it "allows a grader to submit for a student and set submitted_at" do
      submitted_at = 1.day.ago.change(usec: 0)
      @user = course_with_teacher(course: @course).user
      api_call(:post, @url, @args, { submission: { submission_type: "online_url", url: "www.example.com", user_id: @student.id, submitted_at: } }, {}, expected_status: 201)
      submission = Submission.last
      expect(submission.submitted_at).to eq submitted_at
    end

    it "rejects submissions for one student from another" do
      @student1 = @student
      @user = course_with_student(course: @course).user
      api_call(:post, @url, @args, { submission: { submission_type: "online_url", url: "www.example.com", user_id: @student1.id } }, {}, expected_status: 401)
    end

    it "prevents a student from sending submitted_at for their own submission" do
      api_call(:post, @url, @args, { submissions: { submission_type: "online_url", url: "www.example.com", user_id: @student.id, submitted_at: 1.day.ago } }, {}, expected_status: 400)
    end
  end

  context "draft assignments" do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
      @a2 = @course.assignments.create!({ title: "assignment2" })
      @a2.workflow_state = "unpublished"
      @a2.save!
    end

    it "does not allow comments (teachers)" do
      @user = @teacher
      draft_assignment_update({ comment: { text_comment: "Tacos are tasty" } })
    end

    it "does not allow comments (students)" do
      @user = @student
      draft_assignment_update({ comment: { text_comment: "Tacos are tasty" } })
    end

    it "does not allow group comments (students)" do
      student2 = user_factory(active_all: true)
      @course.enroll_student(student2).accept!
      group_category = @course.group_categories.create(name: "Category")
      @group = @course.groups.create(name: "Group", group_category:, context: @course)
      @group.users = [@student, student2]
      @a2 = @course.assignments.create!(title: "assignment1", grading_type: "points", points_possible: 12, group_category:)
      draft_assignment_update({ comment: { text_comment: "HEY GIRL HEY!", group_comment: "1" } })
    end

    it "does not allow grading with points" do
      @a2.grading_type = "points"
      @a2.points_possible = 15
      @a2.save!
      @user = @teacher
      grade = "13.2"
      draft_assignment_update({ submission: { posted_grade: grade } })
    end

    it "does not mark as complete for zero credit assignments" do
      @a2.grading_type = "pass_fail"
      @a2.points_possible = 0
      @a2.save!
      @user = @teacher
      grade = "pass"
      draft_assignment_update({ submission: { posted_grade: grade } })
    end

    # Give this a hash of items to update with the API call
    def draft_assignment_update(opts)
      raw_api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@a2.id}/submissions/#{@student.id}",
        {
          controller: "submissions_api",
          action: "update",
          format: "json",
          course_id: @course.id.to_s,
          assignment_id: @a2.id.to_s,
          user_id: @student.id.to_s
        },
        opts
      )
      assert_status(401)
    end
  end

  it "includes preview urls for attachments" do
    allow(Canvadocs).to receive(:config).and_return({ a: 1 })

    course_with_teacher_logged_in active_all: true
    student_in_course active_all: true
    @user = @teacher
    a = @course.assignments.create!
    a.submit_homework(@student,
                      submission_type: "online_upload",
                      attachments: [crocodocable_attachment_model(context: @student)])
    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/assignments/#{a.id}/submissions?include[]=submission_history",
                    { course_id: @course.id.to_s,
                      assignment_id: a.id.to_s,
                      action: "index",
                      controller: "submissions_api",
                      format: "json",
                      include: %w[submission_history] })

    expect(json[0]["submission_history"][0]["attachments"][0]["preview_url"]).to match(
      /canvadoc_session/
    )
  end

  it "includes anonymous instructor annotation parameters in the preview urls for attachments" do
    allow(Canvadocs).to receive(:config).and_return({ a: 1 })

    course_with_teacher_logged_in active_all: true
    student_in_course active_all: true
    @user = @teacher
    a = @course.assignments.create!
    a.submit_homework(@student,
                      submission_type: "online_upload",
                      attachments: [crocodocable_attachment_model(context: @student)])
    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/assignments/#{a.id}/submissions?include[]=submission_history",
                    { course_id: @course.id.to_s,
                      assignment_id: a.id.to_s,
                      action: "index",
                      controller: "submissions_api",
                      format: "json",
                      include: %w[submission_history] })

    url = URI.parse(URI::DEFAULT_PARSER.unescape(json[0]["submission_history"][0]["attachments"][0]["preview_url"]))
    blob = JSON.parse(URI.decode_www_form(url.query).to_h["blob"])
    expect(blob).to include({
                              "enable_annotations" => true,
                              "anonymous_instructor_annotations" => false,
                              "enrollment_type" => "teacher"
                            })
  end

  it "includes canvadoc_document_id when specified" do
    allow(Canvadocs).to receive(:config).and_return({ a: 1 })

    course_with_teacher_logged_in active_all: true
    student_in_course active_all: true
    @user = @teacher
    a = @course.assignments.create!
    a.submit_homework(@student,
                      submission_type: "online_upload",
                      attachments: [canvadocable_attachment_model(context: @student)])
    canvadoc_params = { attachment_id: a.submissions[0].attachments[0].id, document_id: "testing_doc_id" }
    a.submissions[0].attachments[0].canvadoc = Canvadoc.new(canvadoc_params)
    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/assignments/#{a.id}/submissions?include[]=canvadoc_document_id",
                    { course_id: @course.id.to_s,
                      assignment_id: a.id.to_s,
                      action: "index",
                      controller: "submissions_api",
                      format: "json",
                      include: %w[canvadoc_document_id] })
    canvadoc_document_id = a.submissions[0].attachments[0].canvadoc.document_id
    expect(json[0]["attachments"][0]["canvadoc_document_id"]).to eq canvadoc_document_id
  end

  it "includes crocodoc allowed ids in the preview url for attachments" do
    allow(Canvas::Crocodoc).to receive(:config).and_return({ a: 1 })

    course_with_teacher_logged_in active_all: true
    student_in_course active_all: true
    @user = @teacher
    assignment = @course.assignments.create!(moderated_grading: true, grader_count: 1)
    submission = assignment.submit_homework(@student,
                                            submission_type: "online_upload",
                                            attachments: [crocodocable_attachment_model(context: @student)])
    provisional_grade = submission.find_or_create_provisional_grade!(@teacher, score: 1)
    assignment.moderated_grading_selections
              .where(student_id: @student.id).first
              .update_attribute(:provisional_grade, provisional_grade)
    provisional_grade.publish!
    assignment.update(grades_published_at: 1.hour.ago)
    submission.reload
    submission.attachments.first.create_crocodoc_document(uuid: "1234",
                                                          process_state: "PROCESSED")

    url = "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}/submissions?include[]=submission_history"
    json = api_call(:get, url, { course_id: @course.id.to_s,
                                 assignment_id: assignment.id.to_s,
                                 action: "index",
                                 controller: "submissions_api",
                                 format: "json",
                                 include: %w[submission_history] })

    result_url = json.first.fetch("submission_history").first.fetch("attachments").first
                     .fetch("preview_url")

    @teacher.reload
    @student.reload

    parsed = URI.parse result_url
    parsed_params = CGI.parse parsed.query
    parsed_blob = JSON.parse parsed_params["blob"].first
    expect(parsed.path).to eq "/api/v1/crocodoc_session"

    expect(parsed_blob["moderated_grading_allow_list"]).to include(@student.moderated_grading_ids.as_json)
    expect(parsed_blob["moderated_grading_allow_list"]).to include(@teacher.moderated_grading_ids.as_json)
  end

  def course_with_student_and_submitted_homework
    course_with_teacher(active_all: true)
    @teacher = @user
    student_in_course
    @student = @user
    @user = @teacher # @user needs to be the user making the api calls later
    @assignment = @course.assignments.create!(title: "some assignment", submission_types: "online_url,online_upload")
    @submission = @assignment.submit_homework(@student)
  end

  it "marks as read" do
    course_with_student_and_submitted_homework
    @submission.add_comment(author: @student, comment: "some comment")
    raw_api_call(:put,
                 "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}/read",
                 { course_id: @course.id.to_s,
                   assignment_id: @assignment.id.to_s,
                   user_id: @student.id.to_s,
                   action: "mark_submission_read",
                   controller: "submissions_api",
                   format: "json" })
    expect(@submission.reload.read?(@teacher)).to be_truthy
  end

  it "marks as unread" do
    course_with_student_and_submitted_homework
    @submission.add_comment(author: @student, comment: "some comment")
    @submission.change_read_state("read", @teacher)
    raw_api_call(:delete,
                 "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}/read",
                 { course_id: @course.id.to_s,
                   assignment_id: @assignment.id.to_s,
                   user_id: @student.id.to_s,
                   action: "mark_submission_unread",
                   controller: "submissions_api",
                   format: "json" })
    expect(@submission.reload.read?(@teacher)).to be_falsey
  end

  context "submission feedback" do
    before :once do
      course_with_student_and_submitted_homework
    end

    let(:content_item) { "comment" }
    let(:endpoint) { "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}/read/#{content_item}" }
    let(:params) do
      { course_id: @course.id.to_s,
        assignment_id: @assignment.id.to_s,
        user_id: @student.id.to_s,
        item: content_item,
        action: "mark_submission_item_read",
        controller: "submissions_api",
        format: "json" }
    end

    it "mark comments as read" do
      @submission.add_comment(author: @teacher, comment: "teacher")
      @user = @student
      raw_api_call(:put, endpoint, params)
      expect(@submission.reload.read_item?(@student, "comment")).to be_truthy
      expect(@submission.visible_submission_comments[0].viewed_submission_comments[0].user).to eql @student
    end

    context "when passing an invalid content item" do
      let(:content_item) { "_invalid_" }

      it "returns status 422 and does not mark as read" do
        api_call_as_user(@student, :put, endpoint, params, {}, {}, { expected_status: 422 })
        expect(@submission.reload.read?(@student)).to be_truthy
      end
    end

    context "when current user is not the student" do
      it "doesn't allow you to mark someone else's submission item read" do
        @submission.add_comment(author: @teacher, comment: "teacher")
        api_call_as_user(@teacher, :put, endpoint, params, {}, {}, { expected_status: 401 })
        expect(@submission.reload.unread_item?(@student, "comment")).to be_truthy
      end
    end
  end

  context "document annotation read state" do
    before :once do
      course_with_student_and_submitted_homework
    end

    it "retrieves document annotation read state" do
      @student.mark_submission_annotations_unread!(@submission)
      json = api_call_as_user(@student,
                              :get,
                              "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}/document_annotations/read",
                              { course_id: @course.to_param,
                                assignment_id: @assignment.to_param,
                                user_id: @student.to_param,
                                action: "document_annotations_read_state",
                                controller: "submissions_api",
                                format: "json" })
      expect(json).to eq({ "read" => false })

      @student.mark_submission_annotations_read!(@submission)
      json = api_call_as_user(@student,
                              :get,
                              "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}/document_annotations/read",
                              { course_id: @course.to_param,
                                assignment_id: @assignment.to_param,
                                user_id: @student.to_param,
                                action: "document_annotations_read_state",
                                controller: "submissions_api",
                                format: "json" })
      expect(json).to eq({ "read" => true })
    end

    it "requires read permission on the submission" do
      temp = @student
      other_student = student_in_course(active_all: true).user
      @student = temp

      api_call_as_user(other_student,
                       :get,
                       "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}/document_annotations/read",
                       { course_id: @course.to_param,
                         assignment_id: @assignment.to_param,
                         user_id: @student.to_param,
                         action: "document_annotations_read_state",
                         controller: "submissions_api",
                         format: "json" },
                       {},
                       {},
                       { expected_status: 401 })
    end

    it "marks document annotations read" do
      @student.mark_submission_annotations_unread!(@submission)
      api_call_as_user(@student,
                       :put,
                       "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}/document_annotations/read",
                       { course_id: @course.to_param,
                         assignment_id: @assignment.to_param,
                         user_id: @student.to_param,
                         action: "mark_document_annotations_read",
                         controller: "submissions_api",
                         format: "json" })
      expect(@user.reload.unread_submission_annotations?(@submission)).to be false
    end

    it "doesn't allow you to mark someone else's document annotations read" do
      api_call_as_user(@teacher,
                       :put,
                       "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}/document_annotations/read",
                       { course_id: @course.to_param,
                         assignment_id: @assignment.to_param,
                         user_id: @student.to_param,
                         action: "mark_document_annotations_read",
                         controller: "submissions_api",
                         format: "json" },
                       {},
                       {},
                       { expected_status: 401 })
    end
  end

  context "mark bulk submissions as read" do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course
      @assignment1 = @course.assignments.create!(title: "some assignment", submission_types: "online_url,online_upload")
      @assignment2 = @course.assignments.create!(title: "some assignment 2", submission_types: "online_url,online_upload")
      @submission1 = @assignment1.submit_homework(@student)
      @submission2 = @assignment2.submit_homework(@student)
      @assignment1.grade_student @student, score: 98, grader: @teacher
      @assignment2.grade_student @student, score: 90, grader: @teacher
    end

    let(:endpoint) { "/api/v1/courses/#{@course.id}/submissions/bulk_mark_read" }
    let(:params) do
      { course_id: @course.id.to_s,
        submissionIds: [@submission1.id, @submission2.id],
        action: "mark_bulk_submissions_as_read",
        controller: "submissions_api",
        format: "json" }
    end

    it "marks submission grades as read" do
      raw_api_call(:put, endpoint, params)
      expect(@submission1.reload.read?(@student)).to be_truthy
      expect(@submission2.reload.read?(@student)).to be_truthy
    end

    it "does not mark submission grade as read if user is not the student of the submission" do
      @user = @teacher
      raw_api_call(:put, endpoint, params)
      expect(@submission1.reload.read?(@user)).not_to be_truthy
      expect(@submission2.reload.read?(@user)).not_to be_truthy
    end
  end

  context "clear unread submissions" do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
      assignment_model(course: @course)
      @content = @assignment.submit_homework(@student)
      @assignment2 = assignment_model(course: @course)
      @content2 = @assignment2.submit_homework(@student)
      @assignment.ensure_post_policy(post_manually: false)
      @content.update_columns(posted_at: Time.now.utc, workflow_state: "graded", score: 10)
      @assignment2.ensure_post_policy(post_manually: false)
      @content2.update_columns(posted_at: Time.now.utc, workflow_state: "graded", score: 10)
      ContentParticipation.participate(content: @content, user: @student, workflow_state: "unread", content_item: "grade")
      ContentParticipation.participate(content: @content2, user: @student, workflow_state: "unread", content_item: "grade")
    end

    let(:endpoint) { "/api/v1/courses/#{@course.id}/submissions/#{@student.id}/clear_unread" }
    let(:params) do
      { course_id: @course.id.to_s,
        user_id: @student.id.to_s,
        action: "submissions_clear_unread",
        controller: "submissions_api",
        format: "json" }
    end

    it "marks submission grades as read" do
      @site_admin_member = site_admin_user(name: "site admin", active_all: true)
      content_participation_count = ContentParticipationCount.find_by(user: @student, context: @course)
      content_participation_count.refresh_unread_count
      expect(content_participation_count.unread_count).to eq(2)
      @user = @site_admin_member
      raw_api_call(:put, endpoint, params)
      content_participation_count.reload
      expect(content_participation_count.unread_count).to eq(0)
    end

    it "does not mark submission grade as read if user is not a Site Admin" do
      @user = @teacher
      raw_api_call(:put, endpoint, params)
      assert_status(401)
    end
  end

  context "rubric comments read state" do
    before :once do
      course_with_student_and_submitted_homework
    end

    it "retrieves rubric comments read state" do
      @student.mark_rubric_assessments_unread!(@submission)
      json = api_call_as_user(@student,
                              :get,
                              "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}/rubric_assessments/read",
                              { course_id: @course.to_param,
                                assignment_id: @assignment.to_param,
                                user_id: @student.to_param,
                                action: "rubric_assessments_read_state",
                                controller: "submissions_api",
                                format: "json" })
      expect(json).to eq({ "read" => false })

      @student.mark_rubric_assessments_read!(@submission)
      json = api_call_as_user(@student,
                              :get,
                              "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}/rubric_assessments/read",
                              { course_id: @course.to_param,
                                assignment_id: @assignment.to_param,
                                user_id: @student.to_param,
                                action: "rubric_assessments_read_state",
                                controller: "submissions_api",
                                format: "json" })
      expect(json).to eq({ "read" => true })
    end

    it "requires read permission on the submission" do
      temp = @student
      other_student = student_in_course(active_all: true).user
      @student = temp

      api_call_as_user(other_student,
                       :get,
                       "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}/rubric_assessments/read",
                       { course_id: @course.to_param,
                         assignment_id: @assignment.to_param,
                         user_id: @student.to_param,
                         action: "rubric_assessments_read_state",
                         controller: "submissions_api",
                         format: "json" },
                       {},
                       {},
                       { expected_status: 401 })
    end

    it "marks rubric comments read" do
      @student.mark_rubric_assessments_unread!(@submission)
      api_call_as_user(@student,
                       :put,
                       "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}/rubric_assessments/read",
                       { course_id: @course.to_param,
                         assignment_id: @assignment.to_param,
                         user_id: @student.to_param,
                         action: "mark_rubric_assessments_read",
                         controller: "submissions_api",
                         format: "json" })
      expect(@user.reload.unread_rubric_assessments?(@submission)).to be false
    end

    it "doesn't allow you to mark someone else's rubric comments read" do
      api_call_as_user(@teacher,
                       :put,
                       "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}/rubric_assessments/read",
                       { course_id: @course.to_param,
                         assignment_id: @assignment.to_param,
                         user_id: @student.to_param,
                         action: "mark_rubric_assessments_read",
                         controller: "submissions_api",
                         format: "json" },
                       {},
                       {},
                       { expected_status: 401 })
    end
  end

  context "bulk update" do
    before do
      @student1 = user_factory(active_all: true)
      @student2 = user_factory(active_all: true)
      course_with_teacher(active_all: true)
      @default_section = @course.default_section
      @section = @course.course_sections.create!(name: "section2")
      @course.enroll_user(@student1, "StudentEnrollment", section: @section).accept!
      @course.enroll_user(@student2, "StudentEnrollment").accept!
      @a1 = @course.assignments.create!({ title: "assignment1", grading_type: "percent", points_possible: 10 })
    end

    it "returns an error when grade_data is omitted" do
      json = api_call(:post,
                      "/api/v1/courses/#{@course.id}/assignments/#{@a1.id}/submissions/update_grades",
                      { controller: "submissions_api",
                        action: "bulk_update",
                        format: "json",
                        course_id: @course.id.to_s,
                        assignment_id: @a1.id.to_s },
                      {},
                      {},
                      { expected_status: 400 })

      expect(json["error"]).to eq("'grade_data' parameter required")
    end

    it "queues bulk update through courses" do
      grade_data = {
        grade_data: {
          @student1.id => { posted_grade: "75%" },
          @student2.id => { posted_grade: "95%" }
        }
      }

      json = api_call(:post,
                      "/api/v1/courses/#{@course.id}/assignments/#{@a1.id}/submissions/update_grades",
                      { controller: "submissions_api",
                        action: "bulk_update",
                        format: "json",
                        course_id: @course.id.to_s,
                        assignment_id: @a1.id.to_s },
                      grade_data)

      run_jobs
      progress = Progress.find(json["id"])
      expect(progress.completed?).to be_truthy

      expect(Submission.count).to eq 2
      s1 = @student1.submissions.first
      expect(s1.grade).to eq "75%"
      s2 = @student2.submissions.first
      expect(s2.grade).to eq "95%"
    end

    it "finds users through sis api ids" do
      student3 = user_with_pseudonym(active_all: true)
      student3.pseudonym.update_attribute(:sis_user_id, "my-student-id")
      @course.enroll_user(student3, "StudentEnrollment").accept!

      grade_data = {
        grade_data: {
          "sis_user_id:my-student-id" => { posted_grade: "75%" }
        }
      }

      @user = @teacher
      json = api_call(:post,
                      "/api/v1/courses/#{@course.id}/assignments/#{@a1.id}/submissions/update_grades",
                      { controller: "submissions_api",
                        action: "bulk_update",
                        format: "json",
                        course_id: @course.id.to_s,
                        assignment_id: @a1.id.to_s },
                      grade_data)

      run_jobs
      progress = Progress.find(json["id"])
      expect(progress.completed?).to be_truthy

      expect(Submission.not_placeholder.count).to eq 1
      s1 = student3.submissions.first
      expect(s1.grade).to eq "75%"
    end

    it "restricts with differentiated assignments" do
      @a1.only_visible_to_overrides = true
      @a1.save!
      create_section_override_for_assignment(@a1, course_section: @section)

      student3 = user_with_pseudonym(active_all: true)
      student3.pseudonym.update_attribute(:sis_user_id, "my-student-id")
      @course.enroll_user(student3, "StudentEnrollment").accept!

      grade_data = {
        grade_data: {
          @student1.id => { posted_grade: "75%" },
          @student2.id => { posted_grade: "95%" },
          "sis_user_id:my-student-id" => { posted_grade: "85%" },
        }
      }

      @user = @teacher
      json = api_call(:post,
                      "/api/v1/courses/#{@course.id}/assignments/#{@a1.id}/submissions/update_grades",
                      { controller: "submissions_api",
                        action: "bulk_update",
                        format: "json",
                        course_id: @course.id.to_s,
                        assignment_id: @a1.id.to_s },
                      grade_data)

      run_jobs
      progress = Progress.find(json["id"])
      expect(progress.failed?).to be_truthy
      expect(progress.message).to eq "Couldn't find User(s) with API ids '#{@student2.id}', 'sis_user_id:my-student-id'"

      create_section_override_for_assignment(@a1, course_section: @course.default_section)
      json = api_call(:post,
                      "/api/v1/courses/#{@course.id}/assignments/#{@a1.id}/submissions/update_grades",
                      { controller: "submissions_api",
                        action: "bulk_update",
                        format: "json",
                        course_id: @course.id.to_s,
                        assignment_id: @a1.id.to_s },
                      grade_data)

      run_jobs
      progress = Progress.find(json["id"])
      expect(progress.completed?).to be_truthy

      expect(Submission.count).to eq 3
      s1 = @student1.submissions.first
      expect(s1.grade).to eq "75%"
      s2 = @student2.submissions.first
      expect(s2.grade).to eq "95%"
      s3 = student3.submissions.first
      expect(s3.grade).to eq "85%"
    end

    it "queues bulk update through sections" do
      grade_data = {
        grade_data: {
          @student1.id => { posted_grade: "75%" }
        }
      }

      json = api_call(:post,
                      "/api/v1/sections/#{@section.id}/assignments/#{@a1.id}/submissions/update_grades",
                      { controller: "submissions_api",
                        action: "bulk_update",
                        format: "json",
                        section_id: @section.id.to_s,
                        assignment_id: @a1.id.to_s },
                      grade_data)

      run_jobs
      progress = Progress.find(json["id"])
      expect(progress.completed?).to be_truthy

      expect(Submission.not_placeholder.count).to eq 1
      s1 = @student1.submissions.first
      expect(s1.grade).to eq "75%"
    end

    it "allows bulk grading with rubric assessments" do
      rubric = rubric_model(user: @user, context: @course, data: larger_rubric_data)
      @a1.create_rubric_association(rubric:, purpose: "grading", use_for_grading: true, context: @course)

      grade_data = {
        grade_data: {
          @student1.id => { posted_grade: "75%" },
          @student2.id => {
            rubric_assessment: {
              crit1: { points: 7 },
              crit2: { points: 2, comments: "Rock on" }
            }
          }
        }
      }

      json = api_call(:post,
                      "/api/v1/courses/#{@course.id}/assignments/#{@a1.id}/submissions/update_grades",
                      { controller: "submissions_api",
                        action: "bulk_update",
                        format: "json",
                        course_id: @course.id.to_s,
                        assignment_id: @a1.id.to_s },
                      grade_data)

      run_jobs
      progress = Progress.find(json["id"])
      expect(progress.completed?).to be_truthy

      expect(Submission.count).to eq 2
      s1 = @student1.submissions.first
      expect(s1.grade).to eq "75%"
      s2 = @student2.submissions.first
      expect(s2.rubric_assessment).not_to be_nil
      expect(s2.rubric_assessment.data).to eq(
        [{ description: "B",
           criterion_id: "crit1",
           comments_enabled: true,
           points: 7,
           learning_outcome_id: nil,
           id: "rat2",
           comments: nil },
         { description: "Pass",
           criterion_id: "crit2",
           comments_enabled: true,
           points: 2,
           learning_outcome_id: nil,
           id: "rat1",
           comments: "Rock on",
           comments_html: "Rock on" }]
      )
    end

    it "requires authorization" do
      @user = @student1
      raw_api_call(:post,
                   "/api/v1/courses/#{@course.id}/assignments/#{@a1.id}/submissions/update_grades",
                   { controller: "submissions_api",
                     action: "bulk_update",
                     format: "json",
                     course_id: @course.id.to_s,
                     assignment_id: @a1.id.to_s,
                     grade_data: { foo: "bar" } },
                   {})
      assert_status(401)
    end

    it "excuses assignments" do
      grade_data = {
        grade_data: { @student1.id => { excuse: "1" } }
      }

      api_call(:post,
               "/api/v1/sections/#{@section.id}/assignments/#{@a1.id}/submissions/update_grades",
               { controller: "submissions_api",
                 action: "bulk_update",
                 format: "json",
                 section_id: @section.id.to_s,
                 assignment_id: @a1.id.to_s },
               grade_data)
      run_jobs

      expect(@a1.submission_for_student(@student1)).to be_excused
    end

    it "unexcuses assignments" do
      @a1.grade_student @student1, excused: true, grader: @teacher
      grade_data = {
        grade_data: { @student1.id => { excuse: "0", posted_grade: nil } }
      }

      api_call(:post,
               "/api/v1/sections/#{@section.id}/assignments/#{@a1.id}/submissions/update_grades",
               { controller: "submissions_api",
                 action: "bulk_update",
                 format: "json",
                 section_id: @section.id.to_s,
                 assignment_id: @a1.id.to_s },
               grade_data)
      run_jobs

      expect(@a1.submission_for_student(@student1)).to_not be_excused
    end

    it "posts do not set grader_id for unchanged scores" do
      grade_data = {
        grade_data: {
          @student1.id => { posted_grade: nil },
          @student2.id => { posted_grade: "-" }
        }
      }

      api_call(:post,
               "/api/v1/sections/#{@section.id}/assignments/#{@a1.id}/submissions/update_grades",
               { controller: "submissions_api",
                 action: "bulk_update",
                 format: "json",
                 section_id: @section.id.to_s,
                 assignment_id: @a1.id.to_s },
               grade_data)
      run_jobs

      submission1 = @a1.submission_for_student(@student1)
      submission2 = @a1.submission_for_student(@student2)
      expect(submission1.grader_id).to be_nil
      expect(submission2.grader_id).to be_nil
    end

    it "checks user ids for sections" do
      grade_data = {
        grade_data: {
          @student1.id => { posted_grade: "75%" },
          @student2.id => { posted_grade: "95%" }
        }
      }

      json = api_call(:post,
                      "/api/v1/sections/#{@section.id}/assignments/#{@a1.id}/submissions/update_grades",
                      { controller: "submissions_api",
                        action: "bulk_update",
                        format: "json",
                        section_id: @section.id.to_s,
                        assignment_id: @a1.id.to_s },
                      grade_data)

      run_jobs
      progress = Progress.find(json["id"])
      expect(progress.failed?).to be_truthy
      expect(progress.message).to eq "Couldn't find User(s) with API ids '#{@student2.id}'"
    end

    it "maintains grade when updating comments" do
      @a1.grade_student(@student1, grade: "5%", grader: @teacher)

      grade_data = {
        grade_data: {
          @student1.id => { text_comment: "Awesome comment" }
        }
      }
      api_call(:post,
               "/api/v1/sections/#{@section.id}/assignments/#{@a1.id}/submissions/update_grades",
               { controller: "submissions_api",
                 action: "bulk_update",
                 format: "json",
                 section_id: @section.id.to_s,
                 assignment_id: @a1.id.to_s },
               grade_data)

      run_jobs
      s1 = @student1.submissions.first
      expect(s1.grade).to eq "5%"
    end

    it "nils grade when receiving empty posted_grade" do
      @a1.grade_student(@student1, grade: "5%", grader: @teacher)

      grade_data = {
        grade_data: {
          @student1.id => { posted_grade: nil }
        }
      }
      api_call(:post,
               "/api/v1/sections/#{@section.id}/assignments/#{@a1.id}/submissions/update_grades",
               { controller: "submissions_api",
                 action: "bulk_update",
                 format: "json",
                 section_id: @section.id.to_s,
                 assignment_id: @a1.id.to_s },
               grade_data)

      run_jobs
      s1 = @student1.submissions.first
      expect(s1.grade).to be_nil
    end

    it "will not enqueue jobs for deleted assignments" do
      @a1.destroy
      grade_data = {
        grade_data: {
          @student1.id => { posted_grade: "75%" },
          @student2.id => { posted_grade: "95%" }
        }
      }

      api_call(:post,
               "/api/v1/courses/#{@course.id}/assignments/#{@a1.id}/submissions/update_grades",
               { controller: "submissions_api",
                 action: "bulk_update",
                 format: "json",
                 course_id: @course.id.to_s,
                 assignment_id: @a1.id.to_s },
               grade_data)
      assert_status(400)
      run_jobs
      expect(Submission.count).to eq(2)
      s1 = @student1.submissions.first
      expect(s1.grade).to be_nil
      s2 = @student2.submissions.first
      expect(s2.grade).to be_nil
    end
  end

  describe "list_gradeable_students" do
    before(:once) do
      course_with_teacher active_all: true
      ta_in_course active_all: true
      @student1 = student_in_course(active_all: true).user
      @student2 = student_in_course(active_all: true).user
      @assignment = @course.assignments.build
      @assignment.moderated_grading = true
      @assignment.grader_count = 1
      @assignment.save!
      @assignment.submit_homework @student1, body: "EHLO"
      @path = "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/gradeable_students"
      @params = { controller: "submissions_api",
                  action: "gradeable_students",
                  format: "json",
                  course_id: @course.to_param,
                  assignment_id: @assignment.to_param }
    end

    it "requires grading rights" do
      api_call_as_user(@student1, :get, @path, @params, {}, {}, { expected_status: 401 })
    end

    it "lists students with and without submissions" do
      json = api_call_as_user(@ta, :get, @path, @params)
      expect(json.pluck("id")).to match_array([@student1.id, @student2.id])
    end

    it "anonymizes student ids if anonymously grading" do
      allow_any_instance_of(Assignment).to receive(:can_view_student_names?).and_return false
      params = @params.merge(allow_new_anonymous_id: true)
      json = api_call_as_user(@ta, :get, @path, params)
      expect(json.pluck("anonymous_id")).to match_array([
                                                          @assignment.submission_for_student(@student1).anonymous_id, @assignment.submission_for_student(@student2).anonymous_id
                                                        ])
    end

    it "returns default avatars if anonymously grading" do
      allow_any_instance_of(Assignment).to receive(:can_view_student_names?).and_return false
      params = @params.merge(allow_new_anonymous_id: true)
      json = api_call_as_user(@ta, :get, @path, params)
      expect(json.pluck("avatar_image_url")).to match_array([User.default_avatar_fallback, User.default_avatar_fallback])
    end

    it "does not return identifiable attributes if anonymously grading" do
      allow_any_instance_of(Assignment).to receive(:can_view_student_names?).and_return false
      # This is a workaround until mobile supports new anonymous grading
      params = @params.merge(allow_new_anonymous_id: true)
      json = api_call_as_user(@ta, :get, @path, params)
      anon_names = json.sort_by { |sub| sub["anonymous_id"] }.pluck("display_name")
      expect(json.pluck("id")).to match_array([nil, nil])
      expect(anon_names).to match_array(["Student 1", "Student 2"])
      expect(json.pluck("html_url")).to match_array([nil, nil])
    end

    it "paginates" do
      json = api_call_as_user(@teacher, :get, @path + "?per_page=1", @params.merge(per_page: "1"))
      expect(json.size).to eq 1
      expect(response.headers).to include "Link"
      expect(response.headers["Link"]).to match(/rel="next"/)
    end

    describe "include[]=provisional_grades" do
      before(:once) do
        @course.root_account.enable_service(:avatars)
        @course.root_account.save!
        @path = "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/gradeable_students?include[]=provisional_grades"
        @params = { controller: "submissions_api",
                    action: "gradeable_students",
                    format: "json",
                    course_id: @course.to_param,
                    assignment_id: @assignment.to_param,
                    include: ["provisional_grades"] }
      end

      it "is unauthorized when the user is not the assigned final grader" do
        api_call_as_user(@teacher, :get, @path, @params, {}, {}, expected_status: 401)
      end

      it "is unauthorized when the user is an account admin without 'Select Final Grade for Moderation' permission" do
        @course.account.role_overrides.create!(role: admin_role, enabled: false, permission: :select_final_grade)
        api_call_as_user(account_admin_user, :get, @path, @params, {}, {}, expected_status: 401)
      end

      it "is authorized when the user is the final grader" do
        @assignment.update!(final_grader: @teacher, grader_count: 2)
        api_call_as_user(@teacher, :get, @path, @params, {}, {}, expected_status: 200)
      end

      it "is authorized when the user is an account admin with 'Select Final Grade for Moderation' permission" do
        api_call_as_user(account_admin_user, :get, @path, @params, {}, {}, expected_status: 200)
      end

      it "includes provisional grades with selections" do
        @assignment.update!(final_grader: @teacher)
        sub = @assignment.grade_student(@student1, score: 90, grader: @ta, provisional: true).first
        pg = sub.provisional_grades.first
        @assignment.moderated_grading_selections
                   .where(student_id: @student1.id).first
                   .update_attribute(:provisional_grade, pg)
        json = api_call_as_user(@teacher, :get, @path, @params)
        expect(json).to match_array(
          [{ "id" => @student1.id,
             "anonymous_id" => @student1.id.to_s(36),
             "display_name" => "User",
             "avatar_image_url" => "http://www.example.com/images/messages/avatar-50.png",
             "pronouns" => nil,
             "html_url" => "http://www.example.com/courses/#{@course.id}/users/#{@student1.id}",
             "in_moderation_set" => true,
             "selected_provisional_grade_id" => pg.id,
             "provisional_grades" =>
              [{ "grade" => "90",
                 "entered_grade" => "90",
                 "score" => 90,
                 "entered_score" => 90,
                 "graded_at" => pg.graded_at.iso8601,
                 "scorer_id" => @ta.id,
                 "provisional_grade_id" => pg.id,
                 "grade_matches_current_submission" => true,
                 "graded_anonymously" => nil,
                 "final" => false,
                 "speedgrader_url" => "http://www.example.com/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}&student_id=#{@student1.id}" }] },
           { "id" => @student2.id,
             "anonymous_id" => @student2.id.to_s(36),
             "display_name" => "User",
             "avatar_image_url" => "http://www.example.com/images/messages/avatar-50.png",
             "pronouns" => nil,
             "html_url" => "http://www.example.com/courses/#{@course.id}/users/#{@student2.id}",
             "in_moderation_set" => false,
             "selected_provisional_grade_id" => nil,
             "provisional_grades" => [] }]
        )
      end

      it "anonymizes speedgrader_url if anonymously grading" do
        @assignment.update!(final_grader: @teacher)
        sub = @assignment.grade_student(@student1, score: 90, grader: @ta, provisional: true).first
        pg = sub.provisional_grades.first
        @assignment.moderated_grading_selections
                   .where(student_id: @student1.id).first
                   .update_attribute(:provisional_grade, pg)
        allow_any_instance_of(Assignment).to receive(:can_view_student_names?).and_return false
        json = api_call_as_user(@teacher, :get, @path, @params)
        anonymous_id = @assignment.submission_for_student(@student1).anonymous_id
        json = json.filter_map { |el| el["provisional_grades"][0] }
        expect(json[0]["speedgrader_url"]).to match_path("http://www.example.com/courses/#{@course.id}/gradebook/speed_grader")
          .and_query({ assignment_id: @assignment.id, anonymous_id: })
        expect(json[0]["scorer_id"]).to eq @ta.id
        expect(json[0]["anonymous_grader_id"]).to be_nil
      end

      it "anonymizes scorer id of provisional grade if grading double blind" do
        @assignment.update!(final_grader: @teacher)
        sub = @assignment.grade_student(@student1, score: 90, grader: @ta, provisional: true).first
        pg = sub.provisional_grades.first
        @assignment.moderated_grading_selections
                   .where(student_id: @student1.id).first
                   .update_attribute(:provisional_grade, pg)
        allow_any_instance_of(Assignment).to receive(:can_view_student_names?).and_return false
        allow_any_instance_of(Assignment).to receive(:can_view_other_grader_identities?).and_return false
        json = api_call_as_user(@teacher, :get, @path, @params)
        json = json.filter_map { |el| el["provisional_grades"][0] }
        expect(json[0]["anonymous_grader_id"]).to eq @assignment.grader_ids_to_anonymous_ids[@ta.id.to_s]
        expect(json[0]["scorer_id"]).to be_nil
      end
    end
  end

  describe "list_gradeable_students_for_multiple_assignments" do
    before(:once) do
      course_with_teacher active_all: true
      ta_in_course active_all: true
      @student1 = student_in_course(active_all: true).user
      @student2 = student_in_course(active_all: true).user
      @assignment1 = @course.assignments.build
      @assignment1.moderated_grading = true
      @assignment1.grader_count = 1
      @assignment1.save!
      @assignment2 = @course.assignments.build
      @assignment2.save!
      @assignment_ids = [@assignment1.id, @assignment2.id]
      @path = "/api/v1/courses/#{@course.id}/assignments/gradeable_students"
      @params = { controller: "submissions_api",
                  action: "multiple_gradeable_students",
                  format: "json",
                  course_id: @course.to_param,
                  assignment_ids: [@assignment1.to_param, @assignment2.to_param] }
    end

    it "requires grading rights" do
      api_call_as_user(@student1, :get, @path, @params, {}, {}, { expected_status: 401 })
    end

    it "lists students" do
      json = api_call_as_user(@ta, :get, @path, @params)

      expect(json.pluck("id")).to match_array([@student1.id, @student2.id])
      expect(json[0]["assignment_ids"]).to match_array(@assignment_ids)
      expect(json[1]["assignment_ids"]).to match_array(@assignment_ids)
    end

    it "paginates" do
      json = api_call_as_user(@teacher, :get, @path + "?per_page=1", @params.merge(per_page: "1"))
      expect(json.size).to eq 1
      expect(response.headers).to include "Link"
      expect(response.headers["Link"]).to match(/rel="next"/)
    end

    it "limits access to sections user is a part of" do
      section = add_section("Test Section")
      section_teacher = teacher_in_section(section, active_all: true, limit_privileges_to_course_section: true)
      section_student = student_in_section(section, active_all: true)

      json = api_call_as_user(section_teacher, :get, @path, @params)

      expect(json.size).to eq 1
      expect(json[0]["id"]).to eq section_student.id
    end

    it "respects differentiated assignments" do
      assignment = @course.assignments.build
      section = add_section("Test Section")
      section_teacher = teacher_in_section(section, active_all: true)
      section_student = student_in_section(section, active_all: true)
      differentiated_assignment(assignment:, course_section: section)

      differentiated_params = { controller: "submissions_api",
                                action: "multiple_gradeable_students",
                                format: "json",
                                course_id: @course.to_param,
                                assignment_ids: [@assignment.id] }

      json = api_call_as_user(section_teacher, :get, @path, differentiated_params)

      expect(json.size).to eq 1
      expect(json[0]["id"]).to eq section_student.id
    end
  end

  describe "#index" do
    context "grouped_submissions" do
      let(:course) { course_factory }
      let(:teacher)   { user_factory(active_all: true) }
      let(:student1)  { user_factory(active_all: true) }
      let(:student2)  { user_factory(active_all: true) }
      let(:group) do
        group_category = course.group_categories.create(name: "Engineering")
        course.groups.create(name: "Group1", group_category:)
      end
      let(:assignment) do
        course.assignments.create!(
          title: "group assignment",
          grading_type: "points",
          points_possible: 10,
          submission_types: "online_text_entry",
          group_category: group.group_category
        )
      end

      let!(:enroll_teacher_and_students) do
        course.enroll_teacher(teacher).accept!
        course.enroll_student(student1, enrollment_state: "active")
        course.enroll_student(student2, enrollment_state: "active")
      end
      let!(:add_students_to_group) do
        group.add_user(student1)
        group.add_user(student2)
      end
      let!(:submit_homework) { assignment.submit_homework(student1, submission_type: "online_text_entry") }

      let(:path) { "/api/v1/courses/#{course.id}/assignments/#{assignment.id}/submissions" }
      let(:params) do
        {
          controller: "submissions_api",
          action: "index",
          format: "json",
          course_id: course.id.to_s,
          assignment_id: assignment.id.to_s
        }
      end

      it "returns two assignment and submission objects for a user group" do
        params[:grouped] = false
        json = api_call_as_user(teacher, :get, path, params)
        expect(json.size).to eq 2
      end

      it "returns a single assignment and submission object per user group" do
        params[:grouped] = true
        json = api_call_as_user(teacher, :get, path, params)
        expect(json.size).to eq 1
      end

      it "includes the group_id and group_name if include[]=group is passed" do
        params[:include] = %w[group]
        json = api_call_as_user(teacher, :get, path, params)
        expect(json.first.fetch("group").fetch("id")).to eq group.id
        expect(json.first.fetch("group").fetch("name")).to eq group.name
      end

      context "submission of type basic_lti_launch" do
        let(:external_tool_url) { "http://www.test.com/basic-launch" }
        let(:assignment) do
          course.assignments.create!(
            title: "group assignment",
            grading_type: "points",
            points_possible: 10,
            submission_types: "basic_lti_launch",
            group_category: group.group_category
          )
        end
        let!(:submit_homework) { assignment.submit_homework(student1, submission_type: "basic_lti_launch", url: external_tool_url) }

        it "includes the submission launch URL" do
          expected_url = "http://www.example.com/courses/#{assignment.course.id}/external_tools/retrieve?assignment_id=#{assignment.id}&url=http%3A%2F%2Fwww.test.com%2Fbasic-launch"
          submission_json = api_call_as_user(teacher, :get, path, params)
          expect(submission_json.first["url"]).to eq expected_url
        end

        it "includes the external tool URL" do
          submission_json = api_call_as_user(teacher, :get, path, params)
          expect(submission_json.first["external_tool_url"]).to eq external_tool_url
        end

        it "optionally excludes the external tool URL" do
          body_params = { exclude_response_fields: ["external_tool_url"] }
          submission_json = api_call_as_user(teacher, :get, path, params, body_params)
          expect(submission_json.first).not_to have_key "external_tool_url"
        end

        it "optionally excludes the url" do
          body_params = { exclude_response_fields: ["url"] }
          submission_json = api_call_as_user(teacher, :get, path, params, body_params)
          expect(submission_json.first).not_to have_key "url"
        end
      end

      describe "submission_status" do
        let(:field) { "submission_status" }

        it "does not include label" do
          json = api_call_as_user(teacher, :get, path, params)
          json.each do |entry| # can't use `.not_to all`
            expect(entry).not_to include field
          end
        end

        it "includes label when label is passed to the include param" do
          json = api_call_as_user(teacher, :get, path, params.merge(include: field))
          expect(json).to all include field
        end

        it "defaults to unsubmitted for newly created assignment" do
          assignment = course.assignments.create!(
            title: "new_assignment",
            grading_type: "points",
            points_possible: 10,
            submission_types: "online_text_entry"
          )
          path = "/api/v1/courses/#{course.id}/assignments/#{assignment.id}/submissions"
          json = api_call_as_user(teacher, :get, path, params.merge(assignment_id: assignment.id, include: field))
          expect(json).to all include(field.to_s => "unsubmitted")
        end
      end

      describe "grading_status" do
        let(:field) { "grading_status" }

        it "does not include action" do
          json = api_call_as_user(teacher, :get, path, params)
          json.each do |entry| # can't use `.not_to all`
            expect(entry).not_to include field
          end
        end

        it "includes action when action is passed to the include param" do
          json = api_call_as_user(teacher, :get, path, params.merge(include: field))
          expect(json).to all include field
        end
      end
    end
  end

  describe "#submission_summary" do
    before(:once) do
      course_with_teacher active_all: true
      @student1 = student_in_course(active_all: true).user
      @student2 = student_in_course(active_all: true).user
      @student3 = student_in_course(active_all: true).user

      @section = @course.course_sections.build(name: "Another Section")
      @section.save
      @section.enroll_user(@student1, "StudentEnrollment", "active")
      @section.enroll_user(@student2, "StudentEnrollment", "active")
      @section.enroll_user(@student3, "StudentEnrollment", "active")

      @assignment = @course.assignments.create(points_possible: 100)
      @assignment.submit_homework @student1, body: "EHLO"
      @assignment.submit_homework @student2, body: "EHLO"
      @assignment.grade_student @student1, score: 99, grader: @teacher
      @path = "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submission_summary"
      @params = { controller: "submissions_api",
                  action: "submission_summary",
                  format: "json",
                  course_id: @course.to_param,
                  assignment_id: @assignment.to_param }
    end

    it "summarizes submissions" do
      json = api_call_as_user(@teacher, :get, @path, @params)
      expect(json["graded"]).to eq 1
      expect(json["ungraded"]).to eq 1
      expect(json["not_submitted"]).to eq 1
    end

    it "summarizes submissions with multiple submissions by the same student" do
      @assignment.submit_homework @student2, body: "EHLO2"
      @assignment.submit_homework @student2, body: "EHLO3"
      @assignment.submit_homework @student2, body: "EHLO4"
      json = api_call_as_user(@teacher, :get, @path, @params)
      expect(json["graded"]).to eq 1
      expect(json["ungraded"]).to eq 1
      expect(json["not_submitted"]).to eq 1
    end

    it "summarizes submissions with multiple submissions by the same student but one of them graded" do
      @assignment.submit_homework @student2, body: "EHLO2"
      @assignment.grade_student @student2, score: 98, grader: @teacher
      json = api_call_as_user(@teacher, :get, @path, @params)
      expect(json["graded"]).to eq 2
      expect(json["ungraded"]).to eq 0
      expect(json["not_submitted"]).to eq 1
    end

    it "summarizes submission with multiple submission where latest submission needs grading" do
      @assignment.submit_homework @student2, body: "EHLO2"
      @assignment.grade_student @student2, score: 98, grader: @teacher
      @assignment.submit_homework @student2, body: "EHLO3"
      json = api_call_as_user(@teacher, :get, @path, @params)
      expect(json["graded"]).to eq 1
      expect(json["ungraded"]).to eq 1
      expect(json["not_submitted"]).to eq 1
    end

    it "doesnt count submissions where the grade was removed as graded" do
      @assignment.submit_homework @student2, body: "EHLO2"
      @assignment.grade_student @student2, score: 98, grader: @teacher
      @assignment.grade_student @student2, score: nil, grader: @teacher
      json = api_call_as_user(@teacher, :get, @path, @params)
      expect(json["graded"]).to eq 1
      expect(json["ungraded"]).to eq 1
      expect(json["not_submitted"]).to eq 1
    end

    it "is unauthorized as a student" do
      json = api_call_as_user(@student1, :get, @path, @params)
      expect(json["status"]).to eq "unauthorized"
      expect(json["errors"][0]["message"]).to eq "user not authorized to perform that action"
    end

    it "counts excused as graded" do
      @assignment.grade_student @student2, excused: true, grader: @teacher
      json = api_call_as_user(@teacher, :get, @path, @params)
      expect(json["graded"]).to eq 2
      expect(json["ungraded"]).to eq 0
      expect(json["not_submitted"]).to eq 1
    end

    it "counts quiz submissions in pending_review as not_graded" do
      quiz = @course.quizzes.create! title: "title"
      quiz.quiz_questions.create!(question_data: { question_type: "essay" })
      quiz.quiz_questions.create!(question_data: { question_type: "multiple_choice", answers: [{ "id" => 1 }, { "id" => 2 }] })
      quiz.generate_quiz_data
      quiz.save!
      asg = quiz.assignment
      asg.publish

      sub1 = quiz.generate_submission(@student3)
      sub1.start_grading
      sub1.update_attribute(:workflow_state, "pending_review")
      sub1.update_attribute(:score, 1.0)

      @path = "/api/v1/courses/#{@course.id}/assignments/#{asg.id}/submission_summary"
      @params = { controller: "submissions_api",
                  action: "submission_summary",
                  format: "json",
                  course_id: @course.to_param,
                  assignment_id: asg.to_param }

      json = api_call_as_user(@teacher, :get, @path, @params)
      expect(json["graded"]).to eq 0
      expect(json["ungraded"]).to eq 1
      expect(json["not_submitted"]).to eq 2
    end

    it "returns a 404" do
      assg_id = @assignment.id + 100
      @path = "/api/v1/courses/#{@course.id}/assignments/#{assg_id}/submission_summary"
      @params = { controller: "submissions_api",
                  action: "submission_summary",
                  format: "json",
                  course_id: @course.to_param,
                  assignment_id: assg_id.to_s }
      response = api_call_as_user(@teacher, :get, @path, @params)
      assert_status(404)
      expect(response["errors"][0]["message"]).to eq "The specified resource does not exist."
    end

    it "doesnt show submissions from various inactive types of enrollments" do
      inactive = %w[deleted rejected inactive invited]

      @student4 = student_in_course(active_all: true).user
      enrollment = @section.enroll_user(@student4, "StudentEnrollment", "active")
      @assignment.submit_homework @student4, body: "EHLO"

      inactive.each do |state|
        enrollment.workflow_state = state
        enrollment.save!

        json = api_call_as_user(@teacher, :get, @path, @params)
        expect(json["graded"]).to eq 1
        expect(json["ungraded"]).to eq 1
        expect(json["not_submitted"]).to eq 1
      end
    end

    context "group assignments" do
      it "returns the summary grouped by groups" do
        group_category = @course.group_categories.create(name: "Project Groups")
        group1 = group_category.groups.create(name: "Project Group 1", context: @course)
        group2 = group_category.groups.create(name: "Project Group 2", context: @course)
        group_category.save!
        group1.users << @student1
        group1.users << @student2
        group2.users << @student3

        assignment = @course.assignments.create(points_possible: 100, group_category:, grade_group_students_individually: false)
        assignment.submit_homework @student1, body: "EHLO"
        assignment.submit_homework @student3, body: "EHLO"
        assignment.grade_student @student1, score: 99, grader: @teacher
        path = "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}/submission_summary?grouped=true"
        params = { controller: "submissions_api",
                   action: "submission_summary",
                   format: "json",
                   course_id: @course.to_param,
                   assignment_id: assignment.to_param,
                   grouped: true }

        json = api_call_as_user(@teacher, :get, path, params)
        expect(json["graded"]).to eq 1
        expect(json["ungraded"]).to eq 1
        expect(json["not_submitted"]).to eq 0
      end

      it "does not return the summary grouped by groups if the grouped param isnt sent" do
        group_category = @course.group_categories.create(name: "Project Groups")
        group1 = group_category.groups.create(name: "Project Group 1", context: @course)
        group2 = group_category.groups.create(name: "Project Group 2", context: @course)
        group_category.save!
        group1.users << @student1
        group1.users << @student2
        group2.users << @student3

        assignment = @course.assignments.create(points_possible: 100, group_category:, grade_group_students_individually: false)
        assignment.submit_homework @student1, body: "EHLO"
        assignment.grade_student @student1, score: 99, grader: @teacher

        path = "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}/submission_summary"
        params = { controller: "submissions_api",
                   action: "submission_summary",
                   format: "json",
                   course_id: @course.to_param,
                   assignment_id: assignment.to_param }

        json = api_call_as_user(@teacher, :get, path, params)
        expect(json["graded"]).to eq 2
        expect(json["ungraded"]).to eq 0
        expect(json["not_submitted"]).to eq 1
      end

      it "does not return the summary grouped by groups if grade_group_students_individually is true" do
        group_category = @course.group_categories.create(name: "Project Groups")
        group1 = group_category.groups.create(name: "Project Group 1", context: @course)
        group2 = group_category.groups.create(name: "Project Group 2", context: @course)
        group_category.save!
        group1.users << @student1
        group1.users << @student2
        group2.users << @student3

        assignment = @course.assignments.create(points_possible: 100, group_category:, grade_group_students_individually: true)
        assignment.submit_homework @student1, body: "EHLO"
        assignment.grade_student @student1, score: 99, grader: @teacher

        path = "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}/submission_summary?grouped=true"
        params = { controller: "submissions_api",
                   action: "submission_summary",
                   format: "json",
                   course_id: @course.to_param,
                   assignment_id: assignment.to_param,
                   grouped: true }

        json = api_call_as_user(@teacher, :get, path, params)
        expect(json["graded"]).to eq 1
        expect(json["ungraded"]).to eq 1
        expect(json["not_submitted"]).to eq 1
      end

      it "does not return the summary grouped by groups if grade_group_students_individually is true without grouped param" do
        group_category = @course.group_categories.create(name: "Project Groups")
        group1 = group_category.groups.create(name: "Project Group 1", context: @course)
        group2 = group_category.groups.create(name: "Project Group 2", context: @course)
        group_category.save!
        group1.users << @student1
        group1.users << @student2
        group2.users << @student3

        assignment = @course.assignments.create(points_possible: 100, group_category:, grade_group_students_individually: true)
        assignment.submit_homework @student1, body: "EHLO"
        assignment.grade_student @student1, score: 99, grader: @teacher

        path = "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}/submission_summary"
        params = { controller: "submissions_api",
                   action: "submission_summary",
                   format: "json",
                   course_id: @course.to_param,
                   assignment_id: assignment.to_param }

        json = api_call_as_user(@teacher, :get, path, params)
        expect(json["graded"]).to eq 1
        expect(json["ungraded"]).to eq 1
        expect(json["not_submitted"]).to eq 1
      end

      it "doesnt error when the assignment isnt a group assignment" do
        path = "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submission_summary?grouped=true"
        params = { controller: "submissions_api",
                   action: "submission_summary",
                   format: "json",
                   course_id: @course.to_param,
                   assignment_id: @assignment.to_param,
                   grouped: true }
        json = api_call_as_user(@teacher, :get, path, params)
        expect(json["graded"]).to eq 1
        expect(json["ungraded"]).to eq 1
        expect(json["not_submitted"]).to eq 1
      end
    end
  end
end
