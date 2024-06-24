# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe CustomDataController do
  describe "#set_data" do
    it "works" do
      user = user_with_pseudonym(active_all: true)
      user_session(user)
      post :set_data, params: { ns: "myapp", scope: "scope", data: { key: "foo", value: "bar" }, user_id: user.id }
      expect(response).to be_successful
      cd = user.custom_data.take
      expect(cd).not_to be_nil
      expect(cd.namespace).to eql "myapp"
      expect(cd.get_data("scope")).to eql({ "key" => "foo", "value" => "bar" })
    end
  end
end
