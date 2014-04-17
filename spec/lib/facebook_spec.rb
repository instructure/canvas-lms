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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe Facebook do
  let(:facebook_user) { user }
  let(:facebook_service) {
    UserService.create!(user: facebook_user, token: 'secret_token',
      service: 'facebook', service_user_url: 'https://facebook.com/don.draper',
      service_user_id: '12345', service_user_name: 'Don Draper')
  }

  it 'should increment the app counter' do
    Facebook.
      expects(:send_graph_request).
      with('12345/apprequests', :post, facebook_service.token,
        message: 'some message').
      returns(true)
    Facebook.dashboard_increment_count(facebook_service.service_user_id, facebook_service.token, 'some message')
  end
end
