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

require File.expand_path(File.dirname(__FILE__) + '/common')

require 'nokogiri'

describe "user_content" do
  include_context "in-process server selenium tests"

  context "as a student" do
    let(:message_body) do
      <<-MESSAGE
<p>flash:</p>
<p><object width="425" height="350" data="/javascripts/swfobject/test.swf" type="application/x-shockwave-flash"><param name="wmode" value="transparent" /><param name="src" value="/javascripts/swfobject/test.swf" /></object></p>
      MESSAGE
    end

    before (:each) do
      course_with_student_logged_in(:active_all => true)
      allow(HostUrl).to receive(:is_file_host?).and_return(true)
    end

    describe "iframes" do
      it "should serve embed tags from a safefiles iframe" do
        skip_if_chrome('research')
        factory_with_protected_attributes(Announcement, :context => @course, :title => "hey all read this k", :message => message_body)
        get "/courses/#{@course.to_param}/discussion_topics/#{Announcement.first.to_param}"
        name = ff(".user_content_iframe").first.attribute('name')
        in_frame(name) do
          expect(f('object')).to have_attribute("data", '/javascripts/swfobject/test.swf')
        end
      end

      it "should iframe calendar json requests" do
        skip_if_chrome('research')
        factory_with_protected_attributes(CalendarEvent, :context => @course, :title => "super fun party", :description => message_body, :start_at => 5.minutes.ago, :end_at => 5.minutes.from_now)
        get "/calendar2"

        expect(f("body")).not_to contain_css(".user_content_iframe")
        f('.fc-event').click
        name = f(".user_content_iframe").attribute('name')
        in_frame(name) do
          expect(f('object')).to have_attribute("data", '/javascripts/swfobject/test.swf')
        end
      end
    end
  end
end
