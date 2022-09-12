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
#

describe Lti::ScopeUnion do
  describe "exists?" do
    it "returns true if exists? is true in any scope" do
      course_model
      s1 = Course.where(id: -1)
      s2 = Course.where(id: @course.id)
      s3 = Course.where(id: -2)
      expect(described_class.new([s1, s2, s3]).exists?).to eq(true)
      expect(described_class.new([s1, s3]).exists?).to eq(false)
    end
  end
end
