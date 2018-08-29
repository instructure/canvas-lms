#
# Copyright (C) 2011 - present Instructure, Inc.
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

  def course_announcement(opts = {})
    @announcement = @course.announcements.create!({
      :title => "some announcement",
      :message => "some message"
    }.merge(opts))
  end

  describe "GET 'index'" do
    it "should return unauthorized without a valid session" do
      get 'index', params: {:course_id => @course.id}
      assert_unauthorized
    end

    it "should redirect 'disabled', if disabled by the teacher" do
      user_session(@user)
      @course.update_attribute(:tab_configuration, [{'id'=>14,'hidden'=>true}])
      get 'index', params: {:course_id => @course.id}
      expect(response).to be_redirect
      expect(flash[:notice]).to match(/That page has been disabled/)
    end

    it "returns new bundle for group announcements" do
      user_session(@user)
      @course.group_categories.create!(:name => "My Group Category")
      group = @course.groups.create!(:name => "My Group", :group_category => @course.group_categories.first)
      group.add_user(@user)
      group.save!
      get 'index', params: { :group_id => group.id }
      expect(response).to be_successful
      expect(assigns[:js_bundles].length).to eq 1
      expect(assigns[:js_bundles].first).to include :announcements_index_v2
      expect(assigns[:js_bundles].first).not_to include :announcements_index
    end

    it "returns new bundle for course announcements if section specific enabled" do
      user_session(@user)
      @course.announcements.create!(message: 'hello!')
      get 'index', params: { :course_id => @course.id }
      expect(response).to be_successful
      expect(assigns[:js_bundles].length).to eq 1
      expect(assigns[:js_bundles].first).to include :announcements_index_v2
      expect(assigns[:js_bundles].first).not_to include :announcements_index
    end
  end

  describe "GET 'public_feed.atom'" do
    before :once do
      @context = @course
      announcement_model
    end

    it "should require authorization" do
      get 'public_feed', :format => 'atom', params: {:feed_code => @enrollment.feed_code + 'x'}
      expect(assigns[:problem]).to match /The verification code does not match/
    end

    it "should include absolute path for rel='self' link" do
      get 'public_feed', :format => 'atom', params: {:feed_code => @enrollment.feed_code}
      feed = Atom::Feed.load_feed(response.body) rescue nil
      expect(feed).not_to be_nil
      expect(feed.links.first.rel).to match(/self/)
      expect(feed.links.first.href).to match(/http:\/\//)
    end

    it "should include an author for each entry" do
      get 'public_feed', :format => 'atom', params: {:feed_code => @enrollment.feed_code}
      feed = Atom::Feed.load_feed(response.body) rescue nil
      expect(feed).not_to be_nil
      expect(feed.entries).not_to be_empty
      expect(feed.entries.all?{|e| e.authors.present?}).to be_truthy
    end

    it "shows the 15 most recent announcements" do
      announcement_ids = []
      16.times { announcement_ids << course_announcement.id }
      announcement_ids.shift # Drop first announcement so we have the 15 most recent

      get 'public_feed', :format => 'atom', params: {:feed_code => @enrollment.feed_code}

      feed_entries = Atom::Feed.load_feed(response.body).entries
      feed_entry_ids = feed_entries.map{ |e| e.id.gsub(/.*topic_/, "").to_i }
      expect(feed_entry_ids).to match_array(announcement_ids)
    end

    it "only shows announcements that are visible to the caller" do
      normal_ann = @a # from the announcement_model in the before block
      closed_for_comments_ann = course_announcement(locked: true)
      post_delayed_ann = @course.announcements.build({
        title: 'hi',
        message: 'blah',
        delayed_post_at: 1.day.from_now
      })
      post_delayed_ann.workflow_state = 'post_delayed'
      post_delayed_ann.save!
      deleted_ann = course_announcement
      deleted_ann.destroy

      expect(closed_for_comments_ann).to be_locked
      expect(post_delayed_ann).to be_post_delayed
      expect(deleted_ann).to be_deleted
      visible_announcements = [normal_ann, closed_for_comments_ann]

      get 'public_feed', :format => 'atom', params: {:feed_code => @enrollment.feed_code}

      feed_entries = Atom::Feed.load_feed(response.body).entries
      feed_entry_ids = feed_entries.map{ |e| e.id.gsub(/.*topic_/, "").to_i }
      expect(feed_entry_ids).to match_array(visible_announcements.map(&:id))
    end
  end
end
