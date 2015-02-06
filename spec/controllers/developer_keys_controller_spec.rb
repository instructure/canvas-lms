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

describe DeveloperKeysController do
  before :once do
    account_admin_user(:account => Account.site_admin)
  end
  
  describe "GET 'index'" do
    it 'should require authorization' do
      get 'index'
      expect(response).to be_redirect
    end
    
    it 'should return the list of developer keys' do
      user_session(@admin)
      get 'index'
      expect(response).to be_success
    end
  end
  
end
