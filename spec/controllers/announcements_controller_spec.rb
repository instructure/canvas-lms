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
  before :once do
    course_with_student(:active_all => true)
  end

  def course_announcement
    @announcement = @course.announcements.create!(
      :title => "some announcement", 
      :message => "some message"
    )
  end

  describe "GET 'index'" do
    it "should return unauthorized without a valid session" do
      get 'index', :course_id => @course.id
      assert_unauthorized
    end
    
    it "should redirect 'disabled', if disabled by the teacher" do
      user_session(@user)
      @course.update_attribute(:tab_configuration, [{'id'=>14,'hidden'=>true}])
      get 'index', :course_id => @course.id
      expect(response).to be_redirect
      expect(flash[:notice]).to match(/That page has been disabled/)
    end
  end

  describe "GET 'public_feed.atom'" do
    before :once do
      @context = @course
      announcement_model
    end

    it "should require authorization" do
      get 'public_feed', :format => 'atom', :feed_code => @enrollment.feed_code + 'x'
      expect(assigns[:problem]).to match /The verification code does not match/
    end

    it "should include absolute path for rel='self' link" do
      get 'public_feed', :format => 'atom', :feed_code => @enrollment.feed_code
      feed = Atom::Feed.load_feed(response.body) rescue nil
      expect(feed).not_to be_nil
      expect(feed.links.first.rel).to match(/self/)
      expect(feed.links.first.href).to match(/http:\/\//)
    end

    it "should include an author for each entry" do
      get 'public_feed', :format => 'atom', :feed_code => @enrollment.feed_code
      feed = Atom::Feed.load_feed(response.body) rescue nil
      expect(feed).not_to be_nil
      expect(feed.entries).not_to be_empty
      expect(feed.entries.all?{|e| e.authors.present?}).to be_truthy
    end

    it "shows the 15 most recent announcements" do
      announcements = []
      16.times { announcements << course_announcement.id }
      announcements.shift # Drop first announcement so we have the 15 most recent
      get 'public_feed', :format => 'atom', :feed_code => @enrollment.feed_code
      feed_entries = Atom::Feed.load_feed(response.body).entries
      feed_entries.map!{ |e| e.id.gsub(/.*topic_/, "").to_i }
      expect(feed_entries).to match_array(announcements)
    end
  end
end
