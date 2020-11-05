# frozen_string_literal: true

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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe "RequestContextSession" do
  it "should find the session_id from the rack session and add it a cookie" do
    env = { 'rack.session.options' => { id: 'abc' } }
    _, headers, _ = RequestContextSession.new(->(env) {
      [200, {}, []]
    }).call(env)
    expect(env['action_dispatch.cookies']['log_session_id']).to eq 'abc'
  end
end
