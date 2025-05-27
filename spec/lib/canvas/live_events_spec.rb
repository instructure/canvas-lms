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
      event_name:,
      payload: event_body,
      time: anything,
      context: event_context
    )
  end

  def dont_expect_event(event_name, event_body)
    expect(LiveEvents).not_to receive(:post_event).with(
      event_name:,
      payload: event_body,
      time: anything,
      context: nil
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
  end

  let(:course_context) do
    hash_including(
      root_account_uuid: @course.root_account.uuid,
      root_account_id: @course.root_account.global_id.to_s,
      root_account_lti_guid: @course.root_account.lti_guid.to_s,
      context_account_id: @course.account&.global_id&.to_s,
      context_id: @course.global_id.to_s,
      context_type: "Course"
    )
  end

  describe ".amended_context" do
    it "pulls the context from the canvas context" do
      LiveEvents.set_context(nil)
      course = course_model(sis_source_id: "some-course-sis-id")
      amended_context = Canvas::LiveEvents.amended_context(course)

      context_id = course.global_id
      context_type = course.class.to_s
      root_account_id = course.root_account.global_id
      root_account_uuid = course.root_account.uuid
      root_account_lti_guid = course.root_account.lti_guid

      expect(amended_context).to eq(
        {
          context_account_id: course.account.global_id,
          context_id:,
          context_sis_source_id: "some-course-sis-id",
          context_type:,
          root_account_id:,
          root_account_uuid: root_account_uuid.to_s,
          root_account_lti_guid: root_account_lti_guid.to_s,
        }
      )
    end

    it "omits root_account fields in user context" do
      LiveEvents.set_context(nil)
      user = user_model
      amended_context = Canvas::LiveEvents.amended_context(user)
      expect(amended_context).to eq({
                                      context_account_id: nil,
                                      context_id: user.global_id,
                                      context_type: "User",
                                    })
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

    it "includes course_uuid and user_uuid" do
      enrollment = course_with_student
      expect_event("enrollment_updated", hash_including(course_uuid: @course.uuid, user_uuid: @user.uuid))
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
      course = course_model(account:)
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
      membership = group_membership_model(group:, user:)

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
                   ),
                   {}).once
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

    it "triggers live event from Incoming Mail (via reply_from) method" do
      # when a user replies to a conversation via email, the IncomingMailProcessor
      # looks up the reply_from method of the object, in this case,
      # reply_from creates a new ConversationMessage and adds it to the conversation
      # this spec should prove that the live event is triggered from the "reply_from"
      allow(LiveEvents).to receive(:post_event)
      user1 = user_model
      user2 = user_model
      convo = Conversation.initiate([user1, user2], false)
      convo_message = convo.reply_from({ user: user1, text: "this is an example incoming mail reply" })
      expect(LiveEvents).to have_received(:post_event).with(
        context: nil,
        event_name: "conversation_message_created",
        time: anything,
        payload: {
          author_id: convo_message.author_id.to_s,
          conversation_id: convo_message.conversation_id.to_s,
          message_id: convo_message.id.to_s,
          created_at: convo_message.created_at
        }
      )
    end

    it "doesnt include conversation_id" do
      user = user_model
      msg = Conversation.build_message(user, "lorem ipsum")
      msg.save
      dont_expect_event("conversation_message_created",
                        hash_including(
                          conversation_id: nil
                        ))
      Canvas::LiveEvents.conversation_message_created(msg)
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
        course_score: true,
        enrollment: @enrollment,
        current_score: 5.0,
        final_score: 4.0,
        unposted_current_score: 3.0,
        unposted_final_score: 2.0
      )

      expected_body = hash_including(
        current_score: 5.0,
        final_score: 4.0,
        unposted_current_score: 3.0,
        unposted_final_score: 2.0,
        old_current_score: 1.0,
        old_final_score: 2.0,
        old_unposted_current_score: 3.0,
        old_unposted_final_score: 4.0,
        course_id: @enrollment.course_id.to_s,
        user_id: @enrollment.user_id.to_s,
        workflow_state: "active"
      )
      expect_event("course_grade_change", expected_body, course_context)

      Canvas::LiveEvents.course_grade_change(score,
                                             {
                                               current_score: 1.0,
                                               final_score: 2.0,
                                               unposted_current_score: 3.0,
                                               unposted_final_score: 4.0
                                             },
                                             score.enrollment)
    end
  end

  describe ".grade_changed" do
    it "sets the grader to nil for an autograded quiz" do
      quiz_with_graded_submission([])

      expect_event("grade_change",
                   hash_including({
                     submission_id: @quiz_submission.submission.global_id.to_s,
                     assignment_id: @quiz_submission.submission.global_assignment_id.to_s,
                     assignment_name: @quiz_submission.submission.assignment.name,
                     grader_id: nil,
                     student_id: @quiz_submission.user.global_id.to_s,
                     user_id: @quiz_submission.user.global_id.to_s
                   }.compact!),
                   course_context)

      Canvas::LiveEvents.grade_changed(@quiz_submission.submission, @quiz_submission.submission.versions.current.model)
    end

    it "sets the grader when a teacher grades an assignment" do
      course_with_student_submissions
      submission = @course.assignments.first.submissions.first

      expect_event("grade_change",
                   hash_including(
                     submission_id: submission.global_id.to_s,
                     assignment_id: submission.global_assignment_id.to_s,
                     assignment_name: submission.assignment.name,
                     grader_id: @teacher.global_id.to_s,
                     student_id: @student.global_id.to_s,
                     user_id: @student.global_id.to_s
                   ),
                   course_context)

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
                   }.compact!),
                   course_context)
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
                   ),
                   course_context)
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
                   ),
                   course_context)
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
                   ),
                   course_context)
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
        expect_event("grade_change",
                     hash_including(
                       grading_complete: false
                     ),
                     course_context)
        Canvas::LiveEvents.grade_changed(submission)
      end

      it "is true when submission is fully graded" do
        submission.score = 0
        submission.workflow_state = "graded"

        expect_event("grade_change",
                     hash_including(
                       grading_complete: true
                     ),
                     course_context)
        Canvas::LiveEvents.grade_changed(submission)
      end

      it "is false when submission is partially graded" do
        submission.score = 0
        submission.workflow_state = "pending_review"

        expect_event("grade_change",
                     hash_including(
                       grading_complete: false
                     ),
                     course_context)
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
          expect_event("grade_change",
                       hash_including(
                         muted: true
                       ),
                       course_context)
          Canvas::LiveEvents.grade_changed(submission)
        end

        it "is false when the grade is changed for a submission that is posted" do
          assignment.post_submissions

          expect_event("grade_change",
                       hash_including(
                         muted: false
                       ),
                       course_context)
          Canvas::LiveEvents.grade_changed(submission)
        end
      end

      context "with post policies disabled" do
        it "is true when assignment is muted" do
          submission.assignment.mute!
          expect_event("grade_change",
                       hash_including(
                         muted: true
                       ),
                       course_context)
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
        submission.update(group:)

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
            developer_key:
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
            tool_proxy:,
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

        it "does not include the associated_integration_id if there is no longer an installed tool with that id" do
          submission.assignment.assignment_configuration_tool_lookups.create!(tool_product_code: "turnitin-lti",
                                                                              tool_vendor_code: "turnitin.com",
                                                                              tool_type: "Lti::MessageHandler")

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
                     ),
                     course_context).exactly(3).times

        Canvas::LiveEvents.submissions_bulk_updated(submissions)
      end

      it "includes the ID of an affected submission in each event" do
        aggregate_failures do
          expect_event("submission_updated",
                       hash_including(
                         submission_id: submissions.first.global_id.to_s
                       ),
                       course_context).ordered
          expect_event("submission_updated",
                       hash_including(
                         submission_id: submissions.second.global_id.to_s
                       ),
                       course_context).ordered
          expect_event("submission_updated",
                       hash_including(
                         submission_id: submissions.third.global_id.to_s
                       ),
                       course_context).ordered

          Canvas::LiveEvents.submissions_bulk_updated(submissions)
        end
      end
    end

    describe ".submission_comment_created" do
      it "triggers a submission comment created live event" do
        comment = submission.submission_comments.create!(
          comment: "here is a comment",
          submission_id: submission.id,
          author_id: @student.id
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

      expect_event("asset_accessed",
                   {
                     asset_name: "Unnamed Course",
                     asset_type: "course",
                     asset_id: @course.global_id.to_s,
                     asset_subtype: nil,
                     category: "category",
                     role: "role",
                     level: "participation"
                   }.compact!,
                   {}).once

      Canvas::LiveEvents.asset_access(@course, "category", "role", "participation")
    end

    it "triggers a live event with an asset subtype" do
      course_factory

      expect_event("asset_accessed",
                   {
                     asset_name: "Unnamed Course",
                     asset_type: "course",
                     asset_id: @course.global_id.to_s,
                     asset_subtype: "assignments",
                     category: "category",
                     role: "role",
                     level: "participation"
                   },
                   {}).once

      Canvas::LiveEvents.asset_access(["assignments", @course], "category", "role", "participation")
    end

    it "asset_name is correctly accessed when title is used" do
      course_with_teacher
      @page = @course.wiki_pages.create(title: "old title", body: "old body")

      expect_event("asset_accessed",
                   {
                     asset_name: "old title",
                     asset_type: "wiki_page",
                     asset_id: @page.global_id.to_s,
                     category: "category",
                     role: "role",
                     level: "participation"
                   },
                   {}).once

      Canvas::LiveEvents.asset_access(@page, "category", "role", "participation")
    end

    it "includes filename and display_name if asset is an attachment" do
      attachment_model

      expect_event("asset_accessed",
                   {
                     asset_name: "unknown.example",
                     asset_type: "attachment",
                     asset_id: @attachment.global_id.to_s,
                     asset_subtype: nil,
                     category: "files",
                     role: "role",
                     level: "participation",
                     filename: @attachment.filename,
                     display_name: @attachment.display_name
                   }.compact!,
                   {}).once

      Canvas::LiveEvents.asset_access(@attachment, "files", "role", "participation")
    end

    it "provides a different context if a different context is provided" do
      attachment_model
      context = instance_double(Course, global_id: "1", account: nil)

      expect_event("asset_accessed",
                   {
                     asset_name: "unknown.example",
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
                     context_account_id: context.account&.global_id&.to_s,
                     context_type: context.class.to_s,
                     context_id: "1"
                   }).once

      Canvas::LiveEvents.asset_access(@attachment, "files", "role", "participation", context:)
    end

    it "includes enrollment data if provided" do
      course_with_student

      expect_event("asset_accessed",
                   {
                     asset_name: "Unnamed Course",
                     asset_type: "course",
                     asset_id: @course.global_id.to_s,
                     asset_subtype: "assignments",
                     category: "category",
                     role: "role",
                     level: "participation",
                     enrollment_id: @enrollment.id.to_s,
                     section_id: @enrollment.course_section_id.to_s
                   },
                   {}).once

      Canvas::LiveEvents.asset_access(["assignments", @course],
                                      "category",
                                      "role",
                                      "participation",
                                      context: nil,
                                      context_membership: @enrollment)
    end
  end

  describe ".assignment_created" do
    before do
      course_with_student_submissions
      @assignment = @course.assignments.first
      @assignment.external_tool_tag = ContentTag.create!(context: @assignment)
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

    context "when the assignment is a duplicate" do
      let(:dupe_assignment) { @course.assignments.create!(title: "the og") }

      before do
        @assignment.update!(duplicate_of: dupe_assignment)
      end

      it "includes duplicate assignment id" do
        expect_event("assignment_created",
                     hash_including({
                                      assignment_id_duplicated_from: dupe_assignment.global_id.to_s,
                                    })).once

        Canvas::LiveEvents.assignment_created(@assignment)
      end

      it "includes duplicate's root account domain" do
        expect_event("assignment_created",
                     hash_including({
                                      domain_duplicated_from: dupe_assignment.root_account.domain,
                                    })).once

        Canvas::LiveEvents.assignment_created(@assignment)
      end

      context "when duplicate has lti_resource_link_id" do
        before do
          dupe_assignment.external_tool_tag = ContentTag.create!(context: dupe_assignment)
        end

        it "is included" do
          expect_event("assignment_created",
                       hash_including({
                                        lti_resource_link_id_duplicated_from: dupe_assignment.lti_resource_link_id,
                                      })).once

          Canvas::LiveEvents.assignment_created(@assignment)
        end
      end
    end

    context "when the assignment is created as part of a blueprint sync" do
      before do
        course = course_model
        master_template = MasterCourses::MasterTemplate.create!(course:)
        child_course = course_model
        MasterCourses::ChildSubscription.create!(master_template:, child_course:)
        @assignment = child_course.assignments.create!(assignment_valid_attributes
          .merge({ migration_id: "mastercourse_1_1_bd72ce9cf355d1b2cc467b2156842281" }))
      end

      it "has the created_on_blueprint_sync field set as true" do
        expect_event("assignment_created",
                     hash_including({
                                      assignment_id: @assignment.global_id.to_s,
                                      created_on_blueprint_sync: true
                                    }))
        Canvas::LiveEvents.assignment_created(@assignment)
      end
    end

    context "when the assignment contains a value for 'asset_map'" do
      before do
        @assignment.resource_map = "https://www.instructure.com/asset-map.json"
      end

      it "includes the resource_map in the live event" do
        expect_event(
          "assignment_created",
          hash_including(
            {
              assignment_id: @assignment.global_id.to_s,
              resource_map: "https://www.instructure.com/asset-map.json"
            }
          )
        )
        Canvas::LiveEvents.assignment_created(@assignment)
      end
    end

    context "when the assignment is manually created in a blueprint child course" do
      before do
        master_template = MasterCourses::MasterTemplate.create!(course: course_model)
        child_course = course_model
        MasterCourses::ChildSubscription.create!(master_template:, child_course:)
        @assignment = child_course.assignments.create!(assignment_valid_attributes)
      end

      it "has created_on_blueprint_sync set as false" do
        expect_event("assignment_created",
                     hash_including({
                                      assignment_id: @assignment.global_id.to_s,
                                      created_on_blueprint_sync: false
                                    }))
        Canvas::LiveEvents.assignment_created(@assignment)
      end
    end

    context "when the assignment is manually created in a blueprint course" do
      before do
        course = course_model
        MasterCourses::MasterTemplate.create!(course:)
        @assignment = course.assignments.create!(assignment_valid_attributes)
      end

      it "has created_on_blueprint_sync set as false" do
        expect_event("assignment_created",
                     hash_including({
                                      assignment_id: @assignment.global_id.to_s,
                                      created_on_blueprint_sync: false
                                    }))
        Canvas::LiveEvents.assignment_created(@assignment)
      end
    end

    context "when the assignment is created in a non-blueprint course" do
      it "has created_on_blueprint_sync set as false" do
        expect_event("assignment_created",
                     hash_including({
                                      assignment_id: @assignment.global_id.to_s,
                                      created_on_blueprint_sync: false
                                    }))
        Canvas::LiveEvents.assignment_created(@assignment)
      end
    end

    context "with assignment configuration tool lookup" do
      include_context "lti2_spec_helper"
      let(:product_family) do
        Lti::ProductFamily.create!(
          vendor_code: "turnitin.com",
          product_code: "turnitin-lti",
          vendor_name: "TurnItIn",
          root_account: account,
          developer_key:
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
          tool_proxy:,
          name: "resource_handler",
          resource_type_code: "resource-type-code"
        )

        expect_event(
          "assignment_created",
          hash_including(associated_integration_id: tool_proxy.guid)
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
                     anonymous_grading: @assignment.anonymous_grading,
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
          developer_key:
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
          tool_proxy:,
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
                                                                  tool_vendor_code: "turnitin.com",
                                                                  tool_type: "Lti::MessageHandler")

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

  describe "ContentExport" do
    let(:export_class) do
      Class.new do
        attr_accessor :context

        def initialize(context)
          @context = context
        end

        def export_type
          :new_quizzes
        end

        def created_at
          003_003_2033
        end

        def context_id
          @context.global_id
        end

        def context_type
          "Course"
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

    describe ".quiz_export_complete" do
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
                           root_account_lti_guid: content_export.context.root_account.lti_guid.to_s
                         })
        ).once

        Canvas::LiveEvents.quiz_export_complete(content_export)
      end
    end

    describe ".content_export_created" do
      before do
        @context = course_model
      end

      let(:content_export) { export_class.new(@context) }

      let(:event_data) do
        {
          content_export_id: 123_456_789.to_s,
          export_type: content_export.export_type,
          created_at: content_export.created_at,
          context_id: content_export.context_id.to_s,
          context_uuid: content_export.context.uuid,
          context_type: content_export.context_type,
          settings: content_export.settings
        }
      end

      it "triggers a live event with content export settings and context details" do
        expect_event("content_export_created", event_data).once

        Canvas::LiveEvents.content_export_created(content_export)
      end
    end
  end

  describe ".content_migration_completed" do
    let(:course) { course_factory }
    let(:source_course) { course_factory }
    let(:migration) do
      ContentMigration.create(context: course,
                              source_course:,
                              migration_type: "some_type",
                              workflow_state: "imported",
                              user: @user)
    end

    before do
      migration.migration_settings[:import_quizzes_next] = true
      course.lti_context_id = "abc"
      source_course.lti_context_id = "def"
      allow(source_course).to receive(:has_new_quizzes?).and_return(true)
      allow(migration).to receive(:file_download_url).and_return("http://example.com/resource_map.json")
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
          source_course_lti_id: source_course.lti_context_id,
          source_course_uuid: source_course&.uuid,
          destination_course_lti_id: course.lti_context_id,
          migration_type: migration.migration_type,
          resource_map_url: "http://example.com/resource_map.json"
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

    describe "resource map property" do
      before do
        allow(migration).to receive(:asset_map_v2?).and_return(true)
        allow(source_course).to receive(:has_new_quizzes?).and_return(false)
      end

      describe "the resource map is not needed" do
        before do
          migration.migration_settings[:import_quizzes_next] = false
        end

        it "does not send the resource map" do
          expect_event(
            "content_migration_completed",
            hash_not_including(:resource_map_url),
            hash_including(context_id: course.global_id.to_s)
          ).once

          Canvas::LiveEvents.content_migration_completed(migration)
        end
      end

      describe "importing new quizzes with link migration" do
        before do
          migration.migration_settings[:import_quizzes_next] = true
        end

        it "sends the resource map" do
          expect_event(
            "content_migration_completed",
            hash_including(resource_map_url: "http://example.com/resource_map.json"),
            hash_including(context_id: course.global_id.to_s)
          ).once

          Canvas::LiveEvents.content_migration_completed(migration)
        end
      end

      describe "importing new quizzes from new quiz QTI" do
        before do
          migration.migration_settings[:quiz_next_imported] = true
        end

        it "sends the resource map" do
          expect_event(
            "content_migration_completed",
            hash_including(resource_map_url: "http://example.com/resource_map.json"),
            hash_including(context_id: course.global_id.to_s)
          ).once

          Canvas::LiveEvents.content_migration_completed(migration)
        end
      end
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
        context_module:,
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
        context_module:,
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
        course: { id: course.id.to_s,
                  name: course.name,
                  account_id: course.account_id.to_s,
                  sis_source_id: "abc123" }
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
        course: { id: course.id.to_s,
                  name: course.name,
                  account_id: course.account_id.to_s,
                  sis_source_id: "abc123" }
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
      context_module_progression.completed_at = Time.zone.now
      context_module_progression.requirements_met = ["all of them"]

      allow(Rails.env).to receive(:production?).and_return(true)

      # post-transaction callbacks won't happen in specs, so do this manually
      Canvas::LiveEventsCallbacks.after_update(context_module_progression, context_module_progression.changes)

      cmp_id = context_module_progression.context_module.global_context_id
      singleton = "course_progress_course_#{cmp_id}_user_#{context_module_progression.global_user_id}"
      job = Delayed::Job.find_by(singleton:)
      expect(job).not_to be_nil
      expect(job.run_at).to be > Time.zone.now
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
      quiz_with_graded_submission([])
    end

    let :result do
      create_and_associate_lor(@quiz, @quiz_submission, @quiz)
    end

    def create_and_associate_lor(association_object, artifact_object, associated_asset = nil)
      assignment_model
      outcome = @course.created_learning_outcomes.create!(title: "outcome")
      student = @course.enroll_student(User.create!, active_all: true).user

      LearningOutcomeResult.new(
        alignment: ContentTag.create!({
                                        title: "content",
                                        context: @course,
                                        learning_outcome: outcome
                                      }),
        user: student
      ).tap do |lor|
        lor.association_object = association_object
        lor.artifact = artifact_object
        lor.context = @course
        lor.associated_asset = associated_asset
        lor.save!
      end
    end

    describe "#learning_outcome_result_artifact_updated_and_created_at_data" do
      it "returns the updated_at and created_at data for the artifact" do
        expect(
          Canvas::LiveEvents.learning_outcome_result_artifact_updated_and_created_at_data(result)
        ).to eq(
          {
            artifact_created_at: result.artifact.created_at,
            artifact_updated_at: result.artifact.updated_at
          }
        )
      end

      it "returns empty set if the artifact is nil" do
        result.update!(artifact: nil)
        result.reload
        expect(Canvas::LiveEvents.learning_outcome_result_artifact_updated_and_created_at_data(result)).to eq({})
      end
    end

    describe "#rubric_assessment_learning_outcome_result_associated_asset" do
      it "updates associated_asset info to the assignment if the artifact is a RubricAssessment" do
        assignment_model
        course_with_student
        outcome_with_rubric(outcome: @outcome, context: @course, outcome_context: Account.default)
        association = @rubric.associate_with(@assignment, @course, purpose: "grading", use_for_grading: true)
        rubric_assessment = rubric_assessment_model(rubric: @rubric, user: @student, assessment_type: "graded")

        create_and_associate_lor(association, rubric_assessment, nil)

        expect_event("learning_outcome_result_created", {
          id: result.id.to_s,
          learning_outcome_id: result.learning_outcome_id.to_s,
          learning_outcome_context_uuid: result.learning_outcome.context&.uuid,
          result_context_id: result.context_id.to_s,
          result_context_type: result.context_type,
          result_context_uuid: result&.context&.uuid,
          mastery: result.mastery,
          score: result.score,
          created_at: result.created_at,
          attempt: result.attempt,
          possible: result.possible,
          original_score: result.original_score,
          original_possible: result.original_possible,
          original_mastery: result.original_mastery,
          assessed_at: result.assessed_at,
          percent: result.percent,
          workflow_state: result.workflow_state,
          user_uuid: result.user_uuid,
          associated_asset_id: result.associated_asset_id.to_s,
          associated_asset_type: result.associated_asset_type,
          artifact_id: result.artifact_id.to_s,
          artifact_type: result.artifact_type,
          artifact_created_at: result.artifact.created_at,
          artifact_updated_at: result.artifact.updated_at
        }.compact!).once

        Canvas::LiveEvents.learning_outcome_result_created(result)
      end
    end

    context "artifact is not associated with learning outcome result" do
      before do
        result.update!(artifact: nil)
        result.reload
      end

      it "artifact_id and artifact_type are nil in created live event" do
        expect_event("learning_outcome_result_created", {
          id: result.id.to_s,
          learning_outcome_id: result.learning_outcome_id.to_s,
          learning_outcome_context_uuid: result.learning_outcome.context&.uuid,
          result_context_id: result.context_id.to_s,
          result_context_type: result.context_type,
          result_context_uuid: result&.context&.uuid,
          mastery: result.mastery,
          score: result.score,
          created_at: result.created_at,
          attempt: result.attempt,
          possible: result.possible,
          original_score: result.original_score,
          original_possible: result.original_possible,
          original_mastery: result.original_mastery,
          assessed_at: result.assessed_at,
          percent: result.percent,
          workflow_state: result.workflow_state,
          user_uuid: result.user_uuid,
          associated_asset_id: result.associated_asset_id.to_s,
          associated_asset_type: result.associated_asset_type,
          artifact_id: nil,
          artifact_type: nil
        }.compact!).once

        Canvas::LiveEvents.learning_outcome_result_created(result)
      end

      it "artifact_id and artifact_type are nil in updated live event" do
        expect_event("learning_outcome_result_updated", {
          id: result.id.to_s,
          learning_outcome_id: result.learning_outcome_id.to_s,
          learning_outcome_context_uuid: result.learning_outcome.context&.uuid,
          result_context_id: result.context_id.to_s,
          result_context_type: result.context_type,
          result_context_uuid: result&.context&.uuid,
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
          percent: result.percent,
          workflow_state: result.workflow_state,
          user_uuid: result.user_uuid,
          associated_asset_id: result.associated_asset_id.to_s,
          associated_asset_type: result.associated_asset_type,
          artifact_id: nil,
          artifact_type: nil
        }.compact!).once

        Canvas::LiveEvents.learning_outcome_result_updated(result)
      end
    end

    context "created" do
      it "includes result in created live event" do
        expect_event("learning_outcome_result_created", {
          id: result.id.to_s,
          learning_outcome_id: result.learning_outcome_id.to_s,
          learning_outcome_context_uuid: result.learning_outcome.context&.uuid,
          result_context_id: result.context_id.to_s,
          result_context_type: result.context_type,
          result_context_uuid: result&.context&.uuid,
          mastery: result.mastery,
          score: result.score,
          created_at: result.created_at,
          attempt: result.attempt,
          possible: result.possible,
          original_score: result.original_score,
          original_possible: result.original_possible,
          original_mastery: result.original_mastery,
          assessed_at: result.assessed_at,
          percent: result.percent,
          workflow_state: result.workflow_state,
          user_uuid: result.user_uuid,
          associated_asset_id: result.associated_asset_id.to_s,
          associated_asset_type: result.associated_asset_type,
          artifact_id: result.artifact_id.to_s,
          artifact_type: result.artifact_type,
          artifact_created_at: result.artifact.created_at,
          artifact_updated_at: result.artifact.updated_at
        }.compact!).once

        Canvas::LiveEvents.learning_outcome_result_created(result)
      end

      it "learning_outcome_result has a nil context" do
        result.update!(context: nil)
        expect_event("learning_outcome_result_created", {
          id: result.id.to_s,
          learning_outcome_id: result.learning_outcome_id.to_s,
          learning_outcome_context_uuid: result.learning_outcome.context&.uuid,
          result_context_id: nil,
          result_context_type: nil,
          result_context_uuid: nil,
          mastery: result.mastery,
          score: result.score,
          created_at: result.created_at,
          attempt: result.attempt,
          possible: result.possible,
          original_score: result.original_score,
          original_possible: result.original_possible,
          original_mastery: result.original_mastery,
          assessed_at: result.assessed_at,
          percent: result.percent,
          workflow_state: result.workflow_state,
          user_uuid: result.user_uuid,
          associated_asset_id: result.associated_asset_id.to_s,
          associated_asset_type: result.associated_asset_type,
          artifact_id: result.artifact_id.to_s,
          artifact_type: result.artifact_type,
          artifact_created_at: result.artifact.created_at,
          artifact_updated_at: result.artifact.updated_at
        }.compact!).once

        Canvas::LiveEvents.learning_outcome_result_created(result)
      end

      it "learning_outcome_result context uuid is nil" do
        Course.skip_callback(:save, :assign_uuid)
        context = result.context
        context.update!(uuid: nil)
        context.reload

        result.update!(attempt: 1)
        expect_event("learning_outcome_result_created", {
          id: result.id.to_s,
          learning_outcome_id: result.learning_outcome_id.to_s,
          learning_outcome_context_uuid: result.learning_outcome.context&.uuid,
          result_context_id: result.context_id.to_s,
          result_context_type: result.context_type,
          result_context_uuid: nil,
          mastery: result.mastery,
          score: result.score,
          created_at: result.created_at,
          attempt: result.attempt,
          possible: result.possible,
          original_score: result.original_score,
          original_possible: result.original_possible,
          original_mastery: result.original_mastery,
          assessed_at: result.assessed_at,
          percent: result.percent,
          workflow_state: result.workflow_state,
          user_uuid: result.user_uuid,
          associated_asset_id: result.associated_asset_id.to_s,
          associated_asset_type: result.associated_asset_type,
          artifact_id: result.artifact_id.to_s,
          artifact_type: result.artifact_type,
          artifact_created_at: result.artifact.created_at,
          artifact_updated_at: result.artifact.updated_at
        }.compact!).once

        Canvas::LiveEvents.learning_outcome_result_created(result)
        Course.set_callback(:save, :assign_uuid)
      end
    end

    context "updated" do
      it "includes result in updated live event" do
        result.update!(attempt: 1)
        expect_event("learning_outcome_result_updated", {
          id: result.id.to_s,
          learning_outcome_id: result.learning_outcome_id.to_s,
          learning_outcome_context_uuid: result.learning_outcome.context&.uuid,
          result_context_id: result.context_id.to_s,
          result_context_type: result.context_type,
          result_context_uuid: result&.context&.uuid,
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
          percent: result.percent,
          workflow_state: result.workflow_state,
          user_uuid: result.user_uuid,
          associated_asset_id: result.associated_asset_id.to_s,
          associated_asset_type: result.associated_asset_type,
          artifact_id: result.artifact_id.to_s,
          artifact_type: result.artifact_type,
          artifact_created_at: result.artifact.created_at,
          artifact_updated_at: result.artifact.updated_at
        }.compact!).once

        Canvas::LiveEvents.learning_outcome_result_updated(result)
      end

      it "includes result in updated live event when outcome is deleted" do
        outcome = LearningOutcome.find(result.learning_outcome_id)
        outcome.destroy
        expect_event("learning_outcome_result_updated", {
          id: result.id.to_s,
          learning_outcome_id: result.learning_outcome_id.to_s,
          learning_outcome_context_uuid: result.learning_outcome.context&.uuid,
          result_context_id: result.context_id.to_s,
          result_context_type: result.context_type,
          result_context_uuid: result&.context&.uuid,
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
          percent: result.percent,
          workflow_state: result.workflow_state,
          user_uuid: result.user_uuid,
          associated_asset_id: result.associated_asset_id.to_s,
          associated_asset_type: result.associated_asset_type,
          artifact_id: result.artifact_id.to_s,
          artifact_type: result.artifact_type,
          artifact_created_at: result.artifact.created_at,
          artifact_updated_at: result.artifact.updated_at
        }.compact!).once

        Canvas::LiveEvents.learning_outcome_result_updated(result)
      end

      it "learning_outcome_result has a nil context" do
        result.update!(context: nil)
        expect_event("learning_outcome_result_updated", {
          id: result.id.to_s,
          learning_outcome_id: result.learning_outcome_id.to_s,
          learning_outcome_context_uuid: result.learning_outcome.context&.uuid,
          result_context_id: nil,
          result_context_type: nil,
          result_context_uuid: nil,
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
          percent: result.percent,
          workflow_state: result.workflow_state,
          user_uuid: result.user_uuid,
          associated_asset_id: result.associated_asset_id.to_s,
          associated_asset_type: result.associated_asset_type,
          artifact_id: result.artifact_id.to_s,
          artifact_type: result.artifact_type,
          artifact_created_at: result.artifact.created_at,
          artifact_updated_at: result.artifact.updated_at
        }.compact!).once

        Canvas::LiveEvents.learning_outcome_result_updated(result)
      end

      it "learning_outcome_result context uuid is nil" do
        Course.skip_callback(:save, :assign_uuid)
        context = result.context
        context.update!(uuid: nil)
        context.reload

        result.update!(attempt: 1)
        expect_event("learning_outcome_result_updated", {
          id: result.id.to_s,
          learning_outcome_id: result.learning_outcome_id.to_s,
          learning_outcome_context_uuid: result.learning_outcome.context&.uuid,
          result_context_id: result.context_id.to_s,
          result_context_type: result.context_type,
          result_context_uuid: nil,
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
          percent: result.percent,
          workflow_state: result.workflow_state,
          user_uuid: result.user_uuid,
          associated_asset_id: result.associated_asset_id.to_s,
          associated_asset_type: result.associated_asset_type,
          artifact_id: result.artifact_id.to_s,
          artifact_type: result.artifact_type,
          artifact_created_at: result.artifact.created_at,
          artifact_updated_at: result.artifact.updated_at
        }.compact!).once

        Canvas::LiveEvents.learning_outcome_result_updated(result)
        Course.set_callback(:save, :assign_uuid)
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
    specs_require_sharding
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
          context_uuid: @context.uuid.to_s,
          display_name: @outcome.display_name,
          short_description: @outcome.short_description,
          description: @outcome.description,
          vendor_guid: @outcome.vendor_guid,
          calculation_method: @outcome.calculation_method,
          calculation_int: @outcome.calculation_int,
          rubric_criterion: @outcome.rubric_criterion,
          title: @outcome.title,
          workflow_state: @outcome.workflow_state,
          copied_from_outcome_id: @outcome.copied_from_outcome_id,
          original_outcome_root_account_uuid: nil
        }.compact).once

        Canvas::LiveEvents.learning_outcome_created(@outcome)
      end

      it "triggers a learning_outcome_created live event for a global outcome" do
        @global_outcome = outcome_model(global: true, title: "global outcome")

        expect_event("learning_outcome_created", {
          learning_outcome_id: @global_outcome.id.to_s,
          context_type: nil,
          context_id: nil,
          context_uuid: nil,
          display_name: @global_outcome.display_name,
          short_description: @global_outcome.short_description,
          description: @global_outcome.description,
          vendor_guid: @global_outcome.vendor_guid,
          calculation_method: @global_outcome.calculation_method,
          calculation_int: @global_outcome.calculation_int,
          rubric_criterion: @global_outcome.rubric_criterion,
          title: @global_outcome.title,
          workflow_state: @global_outcome.workflow_state,
          copied_from_outcome_id: nil,
          original_outcome_root_account_uuid: nil
        }.compact).once

        Canvas::LiveEvents.learning_outcome_created(@global_outcome)
      end

      it "triggers a learning_outcome_created live event for course copy" do
        original_outcome = outcome_model(title: "original outcome")
        copied_outcome = outcome_model(title: "copied outcome")
        copied_outcome.update!(copied_from_outcome_id: original_outcome.global_id)

        expect_event("learning_outcome_created", {
          learning_outcome_id: copied_outcome.id.to_s,
          context_type: copied_outcome.context_type,
          context_id: copied_outcome.context_id.to_s,
          context_uuid: @context.uuid.to_s,
          display_name: copied_outcome.display_name,
          short_description: copied_outcome.short_description,
          description: copied_outcome.description,
          vendor_guid: copied_outcome.vendor_guid,
          calculation_method: copied_outcome.calculation_method,
          calculation_int: copied_outcome.calculation_int,
          rubric_criterion: copied_outcome.rubric_criterion,
          title: copied_outcome.title,
          workflow_state: copied_outcome.workflow_state,
          copied_from_outcome_id: copied_outcome.copied_from_outcome_id.to_s,
          original_outcome_root_account_uuid: nil
        }.compact).once

        Canvas::LiveEvents.learning_outcome_created(copied_outcome)
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
          context_uuid: @context.uuid.to_s,
          display_name: @outcome.display_name,
          short_description: @outcome.short_description,
          description: @outcome.description,
          vendor_guid: @outcome.vendor_guid,
          calculation_method: @outcome.calculation_method,
          calculation_int: @outcome.calculation_int,
          rubric_criterion: @outcome.rubric_criterion,
          title: @outcome.title,
          updated_at: @outcome.updated_at,
          workflow_state: @outcome.workflow_state,
          copied_from_outcome_id: @outcome.copied_from_outcome_id,
          original_outcome_root_account_uuid: nil
        }.compact).once

        Canvas::LiveEvents.learning_outcome_updated(@outcome)
      end

      it "triggers a learning_outcome_updated live event for a global outcome" do
        @global_outcome = outcome_model(global: true, title: "global outcome")

        @global_outcome.update!(short_description: "this is new")

        expect_event("learning_outcome_updated", {
          learning_outcome_id: @global_outcome.id.to_s,
          context_type: nil,
          context_id: nil,
          context_uuid: nil,
          display_name: @global_outcome.display_name,
          short_description: @global_outcome.short_description,
          description: @global_outcome.description,
          vendor_guid: @global_outcome.vendor_guid,
          calculation_method: @global_outcome.calculation_method,
          calculation_int: @global_outcome.calculation_int,
          rubric_criterion: @global_outcome.rubric_criterion,
          title: @global_outcome.title,
          updated_at: @global_outcome.updated_at,
          workflow_state: @global_outcome.workflow_state,
          copied_from_outcome_id: nil,
          original_outcome_root_account_uuid: nil
        }.compact).once

        Canvas::LiveEvents.learning_outcome_updated(@global_outcome)
      end
    end

    context "root account uuid for course copy original outcome" do
      before do
        @copied_outcome = outcome_model(title: "test copied outcome 1")
      end

      it "returns nil when copied_from_outcome_id comes from an outcome within the current shard" do
        original_outcome = outcome_model(title: "test outcome 1")
        @copied_outcome.update!(copied_from_outcome_id: original_outcome.global_id)
        response = Canvas::LiveEvents.get_root_account_uuid(@copied_outcome.copied_from_outcome_id)
        expect(response).to be_nil
      end

      it "return an account uuid when copied_from_outcome_id comes from an outcome in a different shard" do
        @shard1.activate do
          @s1_account = Account.create
          @s1_course = @s1_account.courses.create!
          @s1_outcome = @s1_course.created_learning_outcomes.create!(title: "S1 outcome")
        end
        @copied_outcome.update!(copied_from_outcome_id: @s1_outcome.global_id)
        response = Canvas::LiveEvents.get_root_account_uuid(@copied_outcome.copied_from_outcome_id)
        expect(response).to eq @s1_account.uuid
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
          context_uuid: @context.uuid.to_s,
          context_type: @outcome_group.context_type,
          title: @outcome_group.title,
          description: @outcome_group.description,
          vendor_guid: @outcome_group.vendor_guid,
          parent_outcome_group_id: @outcome_group.learning_outcome_group_id.to_s,
          parent_outcome_group_context_uuid: @outcome_group.context.uuid.to_s,
          workflow_state: @outcome_group.workflow_state
        }.compact).once

        Canvas::LiveEvents.learning_outcome_group_created(@outcome_group)
      end

      it "triggers a learning_outcome_group_created live event for a global outcome group" do
        @global_outcome_group = LearningOutcomeGroup.create(title: "global")

        expect_event("learning_outcome_group_created", {
          learning_outcome_group_id: @global_outcome_group.id.to_s,
          context_id: nil,
          context_uuid: nil,
          context_type: nil,
          title: @global_outcome_group.title,
          description: @global_outcome_group.description,
          vendor_guid: @global_outcome_group.vendor_guid,
          parent_outcome_group_id: nil,
          parent_outcome_group_context_uuid: nil,
          workflow_state: @global_outcome_group.workflow_state
        }.compact).once

        Canvas::LiveEvents.learning_outcome_group_created(@global_outcome_group)
      end
    end

    context "updated" do
      it "triggers a learning_outcome_group_updated live event" do
        outcome_group_model

        @outcome_group.update!(title: "this is new")

        expect_event("learning_outcome_group_updated", {
          learning_outcome_group_id: @outcome_group.id.to_s,
          context_id: @outcome_group.context_id.to_s,
          context_uuid: @context.uuid.to_s,
          context_type: @outcome_group.context_type,
          title: @outcome_group.title,
          description: @outcome_group.description,
          vendor_guid: @outcome_group.vendor_guid,
          parent_outcome_group_id: @outcome_group.learning_outcome_group_id.to_s,
          parent_outcome_group_context_uuid: @outcome_group.context.uuid.to_s,
          updated_at: @outcome_group.updated_at,
          workflow_state: @outcome_group.workflow_state
        }.compact).once

        Canvas::LiveEvents.learning_outcome_group_updated(@outcome_group)
      end

      it "triggers a learning_outcome_group_updated live event for a global outcome group" do
        @global_outcome_group = LearningOutcomeGroup.create(title: "global")

        @global_outcome_group.update!(title: "this is new")

        expect_event("learning_outcome_group_updated", {
          learning_outcome_group_id: @global_outcome_group.id.to_s,
          context_id: nil,
          context_uuid: nil,
          context_type: nil,
          title: @global_outcome_group.title,
          description: @global_outcome_group.description,
          vendor_guid: @global_outcome_group.vendor_guid,
          parent_outcome_group_id: nil,
          parent_outcome_group_context_uuid: nil,
          updated_at: @global_outcome_group.updated_at,
          workflow_state: @global_outcome_group.workflow_state
        }.compact).once

        Canvas::LiveEvents.learning_outcome_group_updated(@global_outcome_group)
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
          learning_outcome_context_uuid: @outcome.context.uuid.to_s,
          learning_outcome_group_id: @outcome_group.id.to_s,
          learning_outcome_group_context_uuid: @outcome_group.context.uuid.to_s,
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
          learning_outcome_context_uuid: @outcome.context.uuid.to_s,
          learning_outcome_group_id: @outcome_group.id.to_s,
          learning_outcome_group_context_uuid: @outcome_group.context.uuid.to_s,
          context_id: link.context_id.to_s,
          context_type: link.context_type,
          workflow_state: link.workflow_state,
          updated_at: link.updated_at
        }.compact).once

        Canvas::LiveEvents.learning_outcome_link_updated(link)
      end

      it "triggers a learning_outcome_link_updated live event when outcome is deleted" do
        outcome_model
        outcome_group_model

        link = @outcome_group.add_outcome(@outcome)
        @outcome.destroy

        expect_event("learning_outcome_link_updated", {
          learning_outcome_link_id: link.id.to_s,
          learning_outcome_id: @outcome.id.to_s,
          learning_outcome_context_uuid: @outcome.context.uuid.to_s,
          learning_outcome_group_id: @outcome_group.id.to_s,
          learning_outcome_group_context_uuid: @outcome_group.context.uuid.to_s,
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

  describe "final_grade_custom_status" do
    let(:custom_grade_status) { CustomGradeStatus.create!(name: "custom", color: "#000000", root_account_id: @course.root_account_id, created_by: @teacher) }

    it "sends event when final grade custom status changes" do
      course_model
      enrollment_model

      score = Score.new(override_score: 100.0, course_score: true, custom_grade_status:)

      event_body = {
        score_id: score.id,
        enrollment_id: @enrollment.id,
        user_id: @enrollment.user_id,
        course_id: @enrollment.course_id,
        grading_period_id: score.grading_period_id,
        override_status: score.custom_grade_status&.name,
        override_status_id: score.custom_grade_status_id,
        old_override_status: "",
        old_override_status_id: "",
        updated_at: score.updated_at,
      }

      expect(Canvas::LiveEvents).to receive(:post_event_stringified).with(
        "final_grade_custom_status",
        event_body,
        Canvas::LiveEvents.amended_context(@course)
      )
      Canvas::LiveEvents.final_grade_custom_status(score, nil, @enrollment, @course)
    end

    it "sends event when final grade custom status changes and previous status" do
      course_model
      enrollment_model

      score = Score.new(override_score: 100.0, course_score: true, custom_grade_status: nil)

      event_body = {
        score_id: score.id,
        enrollment_id: @enrollment.id,
        user_id: @enrollment.user_id,
        course_id: @enrollment.course_id,
        grading_period_id: score.grading_period_id,
        override_status: "",
        override_status_id: "",
        old_override_status: custom_grade_status&.name,
        old_override_status_id: custom_grade_status&.id,
        updated_at: score.updated_at,
      }

      expect(Canvas::LiveEvents).to receive(:post_event_stringified).with(
        "final_grade_custom_status",
        event_body,
        Canvas::LiveEvents.amended_context(@course)
      )
      Canvas::LiveEvents.final_grade_custom_status(score, custom_grade_status, @enrollment, @course)
    end
  end

  describe "submission_custom_grade_status" do
    before do
      course_with_student
      assignment_model
    end

    let(:custom_grade_status) { CustomGradeStatus.create!(name: "custom", color: "#000000", root_account_id: @course.root_account_id, created_by: @teacher) }

    it "sends event when submission custom status changes" do
      submission = @assignment.find_or_create_submission(@student)
      submission.update!(custom_grade_status:)

      event_body = {
        assignment_id: submission.assignment_id,
        submission_id: submission.id,
        user_id: submission.user_id,
        course_id: submission.course_id,
        old_submission_status_id: "",
        old_submission_status: "",
        submission_status: submission.custom_grade_status&.name,
        submission_status_id: submission.custom_grade_status_id,
        updated_at: submission.updated_at,
      }

      expect(Canvas::LiveEvents).to receive(:post_event_stringified).with(
        "submission_custom_grade_status",
        event_body,
        Canvas::LiveEvents.amended_context(@course)
      )
      Canvas::LiveEvents.submission_custom_grade_status(submission, nil)
    end

    it "sends event when submission custom status changes and previous status" do
      submission = @assignment.find_or_create_submission(@student)
      submission.update!(custom_grade_status: nil)

      event_body = {
        assignment_id: submission.assignment_id,
        submission_id: submission.id,
        user_id: submission.user_id,
        course_id: submission.course_id,
        old_submission_status_id: custom_grade_status.id,
        old_submission_status: custom_grade_status.name,
        submission_status: "",
        submission_status_id: "",
        updated_at: submission.updated_at,
      }

      expect(Canvas::LiveEvents).to receive(:post_event_stringified).with(
        "submission_custom_grade_status",
        event_body,
        Canvas::LiveEvents.amended_context(@course)
      )
      Canvas::LiveEvents.submission_custom_grade_status(submission, custom_grade_status.id)
    end
  end

  describe "outcome friendly description" do
    before do
      @context = course_model
      @outcome = @context.created_learning_outcomes.create!({ title: "new outcome" })
      description = "A friendly description"
      @friendlyDescription = OutcomeFriendlyDescription.create!(
        learning_outcome: @outcome,
        context: @context,
        description:
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
                       learning_outcome_context_uuid: @context.uuid,
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
                       learning_outcome_context_uuid: @context.uuid,
                       root_account_id: @friendlyDescription.root_account_id.to_s,
                       description: new_description,
                       updated_at: @friendlyDescription.updated_at,
                     }).once

        Canvas::LiveEvents.outcome_friendly_description_updated(@friendlyDescription)
      end

      it "triggers an outcome_friendly_description_udpated live event when the outcome is deleted" do
        @outcome.destroy
        expect_event("outcome_friendly_description_updated", {
                       outcome_friendly_description_id: @friendlyDescription.id.to_s,
                       context_type: @friendlyDescription.context_type,
                       context_id: @friendlyDescription.context_id.to_s,
                       workflow_state: @friendlyDescription.workflow_state,
                       learning_outcome_id: @friendlyDescription.learning_outcome_id.to_s,
                       learning_outcome_context_uuid: @context.uuid,
                       root_account_id: @friendlyDescription.root_account_id.to_s,
                       description: @friendlyDescription.description,
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
                       account_id: @master_template.course.account.global_id.to_s,
                       account_uuid: @master_template.course.account.uuid.to_s,
                       blueprint_course_id: @master_template.course.global_id.to_s,
                       blueprint_course_uuid: @master_template.course.uuid.to_s,
                       blueprint_course_title: @master_template.course.name.to_s,
                       blueprint_course_workflow_state: @master_template.course.workflow_state.to_s
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
                       master_migration_id: @master_migration.id.to_s,
                       master_template_id: @master_template.id.to_s,
                       account_id: @master_migration.master_template.course.account.global_id.to_s,
                       account_uuid: @master_migration.master_template.course.account.uuid.to_s,
                       blueprint_course_uuid: @master_migration.master_template.course.uuid.to_s,
                       blueprint_course_id: @master_migration.master_template.course.global_id.to_s
                     }).once
        Canvas::LiveEvents.master_migration_completed(@master_migration)
      end
    end
  end

  describe "course" do
    before do
      @course = course_model
    end

    let(:event_data) do
      {
        course_id: @course.global_id.to_s,
        uuid: @course.uuid,
        account_id: @course.global_account_id.to_s,
        account_uuid: @course.account.uuid,
        name: @course.name,
        created_at: @course.created_at,
        updated_at: @course.updated_at,
        workflow_state: @course.workflow_state
      }
    end

    context "created" do
      it "triggers a course_created live event" do
        expect_event("course_created", event_data).once
        Canvas::LiveEvents.course_created(@course)
      end
    end

    context "updated" do
      it "triggers a course_udpated live event" do
        @course.name = "Updated Course Name"
        @course.save!
        expect_event("course_updated", event_data).once
        Canvas::LiveEvents.course_updated(@course)
      end
    end
  end

  describe "master template child subscription" do
    before do
      @course = course_model
      @child_course = course_model
      @master_template = MasterCourses::MasterTemplate.create!(course: @course)
    end

    let(:child_subscription) do
      expect_event("course_updated", {
                     account_id: @master_template.course.account.global_id.to_s,
                     account_uuid: @course.account.uuid,
                     course_id: @course.global_id.to_s,
                     created_at: anything,
                     name: @course.name,
                     updated_at: anything,
                     uuid: @course.uuid,
                     workflow_state: "claimed"
                   }).at_least(1).times
      expect_event("blueprint_subscription_created", event_data)

      @child_subscription = @master_template.add_child_course!(@child_course)
    end

    let(:event_data) do
      {
        master_template_account_uuid: @master_template.course.account.uuid,
        master_template_id: @master_template.id.to_s,
        master_course_uuid: @course.uuid,
        child_subscription_id: anything,
        child_course_uuid: @child_course.uuid,
        child_course_account_uuid: @child_course.account.uuid
      }
    end

    it "triggers a blueprint_subscription_created live event" do
      child_subscription
    end

    it "triggers a blueprint_subscription_deleted live event" do
      expect_event("blueprint_subscription_deleted", event_data)
      child_subscription.destroy
    end

    context "when previously associated" do
      before do
        expect_event("blueprint_subscription_deleted", event_data)
        child_subscription.destroy
      end

      it "triggers a blueprint_subscription_created live event" do
        expect_event("blueprint_subscription_created", event_data)
        @master_template.add_child_course!(@child_course)
      end
    end
  end

  describe "master_template" do
    let(:default_restrictions) do
      {
        content: false,
        points: true,
        due_dates: false,
        availability_dates: true,
        settings: false,
        state: true
      }
    end

    let(:default_restrictions_by_type) do
      {
        "Assignment" => { content: false, points: false, due_dates: false, availability_dates: false },
        "DiscussionTopic" => { content: false, points: false, due_dates: false, availability_dates: false },
        "WikiPage" => { content: false },
        "Attachment" => { content: false },
        "Quizzes::Quiz" => { content: false, points: false, due_dates: false, availability_dates: false },
        "CoursePace" => { content: false }
      }
    end

    def expect_restrictions(restrictions)
      expect_event("default_blueprint_restrictions_updated", {
                     canvas_course_id: @course.id.to_s,
                     canvas_course_uuid: @course.uuid,
                     restrictions:
                   }).once
    end

    before do
      @course = course_model
      @master_template = MasterCourses::MasterTemplate.create!(
        course: @course,
        default_restrictions:,
        default_restrictions_by_type:
      )
    end

    context "triggers a default_blueprint_restrictions_updated live event" do
      context("when use_default_restrictions_by_type is true") do
        before do
          @master_template.update_attribute(:use_default_restrictions_by_type, true)
        end

        it "and default_restrictions updated" do
          expect_restrictions(default_restrictions_by_type)
          @master_template.update_attribute(:default_restrictions, { content: true })
        end

        it "and default_restrictions_by_type updated" do
          expect_restrictions({ "Assignment" => { content: true } })
          @master_template.update_attribute(:default_restrictions_by_type, { "Assignment" => { content: true } })
        end

        it "and use_default_restrictions_by_type updated to false" do
          expect_restrictions(default_restrictions)
          @master_template.update_attribute(:use_default_restrictions_by_type, false)
        end
      end

      context("when use_default_restrictions_by_type is false") do
        before do
          @master_template.update_attribute(:use_default_restrictions_by_type, false)
        end

        it "and default_restrictions updated" do
          expect_restrictions({ content: true })
          @master_template.update_attribute(:default_restrictions, { content: true })
        end

        it "and default_restrictions_by_type updated" do
          expect_restrictions(default_restrictions)
          @master_template.update_attribute(:default_restrictions_by_type, { "Assignment" => { content: true } })
        end

        it "and use_default_restrictions_by_type updated to true" do
          expect_restrictions(default_restrictions_by_type)
          @master_template.update_attribute(:use_default_restrictions_by_type, true)
        end
      end
    end
  end

  describe ".blueprint_restrictions_updated" do
    before do
      course_model
      default_restrictions = { content: true, points: false, due_dates: false, availability_dates: false }
      master_template =
        MasterCourses::MasterTemplate.create!(course: @course, default_restrictions:)
      assignment = @course.assignments.create!
      master_content_tag_params = {
        master_template_id: master_template.id,
        content_type: "Assignment",
        content_id: assignment.id,
        restrictions: default_restrictions,
        migration_id: "mastercourse_1_3_f9ca51a6679e4779d0d68ef2dc33bc0a",
        use_default_restrictions: true
      }
      @master_content_tag =
        MasterCourses::MasterContentTag.create!(master_content_tag_params)
      allow_any_instance_of(Assignment).to receive(:lti_resource_link_id).and_return("someltiresourcelinkid")
    end

    it "triggers a blueprint_restrictions_updated live event" do
      expect_event("blueprint_restrictions_updated", {
                     canvas_assignment_id: @master_content_tag.content_id.to_s,
                     canvas_course_id: @master_content_tag.master_template.course_id.to_s,
                     canvas_course_uuid: @master_content_tag.master_template.course.uuid,
                     lti_resource_link_id: "someltiresourcelinkid",
                     restrictions: @master_content_tag.restrictions,
                     use_default_restrictions: @master_content_tag.use_default_restrictions
                   }).once
      Canvas::LiveEvents.blueprint_restrictions_updated(@master_content_tag)
    end
  end

  describe "rubric_assessed" do
    before(:once) do
      assignment_model
      outcome_model
      outcome_with_rubric(outcome: @outcome, context: Account.default)
      course_with_student
      @association = @rubric.associate_with(@assignment, @course, purpose: "grading", use_for_grading: true)
      @rubric_assessment = rubric_assessment_model(rubric: @rubric, user: @student, assessment_type: "graded")
    end

    context "rubric_assessment_submitted_at" do
      it "returns rubric assessment updated_at if the assignment is not submitted" do
        submitted_at = Canvas::LiveEvents.rubric_assessment_submitted_at(@rubric_assessment)
        expect(submitted_at).to eq @rubric_assessment.updated_at
      end

      it "returns submission submitted_at date if the rubric aligned assignment is a submission and is submitted" do
        submitted_at_date = Time.zone.now
        # submission type needs to be present for submitted_at date to be returned
        @rubric_assessment.artifact.update!(submitted_at: submitted_at_date, submission_type: "online_text")
        @rubric_assessment.artifact.reload
        submitted_at = Canvas::LiveEvents.rubric_assessment_submitted_at(@rubric_assessment)
        expect(submitted_at).to eq @rubric_assessment.artifact.submitted_at
      end

      it "returns rubric assessment updated_at if the rubric aligned assignment is not a Submission object" do
        @assignment.update!(moderated_grading: true, grader_count: 1)
        outcome_with_rubric
        assignment_model
        @association = @rubric.associate_with(@assignment, @course, purpose: "grading", use_for_grading: true)
        submission = @assignment.find_or_create_submission(@student)
        provisional_grade = submission.find_or_create_provisional_grade!(@teacher, grade: 3)
        criterion_id = :"criterion_#{@rubric.data[0][:id]}"
        assessment = @association.assess({
                                           user: @student,
                                           assessor: @student,
                                           artifact: provisional_grade,
                                           assessment: {
                                             :assessment_type => "grading",
                                             criterion_id => {
                                               points: "3"
                                             }
                                           }
                                         })
        submitted_at = Canvas::LiveEvents.rubric_assessment_submitted_at(assessment)
        expect(submitted_at).to eq assessment.updated_at
      end
    end

    context "rubric_assessment_attempt" do
      it "return nil if the assignment is not submitted" do
        attempt = Canvas::LiveEvents.rubric_assessment_attempt(@rubric_assessment)
        expect(attempt).to be_nil
      end

      it "returns submission attempt if the rubric aligned assignment is a Submission object and is submitted" do
        submitted_at_date = Time.zone.now
        # submission type needs to be present for submitted_at date to be returned
        @rubric_assessment.artifact.update!(submitted_at: submitted_at_date, submission_type: "online_text")
        @rubric_assessment.artifact.reload
        attempt = Canvas::LiveEvents.rubric_assessment_attempt(@rubric_assessment)
        expect(attempt).to eq @rubric_assessment.artifact.attempt
      end

      it "returns nil if the rubric aligned artifact is not a Submission" do
        assignment_model
        @assignment.update!(moderated_grading: true, grader_count: 1)
        outcome_with_rubric
        @association = @rubric.associate_with(@assignment, @course, purpose: "grading", use_for_grading: true)
        submission = @assignment.find_or_create_submission(@student)
        provisional_grade = submission.find_or_create_provisional_grade!(@teacher, grade: 3)
        criterion_id = :"criterion_#{@rubric.data[0][:id]}"
        assessment = @association.assess({
                                           user: @student,
                                           assessor: @student,
                                           artifact: provisional_grade,
                                           assessment: {
                                             :assessment_type => "grading",
                                             criterion_id => {
                                               points: "3"
                                             }
                                           }
                                         })
        attempt = Canvas::LiveEvents.rubric_assessment_attempt(assessment)
        expect(attempt).to be_nil
      end
    end

    context "triggers a live event" do
      it "successfully with context uuid" do
        attempt = Canvas::LiveEvents.rubric_assessment_attempt(@rubric_assessment)
        expect(attempt).to be_nil
        submitted_at = Canvas::LiveEvents.rubric_assessment_submitted_at(@rubric_assessment)

        assessment_data = {
          id: @rubric_assessment.id.to_s,
          aligned_to_outcomes: @rubric_assessment.aligned_outcome_ids.count.positive?,
          artifact_id: @rubric_assessment.artifact_id.to_s,
          artifact_type: @rubric_assessment.artifact_type,
          assessment_type: @rubric_assessment.assessment_type,
          context_uuid: @rubric_assessment.rubric_association.context.uuid,
          submitted_at:,
          created_at: @rubric_assessment.created_at,
          updated_at: @rubric_assessment.updated_at
        }
        expect_event("rubric_assessed", assessment_data)
        Canvas::LiveEvents.rubric_assessed(@rubric_assessment)
      end

      it "when context uuid is not present event data will be nil" do
        context = @rubric_assessment.rubric_association.context
        allow_any_instance_of(Course).to receive(:assign_uuid).and_return(true)
        context.uuid = nil
        context.save

        attempt = Canvas::LiveEvents.rubric_assessment_attempt(@rubric_assessment)
        expect(attempt).to be_nil
        submitted_at = Canvas::LiveEvents.rubric_assessment_submitted_at(@rubric_assessment)

        assessment_data = {
          id: @rubric_assessment.id.to_s,
          aligned_to_outcomes: @rubric_assessment.aligned_outcome_ids.count.positive?,
          artifact_id: @rubric_assessment.artifact_id.to_s,
          artifact_type: @rubric_assessment.artifact_type,
          assessment_type: @rubric_assessment.assessment_type,
          submitted_at:,
          created_at: @rubric_assessment.created_at,
          updated_at: @rubric_assessment.updated_at,
        }
        expect_event("rubric_assessed", assessment_data)
        Canvas::LiveEvents.rubric_assessed(@rubric_assessment)
      end
    end
  end

  describe ".outcomes_retry_outcome_alignment_clone" do
    it "triggers an outcome alignment clone retry live event" do
      event_payload = {
        original_course_uuid: "eXA43Cb5A8biA87cEPjcpByVwsaff4ULmEsRwM5s",
        new_course_uuid: "8H3aGjEatiLI42zzV0ly8t5UGQAxYfvrI3MDlrCx",
        domain: "canvas.instructure.com",
        new_course_resource_link_id: "c9d7d100bb177c0e54f578e7ac538cd9f7a3e4ad",
        original_assignment_resource_link_id: "bf950e2284bd720a28e407fe326dce68",
        new_assignment_resource_link_id: "2ae6e5cac3081b0cc8515ad79ff114e3406169ef",
        status: "outcome_alignment_cloning"
      }

      expect_event("outcomes.retry_outcome_alignment_clone", event_payload).once

      Canvas::LiveEvents.outcomes_retry_outcome_alignment_clone(event_payload)
    end
  end

  describe ".get_account_data" do
    before do
      @root_account = Account.create!
      @nonroot_account = Account.create!(root_account: @root_account)
    end

    context "for root accounts" do
      it "root_account_id is the account's global id" do
        account_data = Canvas::LiveEvents.get_account_data(@root_account)
        expect(account_data[:root_account_id]).to eq @root_account.global_id
      end
    end

    context "for non-root accounts" do
      it "root_account_id is root account's global id" do
        account_data = Canvas::LiveEvents.get_account_data(@nonroot_account)
        expect(account_data[:root_account_id]).to eq @root_account.global_id
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
        allow(Canvas).to receive_messages(region:, region_code:)
      end

      it "sets region to Canvas.region" do
        expect_event("heartbeat", { region:, environment: "test", region_code: })
        Canvas::LiveEvents.heartbeat
      end
    end

    context "environment" do
      context "in development" do
        let(:environment) { "development" }

        before do
          allow(Canvas).to receive(:environment).and_return environment
        end

        it "sets environment to development" do
          expect_event("heartbeat", { region: "not_configured", environment:, region_code: "not_configured" })
          Canvas::LiveEvents.heartbeat
        end
      end

      context "in beta" do
        let(:environment) { "beta" }

        before do
          allow(ApplicationController).to receive_messages(test_cluster?: true, test_cluster_name: environment)
        end

        it "sets environment to beta" do
          expect_event("heartbeat", { region: "not_configured", environment:, region_code: "not_configured" })
          Canvas::LiveEvents.heartbeat
        end
      end

      context "in prod" do
        let(:environment) { "prod" }

        before do
          allow(Canvas).to receive(:environment).and_return environment
        end

        it "sets environment to prod" do
          expect_event("heartbeat", { region: "not_configured", environment:, region_code: "not_configured" })
          Canvas::LiveEvents.heartbeat
        end
      end
    end
  end
end
