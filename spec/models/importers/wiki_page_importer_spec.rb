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

require_relative "../../import_helper"

describe "Importing wikis" do
  SYSTEMS.each do |system|
    next unless import_data_exists? system, "wiki"

    it "imports for #{system}" do
      data = get_import_data(system, "wiki")
      context = get_import_context(system)
      migration = context.content_migrations.create!

      Importers::WikiPageImporter.import_from_migration(data, context, migration)
      Importers::WikiPageImporter.import_from_migration(data, context, migration)
      expect(context.wiki_pages.count).to eq 1

      wiki = WikiPage.where(migration_id: data[:migration_id]).first
      expect(wiki.title).to eq data[:title]
    end
  end

  it "updates BB9 wiki page links to the correct url" do
    data = get_import_data("bb9", "wikis")
    context = get_import_context("bb9")
    migration = context.content_migrations.create!
    2.times do
      data.each do |wiki|
        Importers::WikiPageImporter.import_from_migration(wiki, context, migration)
      end
    end
    migration.resolve_content_links!

    # The wiki references should resolve to course urls
    expect(context.wiki_pages.count).to eq 18
    wiki = WikiPage.where(migration_id: "res00146").first
    expect(wiki.body =~ %r{/courses/\d+/pages/course-glossary-a-to-d}).not_to be_nil
    expect(wiki.body =~ %r{/courses/\d+/pages/course-glossary-e-f-g-h}).not_to be_nil
    expect(wiki.body =~ %r{/courses/\d+/pages/course-glossary-i-j-k-l-m}).not_to be_nil
    expect(wiki.body =~ %r{/courses/\d+/pages/course-glossary-n-o-p-q-r}).not_to be_nil
  end

  it "resurrects deleted pages" do
    data = get_import_data("bb9", "wiki")
    context = get_import_context("bb9")
    migration = context.content_migrations.create!
    Importers::WikiPageImporter.import_from_migration(data, context, migration)
    page = context.wiki_pages.last
    page.destroy
    Importers::WikiPageImporter.import_from_migration(data, context, migration)
    expect(page.reload).not_to be_deleted
  end

  describe "conditional release and hidden assignment" do
    before do
      stub_const("ASSIGNMENT_MIGRATION_ID", "0000001")

      Account.site_admin.disable_feature!(:wiki_page_mastery_path_no_assignment_group)
    end

    let(:assignment_hash) do
      {
        migration_id: ASSIGNMENT_MIGRATION_ID,
        title: "wiki page assignment",
        submission_types: "wiki_page",
        only_visible_to_overrides: true,
        assignment_group_migration_id: nil,
        assignment_overrides: []
      }
    end

    it "imports the wiki page" do
      data = get_import_data("bb9", "wiki")

      data[:assignment] = assignment_hash

      context = get_import_context("bb9")
      context.conditional_release = true
      migration = context.content_migrations.create!

      Importers::WikiPageImporter.import_from_migration(data, context, migration)

      assignment = context.assignments.where(migration_id: ASSIGNMENT_MIGRATION_ID).first
      expect(assignment.assignment_group.name).to eq("Imported Assignments")
    end

    context "wiki_page_mastery_path_no_assignment_group is on" do
      before do
        Account.site_admin.enable_feature!(:wiki_page_mastery_path_no_assignment_group)
      end

      it "assignment group is nil" do
        data = get_import_data("bb9", "wiki")
        context = get_import_context("bb9")
        context.conditional_release = true
        migration = context.content_migrations.create!

        data[:assignment] = assignment_hash

        Importers::WikiPageImporter.import_from_migration(data, context, migration)

        assignment = context.assignments.where(migration_id: ASSIGNMENT_MIGRATION_ID).first
        expect(assignment.assignment_group).to be_nil
      end
    end
  end
end
