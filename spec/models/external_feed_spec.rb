# frozen_string_literal: true

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

describe ExternalFeed do
  it "adds rss entries" do
    @feed = external_feed_model
    require "rss/1.0"
    require "rss/2.0"
    rss = RSS::Parser.parse rss_example
    res = @feed.add_rss_entries(rss)
    expect(res).not_to be_nil
    expect(res.length).to be(4)
    expect(res.all?(&:valid?)).to be_truthy
    expect(res[0].title).to eql("Star City")
    expect(res[1].title).to eql("Space Exploration")
    expect(res[2].title).to eql("The Engine That Does More")
    expect(res[3].title).to eql("Astronauts' Dirty Laundry")
  end

  it "rss feed should be active for active accounts" do
    @feed = external_feed_model
    course_with_student(course: @course, external_feeds: [@feed]).update!(workflow_state: :active)
    @feed.context = @course
    expect(@feed.inactive?).to be(false)
  end

  it "rss feed should be inactive for deleted accounts" do
    @feed = external_feed_model
    account1 = account_model
    course_with_student(account: account1, course: @course).update!(workflow_state: :active)
    Account.default.update!(workflow_state: :deleted)
    expect(@feed.inactive?).to be(true)
  end

  it "rss feed should be active for concluded courses" do
    account1 = account_model
    course_with_student(account: account1, course: @course).update!(workflow_state: :active)
    @feed = external_feed_model(context: @course)
    expect(@feed.inactive?).to be(false)
  end

  it "rss feed should be inactive for concluded courses" do
    account1 = account_model
    course_with_student(account: account1, course: @course)
    @feed = external_feed_model(context: @course)
    @course.complete!
    expect(@feed.inactive?).to be(true)
  end

  it "rss feed should be inactive for deleted courses" do
    account1 = account_model
    course_with_student(account: account1, course: @course)
    @feed = external_feed_model(context: @course)
    @course.destroy!
    expect(@feed.inactive?).to be(true)
  end

  it "rss feed should be active for groups with active courses" do
    account1 = account_model
    course_with_student(account: account1, course: @course).update!(workflow_state: :active)
    @feed = external_feed_model
    @group = group_model(is_public: true, context: @course)
    @feed.update!(context: @group)
    expect(@feed.inactive?).to be(false)
  end

  it "rss feed should be inactive for groups with active courses" do
    account1 = account_model
    course_with_student(account: account1, course: @course)
    @feed = external_feed_model
    @group = group_model(is_public: true, context: @course)
    @feed.update!(context: @group)
    @course.complete!
    expect(@feed.inactive?).to be(true)
  end

  it "rss feed should be inactive for groups with deleted courses" do
    account1 = account_model
    course_with_student(account: account1, course: @course)
    @feed = external_feed_model
    group_model(is_public: true, context: @course)
    @feed.update!(context: @group)
    @course.destroy!
    expect(@feed.inactive?).to be(true)
  end

  it "adds rss entries as course announcements" do
    @course = course_model
    @feed = external_feed_model(context: @course)
    require "rss/1.0"
    require "rss/2.0"
    rss = RSS::Parser.parse rss_example
    res = @feed.add_rss_entries(rss)
    expect(res).not_to be_nil
    expect(res.length).to be(4)
    expect(@course.announcements.count).to be(4)
    expect(res.map(&:asset) - @course.announcements).to be_empty

    # don't create duplicates
    @feed.add_rss_entries(rss)
    expect(@course.announcements.count).to be(4)
  end

  it "adds atom entries" do
    @feed = external_feed_model
    require "feedjira"
    atom = Feedjira.parse atom_example
    res = @feed.add_atom_entries(atom)
    expect(res).not_to be_nil
    expect(res.length).to be(1)
    expect(res[0].valid?).to be_truthy
    expect(res[0].title).to eql("Atom-Powered Robots Run Amok")
  end

  it "adds atom entries as course announcements" do
    @course = course_model
    @feed = external_feed_model(context: @course)
    require "feedjira"
    atom = Feedjira.parse atom_example
    res = @feed.add_atom_entries(atom)
    expect(res).not_to be_nil
    expect(res.length).to be(1)
    expect(res[0].title).to eql("Atom-Powered Robots Run Amok")
    expect(@course.announcements.count).to be(1)
    expect(res[0].asset).to eql(@course.announcements.first)
  end

  it "allows deleting" do
    @course = course_model
    @feed = external_feed_model(context: @course)
    require "rss/1.0"
    require "rss/2.0"
    rss = RSS::Parser.parse rss_example
    @feed.add_rss_entries(rss)

    @feed.destroy
    @course.reload

    expect(@course.external_feeds.exists?).to be_falsey
    expect(@course.announcements.count).to eq(4)
  end
end

def atom_example
  <<~XML
    <?xml version="1.0" encoding="utf-8"?>
    <feed xmlns="http://www.w3.org/2005/Atom">

     <title>Example Feed</title>
     <subtitle>A subtitle.</subtitle>
     <link href="http://example.org/feed/" rel="self"/>
     <link href="http://example.org/"/>
     <updated>2003-12-13T18:30:02Z</updated>
     <author>
       <name>John Doe</name>
       <email>johndoe@example.com</email>
     </author>
     <id>urn:uuid:60a76c80-d399-11d9-b91C-0003939e0af6</id>

     <entry>
       <title>Atom-Powered Robots Run Amok</title>
       <link href="http://example.org/2003/12/13/atom03"/>
       <id>urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a</id>
       <updated>2003-12-13T18:30:02Z</updated>
       <summary>Some text.</summary>
     </entry>

    </feed>
  XML
end

def rss_example
  <<~XML
    <?xml version="1.0"?>
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

        <item>
          <title>Space Exploration</title>
          <link>http://liftoff.msfc.nasa.gov/</link>
          <description>Sky watchers in Europe, Asia, and parts of Alaska and Canada
            will experience a partial eclipse of the Sun on Saturday, May 31.</description>
          <pubDate>Fri, 30 May 2003 11:06:42 GMT</pubDate>
          <guid>http://liftoff.msfc.nasa.gov/2003/05/30.html#item572</guid>
        </item>

        <item>
          <title>The Engine That Does More</title>
          <link>http://liftoff.msfc.nasa.gov/news/2003/news-VASIMR.asp</link>
          <description>Before man travels to Mars, NASA hopes to design new engines
            that will let us fly through the Solar System more quickly.  The proposed
            VASIMR engine would do that.</description>
          <pubDate>Tue, 27 May 2003 08:37:32 GMT</pubDate>
          <guid>http://liftoff.msfc.nasa.gov/2003/05/27.html#item571</guid>
        </item>

        <item>
          <title>Astronauts' Dirty Laundry</title>
          <link>http://liftoff.msfc.nasa.gov/news/2003/news-laundry.asp</link>
          <description>Compared to earlier spacecraft, the International Space
            Station has many luxuries, but laundry facilities are not one of them.
            Instead, astronauts have other options.</description>
          <pubDate>Tue, 20 May 2003 08:56:02 GMT</pubDate>
          <guid>http://liftoff.msfc.nasa.gov/2003/05/20.html#item570</guid>
        </item>
      </channel>
    </rss>
  XML
end
