# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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
require "json"

describe CanvasLinkMigrator::LinkResolver do
  def course_based_converter(assets = JSON.parse(File.read("spec/fixtures/canvas_resource_map.json")))
    CanvasLinkMigrator::LinkResolver.new(CanvasLinkMigrator::ResourceMapService.new(assets))
  end

  describe "resolve_link!" do
    it "converts wiki_pages links" do
      link = { link_type: :wiki_page, migration_id: "A", query: "?foo=bar" }
      course_based_converter.resolve_link!(link)
      expect(link[:new_value]).to eq("/courses/1/pages/slug-a?foo=bar")
    end

    it "converts module_item links" do
      link = { link_type: :module_item, migration_id: "C", query: "?foo=bar" }
      course_based_converter.resolve_link!(link)
      expect(link[:new_value]).to eq("/courses/1/modules/items/3?foo=bar")
    end

    it "converts file_ref urls" do
      link = { link_type: :file_ref, migration_id: "F" }
      course_based_converter.resolve_link!(link)
      expect(link[:new_value]).to eq("/courses/1/files/6/preview")
    end

    it "converts attachment urls" do
      link = { link_type: :object, type: "attachments", migration_id: "E", query: "?foo=bar" }
      course_based_converter.resolve_link!(link)
      expect(link[:new_value]).to eq("/courses/1/files/5/preview")
    end

    it "converts media_attachments_iframe urls" do
      link = { link_type: :object, type: "media_attachments_iframe", migration_id: "F", query: "?foo=bar" }
      course_based_converter.resolve_link!(link)
      expect(link[:new_value]).to eq("/media_attachments_iframe/6?foo=bar")
    end

    it "converts discussion_topic links" do
      link = { link_type: :discussion_topic, migration_id: "G", query: "?foo=bar" }
      course_based_converter.resolve_link!(link)
      expect(link[:new_value]).to eq("/courses/1/discussion_topics/7?foo=bar")
    end
  end
end
