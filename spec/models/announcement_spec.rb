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
    it "should have a broadcast policy" do
      announcement_model
      @a.should be_respond_to(:dispatch)
      @a.should be_respond_to(:to)
    end
    
    it "should have a single policy" do
      announcement_model
      @a.broadcast_policy_list.size.should eql(1)
    end
    
    it "should have a policy for 'New Announcement'" do
      announcement_model
      @a.broadcast_policy_list.first.dispatch.should eql('New Announcement')
    end
    
    # it "should create a message for the announcement" do
    #   @notification = mock_model(Notification)
    #   @notification.should_receive(:create_message).and_return(true)
    #   Notification.stub!(:find_by_name).and_return(@notification)
    #   @user = User.create
    #   @course = Course.create
    #   @course.enroll_student(@user)
    #   announcement_model(:context_id => @course.id, :context_type => @course.class)
    #   # Need to fix the course context
    # end
    
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
  end
end
