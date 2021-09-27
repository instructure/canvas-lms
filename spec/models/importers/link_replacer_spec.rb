# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '../../../import_helper')

describe "Importers::LinkReplacer" do
  describe "#rewrite_item_version!" do
    it "takes a fresh snapshot of the model" do
      course = course_model
      p = course.wiki_pages.create(title: "some page", body: "asdf")
      version = p.current_version
      expect(version.yaml).to include("asdf")
      WikiPage.where(id: p.id).update_all(body: "fdsa")
      replacer = Importers::LinkReplacer.new(ContentMigration.new)
      replacer.rewrite_item_version!(p.reload)
      expect(version.reload.yaml).to_not include("asdf")
      expect(version.reload.yaml).to include("fdsa")
    end
  end
end