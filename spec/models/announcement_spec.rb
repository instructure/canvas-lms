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

describe Announcement do
  it "should create a new instance given valid attributes" do
    @context = Course.create
    @context.announcements.create!(valid_announcement_attributes)
  end

  describe "locking" do
    it "should lock if its course has the lock_all_announcements setting" do
      course = Course.new
      course.lock_all_announcements = true
      course.save!
      student_in_course(:course => course)
      announcement = course.announcements.create!(valid_announcement_attributes)

      expect(announcement).to be_locked
      expect(announcement.grants_right?(@student, :reply)).to be_falsey
    end

    it "should not lock if its course does not have the lock_all_announcements setting" do
      course = Course.create!
      student_in_course(:course => course)

      announcement = course.announcements.create!(valid_announcement_attributes)

      expect(announcement).not_to be_locked
      expect(announcement.grants_right?(@student, :reply)).to be_truthy
    end

    it "should not automatically lock if it is a delayed post" do
      course = Course.new
      course.lock_all_announcements = true
      course.save!
      announcement = course.announcements.build(valid_announcement_attributes.merge(:delayed_post_at => Time.now + 1.week))
      announcement.workflow_state = 'post_delayed'
      announcement.save!

      expect(announcement).to be_post_delayed
    end

    it "should create a single job for delayed posting even though we do a double-save" do
      course = Course.new
      course.lock_all_announcements = true
      course.save!
      expect {
        course.announcements.create!(valid_announcement_attributes.merge(delayed_post_at: 1.week.from_now))
      }.to change(Delayed::Job, :count).by(1)
    end
  end

  context "permissions" do
    it "should not allow announcements on a course" do
      course_with_student(:active_user => 1)
      expect(Announcement.context_allows_user_to_create?(@course, @user, {})).to be_falsey
    end

    it "should allow announcements on a group" do
      group_with_user(:active_user => 1)
      expect(Announcement.context_allows_user_to_create?(@group, @user, {})).to be_truthy
    end
  end
  
  context "broadcast policy" do
    context "sanitization" do
      before :once do
        announcement_model
      end

      it "should sanitize message" do
        @a.message = "<a href='#' onclick='alert(12);'>only this should stay</a>"
        @a.save!
        expect(@a.message).to eql("<a href=\"#\">only this should stay</a>")
      end

      it "should sanitize objects in a message" do
        @a.message = "<object data=\"http://www.youtube.com/test\"></object>"
        @a.save!
        dom = Nokogiri(@a.message)
        expect(dom.css('object').length).to eql(1)
        expect(dom.css('object')[0]['data']).to eql("http://www.youtube.com/test")
      end

      it "should sanitize objects in a message" do
        @a.message = "<object data=\"http://www.youtuube.com/test\" othertag=\"bob\"></object>"
        @a.save!
        dom = Nokogiri(@a.message)
        expect(dom.css('object').length).to eql(1)
        expect(dom.css('object')[0]['data']).to eql("http://www.youtuube.com/test")
        expect(dom.css('object')[0]['othertag']).to eql(nil)
      end
    end

    it "should broadcast to students and observers" do
      course_with_student(:active_all => true)
      course_with_observer(:course => @course, :active_all => true)

      notification_name = "New Announcement"
      n = Notification.create(:name => notification_name, :category => "TestImmediately")
      n2 = Notification.create(:name => "Announcement Created By You", :category => "TestImmediately")

      channel = @teacher.communication_channels.create(:path => "test_channel_email_#{@teacher.id}", :path_type => "email")
      channel.confirm

      NotificationPolicy.create(:notification => n, :communication_channel => @student.communication_channel, :frequency => "immediately")
      NotificationPolicy.create(:notification => n, :communication_channel => @observer.communication_channel, :frequency => "immediately")
      NotificationPolicy.create(:notification => n2, :communication_channel => channel, :frequency => "immediately")

      @context = @course
      announcement_model(:user => @teacher)

      to_users = @a.messages_sent[notification_name].map(&:user)
      expect(to_users).to include(@student)
      expect(to_users).to include(@observer)
      expect(@a.messages_sent["Announcement Created By You"].map(&:user)).to include(@teacher)
    end
  end
end
