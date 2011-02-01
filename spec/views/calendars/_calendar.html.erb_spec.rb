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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "/calendars/_calendar" do
  it "should render" do
    course_with_student
    view_context(@course, @user)
    assigns[:contexts] = [@course]
    assigns[:first_day] = Date.today
    assigns[:last_day] = Date.today + 30
    assigns[:current] = Date.today + 2
    assigns[:events] = [@course.calendar_events.create!(:title => "some event", :start_at => Time.now)]
    assigns[:assignment_groups_for] = {}
    render :partial => 'calendars/calendar', :object => assigns[:events], :locals => {:current => Date.today, :first_day => Date.today - 3, :last_day => Date.today + 30, :request => OpenObject.new(:path_parameters => {:controller => 'calendars', :action => 'show'}, :query_parameters => {})}
  end
end

