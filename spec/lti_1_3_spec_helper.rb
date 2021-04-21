# frozen_string_literal: true

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

require File.expand_path(File.dirname(__FILE__) + '/spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/lti_1_3_tool_configuration_spec_helper.rb')

RSpec.shared_context "lti_1_3_spec_helper", shared_context: :metadata do
  include_context 'lti_1_3_tool_configuration_spec_helper'

  let(:fallback_proxy) do
    Canvas::DynamicSettings::FallbackProxy.new({
      Canvas::Security::KeyStorage::PAST => Canvas::Security::KeyStorage.new_key,
      Canvas::Security::KeyStorage::PRESENT => Canvas::Security::KeyStorage.new_key,
      Canvas::Security::KeyStorage::FUTURE => Canvas::Security::KeyStorage.new_key
    })
  end

  let(:developer_key) { DeveloperKey.create!(account: account) }

  before do
    allow(Canvas::DynamicSettings).to receive(:kv_proxy).and_return(fallback_proxy)
  end
end
