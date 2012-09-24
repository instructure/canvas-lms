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

describe ContentParticipationCount do
  before do
    course_with_teacher(:active_all => true)
    student_in_course(:active_all => true)

    @course.discussion_topics.create!(:user => @teacher, :title => "hi", :message => "a")
    @course.announcements.create!(:user => @teacher, :title => "to read", :message => "a")

    @group_category = @course.group_categories.create!(:name => "course groups")
    @group = @group_category.groups.create!(:context => @course, :name => "course groups 1")
    @group.add_user(@student, 'accepted')

    @group.discussion_topics.create!(:user => @teacher, :title => "hi", :message => "a")
    @group.announcements.create!(:user => @teacher, :title => "to read", :message => "a")
  end

  describe "create_or_update" do
    it "should count current unread objects correctly" do
      ["DiscussionTopic", "Announcement"].each do |type|
        cpc = ContentParticipationCount.create_or_update(:context => @course, :user => @teacher, :content_type => type)
        cpc.expects(:refresh_unread_count).never
        cpc.unread_count.should == 0

        cpc = ContentParticipationCount.create_or_update(:context => @course, :user => @student, :content_type => type)
        cpc.expects(:refresh_unread_count).never
        cpc.unread_count.should == 1

        cpc = ContentParticipationCount.create_or_update(:context => @group, :user => @teacher, :content_type => type)
        cpc.expects(:refresh_unread_count).never
        cpc.unread_count.should == 0

        cpc = ContentParticipationCount.create_or_update(:context => @group, :user => @student, :content_type => type)
        cpc.expects(:refresh_unread_count).never
        cpc.unread_count.should == 1
      end
    end

    it "should update if the object already exists" do
      cpc = ContentParticipationCount.create_or_update(:context => @course, :user => @student, :content_type => "Announcement")
      ContentParticipationCount.create_or_update(:context => @course, :user => @student, :content_type => "Announcement", :offset => -1)
      cpc.reload
      cpc.expects(:refresh_unread_count).never
      cpc.unread_count.should == 0
    end

    it "should not save if not changed" do
      time = Time.now.utc - 1.day
      cpc = ContentParticipationCount.create_or_update(:context => @course, :user => @student, :content_type => "Announcement")
      ContentParticipationCount.update_all({:updated_at => time}, {:id => cpc.id})
      ContentParticipationCount.create_or_update(:context => @course, :user => @student, :content_type => "Announcement")
      cpc.reload.updated_at.to_i.should == time.to_i
    end
  end

  describe "unread_count_for" do
    it "should find the unread count for different types" do
      ["DiscussionTopic", "Announcement"].each do |type|
        ContentParticipationCount.unread_count_for(type, @course, @teacher).should == 0
        ContentParticipationCount.unread_count_for(type, @course, @student).should == 1
        ContentParticipationCount.unread_count_for(type, @group, @teacher).should == 0
        ContentParticipationCount.unread_count_for(type, @group, @student).should == 1
      end
    end

    it "should handle invalid contexts" do
      ["DiscussionTopic", "Announcement"].each do |type|
        ContentParticipationCount.unread_count_for(type, Account.default, @student).should == 0
      end
    end

    it "should handle invalid types" do
      ContentParticipationCount.unread_count_for("Assignment", @course, @student).should == 0
    end

    it "should handle missing contexts or users" do
      ["DiscussionTopic", "Announcement"].each do |type|
        ContentParticipationCount.unread_count_for(type, nil, @student).should == 0
        ContentParticipationCount.unread_count_for(type, @course, nil).should == 0
      end
    end
  end

  describe "unread_count" do
    it "should not refresh if just created" do
      ["DiscussionTopic", "Announcement"].each do |type|
        cpc = ContentParticipationCount.create_or_update(:context => @course, :user => @teacher, :content_type => type)
        cpc.expects(:refresh_unread_count).never
        cpc.unread_count.should == 0
      end
    end

    it "should refresh if data could be stale" do
      ["DiscussionTopic", "Announcement"].each do |type|
        cpc = ContentParticipationCount.create_or_update(:context => @course, :user => @teacher, :content_type => type)
        cpc.expects(:refresh_unread_count).never
        cpc.unread_count.should == 0
        ContentParticipationCount.update_all({:updated_at => Time.now.utc - 1.day}, {:id => cpc.id})
        cpc.reload
        cpc.expects(:refresh_unread_count)
        cpc.unread_count.should == 0
      end
    end
  end

  describe "unread_submission_count_for" do
    before do
      @assignment = @course.assignments.new(:title => "some assignment")
      @assignment.workflow_state = "published"
      @assignment.save
    end

    it "should be read if a submission exists with no grade" do
      @submission = @assignment.submit_homework(@student)
      ContentParticipationCount.unread_submission_count_for(@course, @student).should == 0
    end

    it "should be unread after assignment is graded" do
      @submission = @assignment.grade_student(@student, { :grade => 3 }).first
      ContentParticipationCount.unread_submission_count_for(@course, @student).should == 1
    end

    it "should be unread after submission is graded" do
      @assignment.submit_homework(@student)
      @submission = @assignment.grade_student(@student, { :grade => 3 }).first
      ContentParticipationCount.unread_submission_count_for(@course, @student).should == 1
    end

    it "should be unread after submission is commented on by teacher" do
      @submission = @assignment.grade_student(@student, { :grader => @teacher, :comment => "good!" }).first
      ContentParticipationCount.unread_submission_count_for(@course, @student).should == 1
    end

    it "should be unread after submission is commented on by self" do
      @submission = @assignment.submit_homework(@student)
      @comment = SubmissionComment.create!(:submission => @submission, :comment => "hi", :author => @student)
      @submission.read?(@student).should be_true
    end

    it "should be read if other submission fields change" do
      @submission = @assignment.submit_homework(@student)
      @submission.workflow_state = 'graded'
      @submission.graded_at = Time.now
      @submission.save!
      ContentParticipationCount.unread_submission_count_for(@course, @student).should == 0
    end
  end
end
