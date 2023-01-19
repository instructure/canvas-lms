# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

module Lti
  describe ToolProxyBinding do
    let(:account) { Account.new }
    let(:tool_proxy) { ToolProxy.new }

    describe "validations" do
      before do
        subject.context = account
        subject.tool_proxy = tool_proxy
      end

      it "requires a context" do
        subject.context = nil
        subject.save
        expect(subject.errors.first).to eq [:context, "can't be blank"]
      end

      it "requires a tool_proxy" do
        subject.tool_proxy = nil
        subject.save
        expect(subject.errors.first).to eq [:tool_proxy, "can't be blank"]
      end
    end
  end
end
