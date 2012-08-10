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

describe ProfileController do
  it "should respect account setting for editing names" do
    a = Account.create!
    u = user_with_pseudonym(:account => a, :active_user => true)
    u.short_name = 'Bracken'
    u.save!
    user_session(u, u.pseudonyms.first)

    get '/profile/settings'
    Nokogiri::HTML(response.body).css('input#user_short_name').should_not be_empty

    put '/profile', :user => { :short_name => 'Cody' }
    response.should be_redirect
    u.reload.short_name.should == 'Cody'

    a.settings[:users_can_edit_name] = false
    a.save!
    get '/profile/settings'
    Nokogiri::HTML(response.body).css('input#user_short_name').should be_empty

    put '/profile', :user => { :short_name => 'JT' }
    response.should be_redirect
    u.reload.short_name.should == 'Cody'
  end

  it "should not show student view student edit profile or other services options" do
    course_with_teacher_logged_in(:active_all => true)
    enter_student_view

    get '/profile/settings'
    assert_unauthorized
  end
end
