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

describe LiveEventsObserver do
  it "should post an event when a course syllabus changes" do
    c = course
    c.syllabus_body = "old syllabus"
    c.save!

    Canvas::LiveEvents.expects(:course_syllabus_updated).never
    c.save!

    c.syllabus_body = "new syllabus"
    Canvas::LiveEvents.expects(:course_syllabus_updated).with(c, "old syllabus")
    c.save
  end

  it "should post an event when a wiki page body or title changes" do
    c = course
    p = c.wiki.wiki_pages.create(:title => 'old title', :body => 'old body')

    Canvas::LiveEvents.expects(:wiki_page_updated).never
    p.touch

    Canvas::LiveEvents.expects(:wiki_page_updated).with(p, 'old title', nil)
    p.title = 'new title'
    p.save

    Canvas::LiveEvents.expects(:wiki_page_updated).with(p, nil, 'old body')
    p.body = 'new body'
    p.save
  end

  it "should post an event when a discussion topic is created" do
    c = course

    Canvas::LiveEvents.expects(:discussion_topic_created).once
    c.discussion_topics.create!(:message => 'test')
  end
end

