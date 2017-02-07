#
# Copyright (C) 2014 Instructure, Inc.
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
require_dependency "lti/resource_handler"

module Lti
  describe ResourceHandler do

    describe 'validations' do
      before(:each) do
        subject.resource_type_code = 'code'
        subject.name = 'name'
        subject.tool_proxy = ToolProxy.new

      end

      it 'requires the name' do
        subject.name = nil
        subject.save
        expect(subject.errors.first).to eq [:name, "can't be blank"]
      end

      it 'requires a tool proxy' do
        subject.tool_proxy = nil
        subject.save
        expect(subject.errors.first).to eq [:tool_proxy, "can't be blank"]
      end

    end

  end
end
