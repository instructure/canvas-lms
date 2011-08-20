#
# Copyright (C) 2011 Instructure, Inc.
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
  before(:each) do
    @user = factory_with_protected_attributes(User, :name => "some student", :workflow_state => "registered")
    @context = factory_with_protected_attributes(Course, :name => "some course", :workflow_state => "available")
    @context.enroll_student(@user)
    @assignment = @context.assignments.new(:title => "some assignment")
    @assignment.workflow_state = "published"
    @assignment.save
    @submission = @assignment.submit_homework(@user)
    @valid_attributes = {
      :submission => @submission,
      :comment => "some comment"
    }
  end
  
  it "should create a new instance given valid attributes" do
    SubmissionComment.create!(@valid_attributes)
  end

  it "should not dispatch notification on create if assignment is not published" do
    assignment_model
    @assignment.workflow_state = 'available'
    @assignment.save
    @course.offer
    te = @course.enroll_teacher(user)
    se = @course.enroll_student(user)
    @assignment.reload
    @submission = @assignment.submit_homework(se.user, :body => 'some message')
    @submission.created_at = Time.now - 60
    @submission.save
    Notification.create(:name => 'Submission Comment')
    @comment = @submission.add_comment(:author => te.user, :comment => "some comment")
    @comment.messages_sent.should_not be_include('Submission Comment')
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
    @comment.messages_sent.keys.sort.should == ["Submission Comment"]
    @comment.clear_broadcast_messages
    @comment = @submission.add_comment(:author => se.user, :comment => "some comment")
    @comment.messages_sent.keys.sort.should == ["Submission Comment", "Submission Comment For Teacher"]
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
    @comment.messages_sent.should be_include('Submission Comment')
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
    @comment.messages_sent.should be_include('Submission Comment For Teacher')
  end
  
  it "should respond to attachments" do
    SubmissionComment.new.should be_respond_to(:attachments)
  end
  
  it "should allow valid attachments" do
    a = Attachment.create!(:context => @assignment, :uploaded_data => default_uploaded_data)
    @comment = SubmissionComment.create!(@valid_attributes)
    a.recently_created.should eql(true)
    @comment.reload
    @comment.update_attributes(:attachments => [a])
    @comment.attachment_ids.should eql(a.id.to_s)
  end
  
  it "should reject invalid attachments" do
    a = Attachment.create!(:context => @assignment, :uploaded_data => default_uploaded_data)
    a.recently_created = false
    @comment = SubmissionComment.create!(@valid_attributes)
    @comment.update_attributes(:attachments => [a])
    @comment.attachment_ids.should eql("")
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
    body.should match(/\<a/)
    body.should match(/quoted_text/)
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
    @item.should_not be_nil
    @item.item_asset_string.should eql(@submission.asset_string)
    @item.data.should be_is_a(OpenObject)
    @item.data.submission_comments.should_not be_nil
    @item.data.id.should eql(@submission.id)
    @item.data.submission_comments[0].id.should eql(@comment.id)
    @item.data.submission_comments[0].formatted_body.should eql(@comment.formatted_body(250))
  end
end
