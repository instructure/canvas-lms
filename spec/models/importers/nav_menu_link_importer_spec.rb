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
      # The importer catches the validation error and adds a warning instead of raising
      expect(@import_all_migration).to receive(:add_warning).with(match(/Custom Link could not be imported/))

      result = Importers::NavMenuLinkImporter.import_from_migration(hash, @course, @import_all_migration, existing_links)

      expect(result).to be_nil
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

    let(:base_data) { { "course" => { "tab_configuration" => [] } }.with_indifferent_access }

    it "imports all nav menu links from data" do
      data = base_data.merge(
        "nav_menu_links" => [
          { "migration_id" => "pm_link_1", "label" => "Link One", "url" => "https://one.com" },
          { "migration_id" => "pm_link_2", "label" => "Link Two", "url" => "https://two.com" }
        ]
      )

      expect { Importers::NavMenuLinkImporter.process_migration(data, @import_all_migration) }
        .to change { NavMenuLink.where(course: @course).count }.by(2)
    end

    it "does nothing when nav_menu_links key is absent or blank" do
      expect { Importers::NavMenuLinkImporter.process_migration(base_data, @import_all_migration) }
        .not_to change { NavMenuLink.count }
      expect { Importers::NavMenuLinkImporter.process_migration(base_data.merge("nav_menu_links" => []), @import_all_migration) }
        .not_to change { NavMenuLink.count }
      expect { Importers::NavMenuLinkImporter.process_migration(base_data.merge("nav_menu_links" => nil), @import_all_migration) }
        .not_to change { NavMenuLink.count }
    end

    it "skips import when course_settings are not selected" do
      # A non-empty copy hash with no course_settings key means selective import w/o settings
      migration = @course.content_migrations.create!(
        migration_settings: { migration_ids_to_import: { copy: { all_assignments: "1" } } }
      )
      data = base_data.merge("nav_menu_links" => [{ "migration_id" => "pm_skip_1", "label" => "L", "url" => "https://x.com" }])
      expect { Importers::NavMenuLinkImporter.process_migration(data, migration) }
        .not_to change { NavMenuLink.count }
    end

    it "adds a warning and continues past a failed link import" do
      migration = @course.content_migrations.create!(
        migration_settings: { migration_ids_to_import: { copy: { everything: "1" } } }
      )
      data = base_data.merge(
        "nav_menu_links" => [
          { migration_id: "pm_bad_link", label: "Bad", url: "https://bad.com" },
          { migration_id: "pm_good_link", label: "Good", url: "https://good.com" }
        ]
      )

      allow(Importers::NavMenuLinkImporter).to receive(:import_from_migration).and_call_original
      allow(Importers::NavMenuLinkImporter).to receive(:import_from_migration)
        .with(hash_including(migration_id: "pm_bad_link"), anything, anything, anything)
        .and_raise(StandardError, "boom")

      expect(migration).to receive(:add_warning).with(match(/Custom Link could not be imported: Bad/), hash_including(:error_report_id))
      Importers::NavMenuLinkImporter.process_migration(data, migration)

      expect(NavMenuLink.where(course: @course, migration_id: "pm_good_link")).to exist
    end

    it "creates an error report when an unexpected error occurs during import" do
      migration = @course.content_migrations.create!(
        migration_settings: { migration_ids_to_import: { copy: { everything: "1" } } }
      )
      data = base_data.merge(
        "nav_menu_links" => [
          { migration_id: "pm_error_link", label: "Error Link", url: "https://error.com" }
        ]
      )

      error = StandardError.new("unexpected error")
      mock_error_report = 12_345

      allow(Importers::NavMenuLinkImporter).to receive(:import_from_migration).and_call_original
      allow(Importers::NavMenuLinkImporter).to receive(:import_from_migration)
        .with(hash_including(migration_id: "pm_error_link"), anything, anything, anything)
        .and_raise(error)

      expect(Canvas::Errors).to receive(:capture_exception)
        .with(:import_nav_menu_links, error)
        .and_return({ error_report: mock_error_report })

      expect(migration).to receive(:add_warning)
        .with(match(/Custom Link could not be imported: Error Link/), { error_report_id: mock_error_report })

      Importers::NavMenuLinkImporter.process_migration(data, migration)

      expect(NavMenuLink.where(course: @course, migration_id: "pm_error_link")).not_to exist
    end

    context "with master course import" do
      let(:master_course_migration) do
        @course.content_migrations.create!(
          migration_settings: { migration_ids_to_import: { copy: { everything: "1" } } }
        ).tap { |m| allow(m).to receive(:for_master_course_import?).and_return(true) }
      end

      it "deletes orphaned master course nav links not present in data" do
        orphaned_link = NavMenuLink.create!(
          course: @course,
          course_nav: true,
          url: "http://example.com",
          label: "Orphaned",
          migration_id: "mastercourse_1_1_orphaned"
        )
        kept_link = NavMenuLink.create!(
          course: @course,
          course_nav: true,
          url: "http://example.com",
          label: "Kept",
          migration_id: "mastercourse_1_1_kept"
        )
        kept_nonmastercourse_link = NavMenuLink.create!(
          course: @course,
          course_nav: true,
          url: "http://example.com",
          label: "Non-master-course",
          migration_id: "not-from-mastercourse"
        )

        data = base_data.merge(
          "nav_menu_links" => [
            { "migration_id" => "mastercourse_1_1_kept", "label" => "Kept", "url" => "http://example.com" }
          ]
        )

        Importers::NavMenuLinkImporter.process_migration(data, master_course_migration)

        expect(orphaned_link.reload.workflow_state).to eq "deleted"
        expect(kept_link.reload.workflow_state).to eq "active"
        expect(kept_nonmastercourse_link.reload.workflow_state).to eq "active"
      end

      it "does not delete links when course settings were not included in the sync" do
        existing_link = NavMenuLink.create!(
          course: @course,
          course_nav: true,
          url: "http://example.com",
          label: "Existing",
          migration_id: "mastercourse_1_1_existing"
        )

        # No "course" key in data simulates a blueprint sync where course settings
        # were not checked — should_process? returns false and links are untouched
        data = { "nav_menu_links" => [] }

        Importers::NavMenuLinkImporter.process_migration(data, master_course_migration)

        expect(existing_link.reload.workflow_state).to eq "active"
      end
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

      data = base_data.merge(
        "nav_menu_links" => [
          { "migration_id" => "pm_existing_1", "label" => "Updated", "url" => "https://updated.com" },
          { "migration_id" => "pm_other_course_1", "label" => "New", "url" => "https://new.com" }
        ]
      )

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

  describe "URL conversion during import" do
    subject { NavMenuLink.active.find_by(migration_id: "nav_link_test") }

    before(:once) { course_model }

    let_once(:assignment) do
      asmt = @course.assignments.create!(title: "Test Assignment")
      asmt.migration_id = "test_migration_id"
      asmt.save!
      asmt
    end

    let_once(:page) do
      @course.wiki_pages.create!(title: "Test Page", url: "test_page_slug")
    end

    let_once(:migration) { @course.content_migrations.create! }

    def process_migration_with_link(url)
      nav_menu_links_data = [
        {
          migration_id: "nav_link_test",
          label: "Test Link",
          url:
        }
      ]
      Importers::NavMenuLinkImporter.process_migration(
        { "nav_menu_links" => nav_menu_links_data, "course" => { "tab_configuration" => [] } }.with_indifferent_access,
        migration
      )
    end

    it "converts various URL types correctly" do
      test_cases = {
        # External URLs are preserved
        "https://example.com/some/path" => "https://example.com/some/path",
        "http://example.com/" => "http://example.com/",
        "https://example.com/123?456#789" => "https://example.com/123?456#789",
        "https://example.com/courses/123/assignments/123" => "https://example.com/courses/123/assignments/123",

        # Canvas object references
        "$CANVAS_OBJECT_REFERENCE$/assignments/#{assignment.migration_id}" => "/courses/#{@course.id}/assignments/#{assignment.id}",
        "$CANVAS_OBJECT_REFERENCE$/assignments/#{assignment.migration_id}?foo=bar&baz=qux" => "/courses/#{@course.id}/assignments/#{assignment.id}?foo=bar&baz=qux",
        "%24CANVAS_OBJECT_REFERENCE%24/assignments/#{assignment.migration_id}" => "/courses/#{@course.id}/assignments/#{assignment.id}",

        # Page references
        "$CANVAS_OBJECT_REFERENCE$/pages/#{page.url}#section1" => "/courses/#{@course.id}/pages/#{page.url}#section1",
        "$WIKI_REFERENCE$/pages/#{page.url}" => "/courses/#{@course.id}/pages/#{page.url}",
        "$WIKI_REFERENCE$/pages/#{page.url}#hello-world" => "/courses/#{@course.id}/pages/#{page.url}#hello-world",
        "$WIKI_REFERENCE$/pages/slug-no-exist" => "/courses/#{@course.id}/pages/slug-no-exist",
        "$WIKI_REFERENCE$/pages/slug-no-exist#hello-world" => "/courses/#{@course.id}/pages/slug-no-exist#hello-world",

        # Course references
        "$CANVAS_COURSE_REFERENCE$/" => "/courses/#{@course.id}/",
        "$CANVAS_COURSE_REFERENCE$/settings#tab-navigation" => "/courses/#{@course.id}/settings#tab-navigation",
        "$CANVAS_COURSE_REFERENCE$/assignments/" => "/courses/#{@course.id}/assignments/",

        # URLs with invalid placeholders are preserved (when they're valid HTTP URLs)
        "http://example.com/$WHATEVER$/foo" => "http://example.com/$WHATEVER$/foo",
        "http://example.com/$123$/foo" => "http://example.com/$123$/foo",
        "http://example.com/$/foo" => "http://example.com/$/foo",
        "http://example.com/courses/123/assignments/$CANVAS_OBJECT_REFERENCE$" => "http://example.com/courses/123/assignments/$CANVAS_OBJECT_REFERENCE$",

        # Course reference in external domain gets relative-ized
        "http://example.com/$CANVAS_COURSE_REFERENCE$/foo" => "/courses/#{@course.id}/foo"
      }

      last_warning = nil
      allow(migration).to receive(:add_warning) do |*args|
        last_warning = args
      end

      test_cases.each do |input_url, expected_url|
        NavMenuLink.where(migration_id: "nav_link_test").destroy_all
        process_migration_with_link(input_url)
        # Don't use subject here as it's cached within the example
        link = NavMenuLink.active.find_by(migration_id: "nav_link_test")
        expect(link&.url).to eq(expected_url), "Failed for input: #{input_url}, got link&.url: #{link&.url.inspect}, last_warning: #{last_warning.inspect}"
      end
    end

    context "when conversion returns nil" do
      [
        "$CANVAS_OBJECT_REFERENCE$/assignments/nonexistent_migration_id",
        "http://$CANVAS_OBJECT_REFERENCE$/assignments/g2fac96de3e3dc1270155dddedb5bb1ce"
      ].each do |input_url|
        it "does not create a link for #{input_url}" do
          allow(migration).to receive(:add_warning).and_call_original
          process_migration_with_link(input_url)
          link = NavMenuLink.active.find_by(migration_id: "nav_link_test")
          expect(link).to be_nil, "Expected no link to be created for: #{input_url}"
          expect(migration).to have_received(:add_warning).with(/To link to this resource, add it manually/)
        end
      end
    end

    it "shows a validation warning when given a url that fails validation" do
      allow(migration).to receive(:add_warning).and_call_original

      input_url = "$  $/path"
      process_migration_with_link(input_url)

      link = NavMenuLink.active.find_by(migration_id: "nav_link_test")
      expect(migration).to have_received(:add_warning).with(/could not be imported.*is not a valid URL/)
      expect(link).to be_nil
    end

    context "urls for which conversion returns a /file_contents/ path" do
      [
        "$CANVAS_COURSE_REFERENCE",
        "/$123",
        "$",
        "$CANVAS_COURSE_REFERENCE$",
      ].each do |input_url|
        it "creates a link for #{input_url.inspect}" do
          process_migration_with_link(input_url)

          link = NavMenuLink.active.find_by(migration_id: "nav_link_test")
          expect(link&.url).to include(input_url), "link mismatch: got #{link&.url.inspect}, expected to contain original [possibly bad] input link #{input_url}"
        end
      end
    end
  end
end
