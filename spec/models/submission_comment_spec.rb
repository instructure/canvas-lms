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
    @item.asset.should == @submission
    @item.data.should be_is_a(Submission)
    @item.data.submission_comments.target.should == [] # not stored on the stream item
    @item.data.submission_comments.should == [@comment] # but we can still get them
  end

  it "should ensure the media object exists" do
    assignment_model
    se = @course.enroll_student(user)
    @submission = @assignment.submit_homework(se.user, :body => 'some message')
    MediaObject.expects(:ensure_media_object).with("fake", { :context => se.user, :user => se.user })
    @comment = @submission.add_comment(:author => se.user, :media_comment_type => 'audio', :media_comment_id => 'fake')
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
        tc1.last_message_at.to_i.should eql c1.created_at.to_i
        tc1.messages.last.body.should eql c2.comment
        tc1.messages.last.author.should eql @teacher1
      end

      it "should set the root_account_ids" do
        @submission1.add_comment(:author => @student1, :comment => "hello")
        @teacher.conversations.where(:root_account_ids => nil).any?.should be_false
        @submission1.add_comment(:author => @teacher1, :comment => "sup")
        @teacher.conversations.where(:root_account_ids => nil).any?.should be_false
        @student.conversations.where(:root_account_ids => nil).any?.should be_false
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
        tconvo.update_attribute :workflow_state, 'read' 
        @submission1.add_comment(:author => @teacher1, :comment => "hi")
        sconvo = @student1.conversations.first
        sconvo.should be_unread
        tconvo.reload.should be_read
      end

      it "should not create conversations for teachers in new conversations" do
        @teacher1.preferences[:use_new_conversations] = true
        @teacher1.save!
        @submission1.add_comment(author: @student1, comment: 'test')
        @teacher1.reload.unread_conversations_count.should == 0
      end

      it "should not create conversations for students in new conversations" do
        @student1.preferences[:use_new_conversations] = true
        @student1.save!
        @submission1.add_comment(author: @teacher1, comment: 'test')
        @student1.reload.unread_conversations_count.should == 0
      end

      context "teacher makes first submission comment" do
        it "should only show as sent for the teacher if private converstation does not already exist" do
          @submission1.add_comment(:author => @teacher1, :comment => "test comment")
          @teacher1.conversations.should be_empty
          @teacher1.all_conversations.size.should eql 1
          @teacher1.all_conversations.sent.size.should eql 1
        end

        it "should reuse an existing private conversation, but not change its state for teacher" do
          convo = Conversation.initiate([@teacher1, @student1], true)
          convo.add_message(@teacher1, 'direct message')
          @teacher1.conversations.count.should == 1
          convo = @teacher1.conversations.first
          convo.workflow_state = 'archived'
          convo.save!
          @teacher1.reload.conversations.default.should be_empty

          @submission1.add_comment(:author => @teacher1, :comment => "test comment")
          @teacher1.reload
          @teacher1.all_conversations.size.should eql 1
          @teacher1.conversations.default.should be_empty
          @teacher1.all_conversations.archived.size.should eql 1
        end
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
          it "should not create new conversations" do
            @teacher1.conversations.count.should == 0
            @submission1.add_comment(:author => @student1, :comment => 'New comment')
            @teacher1.conversations.count.should == 0
          end
          it "should create conversations after re-enabling the notification" do
            @submission1.add_comment(:author => @student1, :comment => 'New comment')
            @teacher1.conversations.count.should == 0
            @teacher1.preferences[:no_submission_comments_inbox] = false
            @teacher1.save!
            # Student adds another comment
            @submission1.add_comment(:author => @student1, :comment => 'Another comment')
            @teacher1.conversations.count.should == 1
          end
          it "should show teacher comment as new to student" do
            @submission1.add_comment(:author => @student1, :comment => 'Test comment')
            @submission1.add_comment(:author => @teacher1, :comment => 'Test response')
            @student1.conversations.unread.count.should == 1
          end
          it "should not block direct message from student" do
            convo = Conversation.initiate([@student1, @teacher], false)
            convo.add_message(@student1, 'My direct message')
            @teacher.conversations.unread.count.should == 1
          end
          it "should add submission comments to existing conversations" do
            convo = Conversation.initiate([@student1, @teacher1], true)
            convo.add_message(@student1, 'My direct message')
            c = @teacher1.conversations.unread.first
            c.should_not be_nil
            c.update_attribute(:workflow_state, 'read')
            @submission1.add_comment(:author => @student1, :comment => 'A comment')
            c.reload
            c.should be_read # still read, since we don't care to be notified
            c.messages.size.should eql 2 # but the submission is visible
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
        @teacher1.all_conversations.sent.size.should eql 0
        @student1.conversations.size.should eql 0
        @assignment.unmute!
        @teacher1.reload.conversations.size.should eql 0
        @teacher1.all_conversations.sent.size.should eql 1
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

      it "should respect the no_submission_comments_inbox setting" do
        @teacher1.preferences[:no_submission_comments_inbox] = true
        @teacher1.save!
        c1 = @submission1.add_comment(:author => @student1, :comment => "help!")
        c2 = @submission1.add_comment(:author => @teacher1, :comment => "ok", :hidden => true)
        c3 = @submission1.add_comment(:author => @teacher2, :comment => "no", :hidden => true)
        @student1.conversations.size.should eql 0
        @teacher1.conversations.size.should eql 0
        @teacher1.all_conversations.sent.size.should eql 0
        t2convo = @teacher2.conversations.first
        t2convo.workflow_state = :read
        t2convo.save!

        @assignment.unmute!

        # If there is more than one author in the set of submission comments,
        # then it is treated as a new message for everyone.
        @teacher1.reload.conversations.should be_empty
        @teacher1.all_conversations.size.should eql 1
        @teacher1.all_conversations.sent.size.should eql 0
        t2convo.reload.should be_unread
        @student1.reload.conversations.size.should eql 2
        @student1.conversations.first.should be_unread
        @student1.conversations.last.should be_unread
      end

      it "should reuse an existing private conversation, but not change its state for teacher on unmute" do
        convo = Conversation.initiate([@teacher1, @student1], true)
        convo.add_message(@teacher1, 'direct message')
        @teacher1.conversations.count.should == 1
        convo = @teacher1.conversations.first
        convo.workflow_state = 'archived'
        convo.save!
        @submission1.add_comment(:author => @teacher1, :comment => "test comment")

        @assignment.unmute!

        @teacher1.reload.conversations.default.should be_empty
        @teacher1.all_conversations.size.should eql 1
        @teacher1.all_conversations.archived.size.should eql 1
        @teacher1.all_conversations.sent.size.should eql 1
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
        tc1.last_message_at.to_i.should eql c1.created_at.to_i
        tc1.messages.last.body.should eql c2.comment
        tc1.messages.last.author.should eql @teacher1

        c3.destroy

        tc1.reload
        tc1.last_message_at.to_i.should eql c1.created_at.to_i
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

      it "should delete other comments for the same assignment with the same group_comment_id" do
        c1 = @submission1.add_comment(:comment => "hai")
        c1.update_attribute(:group_comment_id, "testid1")
        @submission2 = @assignment.submit_homework(@course.enroll_student(user).user, :body => 'sub2')
        c2 = @submission2.add_comment(:comment => "hai2")
        c2.update_attribute(:group_comment_id, "testid1")
        @assignment2 = assignment_model(:course => @course)
        @assignment2.update_attribute(:workflow_state, 'published')
        @submission3 = @assignment2.submit_homework(@student1, :body => 'sub3')
        c3 = @submission3.add_comment(:comment => "hai3")
        c3.update_attribute(:group_comment_id, "testid1")
        c1.destroy
        SubmissionComment.find_by_id(c1.id).should be_nil
        SubmissionComment.find_by_id(c2.id).should be_nil
        SubmissionComment.find_by_id(c3.id).should == c3
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
        convo1 = @student1.initiate_conversation([@teacher1])
        convo1.add_message('ohai')
        convo2 = @student1.initiate_conversation([@teacher2])
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
        convo = @student1.initiate_conversation([@teacher1])
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
        convo = @student1.initiate_conversation([@teacher1])
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
        convo = @student1.initiate_conversation([@teacher1])
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

    @teacher_comment.grants_right?(@student3, :read).should be_false
    @reviewer_comment.grants_right?(@student3, :read).should be_false
    @my_comment.grants_right?(@student3, :read).should be_true

    @teacher_comment.grants_right?(@student1, :read).should be_true
    @reviewer_comment.grants_right?(@student1, :read).should be_true
    @my_comment.grants_right?(@student1, :read).should be_true
  end

  describe "reply_from" do
    it "should ignore replies on deleted accounts" do
      comment = @submission.add_comment(:user => @teacher, :comment => "some comment")
      Account.default.destroy
      comment.reload
      lambda { 
        comment.reply_from(:user => @student, :text => "some reply") 
      }.should raise_error(IncomingMail::Errors::UnknownAddress)
    end
  end

  describe "read/unread state" do
    it "should be unread after submission is commented on by teacher" do
      expect {
        @comment = SubmissionComment.create!(@valid_attributes.merge({:author => @teacher}))
      }.to change(ContentParticipation, :count).by(1)
      ContentParticipation.find_by_user_id(@student).should be_unread
      @submission.unread?(@student).should be_true
    end

    it "should be read after submission is commented on by self" do
      expect {
        @comment = SubmissionComment.create!(@valid_attributes.merge({:author => @student}))
      }.to change(ContentParticipation, :count).by(0)
      @submission.read?(@student).should be_true
    end
  end
end
