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

describe ExternalFeed do
  it "should add ical entries" do
    @feed = external_feed_model(:feed_purpose => 'calendar')
    require 'icalendar'
    cals = Icalendar.parse ical_example
    expect(cals[0].events.first.summary).to eql("Bastille Day Party")
    res = @feed.add_ical_entries(cals[0])
    expect(res).not_to be_nil
    expect(res.length).to eql(1)
    expect(res[0].title).to eql("Bastille Day Party")
  end
  
  it "should add ical entries to a course" do
    @course = course_model
    @feed = external_feed_model(:feed_purpose => 'calendar', :context => @course)
    require 'icalendar'
    cals = Icalendar.parse ical_example
    expect(cals[0].events.first.summary).to eql("Bastille Day Party")
    res = @feed.add_ical_entries(cals[0])
    expect(res).not_to be_nil
    expect(res.length).to eql(1)
    expect(res[0].title).to eql("Bastille Day Party")
    @course.reload
    expect(@course.calendar_events.length).to eql(1)
    expect(@course.calendar_events[0]).to eql(res[0].asset)
  end
  
  it "should add rss entries" do
    @feed = external_feed_model(:feed_purpose => 'announcements')
    require 'rss/1.0'
    require 'rss/2.0'
    rss = RSS::Parser.parse rss_example
    res = @feed.add_rss_entries(rss)
    expect(res).not_to be_nil
    expect(res.length).to eql(4)
    expect(res[0].title).to eql("Star City")
    expect(res[1].title).to eql("Space Exploration")
    expect(res[2].title).to eql("The Engine That Does More")
    expect(res[3].title).to eql("Astronauts' Dirty Laundry")
  end
  
  
  it "should add rss entries as course announcements" do
    @course = course_model
    @feed = external_feed_model(:feed_purpose => 'announcements', :context => @course)
    require 'rss/1.0'
    require 'rss/2.0'
    rss = RSS::Parser.parse rss_example
    res = @feed.add_rss_entries(rss)
    expect(res).not_to be_nil
    expect(res.length).to eql(4)
    expect(@course.announcements.length).to eql(4)
    expect(res.map{|i| i.asset} - @course.announcements).to be_empty
  end
  
  it "should add atom entries" do
    @feed = external_feed_model(:feed_purpose => 'announcements')
    require 'atom'
    atom = Atom::Feed.load_feed atom_example
    res = @feed.add_atom_entries(atom)
    expect(res).not_to be_nil
    expect(res.length).to eql(1)
    expect(res[0].title).to eql("Atom-Powered Robots Run Amok")
  end
  
  it "should add atom entries as course announcements" do
    @course = course_model
    @feed = external_feed_model(:feed_purpose => 'announcements', :context => @course)
    require 'atom'
    atom = Atom::Feed.load_feed atom_example
    res = @feed.add_atom_entries(atom)
    expect(res).not_to be_nil
    expect(res.length).to eql(1)
    expect(res[0].title).to eql("Atom-Powered Robots Run Amok")
    expect(@course.announcements.length).to eql(1)
    expect(res[0].asset).to eql(@course.announcements.first)
  end
  
end

def ical_example
%{BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//hacksw/handcal//NONSGML v1.0//EN
BEGIN:VEVENT
DTSTART:19970714T170000Z
DTEND:19970715T035959Z
SUMMARY:Bastille Day Party
END:VEVENT
END:VCALENDAR}
end

def atom_example
%{<?xml version="1.0" encoding="utf-8"?>
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
 
</feed>}
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
</rss>}
end
