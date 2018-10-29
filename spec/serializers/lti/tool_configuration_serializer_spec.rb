#
# Copyright (C) 2018 - present Instructure, Inc.
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

require 'spec_helper'
require File.expand_path(File.dirname(__FILE__) + '/../../lti_1_3_spec_helper')

RSpec.describe Lti::ToolConfigurationSerializer do
  include_context 'lti_1_3_spec_helper'

  let_once(:account) { Account.default }

  subject { Lti::ToolConfigurationSerializer.new(tool_configuration).as_json }

  it { is_expected.to have_key 'tool_configuration' }

  it { is_expected.to have_key 'developer_key' }
end
