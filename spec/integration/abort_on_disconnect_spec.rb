# frozen_string_literal: true

# Copyright (C) 2021 - present Instructure, Inc.
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

describe AbortOnDisconnect do
  it "returns 408 when aborting in a middleware" do
    allow_any_instance_of(RequestThrottle).to receive(:call).and_raise(AbortOnDisconnect::DisconnectedError)

    get '/'
    expect(response.status).to eq 408
    expect(response.body).to be_empty
  end

  it "returns 408 when aborting in an action" do
    expect_any_instance_of(Login::CanvasController).to receive(:new).and_raise(AbortOnDisconnect::DisconnectedError)

    get '/login/canvas'
    expect(response.status).to eq 408
    expect(response.body).to be_empty
  end
end
