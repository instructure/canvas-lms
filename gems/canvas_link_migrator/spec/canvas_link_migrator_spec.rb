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
#

require "spec_helper"

describe CanvasLinkMigrator do
  describe ".relative_url?" do
    it "recognizes an absolute url" do
      expect(CanvasLinkMigrator.relative_url?("http://example.com")).to be false
    end

    it "recognizes relative urls" do
      expect(CanvasLinkMigrator.relative_url?("/relative/eh")).to be true
      expect(CanvasLinkMigrator.relative_url?("also/relative")).to be true
      expect(CanvasLinkMigrator.relative_url?("watup/nothing.html#anchoritbaby")).to be true
      expect(CanvasLinkMigrator.relative_url?("watup/nothing?absolutely=1")).to be true
    end

    it "does not error on invalid urls" do
      expect(CanvasLinkMigrator.relative_url?("stupid &^%$ url")).to be_falsey
      expect(CanvasLinkMigrator.relative_url?("mailto:jfarnsworth@instructure.com,")).to be_falsey
    end
  end
end
