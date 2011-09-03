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

describe EnrollmentsFromUserList do
  
  # before(:each) do
  #   # This probably means that I need more mocks.
  #   User.find(:all).each {|x| x.destroy}
  #   Pseudonym.find(:all).each {|x| x.destroy}
  #   CommunicationChannel.find(:all).each {|x| x.destroy}
  #   Enrollment.find(:all).each {|x| x.destroy}
  #   
  #   @course = mock_model(Course)
  #   @course.stub!(:id).and_return(1)
  #   @course.stub!("available?".to_sym).and_return(true)
  #   @course.stub!("enroll_user").and_return({})
  #   @course.available?.should eql(true)
  #   Course.stub!(:create_or_find_by_uuid).and_return(@course)
  #   Course.stub!(:find).and_return(@course)
  # 
  #   @txt = %<david@example.com
  #   george@example.com
  #   >
  #   @loader = PseudonymFromUserLoader.new(@course.id, @txt)
  # end

  context "initialized object" do
    
    before do
      course_model(:reusable => true)
      @el = UserList.new(list_to_parse)
    end
    
    it "should initialize with a course id" do
      lambda{EnrollmentsFromUserList.new}.should raise_error(ArgumentError, 'wrong number of arguments (0 for 1)')
      e = EnrollmentsFromUserList.new(@course)
      e.course.should eql(@course)
    end
    
    it "should process with an user list" do
      enrollments = EnrollmentsFromUserList.process(@el, @course)
      enrollments.all? {|e| e.should be_is_a(StudentEnrollment)}
    end
    
    it "should process repeat addresses without creating new users" do
      @el = UserList.new(list_to_parse_with_repeats)
      enrollments = EnrollmentsFromUserList.process(@el, @course)
      enrollments.length.should eql(3)
    end

    it "should process repeat addresses without creating new users, even if the existing user isn't fully registered yet" do
      u = factory_with_protected_attributes(User, :name => "Bob", :workflow_state => "creation_pending")
      u.pseudonyms.create!(:unique_id => "david_richards_jr@example.com", :path => "david_richards_jr@example.com", :password => "dave4Instructure", :password_confirmation => "dave4Instructure")
      @el = UserList.new(list_to_parse_with_repeats)
      enrollments = EnrollmentsFromUserList.process(@el, @course)
      enrollments.length.should eql(3)
      enrollments.map(&:user).should be_include(u)
    end

    it "should check communication channels in a case-insensitive manner" do
      u = user
      u.pseudonyms.create!(:account => Account.default, :unique_id => "david_richards", :path => "David_Richards_JR@example.com", :password => "dave4Instructure", :password_confirmation => "dave4Instructure")
      @el = UserList.new(list_to_parse_with_repeats)
      enrollments = EnrollmentsFromUserList.process(@el, @course)
      enrollments.length.should eql(3)
      enrollments.map(&:user).should be_include(u)
    end

  end
  
  context "EnrollmentsFromUserList.process" do
    it "should be able to process from the class" do
      course_model(:reusable => true)
      @el = UserList.new(list_to_parse)
      enrollments = EnrollmentsFromUserList.process(@el, @course)
      enrollments.all? {|e| e.should be_is_a(StudentEnrollment)}
    end
  end
  
end


def list_to_parse
  %{david@example.com, "Richards, David" <david_richards@example.com>, David Richards <david_richards_jr@example.com}
end

def list_to_parse_with_repeats
  %{david@example.com, "Richards, David" <david_richards@example.com>, David Richards <david_richards_jr@example.com>, david_richards_jr@example.com, DAVID@example.com}
end
