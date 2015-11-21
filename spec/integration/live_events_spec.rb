#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper')

describe LiveEvents do
  before :once do
    user_with_pseudonym(:username => 'jtfrd@instructure.com', :active_all => 1, :password => 'qwerty')
  end

  it "should trigger a live event on login" do
    Canvas::LiveEvents.expects(:logged_in).once
    post '/login', { :pseudonym_session => { :unique_id => 'jtfrd@instructure.com', :password => 'qwerty' } }
    expect(response).to be_redirect
  end
end
