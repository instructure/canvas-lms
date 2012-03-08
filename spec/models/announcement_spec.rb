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
  
  context "broadcast policy" do
    it "should sanitize message" do
      announcement_model
      @a.message = "<a href='#' onclick='alert(12);'>only this should stay</a>"
      @a.save!
      @a.message.should eql("<a href=\"#\">only this should stay</a>")
    end
    
    it "should sanitize objects in a message" do
      announcement_model
      @a.message = "<object data=\"http://www.youtube.com/test\"></object>"
      @a.save!
      dom = Nokogiri(@a.message)
      dom.css('object').length.should eql(1)
      dom.css('object')[0]['data'].should eql("http://www.youtube.com/test")
    end
    
    it "should sanitize objects in a message" do
      announcement_model
      @a.message = "<object data=\"http://www.youtuube.com/test\" othertag=\"bob\"></object>"
      @a.save!
      dom = Nokogiri(@a.message)
      dom.css('object').length.should eql(1)
      dom.css('object')[0]['data'].should eql("http://www.youtuube.com/test")
      dom.css('object')[0]['othertag'].should eql(nil)
    end

    it "should broadcast to students and observers" do
      course_with_student(:active_all => true)
      course_with_observer(:course => @course, :active_all => true)

      notification_name = "New Announcement"
      n = Notification.create(:name => notification_name, :category => "TestImmediately")
      NotificationPolicy.create(:notification => n, :communication_channel => @student.communication_channel, :frequency => "immediately")
      NotificationPolicy.create(:notification => n, :communication_channel => @observer.communication_channel, :frequency => "immediately")

      @context = @course
      announcement_model

      to_users = @a.messages_sent[notification_name].map(&:user)
      to_users.should include(@student)
      to_users.should include(@observer)
    end
  end
end
