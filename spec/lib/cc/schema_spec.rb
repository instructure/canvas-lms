# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

module CC
  describe Schema do
    describe ".for_version" do
      it "will not tolerate names of files not in the folder at all" do
        filename = Schema.for_version("../../../spec/fixtures/test")
        expect(filename).to be_falsey
      end

      it "returns the full filepath for valid file names" do
        expect(Schema.for_version("cccv1p0").to_s).to match(%r{lib/cc/xsd/cccv1p0\.xsd})
      end
    end
  end
end
