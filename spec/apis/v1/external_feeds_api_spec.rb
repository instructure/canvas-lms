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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe 'ExternalFeedsController', type: :request do
  shared_examples_for "Announcement External Feeds" do
    before :once do
      @url_params = { :controller => "external_feeds", :action => "index", :format => "json" }
    end

    it "should not allow access to unauthorized users" do
      api_call_as_user(@denied_user, :get, @url_base, @url_params, {}, {}, :expected_status => 401)
      api_call_as_user(@denied_user, :post, @url_base, @url_params.merge(:action => "create"), { :url => "http://www.example.com/feed" }, {}, :expected_status => 401)
      @feed = external_feed_model(:context => @context)
      api_call_as_user(@denied_user, :delete, @url_base+"/#{@feed.id}", @url_params.merge(:action => "destroy", :external_feed_id => @feed.to_param), {}, {}, :expected_status => 401)
    end

    def feed_json(f)
      {
        'id' => f.id,
        'display_name' => f.display_name,
        'url' => f.url,
        'header_match' => f.header_match,
        'created_at' => f.created_at.as_json,
        'verbosity' => f.verbosity,
        'external_feed_entries_count' => f.external_feed_entries.size,
      }
    end

    it "should allow listing feeds" do
      @feeds = (0...3).map { |i| external_feed_model(:url => "http://www.example.com/feed#{i}", :context => @context, :user => @allowed_user) }
      @feeds[1].external_feed_entries.create!(user: @allowed_user)
      external_feed_model(:context => Course.create!)
      json = api_call_as_user(@allowed_user, :get, @url_base, @url_params, { :per_page => 2 })
      expect(json).to eq @feeds[0,2].map { |f| feed_json(f) }
    end

    it "should allow creating feeds" do
      json = api_call_as_user(@allowed_user, :post, @url_base, @url_params.merge(:action => "create"),
                              { :url => "http://www.example.com/feed" })
      feed = @context.external_feeds.find(json['id'])
      expect(json).to eq feed_json(feed)

      json = api_call_as_user(@allowed_user, :post, @url_base, @url_params.merge(:action => "create"),
                              { :url => "http://www.example.com/feed", :header_match => '' })
      feed = @context.external_feeds.find(json['id'])
      expect(feed.verbosity).to eq 'full'
      expect(feed.header_match).to eq nil
      expect(json).to eq feed_json(feed)

      json = api_call_as_user(@allowed_user, :post, @url_base, @url_params.merge(:action => "create"),
                              { :url => "http://www.example.com/feed", :header_match => ' #mytag  ', :verbosity => 'truncate' })
      feed = @context.external_feeds.find(json['id'])
      expect(feed.verbosity).to eq 'truncate'
      expect(feed.header_match).to eq '#mytag'
      expect(json).to eq feed_json(feed)

      # bad verbosity value
      json = api_call_as_user(@allowed_user, :post, @url_base, @url_params.merge(:action => "create"),
                              { :url => "http://www.example.com/feed", :verbosity => 'bogus' })
      feed = @context.external_feeds.find(json['id'])
      expect(feed.verbosity).to eq 'full'

      # invalid url
      json = api_call_as_user(@allowed_user, :post, @url_base, @url_params.merge(:action => "create"),
                              { :url => "ker blah" }, {}, :expected_status => 400)

      # no url
      json = api_call_as_user(@allowed_user, :post, @url_base, @url_params.merge(:action => "create"),
                              { :verbosity => 'full' }, {}, :expected_status => 400)

      # url protocol is inferred
      json = api_call_as_user(@allowed_user, :post, @url_base, @url_params.merge(:action => "create"),
                              { :url => "www.example.com/feed" })
      feed = @context.external_feeds.find(json['id'])
      expect(feed.url).to eq "http://www.example.com/feed"
      expect(json).to eq feed_json(feed)
    end

    it "should allow deleting a feed" do
      feed = external_feed_model(:url => "http://www.example.com/feed", :context => @context, :user => @allowed_user)
      json = api_call_as_user(@allowed_user, :delete, @url_base+"/#{feed.id}", @url_params.merge(:action => "destroy", :external_feed_id => feed.to_param))
      expect(json).to eq feed_json(feed)
    end
  end

  describe "in a Course" do
    include_examples "Announcement External Feeds"
    before :once do
      @allowed_user = teacher_in_course(:active_all => true).user
      @context = @course
      @denied_user = student_in_course(:course => @course, :active_all => true).user
      @url_base = "/api/v1/courses/#{@course.id}/external_feeds"
      @url_params.merge!({ :course_id => @course.to_param })
    end
  end

  describe "in a Group" do
    include_examples "Announcement External Feeds"
    before :once do
      group_with_user(:moderator => true, :active_all => true)
      @allowed_user = @user
      @allowed_user.pseudonyms.create!(:unique_id => 'user1', :account => Account.default)
      @context = @group
      @denied_user = user_with_pseudonym(:active_all => true, :unique_id => 'user2')
      @url_base = "/api/v1/groups/#{@group.id}/external_feeds"
      @url_params.merge!({ :group_id => @group.to_param })
    end
  end
end
