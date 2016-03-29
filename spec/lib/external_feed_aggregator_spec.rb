#
# Copyright (C) 2015 Instructure, Inc.
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

describe ExternalFeedAggregator do
  context "#process_feed" do
    before(:once) do
      course(active_all: true)
      @feed = external_feed_model
    end

    it "should work correctly" do
      response = Net::HTTPSuccess.new(1.1, 200, "OK")
      response.expects(:body).returns(rss_example)
      CanvasHttp.expects(:get).with(@feed.url).returns(response)
      ExternalFeedAggregator.new.process_feed(@feed)

      expect(@feed.external_feed_entries.length).to eq 1
    end

    it "should set failure counts and refresh_at on failure" do
      CanvasHttp.expects(:get).with(@feed.url).raises(CanvasHttp::Error)
      ExternalFeedAggregator.new.process_feed(@feed)
      expect(@feed.failures).to eq 1
      expect(@feed.consecutive_failures).to eq 1
      expect(@feed.refresh_at).to be > 20.minutes.from_now
    end

  end

def rss_example
%{<?xml version="1.0"?>
<rss version="2.0">
  <channel>
    <title>Lift Off News</title>
    <link>http://liftoff.msfc.nasa.gov/</link>
    <description>Liftoff to Space Exploration.</description>
    <language>en-us</language>
    <pubDate>Tue, 10 Jun 2003 04:00:00 GMT</pubDate>
    <lastBuildDate>Tue, 10 Jun 2003 09:41:01 GMT</lastBuildDate>
    <docs>http://blogs.law.harvard.edu/tech/rss</docs>
    <generator>Weblog Editor 2.0</generator>
    <managingEditor>editor@example.com</managingEditor>
    <webMaster>webmaster@example.com</webMaster>
    <ttl>5</ttl>

    <item>
      <title>Star City</title>
      <link>http://liftoff.msfc.nasa.gov/news/2003/news-starcity.asp</link>
      <description>How do Americans get ready to work with Russians aboard the
        International Space Station? They take a crash course in culture, language
        and protocol at Russia's Star City.</description>
      <pubDate>Tue, 03 Jun 2003 09:39:21 GMT</pubDate>
      <guid>http://liftoff.msfc.nasa.gov/2003/06/03.html#item573</guid>
    </item>
  </channel>
</rss>}
end
end
