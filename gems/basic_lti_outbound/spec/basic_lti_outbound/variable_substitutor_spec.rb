#
# Copyright (C) 2011 Instructure, Inc.
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

require "spec_helper"

describe BasicLtiOutbound::VariableSubstitutor do
  let(:account) {
    BasicLtiOutbound::LTIAccount.new.tap do |account|
      account.domain = 'my.domain'
    end
  }

  it "substitutes variable" do
    params = {'domain' => '$Canvas.api.domain'}
    subject.substitute!(params, '$Canvas.api', account)
    expect(params).to eq({'domain' => 'my.domain'})
  end

  it "does not replace invalid mappings" do
    params = {'domain' => '$Canvas.api.wrong'}
    subject.substitute!(params, '$Canvas.api', account)
    expect(params).to eq({'domain' => '$Canvas.api.wrong'})
  end

  it "does not replace nil mappings" do
    account.domain = nil
    params = {'domain' => '$Canvas.api.domain'}
    subject.substitute!(params, '$Canvas.api', account)
    expect(params).to eq({'domain' => '$Canvas.api.domain'})
  end
end