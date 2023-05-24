# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require_relative "../../import_helper"

describe Importers::ExternalFeedImporter do
  context ".import_from_migration" do
    it "creates a feed from the provided hash" do
      @course = course_factory
      migration = @course.content_migrations.create!
      data = {
        url: "http://www.example.com/feed",
        title: "test feed",
        verbosity: "link_only",
        header_match: ""
      }
      feed = Importers::ExternalFeedImporter.import_from_migration(data, @course, migration)
      expect(feed.url).to eq data[:url]
      expect(feed.title).to eq data[:title]
      expect(feed.verbosity).to eq data[:verbosity]
      expect(feed.header_match).to be_nil
    end
  end

  context ".find_or_initialize_from_migration" do
    before(:once) do
      @course = course_factory
      @feed = external_feed_model(migration_id: "12345")
    end

    it "finds a feed by migration id" do
      found = Importers::ExternalFeedImporter.find_or_initialize_from_migration({
                                                                                  migration_id: "12345"
                                                                                },
                                                                                @course)
      expect(found.id).to eq @feed.id
    end

    it "finds by uniq attrs" do
      found = Importers::ExternalFeedImporter.find_or_initialize_from_migration({
                                                                                  migration_id: "xyzyx",
                                                                                  url: @feed.url,
                                                                                  header_match: @feed.header_match,
                                                                                  verbosity: @feed.verbosity
                                                                                },
                                                                                @course)
      expect(found.id).to eq @feed.id
    end

    it "initializes if none found" do
      found = Importers::ExternalFeedImporter.find_or_initialize_from_migration({
                                                                                  migration_id: "xyzyx",
                                                                                  url: @feed.url + "xxx",
                                                                                  header_match: @feed.header_match,
                                                                                  verbosity: @feed.verbosity
                                                                                },
                                                                                @course)
      expect(found).to be_new_record
    end
  end
end
