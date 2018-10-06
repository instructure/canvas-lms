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
#

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')
require_dependency 'lti/tool_configuration'

module Lti
  describe ToolConfiguration do
    let(:tool_configuration) { Lti::ToolConfiguration.new }
    let_once(:developer_key) { DeveloperKey.create }

    describe 'validations' do
      subject { tool_configuration.valid? }

      context 'when "settings" is blank' do
        before { tool_configuration.developer_key = developer_key }

        it { is_expected.to eq false }
      end

      context 'when "developer_key_id" is blank' do
        before { tool_configuration.settings = {foo: 'bar'} }

        it { is_expected.to eq false }
      end
    end
  end
end
