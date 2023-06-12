# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

describe "request throttling" do
  describe "usage of the middleware in the Canvas middleware stack" do
    it "comes below the middleware which populates the canvas domain root account" do
      acct = nil
      expect_any_instance_of(RequestThrottle).to receive(:client_identifiers) do |_subject, req|
        # for some reason "expect"s in here don't fail the spec -- presumably the error is
        # rescued above in the stack. So, assign acct and test it later
        acct = req.env["canvas.domain_root_account"]
      end
      get "/"
      expect(acct).to be_a(Account)
    end
  end
end
