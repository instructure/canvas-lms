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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AnnouncementsController do
  def course_announcement
    @announcement = @course.announcements.create!(
      :title => "some announcement", 
      :message => "some message"
    )
  end

  describe "GET 'index'" do
    it "should return unauthorized without a valid session" do
      course_with_student(:active_all => true)
      get 'index', :course_id => @course.id
      assert_unauthorized
    end
    
    it "should redirect 'disabled', if disabled by the teacher" do
      course_with_student_logged_in(:active_all => true)
      @course.update_attribute(:tab_configuration, [{'id'=>14,'hidden'=>true}])
      get 'index', :course_id => @course.id
      response.should be_redirect
      flash[:notice].should match(/That page has been disabled/)
    end
    
    it "should assign variables" do
      course_with_student_logged_in(:active_all => true)
      
      get 'index', :course_id => @course.id
      assigns[:announcements].should_not be_nil
    end
    
    it "should retrieve course assignments if they exist" do
      course_with_student_logged_in(:active_all => true)
      course_announcement
      
      get 'index', :course_id => @course.id
      
      assigns[:announcements].should_not be_nil
      assigns[:announcements].should_not be_empty
      assigns[:announcements][0].should eql(@announcement)
    end

    it "should sort announcements by posted_at date" do
      course_with_student_logged_in(:active_all => true)
      posted_30_min_ago = course_announcement
      posted_30_min_ago.posted_at = 30.minutes.ago
      posted_now = course_announcement
      posted_now.posted_at = Time.now
      get 'index', :course_id => @course.id

      assigns[:announcements][0].should eql(posted_now)
      assigns[:announcements][1].should eql(posted_30_min_ago)
    end
  end

  describe "GET 'public_feed.atom'" do
    before(:each) do
      course_with_student(:active_all => true)
      @context = @course
      announcement_model
    end

    it "should require authorization" do
      get 'public_feed', :format => 'atom', :feed_code => @enrollment.feed_code + 'x'
      assigns[:problem].should match /The verification code does not match/
    end

    it "should include absolute path for rel='self' link" do
      get 'public_feed', :format => 'atom', :feed_code => @enrollment.feed_code
      feed = Atom::Feed.load_feed(response.body) rescue nil
      feed.should_not be_nil
      feed.links.first.rel.should match(/self/)
      feed.links.first.href.should match(/http:\/\//)
    end

    it "should include an author for each entry" do
      get 'public_feed', :format => 'atom', :feed_code => @enrollment.feed_code
      feed = Atom::Feed.load_feed(response.body) rescue nil
      feed.should_not be_nil
      feed.entries.should_not be_empty
      feed.entries.all?{|e| e.authors.present?}.should be_true
    end
  end
end
