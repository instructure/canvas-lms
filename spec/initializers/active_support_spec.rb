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

require_relative "../sharding_spec_helper"

describe 'ActiveSupport::JSON' do
  it "encodes hash keys correctly" do
    expect(ActiveSupport::JSON.encode("<>" => "<>").downcase).to eq "{\"\\u003c\\u003e\":\"\\u003c\\u003e\"}"
  end
end

describe ActiveSupport::TimeZone do
  it 'gives a simple JSON interpretation' do
    expect(ActiveSupport::TimeZone['America/Denver'].to_json).to eq "America/Denver".to_json
  end
end

describe "enumerable pluck extension" do
  specs_require_sharding

  it "should transform ids" do
    u = User.create!
    @shard1.activate do
      expect([u].pluck(:id)).to eq [u.global_id]
    end
  end
end
