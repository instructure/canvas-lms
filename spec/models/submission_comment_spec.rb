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

  context "conversations" do
    before do
      assignment_model
      @assignment.workflow_state = 'published'
      @assignment.save
      @course.offer
      @course.enroll_teacher(user).accept
      @teacher1 = @user
      @course.enroll_teacher(user).accept
      @teacher2 = @user
      @assignment.reload
      @course.enroll_student(user)
      @student1 = @user
      @assignment.context.reload
      @submission1 = @assignment.submit_homework(@student1, :body => 'some message')
    end

    context "creation" do
      it "should send submitter comments to all instructors if no instructors have commented" do
        @submission1.add_comment(:author => @student1, :comment => "hello")
        @teacher1.conversations.size.should eql 1
        tc1 = @teacher1.conversations.first
        tc1.messages.size.should eql 1
        tc1.messages.first.asset.should eql @submission1
        @teacher2.conversations.size.should eql 1
        tc2 = @teacher2.conversations.first
        tc2.messages.size.should eql 1
        tc2.messages.first.asset.should eql @submission1
      end

      it "should not send non-participant comments to anyone" do
        @submission1.add_comment(:author => user, :comment => "ohai im in ur group")
        @teacher1.conversations.size.should eql 0 # if we actually set up a group assignment and had this comment on all submissions, the teacher would have one conversation with that commenter
        @student1.conversations.size.should eql 0
      end

      it "should just create a single message for all comments" do
        @submission1.add_comment(:author => @student1, :comment => "hello")
        @submission1.add_comment(:author => @student1, :comment => "hello again!")
        @submission1.add_comment(:author => @student1, :comment => "hello hello hello!")
        @teacher1.conversations.size.should eql 1
        tc1 = @teacher1.conversations.first
        tc1.messages.size.should eql 1
        tc1.messages.first.asset.should eql @submission1
      end

      it "should set the most recent comment as the message data" do
        SubmissionComment.any_instance.stubs(:current_time_from_proper_timezone).returns(Time.now.utc, Time.now.utc + 1.hour)
        c1 = @submission1.add_comment(:author => @student1, :comment => "hello")
        c2 = @submission1.add_comment(:author => @teacher1, :comment => "hello again!").reload
        @teacher1.conversations.size.should eql 1
        tc1 = @teacher1.conversations.first
        tc1.last_message_at.to_i.should eql c2.created_at.to_i
        tc1.messages.last.body.should eql c2.comment
        tc1.messages.last.author.should eql @teacher1
      end

      it "should not be visible to the student until an instructor comments" do
        @submission1.add_comment(:author => @student1, :comment => "hello")
        @student1.conversations.size.should eql 0

        @submission1.add_comment(:author => @teacher1, :comment => "sup")
        @student1.conversations.reload.size.should eql 1
      end

      it "should not be visible to other instructors once the first instructor comments" do
        @submission1.add_comment(:author => @student1, :comment => "hello")
        @teacher1.conversations.size.should eql 1
        @teacher2.conversations.size.should eql 1
        @submission1.add_comment(:author => @teacher1, :comment => "hello")
        @teacher2.reload.conversations.size.should eql 0
        @teacher2.all_conversations.size.should eql 1 # still there, the message was just deleted
      end

      it "should set the unread count/status for everyone but the author" do
        @submission1.add_comment(:author => @student1, :comment => "hello")
        tconvo = @teacher1.conversations.first
        tconvo.should be_unread
        @submission1.add_comment(:author => @teacher1, :comment => "hi")
        sconvo = @student1.conversations.first
        sconvo.should be_unread

        tconvo.remove_messages(:all)
        sconvo.workflow_state = :read
        sconvo.save!
      end

      context "with no_submission_comments_inbox" do
        context "when teacher sets after conversation started" do
          before :each do
            @submission1.add_comment(:author => @student1, :comment => 'Test comment')
            @submission1.add_comment(:author => @teacher1, :comment => 'Test response')
            @student1.mark_all_conversations_as_read!
            @teacher1.mark_all_conversations_as_read!
          end

          it "should keep unread 0 when comments added" do
            @teacher1.conversations.unread.count.should == 0
            # Disable notification with existing conversation
            @teacher1.preferences[:no_submission_comments_inbox] = true
            @teacher1.save!
            # Student adds another comment
            @submission1.add_comment(:author => @student1, :comment => 'New comment')
            @teacher1.conversations.unread.count.should == 0
          end
        end
        context "when not set" do
          before :each do
            @submission1.add_comment(:author => @student1, :comment => 'Test comment')
          end

          it "should add an unread comment" do
            @teacher1.conversations.unread.count.should == 1
          end
        end
        context "when preference set for teacher" do
          before :each do
            # setup user setting
            @teacher1.preferences[:no_submission_comments_inbox] = true
            @teacher1.save!
          end
          it "should not show up in conversations" do
            @teacher1.conversations.count.should == 0
            # Disable notification with existing conversation
            @teacher1.preferences[:no_submission_comments_inbox] = true
            @teacher1.save!
            # Student adds another comment
            @submission1.add_comment(:author => @student1, :comment => 'New comment')
            @teacher1.conversations.count.should == 0
          end
          it "should show teacher comment as new to student" do
            @submission1.add_comment(:author => @student1, :comment => 'Test comment')
            @submission1.add_comment(:author => @teacher1, :comment => 'Test response')
            @student1.conversations.unread.count.should == 1
          end
          it "should not block direct message from student" do
            convo = Conversation.initiate([@student1.id, @teacher.id], false)
            convo.add_message(@student1, 'My direct message')
            @teacher.conversations.unread.count.should == 1
          end
        end
      end
    end

    context "unmuting" do
      before do
        @assignment.mute!
      end

      it "should update conversations when assignments are unmuted" do
        @submission1.add_comment(:author => @teacher1, :comment => "!", :hidden => true)
        @teacher1.conversations.size.should eql 0
        @student1.conversations.size.should eql 0
        @assignment.unmute!
        @teacher1.reload.conversations.size.should eql 1
        @teacher1.conversations.first.should be_read
        @student1.reload.conversations.size.should eql 1
        @student1.conversations.first.should be_unread
      end

      it "should not set an older created_at/message" do
        SubmissionComment.any_instance.stubs(:current_time_from_proper_timezone).returns(Time.now.utc, Time.now.utc + 1.hour)
        c1 = @submission1.add_comment(:author => @teacher1, :comment => "!", :hidden => true)
        c2 = @submission1.add_comment(:author => @student1, :comment => "a new comment").reload
        @teacher1.conversations.size.should eql 1
        @teacher1.conversations.first.messages.last.created_at.to_i.should eql c2.created_at.to_i
        @teacher1.conversations.first.messages.last.body.should eql c2.comment
        @teacher2.conversations.size.should eql 1
        @student1.conversations.size.should eql 0
        @assignment.unmute!
        @teacher1.reload.conversations.size.should eql 1
        @teacher1.conversations.first.messages.last.created_at.to_i.should eql c2.created_at.to_i
        @teacher1.conversations.first.messages.last.body.should eql c2.comment
        @teacher2.reload.conversations.size.should eql 0
        @student1.reload.conversations.size.should eql 1
        @student1.conversations.first.should be_unread
      end

      it "should mark-as-unread for everyone if there are multiple authors of hidden comments" do
        c1 = @submission1.add_comment(:author => @student1, :comment => "help!")
        c2 = @submission1.add_comment(:author => @teacher1, :comment => "ok", :hidden => true)
        c3 = @submission1.add_comment(:author => @teacher2, :comment => "no", :hidden => true)
        @student1.conversations.size.should eql 0
        t1convo = @teacher1.conversations.first
        t1convo.workflow_state = :read
        t1convo.save!
        t2convo = @teacher2.conversations.first
        t2convo.workflow_state = :read
        t2convo.save!

        @assignment.unmute!

        t1convo.reload.should be_unread
        t2convo.reload.should be_unread
        @student1.reload.conversations.size.should eql 2
        @student1.conversations.first.should be_unread
        @student1.conversations.last.should be_unread
      end
    end

    context "deletion" do
      it "should update the message correctly if the most recent comment is deleted" do
        SubmissionComment.any_instance.stubs(:current_time_from_proper_timezone).returns(Time.now.utc, Time.now.utc + 1.hour)
        c1 = @submission1.add_comment(:author => @student1, :comment => "hello").reload
        c2 = @submission1.add_comment(:author => @teacher1, :comment => "hello again!")
        c2.destroy
        @teacher1.conversations.size.should eql 1
        tc1 = @teacher1.conversations.first
        tc1.last_message_at.to_i.should eql c1.created_at.to_i
        tc1.messages.last.body.should eql c1.comment
        tc1.messages.last.author.should eql @student1

        # it won't reappear in the other teacher's conversation until another
        # non-instructor comment is added, since we don't know if it was
        # deleted automatically or explicitly by the teacher
        @teacher2.conversations.size.should eql 0
      end

      it "should not change the message preview/timestamp if the deleted message was by a non-participant" do
        SubmissionComment.any_instance.stubs(:current_time_from_proper_timezone).returns(Time.now.utc, Time.now.utc + 1.hour)
        c1 = @submission1.add_comment(:author => @student1, :comment => "hello")
        c2 = @submission1.add_comment(:author => @teacher1, :comment => "hello again!").reload
        c3 = @submission1.add_comment(:author => user, :comment => "ohai im in ur group")
        tc1 = @teacher1.conversations.first
        tc1.last_message_at.to_i.should eql c2.created_at.to_i
        tc1.messages.last.body.should eql c2.comment
        tc1.messages.last.author.should eql @teacher1

        c3.destroy

        tc1.reload
        tc1.last_message_at.to_i.should eql c2.created_at.to_i
        tc1.messages.last.body.should eql c2.comment
        tc1.messages.last.author.should eql @teacher1
      end

      it "should not re-add the message to users who have deleted it" do
        c1 = @submission1.add_comment(:author => @student1, :comment => "hello")
        c2 = @submission1.add_comment(:author => @student1, :comment => "hello again!")
        @teacher1.conversations.size.should eql 1
        tc1 = @teacher1.conversations.first
        tc1.remove_messages(:all)
        @teacher1.conversations.should be_empty
        c2.destroy

        @teacher1.conversations.reload.should be_empty
      end

      it "should remove the message from conversations when the last comment is deleted" do
        c1 = @submission1.add_comment(:author => @student1, :comment => "hello")
        @teacher1.conversations.size.should eql 1
        c1.destroy
        @teacher1.reload.conversations.size.should eql 0
      end
    end

    context "migration" do
      def raw_comment(submission, author, comment, time=Time.now.utc)
        c = Submission.connection
        c.execute <<-SQL
          INSERT INTO submission_comments(submission_id, author_id, created_at, comment)
          VALUES(#{c.quote(submission.id)}, #{c.quote(author.id)}, #{c.quote(time)}, #{c.quote(comment)})
        SQL
      end

      before do
        @course.enroll_student(user)
        @student2 = @user
        @submission2 = @assignment.submit_homework(@student2, :body => 'some message')
      end

      it "should only create messages where conversations already exist" do
        convo1 = @student1.initiate_conversation([@teacher1.id])
        convo1.add_message('ohai')
        convo2 = @student1.initiate_conversation([@teacher2.id])
        convo2.add_message('hey', :update_for_sender => false) # like if the student did a bulk private message
        @student1.conversations.size.should eql 1 # second one is not visible to student
        @student1.conversations.first.messages.size.should eql 1
        @student2.conversations.size.should eql 0
        @teacher1.conversations.size.should eql 1
        @teacher1.conversations.first.messages.size.should eql 1
        @teacher2.conversations.size.should eql 1
        @teacher2.conversations.first.messages.size.should eql 1

        raw_comment(@submission1, @student1, "hello")
        @submission1.create_or_update_conversations!(:migrate)
        raw_comment(@submission2, @student2, "yo")
        @submission2.create_or_update_conversations!(:migrate)

        # same number of conversations, but existing ones got the new message
        @student1.conversations.size.should eql 1 # second one is still not visible to student
        @student1.conversations.first.messages.size.should eql 2
        @student2.conversations.size.should eql 0
        @teacher1.conversations.size.should eql 1
        @teacher1.conversations.first.messages.size.should eql 2
        @teacher2.conversations.size.should eql 1
        @teacher2.conversations.first.messages.size.should eql 2
      end

      it "should not change any unread count/status" do
        convo = @student1.initiate_conversation([@teacher1.id])
        convo.add_message('ohai')
        @student1.conversations.size.should eql 1
        convo.messages.size.should eql 1
        @teacher1.conversations.size.should eql 1
        tconvo = @teacher1.conversations.first
        tconvo.messages.size.should eql 1
        tconvo.workflow_state = :read
        tconvo.save!
        @teacher1.reload.unread_conversations_count.should eql 0

        raw_comment(@submission1, @student1, "hello")
        @submission1.create_or_update_conversations!(:migrate)

        convo.reload.messages.size.should eql 2
        convo.should be_read
        @student1.reload.unread_conversations_count.should eql 0
        tconvo.reload.messages.size.should eql 2
        tconvo.should be_read
        @teacher1.reload.unread_conversations_count.should eql 0
      end

      it "should update last_message_at, message_count and last_authored_at" do
        convo = @student1.initiate_conversation([@teacher1.id])
        convo.add_message('ohai')
        tconvo = @teacher1.conversations.first
        raw_comment(@submission1, @student1, "hello", Time.now.utc + 1.day)
        raw_comment(@submission1, @student1, "hello!", Time.now.utc + 2.day)
        @submission1.create_or_update_conversations!(:migrate)
        comments = @submission1.submission_comments

        convo.reload.messages.size.should eql 2
        convo.last_message_at.to_i.should eql comments.last.created_at.to_i
        convo.last_authored_at.to_i.should eql comments.last.created_at.to_i
        convo.messages.first.created_at.to_i.should eql comments.last.created_at.to_i

        tconvo.reload.messages.size.should eql 2
        tconvo.last_message_at.to_i.should eql comments.last.created_at.to_i
        tconvo.last_authored_at.should be_nil
        tconvo.messages.first.created_at.to_i.should eql comments.last.created_at.to_i
      end

      it "should skip submissions with no participant comments" do
        convo = @student1.initiate_conversation([@teacher1.id])
        message = convo.add_message('ohai').reload
        tconvo = @teacher1.conversations.first
        raw_comment(@submission1, user, "ohai im in ur group", Time.now.utc + 1.day)

        # should not add a submission message
        @submission1.create_or_update_conversations!(:migrate)

        convo.reload.messages.size.should eql 1
        convo.last_message_at.to_i.should eql message.created_at.to_i
        convo.last_authored_at.to_i.should eql message.created_at.to_i
        convo.messages.first.created_at.to_i.should eql message.created_at.to_i

        tconvo.reload.messages.size.should eql 1
        tconvo.last_message_at.to_i.should eql message.created_at.to_i
        tconvo.last_authored_at.should be_nil
        tconvo.messages.first.created_at.to_i.should eql message.created_at.to_i
      end
    end
  end
end
