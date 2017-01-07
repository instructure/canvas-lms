#
# Copyright (C) 2011 Instructure, Inc.
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

describe "Importing wikis" do

  SYSTEMS.each do |system|
    if import_data_exists? system, 'wiki'
      it "should import for #{system}" do
        data = get_import_data(system, 'wiki')
        context = get_import_context(system)
        migration = context.content_migrations.create!

        Importers::WikiPageImporter.import_from_migration(data, context, migration)
        Importers::WikiPageImporter.import_from_migration(data, context, migration)
        expect(context.wiki.wiki_pages.count).to eq 1

        wiki = WikiPage.where(migration_id: data[:migration_id]).first
        expect(wiki.title).to eq data[:title]
      end
    end
  end

  it "should update BB9 wiki page links to the correct url" do
    data = get_import_data('bb9', 'wikis')
    context = get_import_context('bb9')
    migration = context.content_migrations.create!
    2.times do
      data.each do |wiki|
        Importers::WikiPageImporter.import_from_migration(wiki, context, migration)
      end
    end
    migration.resolve_content_links!

    # The wiki references should resolve to course urls
    expect(context.wiki.wiki_pages.count).to eq 18
    wiki = WikiPage.where(migration_id: 'res00146').first
    expect(wiki.body =~ /\/courses\/\d+\/pages\/course-glossary-a-to-d/).not_to be_nil
    expect(wiki.body =~ /\/courses\/\d+\/pages\/course-glossary-e-f-g-h/).not_to be_nil
    expect(wiki.body =~ /\/courses\/\d+\/pages\/course-glossary-i-j-k-l-m/).not_to be_nil
    expect(wiki.body =~ /\/courses\/\d+\/pages\/course-glossary-n-o-p-q-r/).not_to be_nil
  end

  it 'should resurrect deleted pages' do
    data = get_import_data('bb9', 'wiki')
    context = get_import_context('bb9')
    migration = context.content_migrations.create!
    Importers::WikiPageImporter.import_from_migration(data, context, migration)
    page = context.wiki.wiki_pages.last
    page.destroy
    Importers::WikiPageImporter.import_from_migration(data, context, migration)
    expect(page.reload).not_to be_deleted
  end
end
