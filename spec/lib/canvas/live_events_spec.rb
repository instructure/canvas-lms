# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require "lti2_spec_helper"

describe Canvas::LiveEvents do
  let(:submission_event_endpoint) { "test.com/submission" }
  let(:submission_event_service) do
    {
      "endpoint" => submission_event_endpoint,
      "format" => ["application/json"],
      "action" => ["POST"],
      "@id" => "http://test.service.com/service#vnd.Canvas.SubmissionEvent",
      "@type" => "RestService"
    }
  end
  # The only methods tested in here are ones that have any sort of logic happening.

  def expect_event(event_name, event_body, event_context = nil)
    expect(LiveEvents).to receive(:post_event).with(
      event_name: event_name,
      payload: event_body,
      time: anything,
      context: event_context
    )
  end

  before do
    LiveEvents.stream_client = Class.new do
      attr_accessor :data, :stream, :stream_name

      def initialize(stream_name = "stream")
        @stream_name = stream_name
      end

      def put_records(stream_name:, records:)
        @data = records
        @stream = stream_name
      end

      def body
        @data["body"]
      end
    end.new
    allow(LiveEvents).to receive(:get_context).and_return({ compact_live_events: true })
  end

  let(:course_context) do
    hash_including(
      root_account_uuid: @course.root_account.uuid,
      root_account_id: @course.root_account.global_id.to_s,
      root_account_lti_guid: @course.root_account.lti_guid.to_s,
      context_id: @course.global_id.to_s,
      context_type: "Course"
    )
  end

  describe ".amended_context" do
    it "pulls the context from the canvas context" do
      LiveEvents.set_context(nil)
      course = course_model
      amended_context = Canvas::LiveEvents.amended_context(course)

      context_id = course.global_id
      context_type = course.class.to_s
      root_account_id = course.root_account.global_id
      root_account_uuid = course.root_account.uuid
      root_account_lti_guid = course.root_account.lti_guid

      expect(amended_context).to eq(
        {
          context_id: context_id,
          context_type: context_type,
          root_account_id: root_account_id,
          root_account_uuid: root_account_uuid.to_s,
          root_account_lti_guid: root_account_lti_guid.to_s,
          compact_live_events: true
        }
      )
    end

    it "omits root_account fields in user context" do
      LiveEvents.set_context(nil)
      user = user_model
      amended_context = Canvas::LiveEvents.amended_context(user)
      expect(amended_context).to eq({ context_id: user.global_id, context_type: "User", compact_live_events: true })
    end
  end

  describe ".conversation_created" do
    it "triggers a conversation live event with conversation details" do
      user1 = user_model
      user2 = user_model
      conversation = conversation(user1, user2)
      expect_event("conversation_created",
                   hash_including(
                     conversation_id: conversation.id.to_s
                   ))
      Canvas::LiveEvents.conversation_created(conversation)
    end
  end

  describe ".enrollment_updated" do
    it "does not include associated_user_id for non-observer enrollments" do
      enrollment = course_with_student
      expect_event("enrollment_updated", hash_excluding(:associated_user_id))
      Canvas::LiveEvents.enrollment_updated(enrollment)
    end

    it "includes non-nil associated_user_id for assigned observer enrollment" do
      observee = user_model
      enrollment = course_with_observer
      enrollment.associated_user = observee
      expect_event("enrollment_updated",
                   hash_including(
                     associated_user_id: observee.global_id.to_s
                   ))
      Canvas::LiveEvents.enrollment_updated(enrollment)
    end
  end

  describe ".group_category_created" do
    it "includes the context" do
      course = course_model
      group_category = group_category(context: course, group_limit: 2)
      expect_event("group_category_created",
                   hash_including(
                     context_type: "Course",
                     context_id: course.id.to_s,
                     group_limit: 2
                   ))
      Canvas::LiveEvents.group_category_created(group_category)
    end
  end

  describe ".group_category_updated" do
    it "includes the context" do
      course = course_model
      group_category = group_category(context: course, group_limit: 2)
      expect_event("group_category_updated",
                   hash_including(
                     context_type: "Course",
                     context_id: course.id.to_s,
                     group_limit: 2
                   ))
      Canvas::LiveEvents.group_category_updated(group_category)
    end
  end

  describe ".group_updated" do
    it "includes the context" do
      course = course_model
      group = group_model(context: course, max_membership: 2)
      expect_event("group_updated",
                   hash_including(
                     group_id: group.global_id.to_s,
                     context_type: "Course",
                     context_id: course.global_id.to_s,
                     max_membership: 2
                   ))
      Canvas::LiveEvents.group_updated(group)
    end

    it "includes the account" do
      account = account_model
      course = course_model(account: account)
      group = group_model(context: course)
      expect_event("group_updated",
                   hash_including(
                     group_id: group.global_id.to_s,
                     account_id: account.global_id.to_s
                   ))
      Canvas::LiveEvents.group_updated(group)
    end

    it "includes the workflow_state" do
      group = group_model
      expect_event("group_updated",
                   hash_including(
                     group_id: group.global_id.to_s,
                     workflow_state: group.workflow_state
                   ))
      Canvas::LiveEvents.group_updated(group)
    end
  end

  describe ".group_membership_updated" do
    it "includes the workflow_state" do
      user = user_model
      group = group_model
      membership = group_membership_model(group: group, user: user)

      expect_event("group_membership_updated",
                   hash_including(
                     group_membership_id: membership.global_id.to_s,
                     workflow_state: membership.workflow_state
                   ))
      Canvas::LiveEvents.group_membership_updated(membership)
    end
  end

  describe ".wiki_page_updated" do
    before do
      course_with_teacher
      @page = @course.wiki_pages.create(title: "old title", body: "old body")
    end

    def wiki_page_updated
      Canvas::LiveEvents.wiki_page_updated(@page, @page.title_changed? ? @page.title_was : nil, @page.body_changed? ? @page.body_was : nil)
    end

    it "does not set old_title or old_body if they don't change" do
      expect_event("wiki_page_updated", {
                     wiki_page_id: @page.global_id.to_s,
                     title: "old title",
                     body: "old body"
                   })

      wiki_page_updated
    end

    it "sets old_title if the title changed" do
      @page.title = "new title"

      expect_event("wiki_page_updated", {
                     wiki_page_id: @page.global_id.to_s,
                     title: "new title",
                     old_title: "old title",
                     body: "old body"
                   })

      wiki_page_updated
    end

    it "sets old_body if the body changed" do
      @page.body = "new body"

      expect_event("wiki_page_updated", {
                     wiki_page_id: @page.global_id.to_s,
                     title: "old title",
                     body: "new body",
                     old_body: "old body"
                   })

      wiki_page_updated
    end
  end

  describe ".conversation_forwarded" do
    before do
      @user1 = user_model
      @user2 = user_model
      @convo = Conversation.initiate([@user1, @user2], false)
      @convo.add_message(@user1, "Hi! You are doing great...")
    end

    it "triggers live event if a new user is added to a conversation" do
      @user3 = user_model
      @convo.add_participants(@user1, [@user3])
      expect_event("conversation_forwarded",
                   hash_including(
                     conversation_id: @convo.id.to_s
                   ), { compact_live_events: true }).once
      Canvas::LiveEvents.conversation_forwarded(@convo)
    end
  end

  describe ".conversation_message_created" do
    it "includes the author id, conversation message id, and conversation id" do
      user1 = user_model
      user2 = user_model
      convo = Conversation.initiate([user1, user2], false)
      convo_message = convo.add_message(user1, "Hi! You are doing great...")
      expect_event("conversation_message_created",
                   hash_including(
                     author_id: convo_message.author_id.to_s,
                     conversation_id: convo_message.conversation_id.to_s,
                     message_id: convo_message.id.to_s
                   )).once
      Canvas::LiveEvents.conversation_message_created(convo_message)
    end
  end

  describe ".course_grade_change" do
    before(:once) do
      @user = User.create!
      @course = Course.create!
    end

    it "includes the course context, current scores and old scores" do
      enrollment_model
      score = Score.new(
        course_score: true, enrollment: @enrollment,
        current_score: 5.0, final_score: 4.0, unposted_current_score: 3.0, unposted_final_score: 2.0
      )

      expected_body = hash_including(
        current_score: 5.0, final_score: 4.0, unposted_current_score: 3.0, unposted_final_score: 2.0,
        old_current_score: 1.0, old_final_score: 2.0, old_unposted_current_score: 3.0, old_unposted_final_score: 4.0,
        course_id: @enrollment.course_id.to_s, user_id: @enrollment.user_id.to_s,
        workflow_state: "active"
      )
      expect_event("course_grade_change", expected_body, course_context)

      Canvas::LiveEvents.course_grade_change(score, {
                                               current_score: 1.0,
                                               final_score: 2.0,
                                               unposted_current_score: 3.0,
                                               unposted_final_score: 4.0
                                             }, score.enrollment)
    end
  end

  describe ".grade_changed" do
    it "sets the grader to nil for an autograded quiz" do
      quiz_with_graded_submission([])

      expect_event("grade_change", hash_including({
        submission_id: @quiz_submission.submission.global_id.to_s,
        assignment_id: @quiz_submission.submission.global_assignment_id.to_s,
        assignment_name: @quiz_submission.submission.assignment.name,
        grader_id: nil,
        student_id: @quiz_submission.user.global_id.to_s,
        user_id: @quiz_submission.user.global_id.to_s
      }.compact!), course_context)

      Canvas::LiveEvents.grade_changed(@quiz_submission.submission, @quiz_submission.submission.versions.current.model)
    end

    it "sets the grader when a teacher grades an assignment" do
      course_with_student_submissions
      submission = @course.assignments.first.submissions.first

      expect_event("grade_change", hash_including(
                                     submission_id: submission.global_id.to_s,
                                     assignment_id: submission.global_assignment_id.to_s,
                                     assignment_name: submission.assignment.name,
                                     grader_id: @teacher.global_id.to_s,
                                     student_id: @student.global_id.to_s,
                                     user_id: @student.global_id.to_s
                                   ), course_context)

      submission.grader = @teacher
      submission.grade = "10"
      submission.score = 10
      Canvas::LiveEvents.grade_changed(submission)
    end

    it "includes the user_id and assignment_id" do
      course_with_student_submissions
      submission = @course.assignments.first.submissions.first

      expect_event("grade_change",
                   hash_including({
                     assignment_id: submission.global_assignment_id.to_s,
                     assignment_name: submission.assignment.name,
                     user_id: @student.global_id.to_s,
                     student_id: @student.global_id.to_s,
                     student_sis_id: nil
                   }.compact!), course_context)
      Canvas::LiveEvents.grade_changed(submission, 0)
    end

    it "includes the student_sis_id if present" do
      course_with_student_submissions
      user_with_pseudonym(user: @student)
      @pseudonym.sis_user_id = "sis-id-1"
      @pseudonym.save!
      submission = @course.assignments.first.submissions.first

      expect_event("grade_change",
                   hash_including(
                     student_sis_id: "sis-id-1"
                   ), course_context)
      Canvas::LiveEvents.grade_changed(submission, 0)
    end

    it "includes previous score attributes" do
      course_with_student_submissions submission_points: true
      submission = @course.assignments.first.submissions.first

      submission.score = 9000
      expect_event("grade_change",
                   hash_including(
                     score: 9000,
                     old_score: 5
                   ), course_context)
      Canvas::LiveEvents.grade_changed(submission, submission.versions.current.model)
    end

    it "includes previous points_possible attributes" do
      course_with_student_submissions
      assignment = @course.assignments.first
      assignment.points_possible = 5
      assignment.save!
      submission = assignment.submissions.first

      submission.assignment.points_possible = 99

      expect_event("grade_change",
                   hash_including(
                     points_possible: 99,
                     old_points_possible: 5
                   ), course_context)
      Canvas::LiveEvents.grade_changed(submission, submission, assignment.versions.current.model)
    end

    it "includes course context even when global course context unset" do
      allow(LiveEvents).to receive(:get_context).and_return({
                                                              root_account_uuid: nil,
                                                              root_account_id: nil,
                                                              root_account_lti_guid: nil,
                                                              context_id: nil,
                                                              context_type: nil,
                                                              foo: "bar"
                                                            })
      course_with_student_submissions
      submission = @course.assignments.first.submissions.first

      expect_event("grade_change", anything, course_context)
      Canvas::LiveEvents.grade_changed(submission)
    end

    it "includes existing context when global course context overridden" do
      allow(LiveEvents).to receive(:get_context).and_return({ foo: "bar" })
      course_with_student_submissions
      submission = @course.assignments.first.submissions.first

      expect_event("grade_change", anything, hash_including({ foo: "bar" }))
      Canvas::LiveEvents.grade_changed(submission)
    end

    context "grading_complete" do
      before do
        course_with_student_submissions
      end

      let(:submission) { @course.assignments.first.submissions.first }

      it "is false when submission is not graded" do
        expect_event("grade_change", hash_including(
                                       grading_complete: false
                                     ), course_context)
        Canvas::LiveEvents.grade_changed(submission)
      end

      it "is true when submission is fully graded" do
        submission.score = 0
        submission.workflow_state = "graded"

        expect_event("grade_change", hash_including(
                                       grading_complete: true
                                     ), course_context)
        Canvas::LiveEvents.grade_changed(submission)
      end

      it "is false when submission is partially graded" do
        submission.score = 0
        submission.workflow_state = "pending_review"

        expect_event("grade_change", hash_including(
                                       grading_complete: false
                                     ), course_context)
        Canvas::LiveEvents.grade_changed(submission)
      end
    end

    context "muted" do
      before do
        course_with_student_submissions
      end

      let(:assignment) { @course.assignments.first }
      let(:submission) { assignment.submissions.first }

      context "with post policies enabled" do
        before do
          assignment.hide_submissions
        end

        it "is not called when a grade is changed for a submission that is not posted" do
          expect_event("grade_change", hash_including(
                                         muted: true
                                       ), course_context)
          Canvas::LiveEvents.grade_changed(submission)
        end

        it "is false when the grade is changed for a submission that is posted" do
          assignment.post_submissions

          expect_event("grade_change", hash_including(
                                         muted: false
                                       ), course_context)
          Canvas::LiveEvents.grade_changed(submission)
        end
      end

      context "with post policies disabled" do
        it "is true when assignment is muted" do
          submission.assignment.mute!
          expect_event("grade_change", hash_including(
                                         muted: true
                                       ), course_context)
          Canvas::LiveEvents.grade_changed(submission)
        end
      end
    end
  end

  context "submissions" do
    let(:submission) do
      course_with_student_submissions
      @student.update(lti_context_id: SecureRandom.uuid)
      s = @course.assignments.first.submissions.first
      s.update(lti_user_id: @student.lti_context_id)
      s
    end

    let(:group) do
      Group.create!(
        name: "test group",
        workflow_state: "available",
        context: submission.assignment.course
      )
    end

    before { submission }

    shared_examples_for "a submission event" do |event_name|
      it "includes the user_id and assignment_id" do
        expect_event(
          event_name,
          hash_including(
            workflow_state: "unsubmitted",
            user_id: @student.global_id.to_s,
            lti_user_id: @student.lti_context_id,
            assignment_id: submission.global_assignment_id.to_s,
            lti_assignment_id: submission.assignment.lti_context_id.to_s
          ),
          course_context
        )
        Canvas::LiveEvents.send(event_name.to_sym, submission)
      end

      it "includes the group_id if assignment is a group assignment" do
        submission.update(group: group)

        expect_event(
          event_name,
          hash_including(
            group_id: group.id.to_s
          ),
          course_context
        )
        Canvas::LiveEvents.send(event_name.to_sym, submission)
      end

      context "with assignment configuration tool lookup" do
        include_context "lti2_spec_helper"
        let(:product_family) do
          Lti::ProductFamily.create!(
            vendor_code: "turnitin.com",
            product_code: "turnitin-lti",
            vendor_name: "TurnItIn",
            root_account: account,
            developer_key: developer_key
          )
        end

        it "includes the associated_integration_id if there is an installed tool proxy with that id" do
          submission.assignment.assignment_configuration_tool_lookups.create!(
            tool_product_code: "turnitin-lti",
            tool_vendor_code: "turnitin.com",
            tool_resource_type_code: "resource-type-code",
            tool_type: "Lti::MessageHandler"
          )

          tool_proxy = create_tool_proxy(submission.assignment.course)
          tool_proxy[:raw_data]["tool_profile"] = { "service_offered" => [submission_event_service] }
          tool_proxy.save!

          Lti::ResourceHandler.create!(
            tool_proxy: tool_proxy,
            name: "resource_handler",
            resource_type_code: "resource-type-code"
          )

          expect_event(
            event_name,
            hash_including(
              associated_integration_id: tool_proxy.guid
            ),
            course_context
          )
          Canvas::LiveEvents.send(event_name.to_sym, submission)
        end

        it "temporarily includes multiple associated_integration_ids if there is an installed tool proxy" do
          submission.assignment.assignment_configuration_tool_lookups.create!(
            tool_product_code: "turnitin-lti",
            tool_vendor_code: "turnitin.com",
            tool_resource_type_code: "resource-type-code",
            tool_type: "Lti::MessageHandler"
          )

          tool_proxy = create_tool_proxy(submission.assignment.course)
          tool_proxy[:raw_data]["tool_profile"] = { "service_offered" => [submission_event_service] }
          tool_proxy.save!

          Lti::ResourceHandler.create!(
            tool_proxy: tool_proxy,
            name: "resource_handler",
            resource_type_code: "resource-type-code"
          )

          expect_event(
            event_name,
            hash_including(
              associated_integration_ids: [tool_proxy.guid, "turnitin.com_turnitin-lti_test.com/submission"]
            ),
            course_context
          )
          Canvas::LiveEvents.send(event_name.to_sym, submission)
        end

        it "does not include the associated_integration_id if there is no longer an installed tool with that id" do
          submission.assignment.assignment_configuration_tool_lookups.create!(tool_product_code: "turnitin-lti",
                                                                              tool_vendor_code: "turnitin.com", tool_type: "Lti::MessageHandler")

          expect_event(
            event_name,
            hash_not_including(
              :associated_integration_id
            ),
            course_context
          )
          Canvas::LiveEvents.send(event_name.to_sym, submission)
        end
      end
    end

    describe ".submission_created" do
      it_behaves_like "a submission event", "submission_created"
    end

    describe ".submission_updated" do
      it_behaves_like "a submission event", "submission_updated"

      it "includes late and missing flags" do
        submission.update(late_policy_status: "missing")

        expect_event(
          "submission_updated",
          hash_including(
            late: false,
            missing: true
          ),
          course_context
        )
        Canvas::LiveEvents.submission_updated(submission)
      end

      it "includes posted_at" do
        post_time = Time.zone.now
        submission.update(posted_at: post_time)

        expect_event(
          "submission_updated",
          hash_including(
            posted_at: post_time
          ),
          course_context
        )
        Canvas::LiveEvents.submission_updated(submission)
      end
    end

    describe ".submissions_bulk_updated" do
      before do
        # This creates a course with a single student and a number of assignments
        # equal to the value of "submissions"
        course_with_student_submissions(submissions: 3)
      end

      let(:submissions) do
        @student.submissions.order(:id)
      end

      it "emits a submission_updated event for each passed submission" do
        expect_event("submission_updated",
                     hash_including(
                       :submission_id
                     ), course_context).exactly(3).times

        Canvas::LiveEvents.submissions_bulk_updated(submissions)
      end

      it "includes the ID of an affected submission in each event" do
        aggregate_failures do
          expect_event("submission_updated",
                       hash_including(
                         submission_id: submissions.first.global_id.to_s
                       ), course_context).ordered
          expect_event("submission_updated",
                       hash_including(
                         submission_id: submissions.second.global_id.to_s
                       ), course_context).ordered
          expect_event("submission_updated",
                       hash_including(
                         submission_id: submissions.third.global_id.to_s
                       ), course_context).ordered

          Canvas::LiveEvents.submissions_bulk_updated(submissions)
        end
      end
    end

    describe ".submission_comment_created" do
      it "triggers a submission comment created live event" do
        comment = submission.submission_comments.create!(
          comment: "here is a comment",
          submission_id: submission.id, author_id: @student.id
        )
        expect_event("submission_comment_created", {
                       user_id: comment.author_id.to_s,
                       created_at: comment.created_at,
                       submission_id: comment.submission_id.to_s,
                       body: comment.comment,
                       attachment_ids: [],
                       submission_comment_id: comment.id.to_s,
                     }).once
        Canvas::LiveEvents.submission_comment_created(comment)
      end
    end

    describe ".plagiarism_resubmit" do
      it_behaves_like "a submission event", "plagiarism_resubmit"
    end
  end

  describe ".asset_access" do
    it "triggers a live event without an asset subtype" do
      course_factory

      expect_event("asset_accessed", {
        asset_name: "Unnamed Course",
        asset_type: "course",
        asset_id: @course.global_id.to_s,
        asset_subtype: nil,
        category: "category",
        role: "role",
        level: "participation"
      }.compact!, { compact_live_events: true }).once

      Canvas::LiveEvents.asset_access(@course, "category", "role", "participation")
    end

    it "triggers a live event with an asset subtype" do
      course_factory

      expect_event("asset_accessed", {
                     asset_name: "Unnamed Course",
                     asset_type: "course",
                     asset_id: @course.global_id.to_s,
                     asset_subtype: "assignments",
                     category: "category",
                     role: "role",
                     level: "participation"
                   }, { compact_live_events: true }).once

      Canvas::LiveEvents.asset_access(["assignments", @course], "category", "role", "participation")
    end

    it "asset_name is correctly accessed when title is used" do
      course_with_teacher
      @page = @course.wiki_pages.create(title: "old title", body: "old body")

      expect_event("asset_accessed", {
                     asset_name: "old title",
                     asset_type: "wiki_page",
                     asset_id: @page.global_id.to_s,
                     category: "category",
                     role: "role",
                     level: "participation"
                   }, { compact_live_events: true }).once

      Canvas::LiveEvents.asset_access(@page, "category", "role", "participation")
    end

    it "includes filename and display_name if asset is an attachment" do
      attachment_model

      expect_event("asset_accessed", {
        asset_name: "unknown.loser",
        asset_type: "attachment",
        asset_id: @attachment.global_id.to_s,
        asset_subtype: nil,
        category: "files",
        role: "role",
        level: "participation",
        filename: @attachment.filename,
        display_name: @attachment.display_name
      }.compact!, { compact_live_events: true }).once

      Canvas::LiveEvents.asset_access(@attachment, "files", "role", "participation")
    end

    it "provides a different context if a different context is provided" do
      attachment_model
      context = OpenStruct.new(global_id: "1")

      expect_event("asset_accessed", {
        asset_name: "unknown.loser",
        asset_type: "attachment",
        asset_id: @attachment.global_id.to_s,
        asset_subtype: nil,
        category: "files",
        role: "role",
        level: "participation",
        filename: @attachment.filename,
        display_name: @attachment.display_name
      }.compact!,
                   {
                     compact_live_events: true,
                     context_type: context.class.to_s,
                     context_id: "1"
                   }).once

      Canvas::LiveEvents.asset_access(@attachment, "files", "role", "participation", context: context)
    end

    it "includes enrollment data if provided" do
      course_with_student

      expect_event("asset_accessed", {
                     asset_name: "Unnamed Course",
                     asset_type: "course",
                     asset_id: @course.global_id.to_s,
                     asset_subtype: "assignments",
                     category: "category",
                     role: "role",
                     level: "participation",
                     enrollment_id: @enrollment.id.to_s,
                     section_id: @enrollment.course_section_id.to_s
                   }, { compact_live_events: true }).once

      Canvas::LiveEvents.asset_access(["assignments", @course], "category", "role", "participation",
                                      context: nil, context_membership: @enrollment)
    end
  end

  describe ".assignment_created" do
    before do
      course_with_student_submissions
      @assignment = @course.assignments.first
    end

    it "triggers a live event with assignment details" do
      expect_event("assignment_created",
                   hash_including({
                     assignment_id: @assignment.global_id.to_s,
                     context_id: @course.global_id.to_s,
                     context_uuid: @course.uuid,
                     context_type: "Course",
                     workflow_state: @assignment.workflow_state,
                     title: @assignment.title,
                     description: @assignment.description,
                     due_at: @assignment.due_at,
                     unlock_at: @assignment.unlock_at,
                     lock_at: @assignment.lock_at,
                     points_possible: @assignment.points_possible,
                     lti_assignment_id: @assignment.lti_context_id,
                     lti_resource_link_id: @assignment.lti_resource_link_id,
                     lti_resource_link_id_duplicated_from: @assignment.duplicate_of&.lti_resource_link_id,
                     submission_types: @assignment.submission_types,
                     domain: @assignment.root_account.domain
                   }.compact!)).once

      Canvas::LiveEvents.assignment_created(@assignment)
    end

    context "with assignment configuration tool lookup" do
      include_context "lti2_spec_helper"
      let(:product_family) do
        Lti::ProductFamily.create!(
          vendor_code: "turnitin.com",
          product_code: "turnitin-lti",
          vendor_name: "TurnItIn",
          root_account: account,
          developer_key: developer_key
        )
      end

      it "includes the associated_integration_id if there is an installed tool proxy with that id" do
        @assignment.assignment_configuration_tool_lookups.create!(
          tool_product_code: "turnitin-lti",
          tool_vendor_code: "turnitin.com",
          tool_resource_type_code: "resource-type-code",
          tool_type: "Lti::MessageHandler"
        )
        tool_proxy = create_tool_proxy(@assignment.course)
        tool_proxy[:raw_data]["tool_profile"] = { "service_offered" => [submission_event_service] }
        tool_proxy.save!

        Lti::ResourceHandler.create!(
          tool_proxy: tool_proxy,
          name: "resource_handler",
          resource_type_code: "resource-type-code"
        )

        expect_event(
          "assignment_created",
          hash_including(associated_integration_id: tool_proxy.guid)
        )
        Canvas::LiveEvents.assignment_created(@assignment)
      end

      it "temporarily includes multiple associated_integration_ids if there is an installed tool proxy" do
        @assignment.assignment_configuration_tool_lookups.create!(
          tool_product_code: "turnitin-lti",
          tool_vendor_code: "turnitin.com",
          tool_resource_type_code: "resource-type-code",
          tool_type: "Lti::MessageHandler"
        )
        tool_proxy = create_tool_proxy(@assignment.course)
        tool_proxy[:raw_data]["tool_profile"] = { "service_offered" => [submission_event_service] }
        tool_proxy.save!

        Lti::ResourceHandler.create!(
          tool_proxy: tool_proxy,
          name: "resource_handler",
          resource_type_code: "resource-type-code"
        )

        expect_event(
          "assignment_created",
          hash_including(associated_integration_ids: [tool_proxy.guid, "turnitin.com_turnitin-lti_test.com/submission"])
        )
        Canvas::LiveEvents.assignment_created(@assignment)
      end

      it "does not include the associated_integration_id if there is no longer an installed tool with that id" do
        @assignment.assignment_configuration_tool_lookups.create!(
          tool_product_code: "turnitin-lti",
          tool_vendor_code: "turnitin.com",
          tool_resource_type_code: "resource-type-code",
          tool_type: "Lti::MessageHandler"
        )

        expect_event(
          "assignment_created",
          hash_not_including(:associated_integration_id)
        )
        Canvas::LiveEvents.assignment_created(@assignment)
      end
    end
  end

  describe ".assignment_updated" do
    before do
      course_with_student_submissions
      @assignment = @course.assignments.first
    end

    it "triggers a live event with assignment details" do
      expect_event("assignment_updated",
                   hash_including({
                     assignment_id: @assignment.global_id.to_s,
                     context_id: @course.global_id.to_s,
                     context_uuid: @course.uuid,
                     context_type: "Course",
                     workflow_state: @assignment.workflow_state,
                     title: @assignment.title,
                     description: @assignment.description,
                     due_at: @assignment.due_at,
                     unlock_at: @assignment.unlock_at,
                     lock_at: @assignment.lock_at,
                     points_possible: @assignment.points_possible,
                     lti_assignment_id: @assignment.lti_context_id,
                     lti_resource_link_id: @assignment.lti_resource_link_id,
                     lti_resource_link_id_duplicated_from: @assignment.duplicate_of&.lti_resource_link_id,
                     submission_types: @assignment.submission_types,
                     domain: @assignment.root_account.domain
                   }.compact!)).once

      Canvas::LiveEvents.assignment_updated(@assignment)
    end

    context "with assignment configuration tool lookup" do
      include_context "lti2_spec_helper"
      let(:product_family) do
        Lti::ProductFamily.create!(
          vendor_code: "turnitin.com",
          product_code: "turnitin-lti",
          vendor_name: "TurnItIn",
          root_account: account,
          developer_key: developer_key
        )
      end

      it "includes the associated_integration_id if there is an installed tool proxy with that id" do
        @assignment.assignment_configuration_tool_lookups.create!(
          tool_product_code: "turnitin-lti",
          tool_vendor_code: "turnitin.com",
          tool_resource_type_code: "resource-type-code",
          tool_type: "Lti::MessageHandler"
        )

        tool_proxy = create_tool_proxy(@assignment.course)
        tool_proxy[:raw_data]["tool_profile"] = { "service_offered" => [submission_event_service] }
        tool_proxy.save!

        Lti::ResourceHandler.create!(
          tool_proxy: tool_proxy,
          name: "resource_handler",
          resource_type_code: "resource-type-code"
        )

        expect_event(
          "assignment_updated",
          hash_including(associated_integration_id: tool_proxy.guid)
        )
        Canvas::LiveEvents.assignment_updated(@assignment)
      end

      it "does not include the associated_integration_id if there is no longer an installed tool with that id" do
        @assignment.assignment_configuration_tool_lookups.create!(tool_product_code: "turnitin-lti",
                                                                  tool_vendor_code: "turnitin.com", tool_type: "Lti::MessageHandler")

        expect_event(
          "assignment_updated",
          hash_not_including(:associated_integration_id)
        )
        Canvas::LiveEvents.assignment_updated(@assignment)
      end
    end
  end

  describe "assignment_group_updated" do
    let(:course) do
      course_with_student_submissions
      @course
    end
    let(:assignment_group) { course.assignment_groups.take }
    let(:expected_data) do
      {
        assignment_group_id: assignment_group.id.to_s,
        context_id: assignment_group.context_id.to_s,
        context_type: assignment_group.context_type,
        name: assignment_group.name,
        position: assignment_group.position,
        group_weight: assignment_group.group_weight,
        sis_source_id: assignment_group.sis_source_id,
        integration_data: assignment_group.integration_data,
        rules: assignment_group.rules,
        workflow_state: assignment_group.workflow_state
      }.compact!
    end

    context "when updated" do
      it "sends the expected data" do
        expect_event("assignment_group_updated", expected_data).once
        Canvas::LiveEvents.assignment_group_updated(assignment_group)
      end
    end

    context "when created" do
      it "sends the expected data" do
        expect_event("assignment_group_created", expected_data).once
        Canvas::LiveEvents.assignment_group_created(assignment_group)
      end
    end
  end

  describe "assignment_override_updated" do
    def base_override_hash(override)
      {
        assignment_override_id: override.id.to_s,
        assignment_id: override.assignment.id.to_s,
        due_at: override.due_at,
        all_day: override.all_day,
        all_day_date: override.all_day_date,
        unlock_at: override.unlock_at,
        lock_at: override.lock_at,
        type: override.set_type,
        workflow_state: override.workflow_state,
      }.compact!
    end

    it "triggers a live event with ADHOC assignment override details" do
      course_with_student_submissions
      assignment = @course.assignments.first
      override = create_adhoc_override_for_assignment(assignment, @student)

      expect_event("assignment_override_updated",
                   hash_including(base_override_hash(override).merge({
                                                                       type: "ADHOC",
                                                                     }))).once

      Canvas::LiveEvents.assignment_override_updated(override)
    end

    it "triggers a live event with CourseSection assignment override details" do
      course_with_student_submissions
      assignment = @course.assignments.first
      override = create_section_override_for_assignment(assignment)
      section = override.set

      expect_event("assignment_override_updated",
                   hash_including(base_override_hash(override).merge({
                                                                       type: "CourseSection",
                                                                       course_section_id: section.id.to_s,
                                                                     }))).once

      Canvas::LiveEvents.assignment_override_updated(override)
    end

    it "triggers a live event with Group assignment override details" do
      course_with_student
      assignment = group_assignment_discussion(course: @course).assignment
      override = create_group_override_for_assignment(assignment, group: @group)

      expect_event("assignment_override_updated",
                   hash_including(base_override_hash(override).merge({
                                                                       type: "Group",
                                                                       group_id: override.set.id.to_s,
                                                                     }))).once

      Canvas::LiveEvents.assignment_override_updated(override)
    end
  end

  describe ".quiz_export_complete" do
    let(:export_class) do
      Class.new do
        attr_accessor :context

        def initialize(context)
          @context = context
        end

        def global_id
          123_456_789
        end

        def settings
          {
            quizzes2: {
              key1: "val1",
              key2: "val2"
            }
          }
        end
      end
    end
    let(:content_export) { export_class.new(course_model) }

    it "triggers a live event with content export settings and amended context details" do
      fake_export_context = { key1: "val1", key2: "val2", content_export_id: "content-export-123456789" }

      expect_event(
        "quiz_export_complete",
        fake_export_context,
        hash_including({
                         context_type: "Course",
                         context_id: content_export.context.global_id.to_s,
                         root_account_id: content_export.context.root_account.global_id.to_s,
                         root_account_uuid: content_export.context.root_account.uuid,
                         root_account_lti_guid: content_export.context.root_account.lti_guid.to_s,
                       })
      ).once

      Canvas::LiveEvents.quiz_export_complete(content_export)
    end
  end

  describe ".content_migration_completed" do
    let(:course) { course_factory }
    let(:source_course) { course_factory }
    let(:migration) { ContentMigration.create(context: course, source_course: source_course, migration_type: "some_type") }

    before do
      migration.migration_settings[:import_quizzes_next] = true
      course.lti_context_id = "abc"
      source_course.lti_context_id = "def"
    end

    it "sent events with expected payload" do
      expect_event(
        "content_migration_completed",
        hash_including(
          content_migration_id: migration.global_id.to_s,
          context_id: course.global_id.to_s,
          context_type: course.class.to_s,
          context_uuid: course.uuid,
          import_quizzes_next: true,
          domain: course.root_account.domain,
          source_course_lti_id: migration.source_course.lti_context_id,
          destination_course_lti_id: course.lti_context_id,
          migration_type: migration.migration_type
        ),
        hash_including(
          context_type: course.class.to_s,
          context_id: course.global_id.to_s,
          root_account_id: course.root_account.global_id.to_s,
          root_account_uuid: course.root_account.uuid,
          root_account_lti_guid: course.root_account.lti_guid.to_s
        )
      ).once

      Canvas::LiveEvents.content_migration_completed(migration)
    end
  end

  describe ".course_section_created" do
    it "triggers a course section creation live event" do
      course_with_student_submissions
      section = @course.course_sections.first

      expect_event("course_section_created",
                   {
                     course_section_id: section.id.to_s,
                     sis_source_id: nil,
                     sis_batch_id: nil,
                     course_id: section.course_id.to_s,
                     root_account_id: section.root_account_id.to_s,
                     enrollment_term_id: nil,
                     name: section.name,
                     default_section: section.default_section,
                     accepting_enrollments: section.accepting_enrollments,
                     can_manually_enroll: section.can_manually_enroll,
                     start_at: section.start_at,
                     end_at: section.end_at,
                     workflow_state: section.workflow_state,
                     restrict_enrollments_to_section_dates: section.restrict_enrollments_to_section_dates,
                     nonxlist_course_id: nil,
                     stuck_sis_fields: section.stuck_sis_fields,
                     integration_id: nil
                   }.compact!).once
      Canvas::LiveEvents.course_section_created(section)
    end
  end

  describe ".course_section_updated" do
    it "triggers a course section creation live event" do
      course_with_student_submissions
      section = @course.course_sections.first

      expect_event("course_section_updated",
                   {
                     course_section_id: section.id.to_s,
                     sis_source_id: nil,
                     sis_batch_id: nil,
                     course_id: section.course_id.to_s,
                     root_account_id: section.root_account_id.to_s,
                     enrollment_term_id: nil,
                     name: section.name,
                     default_section: section.default_section,
                     accepting_enrollments: section.accepting_enrollments,
                     can_manually_enroll: section.can_manually_enroll,
                     start_at: section.start_at,
                     end_at: section.end_at,
                     workflow_state: section.workflow_state,
                     restrict_enrollments_to_section_dates: section.restrict_enrollments_to_section_dates,
                     nonxlist_course_id: nil,
                     stuck_sis_fields: section.stuck_sis_fields,
                     integration_id: nil
                   }.compact!).once
      Canvas::LiveEvents.course_section_updated(section)
    end
  end

  describe ".logged_in" do
    it "triggers a live event with user details" do
      user_with_pseudonym

      session = { return_to: "http://www.canvaslms.com/", session_id: SecureRandom.uuid }
      context = {
        user_id: @user.global_id.to_s,
        user_login: @pseudonym.unique_id,
        user_account_id: @pseudonym.global_account_id.to_s,
        user_sis_id: @pseudonym.sis_user_id,
        session_id: session[:session_id]
      }

      expect_event(
        "logged_in",
        { redirect_url: "http://www.canvaslms.com/" },
        hash_including(context)
      ).once

      Canvas::LiveEvents.logged_in(session, @user, @pseudonym)
    end
  end

  describe ".quizzes_next_quiz_duplicated" do
    it "triggers a quiz duplicated live event" do
      event_payload = {
        original_course_id: "1234",
        new_course_id: "5678",
        original_resource_link_id: "abc123",
        new_resource_link_id: "def456",
        domain: "canvas.instructure.com"
      }

      expect_event("quizzes_next_quiz_duplicated", event_payload).once

      Canvas::LiveEvents.quizzes_next_quiz_duplicated(event_payload)
    end
  end

  describe ".module_created" do
    it "triggers a context module created live event" do
      course_with_student_submissions
      context_module = ContextModule.create!(context: @course)

      expected_event_body = {
        module_id: context_module.id.to_s,
        context_id: @course.id.to_s,
        context_type: "Course",
        name: context_module.name,
        position: context_module.position,
        workflow_state: context_module.workflow_state
      }.compact!

      expect_event("module_created", expected_event_body).once

      Canvas::LiveEvents.module_created(context_module)
    end
  end

  describe ".module_updated" do
    it "triggers a context module updated live event" do
      course_with_student_submissions
      context_module = ContextModule.create!(context: @course)

      expected_event_body = {
        module_id: context_module.id.to_s,
        context_id: @course.id.to_s,
        context_type: "Course",
        name: context_module.name,
        position: context_module.position,
        workflow_state: context_module.workflow_state
      }.compact!

      expect_event("module_updated", expected_event_body).once

      Canvas::LiveEvents.module_updated(context_module)
    end
  end

  describe ".module_item_created" do
    it "triggers a context module item created live event" do
      course_with_student_submissions
      context_module = ContextModule.create!(context: @course)
      content_tag = ContentTag.create!(
        title: "content",
        context: @course,
        context_module: context_module,
        content: @course.assignments.first
      )

      expected_event_body = {
        module_item_id: content_tag.id.to_s,
        module_id: context_module.id.to_s,
        context_id: @course.id.to_s,
        context_type: "Course",
        position: content_tag.position,
        workflow_state: content_tag.workflow_state
      }

      expect_event("module_item_created", expected_event_body).once

      Canvas::LiveEvents.module_item_created(content_tag)
    end
  end

  describe ".module_item_updated" do
    it "triggers a context module updated live event" do
      course_with_student_submissions
      context_module = ContextModule.create!(context: @course)
      content_tag = ContentTag.create!(
        title: "content",
        context: @course,
        context_module: context_module,
        content: @course.assignments.first
      )

      expected_event_body = {
        module_item_id: content_tag.id.to_s,
        module_id: context_module.id.to_s,
        context_id: @course.id.to_s,
        context_type: "Course",
        position: content_tag.position,
        workflow_state: content_tag.workflow_state
      }

      expect_event("module_item_updated", expected_event_body).once

      Canvas::LiveEvents.module_item_updated(content_tag)
    end
  end

  describe ".course_completed" do
    it "triggers a course completed live event" do
      course = course_model(sis_source_id: "abc123")
      user = user_model
      context_module = course.context_modules.create!
      context_module_progression = context_module.context_module_progressions.create!(user_id: user.id, workflow_state: "completed")

      expected_event_body = {
        progress: CourseProgress.new(course, user, read_only: true).to_json,
        user: { id: user.id.to_s, name: user.name, email: user.email },
        course: { id: course.id.to_s, name: course.name,
                  account_id: course.account_id.to_s, sis_source_id: "abc123" }
      }

      expect_event("course_completed", expected_event_body).once

      Canvas::LiveEvents.course_completed(context_module_progression)
    end
  end

  describe ".course_progress" do
    it "triggers a course progress live event" do
      course = course_model(sis_source_id: "abc123")
      user = user_model
      context_module = course.context_modules.create!
      # context_module_progression = context_module.context_module_progressions.create!(user_id: user.id, workflow_state: 'completed')
      context_module_progression = context_module.context_module_progressions.create!(user_id: user.id, workflow_state: "started")

      expected_event_body = {
        progress: CourseProgress.new(course, user, read_only: true).to_json,
        user: { id: user.id.to_s, name: user.name, email: user.email },
        course: { id: course.id.to_s, name: course.name,
                  account_id: course.account_id.to_s, sis_source_id: "abc123" }
      }

      expect_event("course_progress", expected_event_body).once

      Canvas::LiveEvents.course_progress(context_module_progression)
    end
  end

  describe "ContextModuleProgression LiveEventsCallback" do
    it "queues a job to dispatch .course_completed" do
      course = course_model(sis_source_id: "abc123")
      user = user_model
      context_module = course.context_modules.create!
      context_module_progression = context_module.context_module_progressions.create!(user_id: user.id)
      context_module_progression.workflow_state = "completed"
      context_module_progression.completed_at = Time.now

      allow(Rails.env).to receive(:production?).and_return(true)

      # post-transaction callbacks won't happen in specs, so do this manually
      Canvas::LiveEventsCallbacks.after_update(context_module_progression, context_module_progression.changes)

      cmp_id = context_module_progression.context_module.global_context_id
      singleton = "course_progress_course_#{cmp_id}_user_#{context_module_progression.global_user_id}"
      job = Delayed::Job.where(singleton: singleton).take
      expect(job).not_to be_nil
      expect(job.run_at).to be > Time.now
      expect(job.max_concurrent).to eq 1
      expect(job.tag).to eq "CourseProgress.dispatch_live_event"
    end
  end

  describe ".discussion_topic_created" do
    it "triggers a discussion topic created live event" do
      course = course_model
      assignment = course.assignments.create!
      topic = course.discussion_topics.create!(
        title: "test title",
        message: "test body",
        assignment_id: assignment.id
      )

      expect_event("discussion_topic_created", {
        discussion_topic_id: topic.global_id.to_s,
        is_announcement: topic.is_announcement,
        title: topic.title,
        body: topic.message,
        assignment_id: topic.assignment_id.to_s,
        context_id: topic.context_id.to_s,
        context_type: topic.context_type,
        workflow_state: topic.workflow_state,
        lock_at: topic.lock_at,
        updated_at: topic.updated_at
      }.compact!).once

      Canvas::LiveEvents.discussion_topic_created(topic)
    end
  end

  describe ".discussion_entry_submitted" do
    context "with non graded discussion" do
      it "creates a discussion entry created live event" do
        course_with_student
        topic = @course.discussion_topics.create!(
          title: "test title",
          message: "test body"
        )
        entry = topic.discussion_entries.create!(
          message: "<p>This is a reply</p>",
          user_id: @student.id
        )

        expect_event("discussion_entry_submitted", {
                       user_id: entry.user_id.to_s,
                       created_at: entry.created_at,
                       discussion_entry_id: entry.id.to_s,
                       discussion_topic_id: entry.discussion_topic_id.to_s,
                       text: entry.message
                     }).once

        Canvas::LiveEvents.discussion_entry_submitted(entry, nil, nil)
      end
    end

    context "with graded discussion" do
      it "includes assignment and submission in created live event" do
        course_with_student_submissions
        assignment = @course.assignments.first
        submission = assignment.submission_for_student_id(@student.id)
        topic = @course.discussion_topics.create!(
          title: "test title",
          message: "test body",
          assignment_id: assignment.id
        )
        entry = topic.discussion_entries.create!(
          message: "<p>This is a reply</p>",
          user_id: @student.id
        )

        expect_event("discussion_entry_submitted", {
                       assignment_id: assignment.id.to_s,
                       submission_id: submission.id.to_s,
                       user_id: entry.user_id.to_s,
                       created_at: entry.created_at,
                       discussion_entry_id: entry.id.to_s,
                       discussion_topic_id: entry.discussion_topic_id.to_s,
                       text: entry.message
                     }).once

        Canvas::LiveEvents.discussion_entry_submitted(entry, assignment.id, submission.id)
      end
    end
  end

  describe ".learning_outcome_result" do
    let_once :quiz do
      quiz_model(assignment: assignment_model)
    end

    let :result do
      create_and_associate_lor(quiz)
    end

    def create_and_associate_lor(association_object, associated_asset = nil)
      assignment_model
      outcome = @course.created_learning_outcomes.create!(title: "outcome")

      LearningOutcomeResult.new(
        alignment: ContentTag.create!({
                                        title: "content",
                                        context: @course,
                                        learning_outcome: outcome
                                      })
      ).tap do |lor|
        lor.association_object = association_object
        lor.context = @course
        lor.associated_asset = associated_asset || association_object
        lor.save!
      end
    end

    context "created" do
      it "includes result in created live event" do
        expect_event("learning_outcome_result_created", {
          learning_outcome_id: result.learning_outcome_id.to_s,
          mastery: result.mastery,
          score: result.score,
          created_at: result.created_at,
          attempt: result.attempt,
          possible: result.possible,
          original_score: result.original_score,
          original_possible: result.original_possible,
          original_mastery: result.original_mastery,
          assessed_at: result.assessed_at,
          title: result.title,
          percent: result.percent,
          workflow_state: result.workflow_state
        }.compact!).once

        Canvas::LiveEvents.learning_outcome_result_created(result)
      end
    end

    context "updated" do
      it "includes result in updated live event" do
        result.update!(attempt: 1)
        expect_event("learning_outcome_result_updated", {
          learning_outcome_id: result.learning_outcome_id.to_s,
          mastery: result.mastery,
          score: result.score,
          created_at: result.created_at,
          updated_at: result.updated_at,
          attempt: result.attempt,
          possible: result.possible,
          original_score: result.original_score,
          original_possible: result.original_possible,
          original_mastery: result.original_mastery,
          assessed_at: result.assessed_at,
          title: result.title,
          percent: result.percent,
          workflow_state: result.workflow_state
        }.compact!).once

        Canvas::LiveEvents.learning_outcome_result_updated(result)
      end
    end
  end

  describe "user" do
    context "created" do
      it "triggers a user_created live event" do
        user_with_pseudonym

        expect_event("user_created", {
          user_id: @user.global_id.to_s,
          uuid: @user.uuid,
          name: @user.name,
          short_name: @user.short_name,
          workflow_state: @user.workflow_state,
          created_at: @user.created_at,
          updated_at: @user.updated_at,
          user_login: @pseudonym&.unique_id,
          user_sis_id: @pseudonym&.sis_user_id
        }.compact!).once

        Canvas::LiveEvents.user_created(@user)
      end
    end

    context "updated" do
      it "triggers a user_updated live event" do
        user_with_pseudonym

        @user.update!(name: "Test Name")

        expect_event("user_updated", {
          user_id: @user.global_id.to_s,
          uuid: @user.uuid,
          name: @user.name,
          short_name: @user.short_name,
          workflow_state: @user.workflow_state,
          created_at: @user.created_at,
          updated_at: @user.updated_at,
          user_login: @pseudonym&.unique_id,
          user_sis_id: @pseudonym&.sis_user_id
        }.compact!).once

        Canvas::LiveEvents.user_updated(@user)
      end
    end
  end

  describe "learning_outcomes" do
    before do
      @context = course_model
    end

    context "created" do
      it "triggers a learning_outcome_created live event" do
        outcome_model

        expect_event("learning_outcome_created", {
          learning_outcome_id: @outcome.id.to_s,
          context_type: @outcome.context_type,
          context_id: @outcome.context_id.to_s,
          display_name: @outcome.display_name,
          short_description: @outcome.short_description,
          description: @outcome.description,
          vendor_guid: @outcome.vendor_guid,
          calculation_method: @outcome.calculation_method,
          calculation_int: @outcome.calculation_int,
          rubric_criterion: @outcome.rubric_criterion,
          title: @outcome.title,
          workflow_state: @outcome.workflow_state
        }.compact).once

        Canvas::LiveEvents.learning_outcome_created(@outcome)
      end
    end

    context "updated" do
      it "triggers a learning_outcome_updated live event" do
        outcome_model

        @outcome.update!(short_description: "this is new")

        expect_event("learning_outcome_updated", {
          learning_outcome_id: @outcome.id.to_s,
          context_type: @outcome.context_type,
          context_id: @outcome.context_id.to_s,
          display_name: @outcome.display_name,
          short_description: @outcome.short_description,
          description: @outcome.description,
          vendor_guid: @outcome.vendor_guid,
          calculation_method: @outcome.calculation_method,
          calculation_int: @outcome.calculation_int,
          rubric_criterion: @outcome.rubric_criterion,
          title: @outcome.title,
          updated_at: @outcome.updated_at,
          workflow_state: @outcome.workflow_state
        }.compact).once

        Canvas::LiveEvents.learning_outcome_updated(@outcome)
      end
    end
  end

  describe "learning_outcome_groups" do
    before do
      @context = course_model
    end

    context "created" do
      it "triggers a learning_outcome_group_created live event" do
        outcome_group_model

        expect_event("learning_outcome_group_created", {
          learning_outcome_group_id: @outcome_group.id.to_s,
          context_id: @outcome_group.context_id.to_s,
          context_type: @outcome_group.context_type,
          title: @outcome_group.title,
          description: @outcome_group.description,
          vendor_guid: @outcome_group.vendor_guid,
          parent_outcome_group_id: @outcome_group.learning_outcome_group_id.to_s,
          workflow_state: @outcome_group.workflow_state
        }.compact).once

        Canvas::LiveEvents.learning_outcome_group_created(@outcome_group)
      end
    end

    context "updated" do
      it "triggers a learning_outcome_group_updated live event" do
        outcome_group_model

        @outcome_group.update!(title: "this is new")

        expect_event("learning_outcome_group_updated", {
          learning_outcome_group_id: @outcome_group.id.to_s,
          context_id: @outcome_group.context_id.to_s,
          context_type: @outcome_group.context_type,
          title: @outcome_group.title,
          description: @outcome_group.description,
          vendor_guid: @outcome_group.vendor_guid,
          parent_outcome_group_id: @outcome_group.learning_outcome_group_id.to_s,
          updated_at: @outcome_group.updated_at,
          workflow_state: @outcome_group.workflow_state
        }.compact).once

        Canvas::LiveEvents.learning_outcome_group_updated(@outcome_group)
      end
    end
  end

  describe "learning_outcome_links" do
    before do
      @context = course_model
    end

    context "created" do
      it "triggers a learning_outcome_link_created live event" do
        outcome_model
        outcome_group_model

        link = @outcome_group.add_outcome(@outcome)

        expect_event("learning_outcome_link_created", {
          learning_outcome_link_id: link.id.to_s,
          learning_outcome_id: @outcome.id.to_s,
          learning_outcome_group_id: @outcome_group.id.to_s,
          context_id: link.context_id.to_s,
          context_type: link.context_type,
          workflow_state: link.workflow_state
        }.compact).once

        Canvas::LiveEvents.learning_outcome_link_created(link)
      end
    end

    context "updated" do
      it "triggers a learning_outcome_link_updated live event" do
        outcome_model
        outcome_group_model

        link = @outcome_group.add_outcome(@outcome)
        link.destroy!

        expect_event("learning_outcome_link_updated", {
          learning_outcome_link_id: link.id.to_s,
          learning_outcome_id: @outcome.id.to_s,
          learning_outcome_group_id: @outcome_group.id.to_s,
          context_id: link.context_id.to_s,
          context_type: link.context_type,
          workflow_state: link.workflow_state,
          updated_at: link.updated_at
        }.compact).once

        Canvas::LiveEvents.learning_outcome_link_updated(link)
      end
    end
  end

  describe "outcome_proficiency" do
    before do
      @account = account_model
      @rating1 = OutcomeProficiencyRating.new(description: "best", points: 10, mastery: true, color: "00ff00")
      rating2 = OutcomeProficiencyRating.new(description: "worst", points: 0, mastery: false, color: "ff0000")
      @proficiency = OutcomeProficiency.create!(outcome_proficiency_ratings: [@rating1, rating2], context: @account)
    end

    def rating_event(rating)
      {
        outcome_proficiency_rating_id: rating.id.to_s,
        description: rating.description,
        points: rating.points,
        mastery: rating.mastery,
        color: rating.color,
        workflow_state: rating.workflow_state
      }
    end

    context "created" do
      it "triggers an outcome_proficiency_created live event" do
        expect_event("outcome_proficiency_created", {
          outcome_proficiency_id: @proficiency.id.to_s,
          context_id: @proficiency.context_id.to_s,
          context_type: @proficiency.context_type,
          workflow_state: @proficiency.workflow_state,
          outcome_proficiency_ratings: @proficiency.outcome_proficiency_ratings.map { |rating| rating_event(rating) }
        }.compact).once

        Canvas::LiveEvents.outcome_proficiency_created(@proficiency)
      end
    end

    context "updated" do
      it "triggers an outcome_proficiency_updated live event" do
        @proficiency.outcome_proficiency_ratings = [@rating1]
        @proficiency.save!
        expect_event("outcome_proficiency_updated", {
          outcome_proficiency_id: @proficiency.id.to_s,
          context_id: @proficiency.context_id.to_s,
          context_type: @proficiency.context_type,
          workflow_state: @proficiency.workflow_state,
          updated_at: @proficiency.updated_at,
          outcome_proficiency_ratings: @proficiency.outcome_proficiency_ratings.map { |rating| rating_event(rating) }
        }.compact).once
        Canvas::LiveEvents.outcome_proficiency_updated(@proficiency)
      end
    end
  end

  describe "outcome_calculation_method" do
    before do
      @account = account_model
      @calculation_method = outcome_calculation_method_model(@account)
    end

    context "created" do
      it "triggers an outcome_calculation_method_created live event" do
        expect_event("outcome_calculation_method_created", {
          outcome_calculation_method_id: @calculation_method.id.to_s,
          calculation_int: @calculation_method.calculation_int,
          calculation_method: @calculation_method.calculation_method,
          workflow_state: @calculation_method.workflow_state,
          context_id: @calculation_method.context_id.to_s,
          context_type: @calculation_method.context_type
        }.compact).once

        Canvas::LiveEvents.outcome_calculation_method_created(@calculation_method)
      end
    end

    context "updated" do
      it "triggers an outcome_calculation_method_updated live event" do
        expect_event("outcome_calculation_method_updated", {
          outcome_calculation_method_id: @calculation_method.id.to_s,
          calculation_int: @calculation_method.calculation_int,
          calculation_method: @calculation_method.calculation_method,
          workflow_state: @calculation_method.workflow_state,
          context_id: @calculation_method.context_id.to_s,
          context_type: @calculation_method.context_type,
          updated_at: @calculation_method.updated_at,
        }.compact).once
        Canvas::LiveEvents.outcome_calculation_method_updated(@calculation_method)
      end
    end
  end

  describe "grade_override" do
    it "does not send event when score does not change" do
      course_model
      enrollment_model

      score = Score.new(override_score: 100.0, course_score: true)
      old_score = 100.0

      expect(Canvas::LiveEvents).not_to receive(:post_event_stringified)
      Canvas::LiveEvents.grade_override(score, old_score, @enrollment, @course)
    end
  end

  describe "outcome friendly description" do
    before do
      @context = course_model
      outcome = @context.created_learning_outcomes.create!({ title: "new outcome" })
      description = "A friendly description"
      @friendlyDescription = OutcomeFriendlyDescription.create!(
        learning_outcome: outcome,
        context: @context,
        description: description
      )
    end

    context "created" do
      it "triggers an outcome_friendly_description_created live event" do
        expect_event("outcome_friendly_description_created", {
                       outcome_friendly_description_id: @friendlyDescription.id.to_s,
                       context_type: @friendlyDescription.context_type,
                       context_id: @friendlyDescription.context_id.to_s,
                       description: @friendlyDescription.description,
                       workflow_state: @friendlyDescription.workflow_state,
                       learning_outcome_id: @friendlyDescription.learning_outcome_id.to_s,
                       root_account_id: @friendlyDescription.root_account_id.to_s
                     }).once

        Canvas::LiveEvents.outcome_friendly_description_created(@friendlyDescription)
      end
    end

    context "updated" do
      it "triggers an outcome_friendly_description_updated live event" do
        new_description = "A new friendly description"
        @friendlyDescription.description = new_description
        @friendlyDescription.save!
        expect_event("outcome_friendly_description_updated", {
                       outcome_friendly_description_id: @friendlyDescription.id.to_s,
                       context_type: @friendlyDescription.context_type,
                       context_id: @friendlyDescription.context_id.to_s,
                       workflow_state: @friendlyDescription.workflow_state,
                       learning_outcome_id: @friendlyDescription.learning_outcome_id.to_s,
                       root_account_id: @friendlyDescription.root_account_id.to_s,
                       description: new_description,
                       updated_at: @friendlyDescription.updated_at,
                     }).once

        Canvas::LiveEvents.outcome_friendly_description_updated(@friendlyDescription)
      end
    end
  end

  describe "master template" do
    before do
      @course = course_model
      @master_template = MasterCourses::MasterTemplate.create!(course: @course)
    end

    context "created" do
      it "triggers an master_template_created live event" do
        expect_event("master_template_created", {
                       master_template_id: @master_template.id.to_s,
                       master_course_id: @master_template.course_id.to_s,
                       root_account_id: @master_template.root_account_id.to_s
                     }).once
        Canvas::LiveEvents.master_template_created(@master_template)
      end
    end
  end

  describe "master migration" do
    before do
      @course = course_model
      @master_template = MasterCourses::MasterTemplate.create!(course: @course)
      @master_migration = MasterCourses::MasterMigration.create!(master_template: @master_template)
    end

    context "completed" do
      it "triggers an master_migration_completed live event" do
        expect_event("master_migration_completed", {
                       master_template_id: @master_template.id.to_s,
                       master_migration_id: @master_migration.id.to_s,
                       root_account_id: @master_migration.root_account_id.to_s
                     }).once
        Canvas::LiveEvents.master_migration_completed(@master_migration)
      end
    end
  end

  describe "heartbeat" do
    context "when database region is not set (local/open source)" do
      it "sets region to not_configured" do
        expect_event("heartbeat", { region: "not_configured", environment: "test", region_code: "not_configured" })
        Canvas::LiveEvents.heartbeat
      end
    end

    context "when Canvas.region is set" do
      let(:region) { "us-east-1" }
      let(:region_code) { "prod-iad" }

      before do
        allow(Canvas).to receive(:region).and_return(region)
        allow(Canvas).to receive(:region_code).and_return(region_code)
      end

      it "sets region to Canvas.region" do
        expect_event("heartbeat", { region: region, environment: "test", region_code: region_code })
        Canvas::LiveEvents.heartbeat
      end
    end
  end
end
