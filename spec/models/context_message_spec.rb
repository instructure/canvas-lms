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

describe ContextMessage do
  context "notifications" do
    it "should create teacher context messages" do
      Notification.create(:name => "Teacher Context Message")
      course_with_teacher(:active_all => true)
      @teacher = @user
      e = @course.enroll_student(user(:active_all => true))
      e.accept
      
      m = @course.context_messages.build
      m.update_attributes(:user => @teacher, :recipients => "#{@teacher.id},#{@user.id}", :subject => 'Some Message', :body => 'Some Body')
      m.messages_sent.should be_include("Teacher Context Message")
    end
    
    it "should create student context messages" do
      Notification.create(:name => "Student Context Message")
      course_with_teacher(:active_all => true)
      @teacher = @user
      e = @course.enroll_student(user(:active_all => true))
      e.accept
      
      m = @course.context_messages.build
      m.update_attributes(:user => @user, :recipients => "#{@teacher.id},#{@user.id}", :subject => 'Some Message', :body => 'Some Body')
      m.messages_sent.should be_include("Student Context Message")
    end
  end
  
  context "stream_items" do
    it "should not delete the root stream_item if a sub-message is deleted, only if the root message is deleted" do
      pre_cnt = StreamItem.count
      course_with_teacher(:active_all => true)
      @teacher = @user
      e = @course.enroll_student(user(:active_all => true))
      e.accept
      
      m = @course.context_messages.build
      m.update_attributes(:user => @teacher, :recipients => "#{@teacher.id},#{@user.id}", :subject => 'Some Message', :body => 'Some Body')
      StreamItem.count.should eql(pre_cnt + 1)
      si = StreamItem.last
      si.item_asset_string.should eql(m.asset_string)
      m2 = @course.context_messages.build
      m2.attributes = {:user => @user, :recipients => "#{@teacher.id}", :subject => "Re: Some Message", :body => "Me too!"}
      m2.root_context_message_id = m.id
      m2.save!
      StreamItem.count.should eql(pre_cnt + 1)
      StreamItem.last.should eql(si)
      
      m2.destroy
      StreamItem.count.should eql(pre_cnt + 1)
      
      m.destroy
      StreamItem.count.should eql(pre_cnt)
    end
  end
end
