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

        Importers::WikiPageImporter.import_from_migration(data, context)
        Importers::WikiPageImporter.import_from_migration(data, context)
        context.wiki.wiki_pages.count.should == 1

        wiki = WikiPage.find_by_migration_id(data[:migration_id])
        wiki.title.should == data[:title]
      end
    end
  end

  it "should update BB9 wiki page links to the correct url" do
    data = get_import_data('bb9', 'wikis')
    context = get_import_context('bb9')
    2.times do
      data.each do |wiki|
        Importers::WikiPageImporter.import_from_migration(wiki, context)
      end
    end
    
    # The wiki references should resolve to course urls
    context.wiki.wiki_pages.count.should == 18
    wiki = WikiPage.find_by_migration_id('res00146')
    (wiki.body =~ /\/courses\/\d+\/wiki\/course-glossary-a-to-d/).should_not be_nil
    (wiki.body =~ /\/courses\/\d+\/wiki\/course-glossary-e-f-g-h/).should_not be_nil
    (wiki.body =~ /\/courses\/\d+\/wiki\/course-glossary-i-j-k-l-m/).should_not be_nil
    (wiki.body =~ /\/courses\/\d+\/wiki\/course-glossary-n-o-p-q-r/).should_not be_nil
  end
end
