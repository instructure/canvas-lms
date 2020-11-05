# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../lti2_spec_helper')
require 'spec_helper'

describe DataFixup::AddToolProxyToMessageHandler do
  include_context 'lti2_spec_helper'

  it "sets message handlers' 'tool_proxy' to the resource handler tool proxy" do
    message_handler.update_attribute(:tool_proxy, nil)
    DataFixup::AddToolProxyToMessageHandler.run
    expect(Lti::MessageHandler.last.tool_proxy).to eq tool_proxy
  end
end
