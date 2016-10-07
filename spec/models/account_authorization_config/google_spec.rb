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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe AccountAuthorizationConfig::Google do
  it 'rejects non-matching hd' do
    ap = AccountAuthorizationConfig::Google.new
    ap.hosted_domain = 'instructure.com'
    Canvas::Security.expects(:decode_jwt).returns({'hd' => 'school.edu', 'sub' => '123'})
    token = stub('token', params: {}, options: {})

    expect { ap.unique_id(token) }.to raise_error
  end

  it 'rejects missing hd' do
    ap = AccountAuthorizationConfig::Google.new
    ap.hosted_domain = 'instructure.com'
    Canvas::Security.expects(:decode_jwt).returns({'sub' => '123'})
    token = stub('token', params: {}, options: {})

    expect { ap.unique_id(token) }.to raise_error
  end

  it "accepts when hosted domain isn't required" do
    ap = AccountAuthorizationConfig::Google.new
    Canvas::Security.expects(:decode_jwt).once.returns({'sub' => '123'})
    token = stub('token', params: {}, options: {})

    expect(ap.unique_id(token)).to eq '123'
  end
end
