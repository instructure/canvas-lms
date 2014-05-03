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
require File.expand_path(File.dirname(__FILE__) + '/messages_helper')

describe 'web_conference_invitation.sms' do
  before do
    # these specs need an enabled web conference plugin
    @plugin = PluginSetting.find_or_create_by_name('wimba')
    @plugin.update_attribute(:settings, { :domain => 'www.example.com' })
  end

  it "should render" do
    course_model(:reusable => true)
    @object = @course.web_conferences.create!(:conference_type => 'Wimba', :user => user)
    generate_message(:web_conference_invitation, :sms, @object)
  end
end
