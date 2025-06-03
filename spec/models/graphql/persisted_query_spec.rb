# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module GraphQL
  describe PersistedQuery do
    describe "::known_queries" do
      it "has queries with boolean field anonymous_access_allowed and string field query" do
        described_class.known_queries.each_value do |query|
          expect(query["anonymous_access_allowed"]).to be_in([true, false])
          expect(query["query"]).to be_a String
        end
      end
    end
  end
end
