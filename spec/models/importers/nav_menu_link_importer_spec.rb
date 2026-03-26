# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

describe Importers::NavMenuLinkImporter do
  describe ".import_from_migration" do
    before :once do
      course_with_teacher
      @import_all_migration = @course.content_migrations.create!(
        migration_settings: { migration_ids_to_import: { copy: { everything: "1" } } }
      )
    end

    it "creates a new link with correct attributes" do
      hash = { "migration_id" => "ifm_link_1", "label" => "My Link", "url" => "https://example.com" }.with_indifferent_access
      existing_links = {}

      expect do
        Importers::NavMenuLinkImporter.import_from_migration(hash, @course, @import_all_migration, existing_links)
      end.to change { NavMenuLink.where(course: @course).count }.by(1)

      link = NavMenuLink.find_by(migration_id: "ifm_link_1")
      expect(link.migration_id).to eq "ifm_link_1"
      expect(link.label).to eq "My Link"
      expect(link.url).to eq "https://example.com"
      expect(link.course_nav).to be true
      expect(link.course).to eq @course
    end

    it "strips whitespace from url and label" do
      hash = { "migration_id" => "ifm_link_2", "label" => "  My Link  ", "url" => "  https://example.com  " }.with_indifferent_access
      existing_links = {}

      Importers::NavMenuLinkImporter.import_from_migration(hash, @course, @import_all_migration, existing_links)

      link = NavMenuLink.find_by(migration_id: "ifm_link_2")
      expect(link.label).to eq "My Link"
      expect(link.url).to eq "https://example.com"
    end

    it "converts nil values to empty strings and handles validation" do
      hash = { "migration_id" => "ifm_link_nil", "label" => nil, "url" => nil }.with_indifferent_access
      existing_links = {}

      # nil becomes "" after .to_s.strip, which fails presence validation
      expect do
        Importers::NavMenuLinkImporter.import_from_migration(hash, @course, @import_all_migration, existing_links)
      end.to raise_error(ActiveRecord::RecordInvalid)

      expect(NavMenuLink.find_by(migration_id: "ifm_link_nil")).to be_nil
    end

    it "does not create when existing link is found but still adds to imported items" do
      existing = NavMenuLink.create!(
        course: @course,
        course_nav: true,
        migration_id: "ifm_existing_1",
        label: "Old Label",
        url: "https://old.com"
      )
      hash = { "migration_id" => "ifm_existing_1", "label" => "New Label", "url" => "https://new.com" }.with_indifferent_access
      existing_links = { "ifm_existing_1" => existing }

      expect(@import_all_migration).to receive(:add_imported_item).with(existing)

      Importers::NavMenuLinkImporter.import_from_migration(hash, @course, @import_all_migration, existing_links)

      expect(NavMenuLink.where(course: @course).count).to eq 1
      existing.reload
      expect(existing.label).to eq "Old Label"
      expect(existing.url).to eq "https://old.com"
    end
  end

  describe ".process_migration" do
    before :once do
      course_with_teacher
      @import_all_migration = @course.content_migrations.create!(
        migration_settings: { migration_ids_to_import: { copy: { everything: "1" } } }
      )
    end

    it "imports all nav menu links from data" do
      data = {
        "nav_menu_links" => [
          { "migration_id" => "pm_link_1", "label" => "Link One", "url" => "https://one.com" },
          { "migration_id" => "pm_link_2", "label" => "Link Two", "url" => "https://two.com" }
        ]
      }

      expect { Importers::NavMenuLinkImporter.process_migration(data, @import_all_migration) }
        .to change { NavMenuLink.where(course: @course).count }.by(2)
    end

    it "does nothing when nav_menu_links key is absent or blank" do
      expect { Importers::NavMenuLinkImporter.process_migration({}, @import_all_migration) }
        .not_to change { NavMenuLink.count }
      expect { Importers::NavMenuLinkImporter.process_migration({ "nav_menu_links" => [] }, @import_all_migration) }
        .not_to change { NavMenuLink.count }
      expect { Importers::NavMenuLinkImporter.process_migration({ "nav_menu_links" => nil }, @import_all_migration) }
        .not_to change { NavMenuLink.count }
    end

    it "skips import when course_settings are not selected" do
      # A non-empty copy hash with no course_settings key means selective import w/o settings
      migration = @course.content_migrations.create!(
        migration_settings: { migration_ids_to_import: { copy: { all_assignments: "1" } } }
      )
      data = { "nav_menu_links" => [{ "migration_id" => "pm_skip_1", "label" => "L", "url" => "https://x.com" }] }
      expect { Importers::NavMenuLinkImporter.process_migration(data, migration) }
        .not_to change { NavMenuLink.count }
    end

    it "adds a warning and continues past a failed link import" do
      migration = @course.content_migrations.create!(
        migration_settings: { migration_ids_to_import: { copy: { everything: "1" } } }
      )
      data = {
        "nav_menu_links" => [
          { migration_id: "pm_bad_link", label: "Bad", url: "https://bad.com" },
          { migration_id: "pm_good_link", label: "Good", url: "https://good.com" }
        ]
      }

      allow(Importers::NavMenuLinkImporter).to receive(:import_from_migration).and_call_original
      allow(Importers::NavMenuLinkImporter).to receive(:import_from_migration)
        .with(hash_including(migration_id: "pm_bad_link"), anything, anything, anything)
        .and_raise(StandardError, "boom")

      expect(migration).to receive(:add_import_warning).with("Custom Link", "Bad", instance_of(StandardError))
      Importers::NavMenuLinkImporter.process_migration(data, migration)

      expect(NavMenuLink.where(course: @course, migration_id: "pm_good_link")).to exist
    end

    it "skips processing if there is an existing links for the migration id and course" do
      existing_link = NavMenuLink.create!(
        course: @course,
        course_nav: true,
        migration_id: "pm_existing_1",
        label: "Existing",
        url: "https://existing.com"
      )
      NavMenuLink.create!(
        course: Course.create!,
        course_nav: true,
        migration_id: "pm_other_course_1",
        label: "Existing Migration ID but wrong course",
        url: "https://existing2.com"
      )

      data = {
        "nav_menu_links" => [
          { "migration_id" => "pm_existing_1", "label" => "Updated", "url" => "https://updated.com" },
          { "migration_id" => "pm_other_course_1", "label" => "New", "url" => "https://new.com" }
        ]
      }

      expect { Importers::NavMenuLinkImporter.process_migration(data, @import_all_migration) }
        .to change { NavMenuLink.where(course: @course).count }.by(1)

      expect(NavMenuLink.where(course: @course, migration_id: "pm_existing_1").count).to eq 1
      expect(NavMenuLink.where(course: @course, migration_id: "pm_other_course_1").count).to eq 1

      # Links are immutable for now; existing record should be unchanged
      existing_link.reload
      expect(existing_link.label).to eq "Existing"
      expect(existing_link.url).to eq "https://existing.com"
    end
  end
end
