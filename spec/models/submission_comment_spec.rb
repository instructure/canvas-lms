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

require_relative "../spec_helper"

RSpec.describe SubmissionComment do
  before(:once) do
    course_with_teacher(active_all: true)
    course_with_observer(active_all: true)
    student_in_course(active_all: true)

    @assignment = @course.assignments.build
    @assignment.workflow_state = :published
    @assignment.save!
    @assignment.unmute!

    @submission = @assignment.submit_homework(@user)
  end

  let(:valid_attributes) { { comment: "some comment" } }

  describe "permissions" do
    describe "delete" do
      context "as a student" do
        it "can delete their own draft comments" do
          comment = @submission.submission_comments.create!(comment: "hi", author: @student, draft: true)
          expect(comment.grants_right?(@student, :delete)).to be true
        end

        it "cannot delete their own non-draft comments" do
          comment = @submission.submission_comments.create!(comment: "hi", author: @student)
          expect(comment.grants_right?(@student, :delete)).to be false
        end

        it "cannot delete their peers' draft comments" do
          first_student = @student
          student_in_course(active_all: true)
          comment = @submission.submission_comments.create!(comment: "hi", author: first_student, draft: true)
          expect(comment.grants_right?(@student, :delete)).to be false
        end

        it "cannot delete their peers' non-draft comments" do
          first_student = @student
          student_in_course(active_all: true)
          comment = @submission.submission_comments.create!(comment: "hi", author: first_student)
          expect(comment.grants_right?(@student, :delete)).to be false
        end
      end

      context "as a teacher" do
        it "can delete their own draft comments" do
          comment = @submission.submission_comments.create!(comment: "hi", author: @teacher, draft: true)
          expect(comment.grants_right?(@teacher, :delete)).to be true
        end

        it "can delete their own non-draft comments" do
          comment = @submission.submission_comments.create!(comment: "hi", author: @teacher)
          expect(comment.grants_right?(@teacher, :delete)).to be true
        end

        it "can delete students' draft comments" do
          comment = @submission.submission_comments.create!(comment: "hi", author: @student, draft: true)
          expect(comment.grants_right?(@teacher, :delete)).to be true
        end

        it "can delete students' non-draft comments" do
          comment = @submission.submission_comments.create!(comment: "hi", author: @student)
          expect(comment.grants_right?(@teacher, :delete)).to be true
        end

        it "can delete comments in a moderated assignment and the grader is not the final grader" do
          @assignment.update!(moderated_grading: true, grades_published_at: nil, grader_count: 1)
          expect(@teacher.id).not_to eq(@assignment.final_grader_id)
          @submission.grade_posting_in_progress = false
          comment = @submission.submission_comments.create!(comment: "hi", author: @student)
          expect(comment.grants_right?(@teacher, :delete)).to be true
        end
      end
    end

    describe "update" do
      context "as a student" do
        it "can update their own draft comments" do
          comment = @submission.submission_comments.create!(comment: "hi", author: @student, draft: true)
          expect(comment.grants_right?(@student, :update)).to be true
        end

        it "cannot update their own non-draft comments" do
          comment = @submission.submission_comments.create!(comment: "hi", author: @student)
          expect(comment.grants_right?(@student, :update)).to be false
        end

        it "cannot update their peers' draft comments" do
          first_student = @student
          student_in_course(active_all: true)
          comment = @submission.submission_comments.create!(comment: "hi", author: first_student, draft: true)
          expect(comment.grants_right?(@student, :update)).to be false
        end

        it "cannot update their peers' non-draft comments" do
          first_student = @student
          student_in_course(active_all: true)
          comment = @submission.submission_comments.create!(comment: "hi", author: first_student)
          expect(comment.grants_right?(@student, :update)).to be false
        end
      end

      context "as a teacher" do
        it "can update their own draft comments" do
          comment = @submission.submission_comments.create!(comment: "hi", author: @teacher, draft: true)
          expect(comment.grants_right?(@teacher, :update)).to be true
        end

        it "can update their own non-draft comments" do
          comment = @submission.submission_comments.create!(comment: "hi", author: @teacher)
          expect(comment.grants_right?(@teacher, :update)).to be true
        end

        it "cannot update students' draft comments" do
          comment = @submission.submission_comments.create!(comment: "hi", author: @student, draft: true)
          expect(comment.grants_right?(@teacher, :update)).to be false
        end

        it "cannot update students' non-draft comments" do
          comment = @submission.submission_comments.create!(comment: "hi", author: @student)
          expect(comment.grants_right?(@teacher, :update)).to be false
        end

        it "can update their own comments in a moderated assignment when the grader is not the final grader" do
          @assignment.update!(moderated_grading: true, grades_published_at: nil, grader_count: 1)
          expect(@teacher.id).not_to eq(@assignment.final_grader_id)
          @submission.grade_posting_in_progress = false
          comment = @submission.submission_comments.create!(comment: "hi", author: @teacher)
          expect(comment.grants_right?(@teacher, :update)).to be true
        end
      end
    end
  end

  it "creates a new instance given valid attributes" do
    expect(@submission.submission_comments.create!(valid_attributes)).to be_persisted
  end

  describe "#set_root_account_id" do
    subject { submission_comment.root_account }

    let(:submission) { @submission }
    let(:submission_comment) { submission.submission_comments.create!(valid_attributes) }

    context "as a before_save callback" do
      it { is_expected.to eq submission.context.root_account }
    end
  end

  describe "#body" do
    it "aliases comment" do
      submission_comment = SubmissionComment.new(comment: "a body")
      expect(submission_comment.body).to eq submission_comment.comment
    end
  end

  describe "#body=" do
    it "aliases comment=" do
      text = "a body"
      submission_comment = SubmissionComment.new
      submission_comment.body = text
      expect(submission_comment.comment).to eq text
    end
  end

  describe "viewed submission comments" do
    it "returns read if the submission is read" do
      comment = @submission.submission_comments.create!(valid_attributes)
      @submission.mark_item_read("comment")
      expect(comment).to be_read(@user)
    end

    it "returns read if there is a viewed submission comment" do
      comment = @submission.submission_comments.create!(valid_attributes)
      comment.viewed_submission_comments.create!(user: @user)
      expect(comment).to be_read(@user)
    end

    it "creates a viewed submission comment if mark_read! is called" do
      comment = @submission.submission_comments.create!(valid_attributes)
      comment.mark_read!(@user)
      expect(comment).to be_read(@user)
      expect(ViewedSubmissionComment.count).to be(1)
      expect(ViewedSubmissionComment.last.user).to eq(@user)
      expect(ViewedSubmissionComment.last.submission_comment).to eq(comment)
    end

    it "returns false if the submission is not read and no viewed submission comments" do
      comment = @submission.submission_comments.create!(valid_attributes)
      expect(comment).not_to be_read(@user)
    end
  end

  describe "notifications" do
    before(:once) do
      @student_ended = user_model
      @section_ended = @course.course_sections.create!(end_at: 1.day.ago)

      Notification.create!(name: "Submission Comment", category: "TestImmediately")
      Notification.create!(name: "Submission Comment For Teacher")
    end

    it "dispatches notifications on create for published assignment" do
      comment = @submission.add_comment(author: @teacher, comment: "some comment")
      expect(comment.messages_sent.keys.sort).to eq ["Submission Comment"]

      comment = @submission.add_comment(author: @student, comment: "some comment")
      expect(comment.messages_sent.keys.sort).to eq ["Submission Comment For Teacher"]
    end

    it "dispatches notifications to observers" do
      course_with_observer(active_all: true, active_cc: true, course: @course, associated_user_id: @student.id)
      @submission.add_comment(author: @teacher, comment: "some comment")
      expect(@observer.email_channel.messages.length).to eq 1
    end

    it "does not send notifications to users in concluded sections" do
      @submission_ended = @assignment.submit_homework(@student_ended)
      @comment = @submission_ended.add_comment(author: @teacher, comment: "some comment")
      expect(@comment.messages_sent.keys).not_to include("Submission Comment")
    end

    it "does not dispatch notification on create if course is unpublished" do
      @course.complete
      @comment = @submission.add_comment(author: @teacher, comment: "some comment")
      expect(@course).to_not be_available
      expect(@comment.messages_sent.keys).to_not include("Submission Comment")
    end

    it "does not dispatch notification on create if student is inactive" do
      @student.enrollments.first.deactivate

      @comment = @submission.add_comment(author: @teacher, comment: "some comment")
      expect(@comment.messages_sent.keys).to_not include("Submission Comment")
    end

    it "does not dispatch notification on create for provisional comments" do
      @comment = @submission.add_comment(author: @teacher, comment: "huttah!", provisional: true)
      expect(@comment.messages_sent).to be_empty
    end

    it "dispatches notification on create to teachers even if submission not submitted yet" do
      student_in_course(active_all: true)
      @submission = @assignment.find_or_create_submission(@student)
      @comment = @submission.add_comment(author: @student, comment: "some comment")
      expect(@submission).to be_unsubmitted
      expect(@comment.messages_sent).to include("Submission Comment For Teacher")
    end

    it "doesn't dispatch notifications on create for manually posted assignments" do
      @assignment.ensure_post_policy(post_manually: true)
      @assignment.hide_submissions(submission_ids: [@submission.id])

      @comment = @submission.add_comment(author: @teacher, comment: "some comment")
      expect(@comment.messages_sent.keys).not_to include("Submission Comment")
    end

    context "draft comment" do
      before do
        @comment = @submission.add_comment(author: @teacher, comment: "42", draft_comment: true)
      end

      it "does not dispatch notification on create" do
        expect(@comment.messages_sent).to be_empty
      end

      it "dispatches notification on update when the draft changes to false" do
        @comment.draft = false
        @comment.save

        expect(@comment.messages_sent.keys).to eq(["Submission Comment"])
      end
    end
  end

  it "allows valid attachments" do
    a = Attachment.create!(context: @assignment, uploaded_data: default_uploaded_data)
    @comment = @submission.submission_comments.create!(valid_attributes)
    expect(a.recently_created).to be(true)
    @comment.reload
    @comment.update(attachments: [a])
    expect(@comment.attachment_ids).to eql(a.id.to_s)
  end

  it "rejects invalid attachments" do
    a = Attachment.create!(context: @assignment, uploaded_data: default_uploaded_data)
    a.recently_created = false
    @comment = @submission.submission_comments.create!(valid_attributes)
    @comment.update(attachments: [a])
    expect(@comment.attachment_ids).to eql("")
  end

  it "renders formatted_body correctly" do
    @comment = @submission.submission_comments.create!(valid_attributes)
    @comment.comment = <<~TEXT
      This text has a http://www.google.com link in it...

      > and some
      > quoted text
    TEXT
    @comment.save!
    body = @comment.formatted_body
    expect(body).to match(/<a/)
    expect(body).to match(/quoted_text/)
  end

  def prepare_test_submission
    assignment_model
    @assignment.workflow_state = "published"
    @assignment.save
    @course.offer
    @course.enroll_teacher(user_factory)
    @se = @course.enroll_student(user_factory)
    @assignment.reload
    @submission = @assignment.submit_homework(@se.user, body: "some message")
    @submission.created_at = Time.now - 60
    @submission.save
  end

  it "sends the submission to the stream" do
    prepare_test_submission
    @comment = @submission.add_comment(author: @se.user, comment: "some comment")
    @item = StreamItem.last
    expect(@item).not_to be_nil
    expect(@item.asset).to eq @submission
    expect(@item.data).to be_is_a(Submission)
    expect(@item.data.submission_comments.target).to eq [] # not stored on the stream item
    expect(@item.data.submission_comments).to eq [@comment] # but we can still get them
    expect(@item.stream_item_instances.first.read?).to be_truthy
  end

  it "marks last_comment_at on the submission" do
    prepare_test_submission
    @submission.add_comment(author: @submission.user, comment: "some comment")
    expect(@submission.reload.last_comment_at).to be_nil

    draft_comment = @submission.add_comment(author: @teacher, comment: "some comment", draft_comment: true)
    expect(@submission.reload.last_comment_at).to be_nil

    frd_comment = @submission.add_comment(author: @teacher, comment: "some comment")
    expect(@submission.reload.last_comment_at.to_i).to eq frd_comment.created_at.to_i

    draft_comment.update(draft: false, created_at: 2.days.from_now) # should re-run after update
    expect(@submission.reload.last_comment_at.to_i).to eq draft_comment.created_at.to_i

    draft_comment.destroy # should re-run after destroy
    expect(@submission.reload.last_comment_at.to_i).to eq frd_comment.created_at.to_i
  end

  it "does not create a stream item for a provisional comment" do
    prepare_test_submission
    expect do
      @submission.add_comment(author: @teacher, comment: "some comment", provisional: true)
    end.not_to change(StreamItem, :count)
  end

  it "ensures the media object exists" do
    assignment_model
    se = @course.enroll_student(user_factory)
    @submission = @assignment.submit_homework(se.user, body: "some message")
    expect(MediaObject).to receive(:ensure_media_object).with("fake", { context: se.user, user: se.user })
    @comment = @submission.add_comment(author: se.user, media_comment_type: "audio", media_comment_id: "fake")
  end

  describe "peer reviews" do
    before(:once) do
      @student1 = @student
      @student2 = student_in_course(active_all: true).user
      @student3 = student_in_course(active_all: true).user

      @assignment.peer_reviews = true
      @assignment.save!
      @assignment.assign_peer_review(@student2, @student1)
      @assignment.assign_peer_review(@student3, @student1)
    end

    it "prevents peer reviewer from seeing other comments" do
      @teacher_comment = @submission.add_comment(author: @teacher, comment: "some comment from teacher")
      @reviewer_comment = @submission.add_comment(author: @student2, comment: "some comment from peer reviewer")
      @my_comment = @submission.add_comment(author: @student3, comment: "some comment from me")

      expect(@teacher_comment.grants_right?(@student3, :read)).to be_falsey
      expect(@reviewer_comment.grants_right?(@student3, :read)).to be_falsey
      expect(@my_comment.grants_right?(@student3, :read)).to be_truthy

      expect(@teacher_comment.grants_right?(@student1, :read)).to be_truthy
      expect(@reviewer_comment.grants_right?(@student1, :read)).to be_truthy
      expect(@my_comment.grants_right?(@student1, :read)).to be_truthy
    end

    describe "when anonymous" do
      before(:once) do
        @assignment.update_attribute(:anonymous_peer_reviews, true)
        @reviewer_comment = @submission.add_comment({
                                                      author: @student2,
                                                      comment: "My peer review comment."
                                                    })

        @teacher_comment = @submission.add_comment({
                                                     author: @teacher,
                                                     comment: "My teacher review comment."
                                                   })
      end

      it "marks submission comment as anonymous" do
        expect(@reviewer_comment.anonymous?).to be_truthy
      end

      it "prevents reviewed from seeing reviewer name" do
        expect(@reviewer_comment.grants_right?(@student1, :read_author)).to be_falsey
      end

      it "allows teacher to see reviewer name" do
        expect(@reviewer_comment.grants_right?(@teacher, :read_author)).to be_truthy
      end

      it "allows reviewed to see a teacher comment" do
        expect(@teacher_comment.grants_right?(@student1, :read_author)).to be_truthy
      end
    end
  end

  describe "reply_from" do
    it "ignores replies on deleted accounts" do
      comment = @submission.add_comment(user: @teacher, comment: "some comment")
      Account.default.destroy
      comment.reload
      expect do
        comment.reply_from(user: @student, text: "some reply")
      end.to raise_error(IncomingMail::Errors::UnknownAddress)
    end

    it "creates reply" do
      comment = @submission.add_comment(user: @teacher, comment: "blah")
      reply = comment.reply_from(user: @teacher, text: "oops I meant blah")
      expect(reply.provisional_grade).to be_nil
    end

    it "does not create reply for observers" do
      comment = @submission.add_comment(user: @teacher, comment: "blah")
      expect do
        comment.reply_from(user: @observer, text: "some reply")
      end.to raise_error(IncomingMail::Errors::InvalidParticipant)
    end

    it "creates reply in the same provisional grade" do
      comment = @submission.add_comment(user: @teacher, comment: "blah", provisional: true)
      reply = comment.reply_from(user: @teacher, text: "oops I meant blah")
      expect(reply.provisional_grade).to eq(comment.provisional_grade)
      expect(reply.provisional_grade.scorer).to eq @teacher
    end

    it "posts submissions for auto-posted assignments" do
      assignment = @course.assignments.create!
      submission = assignment.submission_for_student(@student)
      comment = submission.add_comment(user: @student, comment: "student")
      expect do
        comment.reply_from(user: @teacher, text: "teacher")
      end.to change {
        submission.reload.posted?
      }.from(false).to(true)
    end
  end

  describe "read/unread state" do
    it "is unread after submission is commented on by teacher" do
      expect do
        @comment = @submission.submission_comments.create!(valid_attributes.merge({ author: @teacher }))
      end.to change(ContentParticipation, :count).by(1)

      expect(ContentParticipation.where(user_id: @student).first).to be_unread
      expect(@submission.unread?(@student)).to be_truthy
    end

    it "is read after submission is commented on by self" do
      expect do
        @comment = @submission.submission_comments.create!(valid_attributes.merge({ author: @student }))
      end.not_to change(ContentParticipation, :count)

      expect(@submission.read?(@student)).to be_truthy
    end

    it "does not set unread state when a provisional comment is made" do
      expect do
        @submission.add_comment(author: @teacher, comment: "wat", provisional: true)
      end.not_to change(ContentParticipation, :count)

      expect(@submission.read?(@student)).to be true
    end

    it "is unread when at least a comment is not commented by self" do
      expect do
        @submission.submission_comments.create!(valid_attributes.merge({ author: @student }))
        @submission.submission_comments.create!(valid_attributes.merge({ author: @teacher }))
      end.to change(ContentParticipation, :count).by(1)

      expect(@submission.unread?(@student)).to be_truthy
    end
  end

  describe "after_destroy #delete_other_comments_in_this_group" do
    context "given a submission with several group comments" do
      let!(:assignment) { @course.assignments.create! }
      let!(:unrelated_assignment) { @course.assignments.create! }
      let!(:submission) { assignment.submissions.find_by!(user: @user) }
      let!(:unrelated_submission) { unrelated_assignment.submissions.find_by!(user: @user) }
      let!(:first_comment) do
        submission.submission_comments.create!(
          group_comment_id: "uuid",
          comment: "first comment"
        )
      end
      let!(:second_comment) do
        submission.submission_comments.create!(
          group_comment_id: "uuid",
          comment: "second comment"
        )
      end
      let!(:ungrouped_comment) do
        submission.submission_comments.create!(
          comment: "third comment (ungrouped)"
        )
      end
      let!(:unrelated_comment) do
        unrelated_submission.submission_comments.create!(
          comment: "unrelated: first comment"
        )
      end
      let!(:unrelated_group_comment) do
        unrelated_submission.submission_comments.create!(
          group_comment_id: "uuid",
          comment: "unrelated: second comment (grouped)"
        )
      end

      it "deletes other group comments on destroy" do
        expect do
          first_comment.destroy
        end.to change { submission.submission_comments.count }.from(3).to(1)
        expect(submission.submission_comments.reload).not_to include first_comment, second_comment
        expect(submission.submission_comments.reload).to include ungrouped_comment
      end
    end
  end

  describe "after_update #publish_other_comments_in_this_group" do
    context "given a submission with several group comments" do
      let!(:assignment) { @course.assignments.create! }
      let!(:unrelated_assignment) { @course.assignments.create! }
      let!(:submission) { assignment.submissions.find_by!(user: @user) }
      let!(:unrelated_submission) { unrelated_assignment.submissions.find_by!(user: @user) }
      let!(:first_comment) do
        submission.submission_comments.create!(
          group_comment_id: "uuid",
          comment: "first comment",
          draft: true
        )
      end
      let!(:second_comment) do
        submission.submission_comments.create!(
          group_comment_id: "uuid",
          comment: "second comment",
          draft: true
        )
      end
      let!(:ungrouped_comment) do
        submission.submission_comments.create!(
          comment: "third comment (ungrouped)",
          draft: true
        )
      end
      let!(:unrelated_comment) do
        unrelated_submission.submission_comments.create!(
          comment: "unrelated: first comment",
          draft: true
        )
      end
      let!(:unrelated_group_comment) do
        unrelated_submission.submission_comments.create!(
          group_comment_id: "uuid",
          comment: "unrelated: second comment (grouped)",
          draft: true
        )
      end

      it "updates other group comments when published" do
        expect do
          first_comment.update_attribute(:draft, false)
        end.to change { SubmissionComment.published.count }.from(0).to(2)
        expect(submission.submission_comments.published.pluck(:id)).to include first_comment.id, second_comment.id
        expect(submission.submission_comments.published.pluck(:id)).not_to include ungrouped_comment.id
      end
    end
  end

  context "given group and nongroup comments" do
    before(:once) do
      @group_comment = @submission.submission_comments.create!(group_comment_id: "foo")
      @nongroup_comment = @submission.submission_comments.create!
    end

    describe "scope: for_groups" do
      subject { SubmissionComment.for_groups }

      it { is_expected.to include(@group_comment) }
      it { is_expected.not_to include(@nongroup_comment) }
    end

    describe "scope: not_for_groups" do
      subject { SubmissionComment.not_for_groups }

      it { is_expected.not_to include(@group_comment) }
      it { is_expected.to include(@nongroup_comment) }
    end
  end

  describe "scope: draft" do
    before(:once) do
      @standard_comment = @submission.submission_comments.create!(valid_attributes)
      @published_comment = @submission.submission_comments.create!(valid_attributes.merge({ draft: false }))
      @draft_comment = @submission.submission_comments.create!(valid_attributes.merge({ draft: true }))
    end

    it "returns the draft comment" do
      expect(SubmissionComment.draft.pluck(:id)).to include(@draft_comment.id)
    end

    it "does not return the standard comment" do
      expect(SubmissionComment.draft.pluck(:id)).not_to include(@standard_comment.id)
    end

    it "does not return the published comment" do
      expect(SubmissionComment.draft.pluck(:id)).not_to include(@published_comment.id)
    end
  end

  describe "scope: published" do
    before(:once) do
      @published_comment = @submission.submission_comments.create!(valid_attributes.merge({ draft: false }))
      @draft_comment = @submission.submission_comments.create!(valid_attributes.merge({ draft: true }))
    end

    it "does not return the draft comment" do
      expect(SubmissionComment.published.pluck(:id)).not_to include(@draft_comment.id)
    end

    it "returns the published comment" do
      expect(SubmissionComment.published.pluck(:id)).to include(@published_comment.id)
    end
  end

  describe "authorization policy" do
    context "draft comment" do
      before(:once) do
        course_with_user("TeacherEnrollment", course: @course)
        @second_teacher = @user

        @submission_comment = @submission.submission_comments.create!(valid_attributes.merge({
                                                                                               draft: true,
                                                                                               author: @teacher
                                                                                             }))
      end

      it "can be updated by the teacher who created it" do
        expect(@submission_comment).to be_grants_any_right(@teacher, :update)
      end

      it "cannot be updated by a different teacher on the same course" do
        expect(@submission_comment).not_to be_grants_any_right(@second_teacher, :update)
      end

      it "cannot be read by a student if it would otherwise be readable by them" do
        @submission_comment.teacher_only_comment = false

        expect(@submission_comment).not_to be_grants_any_right(@student, :read)
      end

      it "cannot be read by an observer of the receiving student if it would otherwise be readable by the student" do
        @submission_comment.teacher_only_comment = false

        observer = User.create!
        @course.enroll_user(observer, "ObserverEnrollment", enrollment_state: :active, associated_user_id: @student.id)
        expect(@submission_comment).not_to be_grants_any_right(observer, :read)
      end
    end

    describe "viewing comments" do
      context "when the assignment is not moderated" do
        let(:course) { Course.create! }
        let(:assignment) { course.assignments.create!(title: "hi") }
        let(:ta) { course.enroll_ta(User.create!, active_all: true).user }
        let(:student) { course.enroll_student(User.create!, enrollment_state: "active").user }
        let(:submission) { assignment.submission_for_student(student) }
        let(:comment) do
          assignment.update_submission(student, commenter: student, comment: "ok")
          submission.submission_comments.first
        end

        it "submitter comments can be read by an instructor with default permissions" do
          expect(comment.grants_right?(ta, :read)).to be true
        end

        it "submitter comments can be read by an instructor who cannot manage assignments but can view the submitter's grades" do
          RoleOverride.create!(context: course.account, permission: :manage_assignments, role: ta_role, enabled: false)
          expect(comment.grants_right?(ta, :read)).to be true
        end

        it "does not allow author to be read if current_user is not present" do
          expect(comment.grants_right?(nil, :read_author)).to be false
        end

        describe "anonymous assignments" do
          let(:assignment) { course.assignments.create!(title: "hi", anonymous_grading: true) }

          it "allows students to read the author of their own comments" do
            expect(comment.grants_right?(student, :read_author)).to be true
          end
        end
      end
    end
  end

  describe "#update_submission" do
    context "draft comment" do
      before(:once) do
        @submission.submission_comments.create!(valid_attributes)
        @submission_comment = @submission.submission_comments.create!(valid_attributes.merge({
                                                                                               draft: true,
                                                                                               author: @teacher
                                                                                             }))
      end

      it "is not reflected in the submission's submission_comments_count" do
        expect(@submission_comment.submission.reload.submission_comments_count).to eq(1)
      end

      it "is reflected in the submission's submission_comments_count as soon as its draft field changes" do
        @submission_comment.draft = false

        expect { @submission_comment.save }.to(
          change { @submission_comment.submission.reload.submission_comments_count }
            .from(1).to(2)
        )
      end
    end
  end

  describe "#auditable?" do
    it "is auditable if it is not a draft and the assignment is auditable" do
      @assignment.update!(anonymous_grading: true)
      comment = @submission.submission_comments.create!(valid_attributes)
      expect(comment).to be_auditable
    end

    it "is not auditable if it is a draft and the assignment is auditable" do
      @assignment.update!(anonymous_grading: true)
      comment = @submission.submission_comments.create!(valid_attributes.merge(draft: true))
      expect(comment).not_to be_auditable
    end

    it "is not auditable if it is not a draft and the assignment is not auditable" do
      @assignment.update!(anonymous_grading: false, moderated_grading: false)
      comment = @submission.submission_comments.create!(valid_attributes)
      expect(comment).not_to be_auditable
    end

    it "is not auditable if posting grades" do
      @assignment.update!(anonymous_grading: true)
      comment = @submission.submission_comments.create!(valid_attributes)
      comment.grade_posting_in_progress = true
      expect(comment).not_to be_auditable
    end
  end

  describe "#edited_at" do
    before(:once) do
      @comment = @submission.submission_comments.create!(valid_attributes)
    end

    it "is nil for newly-created submission comments" do
      expect(@comment.edited_at).to be_nil
    end

    it "remains nil if the submission comment is updated but the 'comment' attribute is unchanged" do
      @comment.update!(draft: true, hidden: true)
      expect(@comment.edited_at).to be_nil
    end

    it "is set if the 'comment' attribute is updated on the submission comment" do
      now = Time.zone.now
      Timecop.freeze(now) { @comment.update!(comment: "changing the comment!") }
      expect(@comment.edited_at).to eql now
    end

    it "is updated on subsequent changes to the 'comment' attribute" do
      now = Time.zone.now
      Timecop.freeze(now) { @comment.update!(comment: "changing the comment!") }

      later = 2.minutes.from_now(now)
      Timecop.freeze(later) do
        expect { @comment.update!(comment: "and again, changing it!") }.to change {
          @comment.edited_at
        }.from(now).to(later)
      end
    end
  end

  describe "audit event logging" do
    before(:once) { @assignment.update!(anonymous_grading: true, grader_count: 2) }

    it "creates exactly one AnonymousOrModerationEvent on creation" do
      expect { @submission.submission_comments.create!(author: @student, anonymous: false) }
        .to change { AnonymousOrModerationEvent.count }.by(1)
    end

    it "on creation of the comment, the payload of the event includes boolean values that were set to false" do
      @submission.submission_comments.create!(author: @student, anonymous: false)
      payload = AnonymousOrModerationEvent.where(assignment: @assignment).last.payload
      expect(payload).to include("anonymous" => false)
    end

    it "does not create an event on creation when no author present" do
      expect do
        @submission.submission_comments.create!(comment: "a comment")
      end.not_to change { AnonymousOrModerationEvent.count }
    end

    it "does not create an event when no updating_user present" do
      comment = @submission.submission_comments.create!(author: @student)
      expect { comment.update!(comment: "changing the comment!") }.not_to change { AnonymousOrModerationEvent.count }
    end
  end

  describe "#attempt" do
    before(:once) do
      @submission.update!(attempt: 4)
      @comment1 = @submission.submission_comments.create!(valid_attributes.merge(attempt: 1))
      @comment2 = @submission.submission_comments.create!(valid_attributes.merge(attempt: 2))
      @comment3 = @submission.submission_comments.create!(valid_attributes.merge(attempt: 2))
      @comment4 = @submission.submission_comments.create!(valid_attributes.merge(attempt: nil))
    end

    context "when the submission attempt is nil" do
      before(:once) do
        @submission.update!(attempt: nil)
      end

      it "raises an error if the submission_comment attempt is greater than 1" do
        expect { @submission.submission_comments.create!(valid_attributes.merge(attempt: 2)) }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "does not raise an error if the submission_comment attempt is equal to 0" do
        expect { @submission.submission_comments.create!(valid_attributes.merge(attempt: 0)) }.not_to raise_error
      end

      it "does not raise an error if the submission_comment attempt is equal to 1" do
        expect { @submission.submission_comments.create!(valid_attributes.merge(attempt: 1)) }.not_to raise_error
      end
    end

    it "can limit comments to the specific attempt" do
      expect(@submission.submission_comments.where(attempt: 1)).to eq [@comment1]
    end

    it "can have multiple comments" do
      expect(@submission.submission_comments.where(attempt: 2).sort).to eq [@comment2, @comment3]
    end

    it "can limit the comments to attempts that are nil" do
      expect(@submission.submission_comments.where(attempt: nil)).to eq [@comment4]
    end

    it "cannot be present? if submission#attempt is nil" do
      @submission.update_column(:attempt, nil) # bypass infer_values callback
      @comment1.reload
      @comment1.attempt = 2
      expect(@comment1).not_to be_valid
    end

    it "cannot be larger then submission#attempt" do
      @comment1.attempt = @submission.attempt + 1
      expect(@comment1).not_to be_valid
    end
  end

  describe "after_save#update_participation" do
    it "doesn't update participation for a manually posted assignment" do
      @assignment.post_policy.update_attribute(:post_manually, true)
      @assignment.hide_submissions(submission_ids: [@submission.id])

      expect(ContentParticipation).to_not receive(:create_or_update)
      @comment = @submission.add_comment(author: @teacher, comment: "some comment")
    end

    it "updates participation for an automatically posted assignment" do
      expect(ContentParticipation).to receive(:participate)
        .with({ content: @submission, user: @student, content_item: "comment", workflow_state: "unread" })
      @comment = @submission.add_comment(author: @teacher, comment: "some comment")
    end

    it "does not update participation for a draft comment" do
      expect(ContentParticipation).to_not receive(:create_or_update)
        .with({ content: @submission, user: @submission.user, workflow_state: "unread" })
      @comment = @submission.add_comment(author: @teacher, comment: "some comment", draft_comment: true)
    end
  end

  describe "workflow_state" do
    it "is set to active by default" do
      comment = @submission.add_comment(author: @teacher, comment: ":|")
      expect(comment).to be_active
    end
  end

  describe "#allows_posting_submission?" do
    it "returns true if the comment is hidden and published" do
      comment = @submission.add_comment(author: @teacher, comment: "hi", hidden: true, draft_comment: false)
      expect(comment).to be_allows_posting_submission
    end

    it "returns false if the comment is not hidden" do
      comment = @submission.add_comment(author: @teacher, comment: "hi", hidden: false, draft_comment: false)
      expect(comment).not_to be_allows_posting_submission
    end

    it "returns false if the comment is a draft" do
      comment = @submission.add_comment(author: @teacher, comment: "hi", hidden: true, draft_comment: true)
      expect(comment).not_to be_allows_posting_submission
    end
  end

  describe "finalizing draft comments" do
    let(:assignment) { @course.assignments.create! }
    let(:student) { @user }
    let(:submission) { assignment.submission_for_student(student) }
    let(:teacher) { @course.enroll_teacher(User.create!, enrollment_state: "active").user }
    let(:admin) { @course.root_account.account_users.create!(user: User.create!).user }

    context "when the associated submission is not yet posted and the assignment is auto-posted" do
      it "posts the submission when an active instructor finalizes a draft comment" do
        comment = submission.add_comment(comment: "hmmmm", draft_comment: true, author: teacher)
        comment.update!(draft: false)
        expect(submission.reload).to be_posted
      end

      it "posts the submission when an admin finalizes a draft comment" do
        comment = submission.add_comment(comment: "HMMMM", draft_comment: true, author: admin)
        comment.update!(draft: false)
        expect(submission.reload).to be_posted
      end

      it "does not post the submission when a non-active instructor finalizes a draft comment" do
        comment = submission.add_comment(comment: "hmmmm", draft_comment: true, author: teacher)
        teacher.enrollments.first.destroy
        comment.update!(draft: false)
        expect(submission.reload).not_to be_posted
      end

      it "does not post the submission if a student somehow creates and finalizes a draft comment" do
        comment = submission.add_comment(comment: "I am the greatest!", draft_comment: true, author: student)
        comment.update!(draft: false)
        expect(submission.reload).not_to be_posted
      end

      it "does not post the submission if the finalized comment has no author" do
        comment = submission.add_comment(comment: "who am I?", draft_comment: true, skip_author: true)
        comment.update!(draft: false)
        expect(submission.reload).not_to be_posted
      end
    end

    it "does not update the submission's posted_at when it is already posted" do
      submission.update!(posted_at: 1.hour.ago(Time.zone.now))
      comment = submission.add_comment(comment: "hmmmm", draft_comment: true, author: teacher)

      expect do
        comment.update!(draft: false)
      end.not_to change {
        submission.reload.posted_at
      }
    end

    it "does not post the submission when the assignment is manually-posted" do
      assignment.post_policy.update!(post_manually: true)

      comment = submission.add_comment(comment: "hmmmm", draft_comment: true, author: teacher)
      comment.update!(draft: false)
      expect(submission.reload).not_to be_posted
    end
  end
end
