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

describe "/conference/index" do
  before do
    # these specs need an enabled web conference plugin
    @plugin = PluginSetting.create!(name: 'wimba')
    @plugin.update_attribute(:settings, { :domain => 'www.example.com' })
  end

  it "should render" do
    course_with_teacher(:active_all => true)
    view_context(@course, @user)
    @conference = @course.web_conferences.build(:conference_type => "Wimba")
    @conference.user = @user
    @conference.save!
    @conference.add_initiator(@user)
    assign(:conferences, [@conference])
    assign(:users, @course.users)
    render "conferences/index"
    expect(response).to have_tag("#new-conference-list")
  end
end

