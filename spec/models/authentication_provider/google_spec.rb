#
# Copyright (C) 2015 - present Instructure, Inc.
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

describe AuthenticationProvider::Google do
  it 'rejects non-matching hd' do
    ap = AuthenticationProvider::Google.new
    ap.hosted_domain = 'instructure.com'
    expect(Canvas::Security).to receive(:decode_jwt).and_return({'hd' => 'school.edu', 'sub' => '123'})
    userinfo = double('userinfo', parsed: {})
    token = double('token', params: {}, options: {}, get: userinfo)

    expect { ap.unique_id(token) }.to raise_error('User is from unacceptable domain "school.edu".')
  end

  it 'allows hd from list' do
    ap = AuthenticationProvider::Google.new
    ap.hosted_domain = 'canvaslms.com, instructure.com'
    expect(Canvas::Security).to receive(:decode_jwt).and_return({'hd' => 'instructure.com', 'sub' => '123'})
    userinfo = double('userinfo', parsed: {})
    token = double('token', params: {}, options: {}, get: userinfo)

    expect(ap.unique_id(token)).to eq '123'
  end

  it 'rejects missing hd' do
    ap = AuthenticationProvider::Google.new
    ap.hosted_domain = 'instructure.com'
    expect(Canvas::Security).to receive(:decode_jwt).and_return({'sub' => '123'})
    token = double('token', params: {}, options: {})

    expect { ap.unique_id(token) }.to raise_error('Google Apps user not received, but required')
  end

  it 'rejects missing hd for *' do
    ap = AuthenticationProvider::Google.new
    ap.hosted_domain = '*'
    expect(Canvas::Security).to receive(:decode_jwt).and_return({'sub' => '123'})
    token = double('token', params: {}, options: {})


    expect { ap.unique_id(token) }.to raise_error('Google Apps user not received, but required')
  end

  it "accepts any hd for '*'" do
    ap = AuthenticationProvider::Google.new
    ap.hosted_domain = '*'
    expect(Canvas::Security).to receive(:decode_jwt).once.and_return({'hd' => 'instructure.com', 'sub' => '123'})
    token = double('token', params: {}, options: {})
    expect(token).to receive(:get).and_return(double(parsed: {}))

    expect(ap.unique_id(token)).to eq '123'
  end

  it "accepts when hosted domain isn't required" do
    ap = AuthenticationProvider::Google.new
    expect(Canvas::Security).to receive(:decode_jwt).once.and_return({'sub' => '123'})
    token = double('token', params: {}, options: {})

    expect(ap.unique_id(token)).to eq '123'
  end

  it "it sets hosted domain to nil if empty string" do
    ap = AuthenticationProvider::Google.new
    ap.hosted_domain = ''
    expect(ap.hosted_domain).to be_nil
  end

  it "requests * from google when configured for a list of domains" do
    ap = AuthenticationProvider::Google.new
    ap.hosted_domain = 'canvaslms.com, instructure.com'
    expect(ap.send(:authorize_options)[:hd]).to eq '*'
  end
end
