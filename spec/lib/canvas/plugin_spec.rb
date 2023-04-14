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

describe Canvas::Plugin do
  describe ".value_to_boolean" do
    it "accepts 0/1 as strings" do
      expect(Canvas::Plugin.value_to_boolean("0")).to be false
      expect(Canvas::Plugin.value_to_boolean("1")).to be true
    end

    it "accepts t/f" do
      expect(Canvas::Plugin.value_to_boolean("f")).to be false
      expect(Canvas::Plugin.value_to_boolean("t")).to be true
    end

    it "accepts nil" do
      expect(Canvas::Plugin.value_to_boolean(nil)).to be false
    end

    it "does not accept unrecognized arguments" do
      file = Tempfile.new("hello world")
      hash = { tempfile: file }
      value = ActionDispatch::Http::UploadedFile.new(hash)
      expect(Canvas::Plugin.value_to_boolean(value)).to be_nil
    end
  end
end
