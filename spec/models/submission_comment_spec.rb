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

  it "should dispatch notifications on create regardless of how long ago the submission was created" do
    assignment_model
    @assignment.workflow_state = 'published'
    @assignment.save
    @course.offer
    te = @course.enroll_teacher(user)
    se = @course.enroll_student(user)
    @assignment.reload
    @submission = @assignment.submit_homework(se.user, :body => 'some message')
    @submission.save
    Notification.create(:name => 'Submission Comment')
    Notification.create(:name => 'Submission Comment For Teacher')
    @comment = @submission.add_comment(:author => te.user, :comment => "some comment")
    expect(@comment.messages_sent.keys.sort).to eq ["Submission Comment"]
    @comment.clear_broadcast_messages
    @comment = @submission.add_comment(:author => se.user, :comment => "some comment")
    expect(@comment.messages_sent.keys.sort).to eq ["Submission Comment", "Submission Comment For Teacher"]
  end

  it "should dispatch notification on create if assignment is published" do
    assignment_model
    @assignment.workflow_state = 'published'
    @assignment.save
    @course.offer
    @course.enroll_teacher(user)
    se = @course.enroll_student(user)
    @assignment.reload
    @submission = @assignment.submit_homework(se.user, :body => 'some message')
    @submission.created_at = Time.now - 60
    @submission.save
    Notification.create(:name => 'Submission Comment')
    @comment = @submission.add_comment(:author => se.user, :comment => "some comment")
    expect(@comment.messages_sent).to be_include('Submission Comment')
  end

  it "should not dispatch notification on create if course is unpublished" do
    assignment_model
    @assignment.workflow_state = 'published'
    @assignment.save
    @course.enroll_teacher(user)
    se = @course.enroll_student(user)
    @assignment.reload
    @submission = @assignment.submit_homework(se.user, :body => 'some message')
    @submission.created_at = Time.now - 60
    @submission.save
    Notification.create(:name => 'Submission Comment')
    @comment = @submission.add_comment(:author => se.user, :comment => "some comment")
    expect(@comment.messages_sent).to_not be_include('Submission Comment')
  end
  
  it "should dispatch notification on create to teachers even if submission not submitted yet" do
    assignment_model
    @assignment.workflow_state = 'published'
    @assignment.save
    @course.offer
    @course.enroll_teacher(user)
    se = @course.enroll_student(user)
    @submission = @assignment.find_or_create_submission(se.user)
    @submission.save
    Notification.create(:name => 'Submission Comment For Teacher')
    @comment = @submission.add_comment(:author => se.user, :comment => "some comment")
    expect(@comment.messages_sent).to be_include('Submission Comment For Teacher')
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
  
  it "should send the submission to the stream" do
    assignment_model
    @assignment.workflow_state = 'published'
    @assignment.save
    @course.offer
    @course.enroll_teacher(user)
    se = @course.enroll_student(user)
    @assignment.reload
    @submission = @assignment.submit_homework(se.user, :body => 'some message')
    @submission.created_at = Time.now - 60
    @submission.save
    @comment = @submission.add_comment(:author => se.user, :comment => "some comment")
    @item = StreamItem.last
    expect(@item).not_to be_nil
    expect(@item.asset).to eq @submission
    expect(@item.data).to be_is_a(Submission)
    expect(@item.data.submission_comments.target).to eq [] # not stored on the stream item
    expect(@item.data.submission_comments).to eq [@comment] # but we can still get them
    expect(@item.stream_item_instances.first.read?).to be_truthy
  end

  it "should ensure the media object exists" do
    assignment_model
    se = @course.enroll_student(user)
    @submission = @assignment.submit_homework(se.user, :body => 'some message')
    MediaObject.expects(:ensure_media_object).with("fake", { :context => se.user, :user => se.user })
    @comment = @submission.add_comment(:author => se.user, :media_comment_type => 'audio', :media_comment_id => 'fake')
  end

  it "should prevent peer reviewer from seeing other comments" do
    @student1 = @student
    @student2 = student_in_course(:active_all => true).user
    @student3 = student_in_course(:active_all => true).user

    @assignment.peer_reviews = true
    @assignment.save!
    @assignment.assign_peer_review(@student2, @student1)
    @assignment.assign_peer_review(@student3, @student1)

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

  describe "reply_from" do
    it "should ignore replies on deleted accounts" do
      comment = @submission.add_comment(:user => @teacher, :comment => "some comment")
      Account.default.destroy
      comment.reload
      expect { 
        comment.reply_from(:user => @student, :text => "some reply") 
      }.to raise_error(IncomingMail::Errors::UnknownAddress)
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
  end
end
