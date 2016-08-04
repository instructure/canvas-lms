#
# Copyright (C) 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe SubmissionComment do
  before(:once) do
    course_with_teacher(:active_all => true)
    student_in_course(:active_all => true)
    @assignment = @course.assignments.new(:title => "some assignment")
    @assignment.workflow_state = "published"
    @assignment.save!
    @submission = @assignment.submit_homework(@user)
    @valid_attributes = {
      :submission => @submission,
      :comment => "some comment"
    }
  end

  it "should create a new instance given valid attributes" do
    SubmissionComment.create!(@valid_attributes)
  end

  describe 'notifications' do
    before(:once) do
      Notification.create(:name => 'Submission Comment', category: 'TestImmediately')
      Notification.create(:name => 'Submission Comment For Teacher')
    end

    it "dispatches notifications on create for published assignment" do
      comment = @submission.add_comment(:author => @teacher, :comment => "some comment")
      expect(comment.messages_sent.keys.sort).to eq ["Submission Comment"]

      comment = @submission.add_comment(:author => @student, :comment => "some comment")
      expect(comment.messages_sent.keys.sort).to eq ["Submission Comment For Teacher"]
    end

    it "dispatches notifications to observers" do
      course_with_observer(active_all: true, active_cc: true, course: @course, associated_user_id: @student.id)
      @submission.add_comment(:author => @teacher, :comment => "some comment")
      expect(@observer.email_channel.messages.length).to eq 1
    end

    it "should not dispatch notification on create if course is unpublished" do
      @course.complete
      @comment = @submission.add_comment(:author => @teacher, :comment => "some comment")
      expect(@course).to_not be_available
      expect(@comment.messages_sent.keys).to_not be_include('Submission Comment')
    end

    it "should not dispatch notification on create if student is inactive" do
      @student.enrollments.first.deactivate

      @comment = @submission.add_comment(:author => @teacher, :comment => "some comment")
      expect(@comment.messages_sent.keys).to_not be_include('Submission Comment')
    end

    it "should not dispatch notification on create for provisional comments" do
      @comment = @submission.add_comment(:author => @teacher, :comment => "huttah!", :provisional => true)
      expect(@comment.messages_sent).to be_empty
    end

    it "should dispatch notification on create to teachers even if submission not submitted yet" do
      student_in_course(active_all: true)
      @submission = @assignment.find_or_create_submission(@student)
      @comment = @submission.add_comment(:author => @student, :comment => "some comment")
      expect(@submission).to be_unsubmitted
      expect(@comment.messages_sent).to be_include('Submission Comment For Teacher')
    end

    context 'draft comment' do
      before(:each) do
        @comment = @submission.add_comment(author: @teacher, comment: '42', draft_comment: true)
      end

      it 'does not dispatch notification on create' do
        expect(@comment.messages_sent).to be_empty
      end

      it 'dispatches notification on update when the draft changes to false' do
        @comment.draft = false
        @comment.save

        expect(@comment.messages_sent.keys).to eq(['Submission Comment'])
      end
    end
  end

  it "should allow valid attachments" do
    a = Attachment.create!(:context => @assignment, :uploaded_data => default_uploaded_data)
    @comment = SubmissionComment.create!(@valid_attributes)
    expect(a.recently_created).to eql(true)
    @comment.reload
    @comment.update_attributes(:attachments => [a])
    expect(@comment.attachment_ids).to eql(a.id.to_s)
  end

  it "should reject invalid attachments" do
    a = Attachment.create!(:context => @assignment, :uploaded_data => default_uploaded_data)
    a.recently_created = false
    @comment = SubmissionComment.create!(@valid_attributes)
    @comment.update_attributes(:attachments => [a])
    expect(@comment.attachment_ids).to eql("")
  end

  it "should render formatted_body correctly" do
    @comment = SubmissionComment.create!(@valid_attributes)
    @comment.comment = %{
This text has a http://www.google.com link in it...

> and some
> quoted text
}
    @comment.save!
    body = @comment.formatted_body
    expect(body).to match(/\<a/)
    expect(body).to match(/quoted_text/)
  end

  def prepare_test_submission
    assignment_model
    @assignment.workflow_state = 'published'
    @assignment.save
    @course.offer
    @course.enroll_teacher(user)
    @se = @course.enroll_student(user)
    @assignment.reload
    @submission = @assignment.submit_homework(@se.user, :body => 'some message')
    @submission.created_at = Time.now - 60
    @submission.save
  end

  it "should send the submission to the stream" do
    prepare_test_submission
    @comment = @submission.add_comment(:author => @se.user, :comment => "some comment")
    @item = StreamItem.last
    expect(@item).not_to be_nil
    expect(@item.asset).to eq @submission
    expect(@item.data).to be_is_a(Submission)
    expect(@item.data.submission_comments.target).to eq [] # not stored on the stream item
    expect(@item.data.submission_comments).to eq [@comment] # but we can still get them
    expect(@item.stream_item_instances.first.read?).to be_truthy
  end

  it "should not create a stream item for a provisional comment" do
    prepare_test_submission
    expect {
      @submission.add_comment(:author => @teacher, :comment => "some comment", :provisional => true)
    }.to change(StreamItem, :count).by(0)
  end

  it "should ensure the media object exists" do
    assignment_model
    se = @course.enroll_student(user)
    @submission = @assignment.submit_homework(se.user, :body => 'some message')
    MediaObject.expects(:ensure_media_object).with("fake", { :context => se.user, :user => se.user })
    @comment = @submission.add_comment(:author => se.user, :media_comment_type => 'audio', :media_comment_id => 'fake')
  end

  describe "peer reviews" do
    before(:once) do
      @student1 = @student
      @student2 = student_in_course(:active_all => true).user
      @student3 = student_in_course(:active_all => true).user

      @assignment.peer_reviews = true
      @assignment.save!
      @assignment.assign_peer_review(@student2, @student1)
      @assignment.assign_peer_review(@student3, @student1)
    end

    it "should prevent peer reviewer from seeing other comments" do
      @teacher_comment = @submission.add_comment(:author => @teacher, :comment => "some comment from teacher")
      @reviewer_comment = @submission.add_comment(:author => @student2, :comment => "some comment from peer reviewer")
      @my_comment = @submission.add_comment(:author => @student3, :comment => "some comment from me")

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

      it "should mark submission comment as anonymous" do
        expect(@reviewer_comment.anonymous?).to be_truthy
      end

      it "should prevent reviewed from seeing reviewer name" do
        expect(@reviewer_comment.grants_right?(@student1, :read_author)).to be_falsey
      end

      it "should allow teacher to see reviewer name" do
        expect(@reviewer_comment.grants_right?(@teacher, :read_author)).to be_truthy
      end

      it "should allow reviewed to see a teacher comment" do
        expect(@teacher_comment.grants_right?(@student1, :read_author)).to be_truthy
      end
    end
  end

  describe "reply_from" do
    it "should ignore replies on deleted accounts" do
      comment = @submission.add_comment(:user => @teacher, :comment => "some comment")
      Account.default.destroy
      comment.reload
      expect {
        comment.reply_from(:user => @student, :text => "some reply")
      }.to raise_error(IncomingMail::Errors::UnknownAddress)
    end

    it "should create reply" do
      comment = @submission.add_comment(:user => @teacher, :comment => "blah")
      reply = comment.reply_from(:user => @teacher, :text => "oops I meant blah")
      expect(reply.provisional_grade).to be_nil
    end

    it "should create reply in the same provisional grade" do
      comment = @submission.add_comment(:user => @teacher, :comment => "blah", :provisional => true)
      reply = comment.reply_from(:user => @teacher, :text => "oops I meant blah")
      expect(reply.provisional_grade).to eq(comment.provisional_grade)
      expect(reply.provisional_grade.scorer).to eq @teacher
    end
  end

  describe "read/unread state" do
    it "should be unread after submission is commented on by teacher" do
      expect {
        @comment = SubmissionComment.create!(@valid_attributes.merge({:author => @teacher}))
      }.to change(ContentParticipation, :count).by(1)
      expect(ContentParticipation.where(user_id: @student).first).to be_unread
      expect(@submission.unread?(@student)).to be_truthy
    end

    it "should be read after submission is commented on by self" do
      expect {
        @comment = SubmissionComment.create!(@valid_attributes.merge({:author => @student}))
      }.to change(ContentParticipation, :count).by(0)
      expect(@submission.read?(@student)).to be_truthy
    end

    it "should not set unread state when a provisional comment is made" do
      expect {
        @submission.add_comment(:author => @teacher, :comment => 'wat', :provisional => true)
      }.to change(ContentParticipation, :count).by(0)
      expect(@submission.read?(@student)).to eq true
    end
  end

  describe 'after_destroy #delete_other_comments_in_this_group' do
    context 'given a submission with several group comments' do
      let!(:assignment) { @course.assignments.create! }
      let!(:unrelated_assignment) { @course.assignments.create! }
      let!(:submission) { assignment.submissions.create!(user: @user) }
      let!(:unrelated_submission) { unrelated_assignment.submissions.create!(user: @user) }
      let!(:first_comment) do
        submission.submission_comments.create!(
          group_comment_id: 'uuid',
          comment: 'first comment'
        )
      end
      let!(:second_comment) do
        submission.submission_comments.create!(
          group_comment_id: 'uuid',
          comment: 'second comment'
        )
      end
      let!(:ungrouped_comment) do
        submission.submission_comments.create!(
          comment: 'third comment (ungrouped)'
        )
      end
      let!(:unrelated_comment) do
        unrelated_submission.submission_comments.create!(
          comment: 'unrelated: first comment'
        )
      end
      let!(:unrelated_group_comment) do
        unrelated_submission.submission_comments.create!(
          group_comment_id: 'uuid',
          comment: 'unrelated: second comment (grouped)'
        )
      end

      it 'deletes other group comments on destroy' do
        expect {
          first_comment.destroy
        }.to change { submission.submission_comments.count }.from(3).to(1)
        expect(submission.submission_comments).to_not include [first_comment, second_comment]
        expect(submission.submission_comments).to include ungrouped_comment
      end
    end
  end

  describe 'scope: draft' do
    before(:once) do
      @standard_comment = SubmissionComment.create!(@valid_attributes)
      @published_comment = SubmissionComment.create!(@valid_attributes.merge({ draft: false }))
      @draft_comment = SubmissionComment.create!(@valid_attributes.merge({ draft: true }))
    end

    it 'returns the draft comment' do
      expect(SubmissionComment.draft.pluck(:id)).to include(@draft_comment.id)
    end

    it 'does not return the standard comment' do
      expect(SubmissionComment.draft.pluck(:id)).not_to include(@standard_comment.id)
    end

    it 'does not return the published comment' do
      expect(SubmissionComment.draft.pluck(:id)).not_to include(@published_comment.id)
    end
  end

  describe 'scope: published' do
    before(:once) do
      @standard_comment = SubmissionComment.create!(@valid_attributes)
      @published_comment = SubmissionComment.create!(@valid_attributes.merge({ draft: false }))
      @draft_comment = SubmissionComment.create!(@valid_attributes.merge({ draft: true }))

      @standard_comment.update_attribute(:draft, nil)
    end

    it 'does not return the draft comment' do
      expect(SubmissionComment.published.pluck(:id)).not_to include(@draft_comment.id)
    end

    it 'returns the standard comment' do
      expect(SubmissionComment.published.pluck(:id)).to include(@standard_comment.id)
    end

    it 'returns the published comment' do
      expect(SubmissionComment.published.pluck(:id)).to include(@published_comment.id)
    end
  end

  describe 'authorization policy' do
    context 'draft comment' do
      before(:once) do
        course_with_user('TeacherEnrollment', course: @course)
        @second_teacher = @user

        @submission_comment = SubmissionComment.create!(@valid_attributes.merge({ draft: true, author: @teacher }))
      end

      it 'can be updated by the teacher who created it' do
        expect(@submission_comment.grants_any_right?(@teacher, {}, :update)).to be_truthy
      end

      it 'cannot be updated by a different teacher on the same course' do
        expect(@submission_comment.grants_any_right?(@second_teacher, {}, :update)).to be_falsey
      end

      it 'cannot be read by a student if it would otherwise be readable by them' do
        @submission_comment.teacher_only_comment = false

        expect(@submission_comment.grants_any_right?(@student, {}, :read)).to be_falsey
      end
    end
  end

  describe '#update_submission' do
    context 'draft comment' do
      before(:once) do
        SubmissionComment.create!(@valid_attributes)
        @submission_comment = SubmissionComment.create!(@valid_attributes.merge({ draft: true, author: @teacher }))
      end

      it "is not reflected in the submission's submission_comments_count" do
        expect(@submission_comment.submission.reload.submission_comments_count).to eq(1)
      end

      it "is reflected in the submission's submission_comments_count as soon as its draft field changes" do
        @submission_comment.draft = false

        expect { @submission_comment.save }.to(
          change { @submission_comment.submission.reload.submission_comments_count }.
            from(1).to(2)
        )
      end
    end
  end
end
