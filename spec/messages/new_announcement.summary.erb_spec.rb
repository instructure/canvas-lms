#
# Copyright (C) 2013 Instructure, Inc.
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

describe 'new_announcement.summary' do
  it "should render" do
    announcement_model
    @object = @a
    @message = generate_message(:new_announcement, :summary, @object)
    expect(@message.subject).to eq "value for title: value for name"
    expect(@message.url).to match(/\/courses\/\d+\/announcements\/\d+/)
    expect(@message.body.strip).to eq "value for message"
  end
end
